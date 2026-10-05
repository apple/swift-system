# A Noncopyable `Win32.FileHandle`

* Proposal: [SYS-0011](0011-win32-filehandle.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds `Win32.FileHandle`, a noncopyable wrapper that owns a synchronous (non-overlapped) Windows `HANDLE`. It builds on the `Win32` namespace and `Win32Error` introduced in [SYS-0010](0010-win32-namespace-and-error.md). Opening a handle is proposed in [SYS-0012](0012-win32-opening-handles.md), and bridging with `FileDescriptor` in [SYS-0013](0013-win32-filedescriptor-bridging.md).

## Motivation

A `HANDLE` is Windows' canonical representation of an open file, and the Win32 APIs in this series need a type for it. `FileDescriptor` is a POSIX abstraction, and on Windows it's a C runtime file descriptor layered over the handle. That works for a POSIX shim, but it makes a poor Windows type in two ways.

### The descriptor is not the object

A C runtime descriptor is a second index over the handle and carries state of its own, including a translation mode. In text mode, the runtime rewrites bytes in transit, expanding `\n` to `\r\n` on write and collapsing it on read. Anything built on a descriptor inherits a translation setting that is invisible in System's APIs.

The descriptor also leaks Windows semantics into portable-looking APIs. For example, `FileDescriptor.read(fromAbsoluteOffset:into:)` on Windows calls `ReadFile` with an `OVERLAPPED` carrying the offset. However, passing an `OVERLAPPED` on a synchronous handle reads from the given offset *and* updates the file pointer, unlike POSIX `pread`. `FileDescriptor` should document that deviation, but a dedicated `Win32` type eliminates the POSIX contradiction entirely. See [SYS-0014](0014-win32-file-io.md).

### A copied handle is a use-after-close hazard

`FileDescriptor` is a copyable value with a non-consuming `FileDescriptor.close()`. Copy it, close one copy, and the other still compiles and still names a number. Windows also recycles handle values, so a stale copy may name a different kernel object and lead to I/O on the wrong file.

`FileDescriptor` keeps the copyable model because it's shipped ABI on Apple platforms and predates `~Copyable`. Neither constraint applies to new Windows APIs, so we should pursue an owning, noncopyable type instead. A double close or use after close then becomes a compile error, a dropped handle is closed rather than leaked, and every signature says clearly whether it borrows or consumes. System already ships a precedent: `Mach.Port` is a noncopyable owner that deallocates its port right in `deinit` and gives up ownership with `consuming func relinquish()`.

## Proposed solution

Add `Win32.FileHandle`, a `~Copyable` type that owns its handle and closes it with a `consuming func close()`.

```swift
#if os(Windows)
// `open` is proposed separately, in SYS-0012.
let file = try Win32.FileHandle.open(path, access: .genericRead)
try parse(file)   // Borrows `file`.
try file.close()  // Consumes `file` and reports any error.
try file.close()  // error: 'file' consumed more than once
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them. A `Win32.FileHandle` is always synchronous; see **Synchronous handles only**.

### `Win32.FileHandle`

```swift
extension Win32 {
  /// An open file, device, or pipe.
  ///
  /// This type owns its handle. Call ``close()`` to close it and report any
  /// error. Otherwise, `deinit` closes the handle at the end of its scope and
  /// discards the error.
  ///
  /// The corresponding C type is `HANDLE`.
  @frozen @safe
  public struct FileHandle: ~Copyable, Sendable {
    /// Adopts a raw handle, taking ownership of it.
    ///
    /// Returns `nil` if `raw` is `NULL` or `INVALID_HANDLE_VALUE`.
    ///
    /// - Warning: `raw` must be a synchronous handle that's closed by
    ///   `CloseHandle`. Do not pass a handle opened with `FILE_FLAG_OVERLAPPED`
    ///   or a socket, which is overlapped by default and must be closed with
    ///   `closesocket`.
    @unsafe
    public init?(unsafelyAdopting raw: HANDLE?)

    /// The raw C handle. Valid only while this value is alive.
    @unsafe
    public var unsafeRawHandle: HANDLE { get }

    /// Gives up ownership and returns the raw handle.
    ///
    /// The caller becomes responsible for closing it.
    @unsafe
    public consuming func relinquish() -> HANDLE

    /// Closes this handle.
    ///
    /// The corresponding C function is `CloseHandle`.
    public consuming func close() throws(Win32Error)
  }
}
```

#### Lifetime and error handling

A handle is always closed — the only question is whether the caller sees an error if one occurs. `close()` reports it, and `deinit` discards it at the end of the handle's scope. `deinit` still closes to prevent a throw between the open and the close from leaking the handle. `close()` consumes the handle even when it throws because a failed `CloseHandle` leaves nothing safe to retry: the handle may already be invalid, and Windows may have recycled its value for an unrelated object. The one exception is a handle marked `HANDLE_FLAG_PROTECT_FROM_CLOSE`, which `CloseHandle` leaves open. Callers should be aware that consuming a protected handle leaks it, as intended by the flag.

Note that `CloseHandle` is only documented to fail for an invalid handle or one protected from closing. It doesn't wait for the cache manager to write cached data to the device, and can't report a failure that happens then, so a client must call `flush()` ([SYS-0014](0014-win32-file-io.md)) first if a write-back failure needs to be surfaced.

Ownership also removes the need for a scoped form like `closeAfter(_:)` or `withOpen`. An ordinary binding plus an explicit close reproduces the contract a `closeAfter` would document:

```swift
let file = try Win32.FileHandle.open(path, access: .genericRead)
try doWork(file)    // If this throws, `deinit` closes and discards the error.
try file.close()    // Otherwise, any close error is reported here.
```

`unsafeRawHandle` and `relinquish()` are `@unsafe` escape hatches from that model. `unsafeRawHandle` may be used with Win32 functions that borrow a handle and have no System wrapper yet, and `relinquish()` hands ownership to code that will close it.

#### Two invalid sentinels

`CreateFileW` reports failure as `INVALID_HANDLE_VALUE` (`(HANDLE)-1`), while most other handle-producing functions report failure as `NULL`. `init?(unsafelyAdopting:)` is failable so that both are rejected in one place. A non-nil `Win32.FileHandle` means a valid `HANDLE`. There is no `.invalid` member, since both sentinels report only that the call failed, and `.invalid` would name a handle on which every operation fails. The parameter is `HANDLE?` to support Win32 functions that return `NULL` but import as returning `HANDLE!`.

> Note: The C runtime has a third sentinel, `_NO_CONSOLE_FILENO` (`(intptr_t)-2`). This is a CRT convention rather than a Win32 one, so it's filtered by `FileDescriptor.withWin32HandleIfAvailable(_:)` in [SYS-0013](0013-win32-filedescriptor-bridging.md) instead.

#### Synchronous handles only

None of the synchronous I/O in [SYS-0014](0014-win32-file-io.md) survives an overlapped handle: a transfer can report itself complete while the kernel is still writing into the span's memory, or a call can return `ERROR_IO_PENDING` immediately while the work completes later. Therefore, a `Win32.FileHandle` is never overlapped. [SYS-0012](0012-win32-opening-handles.md) rejects `FILE_FLAG_OVERLAPPED` on open, and [SYS-0013](0013-win32-filedescriptor-bridging.md)'s `FileDescriptor` bridging does not lend a handle if it's overlapped. A future asynchronous handle API should instead apply the flag implicitly and withhold the operations that fail, like `Win32.DirectoryHandle` does with `FILE_FLAG_BACKUP_SEMANTICS`.

`init?(unsafelyAdopting:)` does not check for the flag. It's `@unsafe` because the caller vouches that the handle is valid, owned, and synchronous. The safe `FileDescriptor.withWin32HandleIfAvailable(_:)` can't take a caller's word for it, so it makes the check. Code that owns an overlapped handle should keep it as a `HANDLE` until an asynchronous type exists.

#### Conformances

`Win32.FileHandle` conforms to `Sendable` and nothing else. `Sendable` is safe on a uniquely owned handle, and Windows permits concurrent use of one handle from multiple threads, though it serializes I/O on a synchronous handle (see [SYS-0014](0014-win32-file-io.md)). `Hashable` may be revisited when noncopyable hashed collections are more widely available.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

`Win32.FileHandle` sits behind `#if os(Windows)`, so cross-platform callers must guard their uses.

## Future directions

[SYS-0010](0010-win32-namespace-and-error.md) lists the rest of this series and the stages that could follow it.

* **Standard handles.** `GetStdHandle` is the Win32 analog of `FileDescriptor.standardInput` and friends.
* **Asynchronous I/O.** An overlapped handle could get its own type as **Synchronous handles only** describes, with async versions of the I/O in [SYS-0014](0014-win32-file-io.md).
* **A borrowed handle type.** A copyable, nonescapable handle view would let an API accept any handle kind, and could represent handles no Swift value owns, such as standard handles. Blocked as of Swift 6.4 since an owned `let handle` that has been viewed can't be consumed with `handle.close()` afterward, even after the view's last use. APIs that take several handles, such as `WaitForMultipleObjects`, can't use views, since no container accepts nonescapable elements, but they can take a `Span` of owned handles from `InlineArray` or swift-collections' `UniqueArray`. Mixing kinds would require a shared protocol.

## Alternatives considered

### Build on `FileDescriptor` instead

Add the Win32 operations in this series to `FileDescriptor` on Windows, recovering the handle internally, so System keeps one file type.

Rejected because:

* Every operation would inherit the descriptor's translation mode and its copyable model, as **Motivation** describes.
* It can't fix the `pread` deviation, where matching POSIX semantics would take three calls (seek, read, restore) and not be atomic against other users of the handle.

### A copyable value type with a manual `close()`

Model `Win32.FileHandle` on `FileDescriptor`: a `@frozen` copyable struct conforming to `RawRepresentable` and `Hashable`, with a non-consuming `close()`. This matches System's house style and allows handles in ordinary collections.

Rejected because:

* Double close, use after close, and leaks all stay expressible, as **A copied handle is a use-after-close hazard** describes. The primary type should offer lifetime safety.
* The decision is asymmetric. A copyable borrowed view can be added to a noncopyable type later, but ownership cannot be added to a copyable type.

### A copyable `Win32.RawFileHandle` beneath `Win32.FileHandle`

Keep `Win32.FileHandle` as the owner, but have it store a copyable `Win32.RawFileHandle` and forward its operations to it. Code that can't hold a borrow would still get a type more specific than `HANDLE`.

Rejected because:

* A `Win32.RawFileHandle` names a file handle only until that handle is closed. After that, Windows can reuse the value for any new object, including an overlapped handle, on which the synchronous I/O in [SYS-0014](0014-win32-file-io.md) is memory-unsafe (see **Synchronous handles only**). Its operations would therefore have to be `@unsafe`, just like calling Win32 with a `HANDLE` directly.
* It doubles the API surface without improving the escape hatch. Code that can't use `Win32.FileHandle` is typically giving the handle to raw Win32 or another library, which uses `HANDLE` anyway. Unlike `FileDescriptor`, there's no existing `Win32.RawFileHandle` API to interop with.
* Where a handle is a parameter, `borrowing` already gives it a distinct type along with lifetime safety, and **Future directions** describes a borrowed handle type for the cases `borrowing` can't express.

### A `class` with a closing `deinit`

Make `Win32.FileHandle` a `class` whose `deinit` closes the handle, preventing leaks without a noncopyable type.

Rejected because:

* It adds ARC and an allocation to a type that is morally a machine word. A `~Copyable` struct prevents leaks with neither cost, and on the explicit-close path the optimizer produces the same function as the copyable design.
* Every copy of the reference gains the ability to close.

### A `deinit` that traps on leak

As prior art, NIO's `SystemFileHandle` calls `fatalError` when a handle is dropped without being closed or detached, and never closes implicitly.

Rejected because turning a leaked handle into a process abort is a policy that an application could choose but a low-level library like System should not impose here.

### Scoped `withOpen` and `closeAfter` entry points

`withOpen(path, access:...) { file in }` and a `consuming func closeAfter(_:)` would make the close impossible to forget, as `FileDescriptor.closeAfter(_:)` does today.

Rejected because:

* Noncopyable ownership already guarantees that, so the scoped forms only add more API surface (up to four large declarations restating the nine-parameter list and doc comment of `open` in [SYS-0012](0012-win32-opening-handles.md)).
* Typed throws would then double that surface with the overload pattern `withLock(byteRange:mode:_:)` uses in [SYS-0016](0016-win32-byte-range-locking.md). Separate statements already give each call its own error type.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle` | `HANDLE` |
| `Win32.FileHandle.close()` | `CloseHandle` |
| `Win32.FileHandle.deinit` | `CloseHandle`, error discarded |
| `Win32.FileHandle.relinquish()` | none; gives up ownership of the `HANDLE` |
