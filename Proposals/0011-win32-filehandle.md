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

A C runtime descriptor is a second index over the handle and carries state of its own, including a translation mode. In text mode, the runtime rewrites bytes in transit, expanding `\n` to `\r\n` on write and collapsing it on read. Anything built on a descriptor inherits a translation setting that is invisible in System's APIs, and Win32 calls on the underlying handle bypass it.

The descriptor also leaks Windows semantics into portable-looking APIs: `FileDescriptor.read(fromAbsoluteOffset:into:)` moves the file pointer on Windows, unlike POSIX `pread` (see [SYS-0014](0014-win32-file-io.md)).

### A copied handle is a use-after-close hazard

`FileDescriptor` is a copyable value with a non-consuming `FileDescriptor.close()`. Copy it, close one copy, and the other still compiles and names an index. Windows also recycles handle values, so a stale copy may name a different kernel object and lead to I/O on the wrong file.

`FileDescriptor` keeps the copyable model because it's shipped ABI and predates `~Copyable`. Neither constraint applies to new Windows APIs, so we should pursue an owning, noncopyable type instead. A double close or use after close then becomes a compile error, a dropped handle is closed rather than leaked, and every signature says clearly whether it borrows or consumes. System already ships a precedent: `Mach.Port` is a noncopyable owner that deallocates its port right in `deinit` and gives up ownership with `consuming func relinquish()`.

## Proposed solution

Add `Win32.FileHandle`, a noncopyable type that owns its handle and closes it with a `consuming func close()`.

```swift
#if os(Windows)
// `open` is proposed separately, in SYS-0012.
let file = try Win32.FileHandle.open(path, access: .genericRead)
try parse(file)   // Borrows `file`. If this throws, `deinit` closes it.
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
  /// discards the error. In debug builds, both trap if unsafe code closed the
  /// handle or marked it `HANDLE_FLAG_PROTECT_FROM_CLOSE`.
  ///
  /// The corresponding C type is `HANDLE`.
  @frozen @safe
  public struct FileHandle: ~Copyable, Sendable {
    /// Adopts a raw handle, taking ownership of it.
    ///
    /// Returns `nil` if `raw` is `NULL` or `INVALID_HANDLE_VALUE`.
    ///
    /// - Warning: `raw` must be a synchronous handle that's closed by
    ///   `CloseHandle`. Do not pass:
    ///   - A handle opened with `FILE_FLAG_OVERLAPPED`.
    ///   - A socket, which is overlapped by default and must be closed with
    ///     `closesocket`.
    ///   - A handle you don't own, such as one from `GetStdHandle`, since
    ///     `deinit` closes it.
    ///   - A handle with `HANDLE_FLAG_PROTECT_FROM_CLOSE` set, since closing
    ///     it fails.
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

Every handle gets one `CloseHandle` call, from `close()` at a point the caller chooses or from `deinit` at the end of the handle's scope. Closing in `deinit` prevents a throw between an open and close from leaking the handle. A `Win32.FileHandle` must never hold a handle marked `HANDLE_FLAG_PROTECT_FROM_CLOSE`, which `CloseHandle` leaves open.

`CloseHandle`'s documentation doesn't list failure conditions, but `NtClose` documents error statuses for 1) an invalid handle and 2) a handle that's protected from closing. Testing shows that `CloseHandle` reports `.invalidHandle` for both cases. `Win32.FileHandle`'s ownership prevents this failure unless unsafe code closed the handle or set its protect-from-close flag. Therefore, `close()` and `deinit` trap in debug builds if `CloseHandle` fails with `.invalidHandle`. Note this can't catch a value that Windows has already reused, so it's only a probabilistic debugging aid.

`CloseHandle` doesn't wait for the cache manager to write cached data to the device, so `close()` can't report such a failure. A client must call `flush()` ([SYS-0014](0014-win32-file-io.md)) before closing if a write-back failure needs to be surfaced.

`unsafeRawHandle` and `relinquish()` are `@unsafe` escape hatches from the ownership model. `unsafeRawHandle` may be used with Win32 functions that borrow a handle and have no System wrapper yet, and `relinquish()` hands ownership to code that will close it.

#### Two invalid sentinels

`CreateFileW` reports failure as `INVALID_HANDLE_VALUE` (`(HANDLE)-1`), while most other handle-producing functions report failure as `NULL`. `init?(unsafelyAdopting:)` is failable so that both are rejected in one place. There is no `.invalid` member, since both sentinels report only that the call failed, and `.invalid` would name a handle on which every operation fails. The parameter is `HANDLE?` to support Win32 functions that return `NULL` but import as returning `HANDLE!`.

> Note: The C runtime has a third sentinel, `_NO_CONSOLE_FILENO` (`(intptr_t)-2`). This is a CRT convention rather than a Win32 one, so it's filtered by `FileDescriptor.withWin32HandleIfAvailable(_:)` in [SYS-0013](0013-win32-filedescriptor-bridging.md) instead.

#### Synchronous handles only

None of the synchronous I/O in [SYS-0014](0014-win32-file-io.md) is memory-safe on an overlapped handle: a transfer can report itself complete while the kernel is still writing into the span's memory, or a call can return `ERROR_IO_PENDING` immediately while the work completes later. Therefore, a `Win32.FileHandle` is never overlapped. [SYS-0012](0012-win32-opening-handles.md) rejects `FILE_FLAG_OVERLAPPED` on open, and [SYS-0013](0013-win32-filedescriptor-bridging.md)'s `FileDescriptor` bridging does not lend a handle if it's overlapped. A future asynchronous handle API should instead apply the flag implicitly like `Win32.DirectoryHandle` ([SYS-0012](0012-win32-opening-handles.md)) does with `FILE_FLAG_BACKUP_SEMANTICS` and withhold operations that fail.

`init?(unsafelyAdopting:)` does not check for the overlapped flag. It's `@unsafe` because the caller vouches that the handle is valid, owned, and synchronous. The safe `FileDescriptor.withWin32HandleIfAvailable(_:)` can't take a caller's word for it, so it makes the check. Code that owns an overlapped handle should keep it as a `HANDLE` until an asynchronous type exists.

#### Conformances

`Win32.FileHandle` conforms to `Sendable` and nothing else. `Sendable` is safe on a uniquely owned handle, and Windows permits concurrent use of one handle from multiple threads, though it serializes I/O on a synchronous handle (see [SYS-0014](0014-win32-file-io.md)). `Hashable` may be revisited when noncopyable hashed collections are more widely available.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

`Win32.FileHandle` sits behind `#if os(Windows)`, so cross-platform callers must guard their uses. The `@safe` and `@unsafe` attributes require Swift 6.2, so System will need to raise its toolchain floor.

