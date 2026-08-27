# File Type for `Win32.FileHandle`

* Proposal: [SYS-0015](0015-win32-file-type.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md), [SYS-0012](0012-win32-opening-handles.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds `Win32.FileType` and a `fileType()` query on `Win32.FileHandle`, reporting whether a handle refers to a disk file, a character device, or a pipe.

## Motivation

### Device class determines handle behavior

A developer with a `Win32.FileHandle` might need to know what device class they're holding to drive decisions in their code. For example, device class matters for the file I/O described in [SYS-0014](0014-win32-file-io.md). On a disk file, `ReadFile` comes up short only at the end of the file, and `GetFileSizeEx` and seek operations report correct values. On a pipe or console, `ReadFile` returns whatever has arrived, `readFully(fromAbsoluteOffset:into:)` blocks until the span fills, and a seek succeeds while reporting a position that no transfer ever advances.

Furthermore, a caller doesn't always know this information. `Win32.FileHandle.open` accepts `\\.\pipe\name`, `CONIN$`, and `NUL` as readily as a file path, or code may receive a handle from another API. `fileType()` allows the caller to query this class information regardless.

### Error handling for `GetFileType`

`GetFileType` returns `FILE_TYPE_UNKNOWN` for both a device it doesn't classify and a call that failed. Separating the two requires `SetLastError(ERROR_SUCCESS)` before the call and `GetLastError` after. A developer may be unaware of this, so `fileType()` handles these details.

## Proposed solution

Add `fileType()` to `Win32.FileHandle`. The read functions in this example come from [SYS-0014](0014-win32-file-io.md).

```swift
#if os(Windows)
let handle = try Win32.FileHandle.open(path, access: .readData)

switch try handle.fileType() {
case .disk:
  // Reads stop only at the end of the file, so fill the span.
  _ = try handle.readFully(into: &span)
default:
  // On a pipe or console, take whatever has arrived.
  _ = try handle.read(into: &span)
}
try handle.close()
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them.

```swift
extension Win32 {
  /// The class of device a handle refers to.
  @frozen
  public struct FileType: RawRepresentable, Sendable, Hashable, Codable {
    /// The raw C value.
    public var rawValue: DWORD

    /// Creates a strongly-typed file type from a raw C value.
    public init(rawValue: DWORD)

    /// Creates a strongly-typed file type from a raw C value.
    public init(_ rawValue: DWORD)

    /// A file or directory on a volume, local or remote.
    ///
    /// The corresponding C constant is `FILE_TYPE_DISK`.
    public static var disk: FileType { get }

    /// A character device, such as a console, a printer, or `NUL`.
    ///
    /// The corresponding C constant is `FILE_TYPE_CHAR`.
    public static var character: FileType { get }

    /// A named pipe, an anonymous pipe, or a socket.
    ///
    /// The corresponding C constant is `FILE_TYPE_PIPE`.
    public static var pipe: FileType { get }

    /// A device that Windows does not classify.
    ///
    /// The corresponding C constant is `FILE_TYPE_UNKNOWN`.
    public static var unknown: FileType { get }
  }
}

extension Win32.FileHandle {
  /// The type of device this handle refers to.
  ///
  /// The corresponding C function is `GetFileType`.
  public func fileType() throws(Win32.Error) -> Win32.FileType
}
```

Notes on the design:

* **`.unknown` is a result, not a failure.** `fileType()` calls `SetLastError(ERROR_SUCCESS)` first and throws only if `GetLastError` then reports an error. A usable handle on a device Windows doesn't classify returns `.unknown`, which `GetFileType` documents as a successful result. In testing, a handle to the mount manager (`\\.\MountPointManager`) and several other built-in devices report it with no error.
* **Requires no access rights.** `GetFileType` documents none, and a handle opened with an empty `Win32.AccessMask` is still classified.
* **`FILE_TYPE_REMOTE` isn't vended.** `winbase.h` defines it (`0x8000`), but it's documented as unused, and testing shows a remote file reports `.disk`. `rawValue` would carry it if it ever appeared.
* **`.pipe` covers sockets.** A `SOCKET` is a kernel handle that Windows classifies with pipes, so `.pipe` doesn't imply the named-pipe API surface (e.g. `PeekNamedPipe`) will work on the handle.
* **`Win32.DirectoryHandle` doesn't get this member.** A directory handle always reports `.disk` since `open` confirms the object is a directory; see [SYS-0012](0012-win32-opening-handles.md).

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

Everything here is reached through `Win32.FileHandle` and sits behind `#if os(Windows)`, so cross-platform callers must guard their uses.

## Future directions

* **Pipe queries.** `PeekNamedPipe` reports how many bytes a pipe has ready without consuming them, so a caller can size a span that `readFully(fromAbsoluteOffset:into:)` will fill exactly. `GetNamedPipeInfo` and `GetNamedPipeHandleStateW` report the rest of a pipe's configuration. A `.pipe` result is the first check before these calls but is not completely sufficient since a socket reports the same type.
* **Console detection.** The `.character` file type doesn't distinguish a console from any other character device, and `NUL` reports the same type. `GetConsoleMode` is the check and belongs alongside other console APIs.

## Alternatives considered

### Throw for `FILE_TYPE_UNKNOWN`

Treat an unclassified device as a failure, so a successful `fileType()` always names a device class.

Rejected because `GetFileType` documents `FILE_TYPE_UNKNOWN` with no error as a successful result, and usable handles report it, such as one to the mount manager (`\\.\MountPointManager`).

### Vend predicates instead of a type

Add `isSeekable`, `isTerminal`, or `isPipe` to `Win32.FileHandle` rather than a device class.

Rejected because `GetFileType` doesn't fully answer those questions, and the answer may be vague. For instance, a console and `NUL` share one type, and so do a socket and a pipe. And in testing, a seek was actually measured to succeed on every device class even though the result isn't always meaningful.

### Name it `deviceType()`

The values name device classes, and a pipe isn't a file, so `fileType()` reads oddly for three of the four results.

Rejected because the C function is `GetFileType` and the constants are `FILE_TYPE_*`. Matching Win32's own naming is worth more than correcting it.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle.fileType()` | `GetFileType`, preceded by `SetLastError(ERROR_SUCCESS)` |
| `Win32.FileType.disk` | `FILE_TYPE_DISK` (`0x1`) |
| `Win32.FileType.character` | `FILE_TYPE_CHAR` (`0x2`) |
| `Win32.FileType.pipe` | `FILE_TYPE_PIPE` (`0x3`) |
| `Win32.FileType.unknown` | `FILE_TYPE_UNKNOWN` (`0x0`) |
| none | `FILE_TYPE_REMOTE` (`0x8000`), documented as unused |

### What each type means for I/O

| Type | A transfer | Position and size |
| --- | --- | --- |
| `.disk` | comes up short only at the end of the file | meaningful, except on a volume or disk device, where `size()` fails |
| `.character` | returns what has arrived | meaningless; `size()` fails on a console |
| `.pipe` | returns what has arrived | meaningless; the call succeeds anyway |
| `.unknown` | unspecified | unspecified |

Testing was performed on an ARM64 Windows 11 VM (build 22631), where the remote file was in a shared folder (not on an SMB share). The classification results were reproduced on an x64 Windows 11 PC (build 26200).
