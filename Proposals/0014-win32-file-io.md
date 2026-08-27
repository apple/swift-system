# File I/O on `Win32.FileHandle`

* Proposal: [SYS-0014](0014-win32-file-io.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md), [SYS-0012](0012-win32-opening-handles.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds reading, writing, seeking, flushing, and resizing to `Win32.FileHandle`, the type introduced in [SYS-0011](0011-win32-filehandle.md).

## Motivation

`Win32.FileHandle` needs an I/O surface, and designing it for Windows rather than mirroring `FileDescriptor` gives it three advantages.

### Positional I/O with Windows semantics

`FileDescriptor.read(fromAbsoluteOffset:into:)` corresponds to `pread`, which leaves the file pointer where it is. However, Windows has no `pread`, so System calls `ReadFile` at the offset instead. This moves the pointer, and even resetting it wouldn't be atomic. Documenting that would warn callers, but code that assumes `pread` semantics, like a sequential read after a positional one, would still read the wrong bytes on Windows.

`Win32.FileHandle` can instead make Windows' file I/O behavior its contract and point callers who need an independent pointer to `reopen(access:shareMode:flags:)`. It can also document that pipes, consoles, and append-only handles ignore a provided offset.

### Defined behavior above `DWORD.max`

`ReadFile` and `WriteFile` take a `DWORD` byte count, so one transfer moves at most 4 GiB - 1 byte. Each Win32 entry point can state what it does with a larger span, either splitting it across calls or rejecting it. `FileDescriptor` handles a larger buffer inconsistently. Its positional methods throw `Errno.invalidArgument`, while `FileDescriptor.read(into:)` and `FileDescriptor.write(_:)` trap, since their adapters `numericCast` the count to the C runtime's `unsigned int`.

### Declarations for modern Swift

This surface can take spans, throw a concrete error type, and shape transfers around Windows' behavior. A synchronous `WriteFile` rarely comes up short, so a single `write(_:toAbsoluteOffset:)` can transfer the whole span. `FileDescriptor` predates `Span` and typed throws, so it takes `UnsafeMutableRawBufferPointer` and throws an untyped error, and it splits writing into `FileDescriptor.write` and `FileDescriptor.writeAll` because `write(2)` can come up short.

## Proposed solution

Add the I/O surface in Win32's own shape, with spans as the currency type.

```swift
#if os(Windows)
let handle = try Win32.FileHandle.open(
  path, access: [.genericRead, .genericWrite]
)

// `readFully` stops only at a full span or end of file.
let header = try [UInt8](capacity: 512) { span in
  try handle.readFully(fromAbsoluteOffset: 0, into: &span)
}
guard header.count == 512 else { throw HeaderError.truncated }
// `write` transfers the whole span.
try handle.write(header.span.bytes, toAbsoluteOffset: 0)

// Flushing is for commit points like this header, not every write.
try handle.flush()
try handle.close()
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them. The span types require Swift 6.2; see **Implications on adoption**.

Each operation requires a matching right in the handle's `Win32.AccessMask`:

| Operation | Required right |
| --- | --- |
| Read | `.readData` |
| Write, append, flush | `.writeData` or `.appendData` |
| Resize | `.writeData` |
| Seek | none |
| `size()` | none |

These operations share the handle's one file pointer which belongs to the file object, so concurrent use is memory-safe but races that pointer. A handle that's duplicated, inherited by a child process, or bridged via `FileDescriptor.withWin32HandleIfAvailable(_:)` all move the same pointer. An independent pointer requires a second `open` or `reopen(access:shareMode:flags:)`. Windows also serializes I/O on a synchronous handle, so concurrent positional reads don't run in parallel, and while one thread waits in a read on a pipe or console, most other calls on that handle wait too, including `size()`, seeks, a write in the other direction, and `PeekNamedPipe`. (`fileType()` from [SYS-0015](0015-win32-file-type.md) doesn't wait.) None of these synchronous operations are valid on a `FILE_FLAG_OVERLAPPED` handle, which is why [SYS-0012](0012-win32-opening-handles.md) makes `.overlapped` unavailable and `Win32.FileHandle` rejects the flag at `open`.

### Position and length types

Every absolute position and length is an `Int64`, or an `Int64?` where `nil` means the current file pointer, matching the signed `LARGE_INTEGER` Windows takes. The `offset` of `seek(offset:from:)` is a displacement, so it accepts negative values.

For other operations, a negative value fails, mostly from the Win32 layer itself: `seek(to:)` throws `.negativeSeek`, and `resize(to:)` throws `.invalidParameter`. The positional transfers are the exception and reject a negative `offset` _before_ the Win32 call. This is because two "negative" bit patterns are `OVERLAPPED` sentinels, `-1` for appending and `-2` for transferring at the current file pointer. These use cases are satisfied using a `nil` offset and `append(_:)`, so rejecting negative values doesn't hurt usability and keeps arithmetic from silently reaching a sentinel.

Windows ignores `offset` on a device that doesn't support byte offsets, such as a pipe or console. It also ignores it for writes on a handle opened with `.appendData` but not `.writeData` access, since that handle appends every write to the end of the file.

### Reading

> Note: An empty span still issues its `ReadFile` or `WriteFile`; on a message-mode pipe, a zero-length write sends a zero-length message.

```swift
extension Win32.FileHandle {
  /// Reads bytes starting at `offset`, or the current file pointer when
  /// `offset` is `nil`.
  ///
  /// Calls `ReadFile` once. A short read ends the call, which can be useful
  /// when reading from a pipe or console. To read until `span` is full or the
  /// file ends, use ``readFully(fromAbsoluteOffset:into:)-(_,MutableRawSpan)``.
  ///
  /// Throws ``Win32/Error/invalidParameter`` if
  /// - `offset` is negative, or
  /// - `span` is larger than the `DWORD.max` bytes `ReadFile` can express.
  ///
  /// - Important: Reading from a non-`nil` `offset` also updates the file
  ///   pointer, unlike POSIX `pread`.
  ///
  /// - Returns: The number of bytes read, which may be fewer than
  ///   `span.byteCount`. Zero indicates end of file, an empty `span`, a
  ///   zero-length pipe message, or a serial port time-out.
  ///
  /// The corresponding C function is `ReadFile`, with an `OVERLAPPED` offset
  /// when `offset` is non-`nil`.
  public func read(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout MutableRawSpan
  ) throws(Win32.Error) -> Int

  public func read(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout MutableSpan<UInt8>
  ) throws(Win32.Error) -> Int

  /// Reads bytes starting at `offset`, or the current file pointer when
  /// `offset` is `nil`, into `span`'s free capacity.
  ///
  /// - Returns: The number of bytes read. `span.byteCount` also grows by
  ///   this amount. Zero indicates end of file, no free capacity, a
  ///   zero-length pipe message, or a serial port time-out.
  @discardableResult
  public func read(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout OutputRawSpan
  ) throws(Win32.Error) -> Int

  @discardableResult
  public func read(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout OutputSpan<UInt8>
  ) throws(Win32.Error) -> Int

  /// Reads bytes starting at `offset`, or the current file pointer when
  /// `offset` is `nil`, until `span` is full or the file ends.
  ///
  /// Unlike ``read(fromAbsoluteOffset:into:)-(_,MutableRawSpan)``, a short
  /// read ends the transfer only if it reads zero bytes or comes from a disk
  /// file, where it means the file ended. A span larger than `DWORD.max`
  /// bytes is split across calls to `ReadFile` rather than rejected.
  ///
  /// Throws ``Win32/Error/invalidParameter`` if `offset` is negative.
  ///
  /// - Important: On a pipe or console, this blocks until the span fills, so
  ///   an over-sized span will hang for as long as the writer stays open.
  ///   Size the span to a length given by the transfer protocol, or use
  ///   ``read(fromAbsoluteOffset:into:)-(_,MutableRawSpan)`` to only read
  ///   bytes that are currently available.
  ///
  /// - Returns: The number of bytes read. A number less than `span.byteCount`
  ///   signifies the end of the file. If a `ReadFile` fails, the bytes already
  ///   read stay initialized in `span`.
  ///
  /// The corresponding C function is `ReadFile`, called in a loop.
  public func readFully(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout MutableRawSpan
  ) throws(Win32.Error) -> Int

  public func readFully(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout MutableSpan<UInt8>
  ) throws(Win32.Error) -> Int

  /// Reads bytes starting at `offset`, or the current file pointer when
  /// `offset` is `nil`, until `span` has no free capacity or the file ends.
  ///
  /// - Returns: The number of bytes read. `span.byteCount` also grows by
  ///   this amount, and still counts the bytes read if a later `ReadFile`
  ///   throws.
  @discardableResult
  public func readFully(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout OutputRawSpan
  ) throws(Win32.Error) -> Int

  @discardableResult
  public func readFully(
    fromAbsoluteOffset offset: Int64? = nil,
    into span: inout OutputSpan<UInt8>
  ) throws(Win32.Error) -> Int
}
```

Reading differs by device classes: on a disk file, `ReadFile` comes up short only at end of file, while on a pipe or console, it returns whatever has arrived. When calling `read(fromAbsoluteOffset:into:)` on a message-mode pipe, a message longer than `span` fills the span, and the rest of the message follows on the next read. Clients should be careful to size their span appropriately when calling `readFully(fromAbsoluteOffset:into:)` on a pipe or console; a span too large will hang waiting for writer data that may not arrive. A caller can determine a handle's device class using `fileType()` from [SYS-0015](0015-win32-file-type.md). A read on a serial port can also return zero when a time-out elapses; see `COMMTIMEOUTS`. A console read that Ctrl+C interrupts succeeds with the last error set to `ERROR_OPERATION_ABORTED`, so reads clear the last error before each `ReadFile` and throw `.operationAborted` in this case instead of reporting the end of the file.

No read throws `.endOfFile` (`ERROR_HANDLE_EOF`). On a synchronous handle, a file-pointer (default `offset`) read at the end of file returns zero bytes while a read from that specific `offset` fails, so absorbing the code unifies the behavior. Likewise, no read throws `.brokenPipe` or `.pipeNotConnected`, which is how a pipe reports that its writer closed or its server disconnected; the C runtime's `_read` also returns 0 for the former. `readFully(fromAbsoluteOffset:into:)` returns the short count as documented: it stops at a zero-byte read on any handle, such as a pipe's final `ReadFile` or any read from `NUL`, and stops at the first short read on a handle whose `fileType()` is `.disk`.

### Writing

```swift
extension Win32.FileHandle {
  /// Writes the contents of `span` to the specified `offset`, or the current
  /// file pointer when `offset` is `nil`.
  ///
  /// This loops until the span is exhausted by splitting a span larger than
  /// `DWORD.max` bytes across multiple `WriteFile` calls.
  ///
  /// Throws ``Win32/Error/invalidParameter`` if `offset` is
  /// negative. To write at the end of the file, use ``append(_:)``.
  ///
  /// - Important: Writing to a non-`nil` `offset` also updates the file
  ///   pointer, unlike POSIX `pwrite`.
  ///
  /// - Important: On a blocking pipe, this waits until the reader has taken
  ///   the whole span, so an over-sized span will hang until a reader fully
  ///   drains it.
  ///
  /// - Note: If a `WriteFile` succeeds without writing any of the given bytes,
  ///   the loop ends with a synthesized ``Win32/Error/incompleteTransfer``
  ///   instead of retrying forever. A legacy `PIPE_NOWAIT` pipe reports a span
  ///   that doesn't fit this way. Such a write is all-or-nothing, so only retry
  ///   a `span` that will fit in the pipe's buffer.
  ///
  /// The corresponding C function is `WriteFile`, called in a loop, with an
  /// `OVERLAPPED` offset when `offset` is non-`nil`.
  public func write(
    _ span: RawSpan,
    toAbsoluteOffset offset: Int64? = nil
  ) throws(Win32.Error)

  /// Writes `span` like ``write(_:toAbsoluteOffset:)``, but advances the start
  /// of `span` to exclude the bytes that were written.
  ///
  /// If this throws, `span` holds the bytes that weren't written. On success,
  /// `span` is empty. To resume after a throw, advance `offset` by the number
  /// of bytes written, if needed.
  public func write(
    draining span: inout RawSpan,
    toAbsoluteOffset offset: Int64? = nil
  ) throws(Win32.Error)

  /// Writes the contents of `span` to the end of the file.
  ///
  /// Calls `WriteFile` once, transferring the whole span or throwing. The file
  /// pointer is updated to the new end of file.
  ///
  /// Throws ``Win32/Error/invalidParameter`` if `span` is larger
  /// than `DWORD.max` bytes. A single `WriteFile` can't express this size, and
  /// looping would risk another writer appending between the chunks.
  ///
  /// - Note: Because the append is all-or-nothing, a `WriteFile` that succeeds
  ///   without taking the whole span throws ``Win32/Error/incompleteTransfer``.
  ///   A legacy `PIPE_NOWAIT` pipe reports a span that doesn't fit this way;
  ///   see ``write(_:toAbsoluteOffset:)``.
  ///
  /// The corresponding C function is `WriteFile` with an `OVERLAPPED` offset of `-1`.
  public func append(_ span: RawSpan) throws(Win32.Error)

  /// Appends `span` like ``append(_:)``, but advances the start of `span` to
  /// exclude the bytes that were written.
  ///
  /// If this throws, `span` holds the bytes that weren't written. On success,
  /// `span` is empty.
  public func append(draining span: inout RawSpan) throws(Win32.Error)
}
```

`write(_:toAbsoluteOffset:)` has no single-`WriteFile` counterpart to `read(fromAbsoluteOffset:into:)` because on a synchronous handle, a successful short write is uncommon: a disk file transfers everything or fails (a full volume throws an error with no bytes written), and a blocking pipe blocks until it has taken the whole span. Asynchronous writes belong to the excluded `FILE_FLAG_OVERLAPPED` surface.

This leaves three cases where a successful write may be shorter than the given span:
- A `PIPE_NOWAIT` pipe, which Windows discourages new applications from using, reports 0 bytes written when the span doesn't fit in the available space. In testing, this occurred even when part of the span would fit, despite documentation claiming a byte-mode pipe will write what fits.
- A serial port with a write time-out (see `COMMTIMEOUTS`) can complete a write early with a short count. `write` keeps writing the remainder, so each call can wait for the time-out again.
- The span is larger than `DWORD.max`, which is a restriction of `WriteFile`'s signature. Reporting this would tell a caller nothing but to write the loop this method already provides. See **Alternatives considered**.

A call that writes nothing while bytes remain ends the loop by throwing `.incompleteTransfer` rather than retrying forever.

`append(_:)` is its own entry point in part because the end-of-file sentinel is an `OVERLAPPED` offset of `-1`, which `write(_:toAbsoluteOffset:)` rejects. Unlike `write(_:toAbsoluteOffset:)`, `append(_:)` rejects a span above `DWORD.max` instead of splitting it. Calling `WriteFile` with the sentinel writes to the _current_ end of file, so two calls may interleave with another thread or process appending data. Rejecting an over-sized span means every successful append is a single, contiguous `WriteFile`. Therefore, `append(_:)` returns nothing and throws `.incompleteTransfer` on a short write. `append(draining:)` reports how much was written, which is none for a `PIPE_NOWAIT` pipe as described above. A partial write on failure, which didn't occur in testing, might occur for a serial port, an SMB redirector, or a mid-write quota.

Writes only take `RawSpan` since `Span.bytes` is easily accessible from any types we might consider for an overload.

### Non-buffered handles

On a handle opened with the `.noBuffering` flag, `ReadFile` requires a sector-multiple offset and length and a sector-aligned buffer address. A caller using a non-buffered handle must ensure their inputs satisfy all three, or `ReadFile` will fail with `.invalidParameter`. `readFully(fromAbsoluteOffset:into:)` splits an over-sized span at a sector multiple (not `DWORD.max`) to allow this use case, and stops at the first short read, since the next `ReadFile` would start at an unaligned offset and fail with `.invalidParameter` instead of reporting the end of the file.

`write(_:toAbsoluteOffset:)` also splits at a sector multiple since `WriteFile` imposes the same three requirements on a non-buffered handle. Because non-buffered writes must cover whole sectors, a caller writing a file whose length is not a sector multiple must pad the final write and then trim the file with `resize(to:)`.

### Progress on failure

Every transfer function throws `Win32.Error`, and one that fails after moving bytes may report that progress through its span:

* A read into an `OutputRawSpan` or `OutputSpan` grows `span.byteCount` as bytes arrive.
* `write(draining:toAbsoluteOffset:)` and `append(draining:)` drop bytes from the front of `span` as they're written.

Both survive a throw, since the `inout` parameters are written either way. Callers that don't need the count can pass a span to `write(_:toAbsoluteOffset:)` or `append(_:)` instead.

```swift
var rest = record.span.bytes
do {
  try handle.write(draining: &rest)
} catch .diskFull {
  // `rest` holds the bytes that weren't written.
}
```

A message-mode pipe reports a message longer than `span` as `ERROR_MORE_DATA`, with the prefix already in `span`. The single-call reads return that prefix as a short read instead of throwing `.moreData`, and the rest of the message arrives on the next read. `PeekNamedPipe` reports how much of it is left. `readFully(fromAbsoluteOffset:into:)` keeps reading, so it doesn't preserve message boundaries.

`.incompleteTransfer` is System's own synthesized code rather than the device's, as described in **Writing**.

### Seeking

```swift
extension Win32 {
  /// The reference point that a seek offset is measured from.
  @frozen
  public struct SeekOrigin: RawRepresentable, Sendable, Hashable, Codable {
    public var rawValue: DWORD
    public init(rawValue: DWORD)

    public static var start: SeekOrigin { get }    // FILE_BEGIN
    public static var current: SeekOrigin { get }  // FILE_CURRENT
    public static var end: SeekOrigin { get }      // FILE_END
  }
}

extension Win32.FileHandle {
  /// Returns the current position of the file pointer.
  ///
  /// - Warning: This function is not valid on a nonseeking device such as a
  ///   pipe or console. The call may succeed anyway, reporting a position
  ///   that no transfer ever advances, so file pointer arithmetic is invalid.
  ///
  /// The corresponding C function is `SetFilePointerEx` with zero offset
  /// from `FILE_CURRENT`.
  public func currentOffset() throws(Win32.Error) -> Int64

  /// Moves the file pointer to an absolute position.
  ///
  /// A negative `offset` throws ``Win32/Error/negativeSeek``, the error
  /// `SetFilePointerEx` sets when a displacement lands before the start
  /// of the file.
  ///
  /// - Warning: This function is not valid on a nonseeking device such as a
  ///   pipe or console. The call may succeed anyway, moving a position that
  ///   no transfer uses.
  ///
  /// The corresponding C function is `SetFilePointerEx`.
  public func seek(to offset: Int64) throws(Win32.Error)

  /// Moves the file pointer and returns its new absolute position.
  ///
  /// `offset` is a displacement from `origin`, so it may be negative. For
  /// instance, `-1` from ``Win32/SeekOrigin/end`` addresses the last byte.
  /// A displacement that would land before the start of the file throws
  /// ``Win32/Error/negativeSeek``.
  ///
  /// - Warning: This function is not valid on a nonseeking device such as a
  ///   pipe or console. The call may succeed anyway, returning a position
  ///   that no transfer ever advances, so file pointer arithmetic is invalid.
  ///
  /// The corresponding C function is `SetFilePointerEx`.
  @discardableResult
  public func seek(
    offset: Int64,
    from origin: Win32.SeekOrigin
  ) throws(Win32.Error) -> Int64
}
```

### Flushing

```swift
extension Win32.FileHandle {
  /// Flushes this file's buffered data to the device.
  ///
  /// Call this after writes that must survive power loss, such as a commit
  /// record. Most writes don't require flushing; readers already see the data
  /// without it, and each call costs a round trip to the device.
  ///
  /// This function provides a durability barrier similar to POSIX `fsync`. It
  /// writes this file's data out of the system cache and tells the device to
  /// commit its own volatile cache. For many writes that must each be durable,
  /// Windows recommends opening with the ``Win32/FileFlags/writeThrough`` and
  /// ``Win32/FileFlags/noBuffering`` flags instead, which also asks the
  /// device to write through its cache.
  ///
  /// - Important: On a pipe, this blocks until the reader has read everything
  ///   written so far.
  ///
  /// The corresponding C function is `FlushFileBuffers`.
  public func flush() throws(Win32.Error)
}
```

### Resizing

```swift
extension Win32.FileHandle {
  /// The size of the file, in bytes.
  ///
  /// - Warning: This function is not valid on a nonseeking device such as a
  ///   pipe or console. On a pipe, the call may succeed anyway and return an
  ///   unspecified value. To ask how many bytes a pipe has available to read,
  ///   use `PeekNamedPipe`.
  ///
  /// The corresponding C function is `GetFileSizeEx`.
  public func size() throws(Win32.Error) -> Int64

  /// Sets the end of the file to the current file pointer, truncating or
  /// extending it.
  ///
  /// Throws ``Win32/Error/userMappedFile`` when truncating a file that has a
  /// mapped view.
  ///
  /// The corresponding C function is `SetEndOfFile`.
  public func resizeToCurrentOffset() throws(Win32.Error)

  /// Truncates or extends the file to `newSize`, leaving the file pointer
  /// where it is.
  ///
  /// Throws ``Win32/Error/invalidParameter`` if `newSize` is negative, or
  /// larger than the file system can represent, and
  /// ``Win32/Error/userMappedFile`` when truncating a file that has a mapped
  /// view.
  ///
  /// The corresponding C function is `SetFileInformationByHandle` with
  /// `FileEndOfFileInfo`.
  public func resize(to newSize: Int64) throws(Win32.Error)
}
```

Writes already extend a file, but resizing can be used to decouple the file size from what's written. `resize(to:)` takes that size directly and is the usual choice. `resizeToCurrentOffset()` is a direct call to `SetEndOfFile`, which reads the size from the file pointer instead. Writing or scanning an existing longer file leaves the pointer at the new end, so `resizeToCurrentOffset()` can make the cut in one call. `try resize(to: handle.currentOffset())` would leave a window for another handle to move the pointer.

`resize(to:)` mirrors `FileDescriptor.resize(to:)` but resizes in one call without touching the file pointer, whereas System's `ftruncate` adapter seeks, resizes, and restores it non-atomically. Extending a file makes the new region read as zeros. A size past the volume's free space fails with `.diskFull`. No failure leaves the file partly resized.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

Everything here is reached through `Win32.FileHandle` and sits behind `#if os(Windows)`, so cross-platform callers must guard their uses. The span types require Swift 6.2, so System will need to raise its toolchain floor.

## Future directions

* **Asynchronous I/O.** `FILE_FLAG_OVERLAPPED` handles, caller-owned `OVERLAPPED` structures, I/O completion ports, and `CancelIoEx`. This is the largest remaining piece of the Win32 file surface. It interacts with the `IORing` work and deserves its own design.
* **Scatter/gather.** `ReadFileScatter` and `WriteFileGather` are the closest Win32 analogs to `readv` and `writev`. They need page-aligned, page-sized segments on an unbuffered, overlapped handle, so they belong with the asynchronous work.

## Alternatives considered

### Take positions and lengths as `UInt64`

Spell every position and size unsigned, since none can be negative, and reject anything above `Int64.max` before it reaches the signed C field.

Rejected because:

* `Int64` matches the underlying C fields, has precedent from `FileDescriptor.resize(to:)` and `FileDescriptor.seek(offset:from:)`, and keeps `Int` semantics where rejecting negative values is unsurprising (and matches the underlying Win32 behavior).
* Accepting a `UInt64` but rejecting values over `Int64.max` is surprising. Note the rejection would be necessary since those values reach Windows as negative offsets, including the append (`-1`) and transfer-at-file-pointer (`-2`) sentinels.

### Throw a `Win32.PartialTransferError` wrapper

Throw a `Win32.PartialTransferError` carrying `bytesTransferred` and the underlying `Win32.Error` from every transfer that can fail after moving bytes.

Rejected because:

* Typed throws has no implicit conversion, so a function that throws `Win32.Error` couldn't call a transfer without mapping the error.
* Every caller would carry a count that most ignore, and a `catch` clause would need `~=` to reach through the wrapper to name a code.
* Some span types already know how many bytes moved. Reporting progress there costs nothing for callers who don't ask.

### Ship a single-`WriteFile` write alongside the looping one

Mirror `FileDescriptor.write(_:)` and `FileDescriptor.writeAll(_:)`, keeping the pairing symmetric with the two read forms.

Rejected because:

* The two would be the same function for nearly every caller as **Writing** describes. Outside the three cases named there, a successful `WriteFile` on a synchronous handle takes the whole span.
* A caller who wants individual call handling can slice their span to the documented `DWORD.max` cap and write each piece. A caller who needs a serial port's write time-out to end the write can call `WriteFile` through `unsafeRawHandle` until a future proposal models communications devices.

### Return a byte count from `append(_:)`

Have `append(_:)` return the `lpNumberOfBytesWritten` that `WriteFile` reports, so a caller sees a short append.

Rejected because the return value would always be `span.byteCount`: a short append throws, and an over-`DWORD.max` span is rejected before the call. Throwing is safer since it can't be mistaken for a complete write; a returned count could instead be ignored. The count isn't lost either, since `append(draining:)` reports it via the `inout RawSpan`.

### Loop internally on every transfer

Have `read(fromAbsoluteOffset:into:)` loop too, so callers never see a short transfer and the `DWORD` cap disappears.

Rejected because a short read is meaningful on pipes and consoles, and hiding the cap would hide the point where a 5 GiB read becomes two system calls with a window between them. A short read can also be reported in the return value, which leaves the choice to the caller. A short write can only be reported by returning a count, which is rejected above, so `write(_:toAbsoluteOffset:)` loops and accepts the window.

### Throw at the end of the file from `readFully(fromAbsoluteOffset:into:)`

Treat a span that couldn't be filled as an error, as Go's `io.ReadFull` and Java's `readFully` do, so a successful call always means a full span.

Rejected because the end of the file is one expected outcome of reading rather than a failure, and a caller reading to the end would otherwise need to drive control flow through `catch`. This is unlike `append(_:)` where a short transfer is uncommon and throwing always reports a failure.

### Separate positional entry points

Declare `read(into:)` and `read(fromAbsoluteOffset:into:)` as distinct methods, as `FileDescriptor` does, rather than folding the offset into a defaulted `Int64?`.

Rejected because:

* It doubles an overload surface that's already wide.
* Windows, unlike POSIX, uses a single `ReadFile` call either way. The `Int64?` parameter matches the `lpOverlapped` argument it becomes in either case. Also, every `ReadFile` on a synchronous handle moves the pointer, so a single function can document this behavior.

### Clamp oversized spans instead of throwing

`read(fromAbsoluteOffset:into:)` and `append(_:)` could pass `min(span.byteCount, DWORD.max)` to Windows, reporting the short count from the read and dropping the tail of the append. This is similar to the clamping behavior of `read(2)` on Linux.

Rejected because a clamped read is indistinguishable from the end of the file without looping. A caller that stops on a short read would see a 5 GiB span report that the file ended at 4 GiB. Darwin `read(2)` also fails with `EINVAL` above `INT_MAX` and "do[es] not attempt a partial read." Clamping `append(_:)` is worse since it would return successfully having dropped the tail, so the API would need a new way to communicate that with the client. (Every other short append throws, and `append(draining:)` reports its length.)

### Hide the file-pointer side effect of positional I/O

Save and restore the file pointer around each positional call, so `read(fromAbsoluteOffset:into:)` matches `pread`.

Rejected because it turns one system call into three, is still not atomic against other users of the handle, and emulates POSIX while the reason to reach for `Win32.FileHandle` is to get Windows' semantics. A caller who wants `pread` semantics needs a second file object from another `open` or `reopen(access:shareMode:flags:)` (not `duplicate(access:inheritable:)`, since a duplicate shares the original's file pointer).

