# `FileDescriptor` Bridging for `Win32.FileHandle`

* Proposal: [SYS-0013](0013-win32-filedescriptor-bridging.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds conversions in both directions between `FileDescriptor` and `Win32.FileHandle`, the type introduced in [SYS-0011](0011-win32-filehandle.md).

## Motivation

Code that holds a `FileDescriptor` needs its handle to use the Win32 APIs in this series, and code that opens a file with Win32 options may need to pass it to an API that takes a `FileDescriptor`. The C runtime converts in each direction with `_get_osfhandle` and `_open_osfhandle`, but there are three hazards a System API can help developers avoid.

### Recovering a handle can crash

Code that recovers a handle needs a failure path for the case where the `CInt` maps to no handle at all. System's adapters report `EBADF` when `_get_osfhandle` returns `INVALID_HANDLE_VALUE`, but those paths rarely run since `_get_osfhandle` on an invalid descriptor terminates the process by default. The `pread`, `pwrite`, and `ftruncate` implementations crash on Windows where Linux and Darwin throw.

### Not every descriptor has a usable handle

Even a valid descriptor may have no handle behind it, as with the standard descriptors in a process with no console, or wrap an overlapped handle, such as a socket. [SYS-0011](0011-win32-filehandle.md) doesn't allow either in a `Win32.FileHandle`.

### Adopting a handle requires unsafe code

`_open_osfhandle` takes a raw handle, and the descriptor it returns owns that handle. So code that holds a `Win32.FileHandle` must first call `relinquish()`, which is `@unsafe`, and close the raw handle if the call fails. A System wrapper can handle these unsafe operations.

## Proposed solution

Add `FileDescriptor.withWin32HandleIfAvailable(_:)`, which lends the backing handle to a closure, and `FileDescriptor.init(adopting:translation:append:)`, which wraps a handle in a descriptor that takes ownership of it.

```swift
#if os(Windows)
// `fileType()` is proposed in SYS-0015, and `open` in SYS-0012.
let kind = try fd.withWin32HandleIfAvailable { try $0.fileType() }

// Prevent writing while descriptor-based code reads the file.
let handle = try Win32.FileHandle.open(path, access: .genericRead, shareMode: .read)
let reader = try FileDescriptor(adopting: handle)
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them.

The two types convert in both directions, with different ownership semantics:

```swift
extension FileDescriptor {
  /// Calls `body` with the Win32 handle backing this descriptor, if it maps to
  /// a usable handle.
  ///
  /// The handle is **borrowed** from the C runtime descriptor, which owns it
  /// and closes it when the descriptor is closed. The borrow is valid only for
  /// the duration of the call, and the descriptor must stay open until `body`
  /// returns.
  ///
  /// `body` isn't called for an invalid descriptor, for a valid descriptor
  /// with no underlying handle (which the C runtime reports for the standard
  /// descriptors in a process with no console), or for a descriptor over an
  /// overlapped handle, such as a socket.
  ///
  /// - Note: Checking whether the handle is overlapped waits for any
  ///   synchronous call in progress on it, so this blocks while another
  ///   thread waits in a read on the same pipe or console.
  ///
  /// - Parameter body: A closure that receives the handle backing this
  ///   descriptor.
  /// - Returns: The return value of `body`, or `nil` if it wasn't called.
  ///
  /// The corresponding C function is `_get_osfhandle`.
  public func withWin32HandleIfAvailable<R: ~Copyable, E: Error>(
    _ body: (borrowing Win32.FileHandle) throws(E) -> R
  ) throws(E) -> R?

  /// Wraps a Win32 handle in a C runtime file descriptor, **consuming**
  /// the handle.
  ///
  /// On success, the returned descriptor owns the handle, and closing the
  /// descriptor closes it. On failure, this initializer closes the handle
  /// before throwing.
  ///
  /// - Parameters:
  ///   - handle: The handle to wrap.
  ///   - translation: The descriptor's translation mode. Defaults to
  ///     ``FileDescriptor/TranslationMode/binary``, which passes bytes
  ///     through unchanged.
  ///   - append: Whether every write seeks to the end of the file first.
  ///
  /// - Note: The descriptor's access is that of the underlying handle.
  ///
  /// The corresponding C function is `_open_osfhandle`.
  public init(
    adopting handle: consuming Win32.FileHandle,
    translation: TranslationMode = .binary,
    append: Bool = false
  ) throws(Errno)

  /// The C runtime's translation mode for a file descriptor.
  @frozen
  public struct TranslationMode: RawRepresentable, Sendable, Hashable, Codable {
    /// The raw C flag.
    public var rawValue: CInt

    /// Creates a strongly-typed translation mode from a raw C flag.
    public init(rawValue: CInt)

    /// Bytes pass through unchanged.
    ///
    /// The corresponding C constant is `_O_BINARY`.
    public static var binary: TranslationMode { get }

    /// Expands `\n` to `\r\n` on write and collapses it on read. A read also
    /// stops at a Ctrl+Z (`0x1A`) byte, which the C runtime treats as end of
    /// file.
    ///
    /// The corresponding C constant is `_O_TEXT`.
    public static var text: TranslationMode { get }
  }
}
```

`FileDescriptor.withWin32HandleIfAvailable(_:)` is a closure so the scope of the borrow is visible at the call site. Like `withContiguousStorageIfAvailable(_:)`, it returns `nil` instead of calling `body` when there's no handle to lend, so `body` never has to unwrap one. It never throws on its own, so it passes `body`'s error type through as `E`. Both sentinels, `INVALID_HANDLE_VALUE` and `_NO_CONSOLE_FILENO`, return `nil`. An overlapped handle also returns `nil` because the synchronous I/O in [SYS-0014](0014-win32-file-io.md) isn't memory-safe on one. (Note a descriptor can wrap an overlapped handle, e.g. Winsock sockets are overlapped by default.) Detecting an overlapped handle requires an `NtQueryInformationFile` call for `FileModeInformation`. The implementation brackets the call to `_get_osfhandle` with a no-op `_set_thread_local_invalid_parameter_handler`, since `_get_osfhandle` on an invalid descriptor otherwise invokes the C runtime's invalid parameter handler, which terminates the process by default.

`FileDescriptor.init(adopting:)` consumes its handle and does not return ownership on failure. It throws `Errno` because it lives on `FileDescriptor`. The `translation` and `append` parameters cover every `_open_osfhandle` flag except the implicit `_O_RDONLY`, which is `0x0000` on Windows, and `_O_WTEXT`. Despite its documentation, `_open_osfhandle` ignores `_O_WTEXT` and produces a binary descriptor, and in Unicode mode an odd-length read or write terminates the process by default, so `FileDescriptor.TranslationMode` omits it. `_open_osfhandle` also rejects a handle whose `GetFileType` is `FILE_TYPE_UNKNOWN`, so the initializer throws `Errno.invalidArgument` if so. The C runtime's `_read` and `_write` call `ReadFile` and `WriteFile` with a null `lpOverlapped`, so an overlapped handle would carry the same hazard as **Synchronous handles only** in [SYS-0011](0011-win32-filehandle.md) describes.

`Win32.DirectoryHandle` ([SYS-0012](0012-win32-opening-handles.md)) has no bridge: `_open_osfhandle` on a directory handle produces a descriptor that can't be read or written.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

These `FileDescriptor` extensions sit behind `#if os(Windows)`, so cross-platform callers must guard their uses.

## Future directions

* **A borrowing accessor.** A `yielding borrow` property could lend the handle without a closure once that feature stabilizes.

## Alternatives considered

### Put the bridge entirely on `Win32.FileHandle`

Spell the conversions `Win32.FileHandle.init?(borrowing: FileDescriptor)` and `Win32.FileHandle.fileDescriptor(translation:append:)`, so the bridge stays inside the namespace.

Rejected because:

* The two directions have different ownership, and the spellings should show it. The borrow direction cannot be an initializer at all, since the result would be an owning value that closes a handle it does not own. The reverse transfers ownership and can fail, so it should not read like an accessor, whereas an initializer on the destination type states the transfer plainly.
* `FileDescriptor.TranslationMode` is C runtime state, so `FileDescriptor` gains an extension either way.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `FileDescriptor.withWin32HandleIfAvailable(_:)` | `_get_osfhandle`, guarded by `_set_thread_local_invalid_parameter_handler`, then `NtQueryInformationFile` with `FileModeInformation` |
| `FileDescriptor.init(adopting:translation:append:)` | `_open_osfhandle` |
| `FileDescriptor.TranslationMode` | `_O_BINARY`, `_O_TEXT` |

Testing was performed on an ARM64 Windows 11 VM (build 22631). The `_open_osfhandle` and overlapped-handle results were reproduced on an x64 Windows 11 PC (build 26200).