## Future directions

[SYS-0010](0010-win32-namespace-and-error.md) lists the rest of this series and the stages that could follow it.

* **Asynchronous I/O.** An overlapped handle could get its own type as **Synchronous handles only** describes, with async versions of the I/O in [SYS-0014](0014-win32-file-io.md).
* **A borrowed handle type.** A copyable, nonescapable handle view would let an API accept any handle kind, and could represent handles no Swift value owns, such as the standard handles from `GetStdHandle`. Blocked as of Swift 6.4 since an owned `let handle` that has been viewed can't be consumed with `handle.close()` afterward, even after the view's last use.
* **Opt-in close checking.** If Swift adds must-consume types, a wrapper could make a forgotten `close()` a compile error. Until then, an application that wants every close to be explicit can wrap `Win32.FileHandle` in a type whose `deinit` traps.

## Alternatives considered

### Build on `FileDescriptor` instead

Add the Win32 operations in this series to `FileDescriptor` on Windows, recovering the handle internally, so System keeps one file type.

Rejected because:

* It would keep the descriptor's copyable model.
* Every operation would bypass the descriptor's translation mode, disagreeing with `FileDescriptor.read(into:)` on a text-mode descriptor.
* It can't fix the `pread` deviation, where matching POSIX semantics would take three calls (seek, read, restore) and not be atomic against other users of the handle.

### A copyable value type with a manual `close()`

Model `Win32.FileHandle` on `FileDescriptor`: a `@frozen` copyable struct conforming to `RawRepresentable`, with a non-consuming `close()`. This matches System's house style and allows handles in ordinary collections.