### Split the file pointer out of the handle

Put every operation that touches the file pointer on a non-`Sendable` cursor view: the transfers, `seek(to:)`, `seek(offset:from:)`, `currentOffset()`, and `resizeToCurrentOffset()`. `Win32.FileHandle` keeps the rest and stays `Sendable`, making the shared mutable position visible in the type system.

Rejected because:

* The view would hold the whole I/O surface, so the split doesn't isolate the hazard so much as rename the type that carries it.
* It prevents correct code that always uses positional transfers and has nothing to race.
* Swift can't enforce the split regardless. A duplicated handle, one inherited by a child process, and one bridged through `FileDescriptor.withWin32HandleIfAvailable(_:)` all move the same pointer, and a non-`Sendable` cursor doesn't stop them.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle.read(fromAbsoluteOffset:into:)` | `ReadFile`, with an `OVERLAPPED` offset when `offset` is non-`nil` |
| `Win32.FileHandle.readFully(fromAbsoluteOffset:into:)` | the same, called in a loop, and `GetFileType` |
| `Win32.FileHandle.write(_:toAbsoluteOffset:)` | `WriteFile`, with an `OVERLAPPED` offset when `offset` is non-`nil`, called in a loop |
| `Win32.FileHandle.append(_:)` | `WriteFile` with an `OVERLAPPED` offset of all ones |
| `Win32.FileHandle.write(draining:toAbsoluteOffset:)`, `append(draining:)` | the same, dropping bytes written from the front of `span` |
| `Win32.FileHandle.currentOffset()` | `SetFilePointerEx` with a zero `FILE_CURRENT` displacement |
| `Win32.FileHandle.seek(to:)` | `SetFilePointerEx` with `FILE_BEGIN` |
| `Win32.FileHandle.seek(offset:from:)` | `SetFilePointerEx`, with `liDistanceToMove` and `lpNewFilePointer` both signed |
| `Win32.SeekOrigin.start` / `.current` / `.end` | `FILE_BEGIN` / `FILE_CURRENT` / `FILE_END` |
| `Win32.FileHandle.flush()` | `FlushFileBuffers` |
| `Win32.FileHandle.size()` | `GetFileSizeEx` |
| `Win32.FileHandle.resizeToCurrentOffset()` | `SetEndOfFile` |
| `Win32.FileHandle.resize(to:)` | `SetFileInformationByHandle` with `FileEndOfFileInfo` |

Testing was performed on an ARM64 Windows 11 VM (build 22631), with every file on a local NTFS volume. The results for pipe blocking and disconnects, `PIPE_NOWAIT`, non-buffered and append-only handles, and mapped views were reproduced on an x64 Windows 11 PC (build 26200).