Rejected because:

* Double close, use after close, and leaks all stay expressible. The primary type should offer lifetime safety.
* The decision is asymmetric. A copyable borrowed view can be added to a noncopyable type later, but ownership cannot be added to a copyable type.

### A copyable `Win32.RawFileHandle` beneath `Win32.FileHandle`

Keep `Win32.FileHandle` as the owner, but have it store a copyable `Win32.RawFileHandle` and forward its operations to it. Code that can't hold a borrow would still get a type more specific than `HANDLE`.

Rejected because:

* If a programmer error closes the copyable handle early, Windows can reuse the value for any new object, including an overlapped handle, on which the synchronous I/O in [SYS-0014](0014-win32-file-io.md) is memory-unsafe. Its operations would therefore have to be `@unsafe`, just like calling Win32 with a `HANDLE` directly.
* It doubles the API surface without improving the escape hatch. Code that can't use `Win32.FileHandle` is typically giving the handle to raw Win32 or another library, which uses `HANDLE` anyway. Unlike `FileDescriptor`, there's no existing `Win32.RawFileHandle` API to interop with.
* Where a handle is a parameter, `borrowing` already gives it a distinct type along with lifetime safety, and **Future directions** describes a borrowed handle type for the cases `borrowing` can't express.

### A `class` with a closing `deinit`

Make `Win32.FileHandle` a `class` whose `deinit` closes the handle, preventing leaks without a noncopyable type.

Rejected because:

* It adds ARC and an allocation to a type that is morally a machine word. A `~Copyable` struct prevents leaks with neither cost.
* Every copy of the reference gains the ability to close.

### A `deinit` that traps instead of closing

As prior art, NIO's `SystemFileHandle` calls `fatalError` if it's dropped while open, and [SE-0528](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0528-noncopyable-continuation.md)'s `Continuation` traps if it's deinitialized without being resumed. A trap forces the programmer to choose where the handle closes.

Rejected because:

* Unlike the cases above, `Win32.FileHandle.deinit` can close the handle correctly since `CloseHandle` is synchronous, and a trap there wouldn't rule out bugs in safe code. NIO's `deinit` can't await its `async` `close()`, and `Continuation.deinit` has no result to resume with, so their traps turn a silent leak or hang into a crash.
* A trapping `deinit` would make the client close the handle on every error path in the scope. Since `defer` can't consume a noncopyable value, the owner would need a `do`/`catch` that closes the handle and rethrows, or an `Optional` that `defer` can `take()`. Otherwise, a throw between the open and close would abort the process before any caller could catch it. An application could choose that `fatalError` policy using a wrapper type, but a low-level library like System should not impose it.
* An owner that needs a precise close point can still call `close()`.
* `deinit` discards errors, but they're errors a caller can't reasonably recover from. Every known `CloseHandle` failure is an ownership violation that already traps in debug builds (see **Lifetime and error handling**).
* Some owners wouldn't be able to close a trapping handle without wrapping it. A class or an `InlineArray` would need an `Optional`, since neither can consume a stored handle. A handle shared with a task group's children would need a box such as `Mutex`, since a value they capture can't be consumed afterward.

### Scoped `withOpen` and `closeAfter` entry points

`withOpen(path, access:...) { file in }` and a `consuming func closeAfter(_:)` would make the close impossible to forget, as `FileDescriptor.closeAfter(_:)` does today.

Rejected because:

* Noncopyable ownership already guarantees that, so the scoped forms only add more API surface (a `withOpen` per opening function in [SYS-0012](0012-win32-opening-handles.md), each restating its parameters and doc comment).
* Typed throws would then double that surface with the overload pattern `withLock(byteRange:mode:_:)` uses in [SYS-0016](0016-win32-byte-range-locking.md). Separate statements already give each call its own error type.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle` | `HANDLE` |
| `Win32.FileHandle.close()` | `CloseHandle` |
| `Win32.FileHandle.deinit` | `CloseHandle`, error discarded |
| `Win32.FileHandle.relinquish()` | none; gives up ownership of the `HANDLE` |

Testing was performed on an ARM64 Windows 11 VM (build 22631).
