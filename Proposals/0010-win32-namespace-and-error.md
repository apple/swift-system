# A `Win32` Namespace and `Win32.Error` for Swift System

* Proposal: [SYS-0010](0010-win32-namespace-and-error.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD

#### Revision history

* **v1** Initial version.

## Introduction

System's current file system APIs are POSIX-shaped, and on Windows they are built mostly on the Universal C Runtime's POSIX compatibility layer. That layer is a portability shim, not a model of the operating system. This proposal adds `Win32`, a namespace for Windows-native file system APIs, and `Win32.Error`, the error type those APIs report.

It's the foundation for a series of proposals that nest their types in the namespace and throw the error. Each is mostly reviewable on its own, but may depend on others in the series for the final shape:

| API | Proposal |
| --- | --- |
| `Win32` namespace, `Win32.Error` | This proposal |
| `Win32.FileHandle`, ownership and closing | [SYS-0011](0011-win32-filehandle.md) |
| Opening files and directories, duplication, and reopening | [SYS-0012](0012-win32-opening-handles.md) |
| `FileDescriptor` bridging for `Win32.FileHandle` | [SYS-0013](0013-win32-filedescriptor-bridging.md) |
| Reading, writing, seeking, flushing, and resizing | [SYS-0014](0014-win32-file-io.md) |
| `Win32.FileType` | [SYS-0015](0015-win32-file-type.md) |
| Byte-range locking | [SYS-0016](0016-win32-byte-range-locking.md) |
| Volume information for a handle | [SYS-0017](0017-win32-volume-information.md) |
| Final path name for a handle | [SYS-0018](0018-win32-final-path-name.md) |

See **Future directions** for additional APIs that could follow.

## Motivation

### Windows API layers

Windows exposes file system functionality at several layers, and it matters which one System wraps:

| Layer | Examples | Expose this from System? |
| --- | --- | --- |
| Kernel-mode file system interfaces | IRPs, `FltMgr` minifilters, `FsRtl*` | No. Driver-only. |
| NT Native API (`ntdll.dll`) | `NtCreateFile`, `NtQueryInformationFile` | No. Only partly documented, and not stability-committed. |
| **Win32 base API** | `CreateFileW`, `GetFileInformationByHandleEx` | **Yes** |
| C runtime (UCRT) | `_open_osfhandle`, `_get_osfhandle`, `_read`, `_close` | Yes. This is how `FileDescriptor` works today. |
| Shell, COM, WinRT, .NET | `IFileOperation`, `Windows.Storage` | No. Different app models. |

Win32 is the documented, stable, ABI-committed system interface for desktop Windows, and System already uses it internally. System's Windows adapters implement `open` by calling `CreateFileW` directly rather than `_wopen`, then convert the handle to a descriptor with `_open_osfhandle`. What System lacks is a place to name the Win32 layer in its public APIs.

### System has no home for Windows-native APIs

The library already treats POSIX and Windows file metadata as disjoint surfaces. `UserID`, `GroupID`, `DeviceID`, and `Inode` are declared entirely inside `#if !os(Windows)`. [SYS-0006](0006-system-stat.md) proposes `Stat` for Unix-like platforms only, where we argue in its **Alternatives considered**:

> Rather than forcing Windows file metadata semantics into a cross-platform `Stat` type, we should instead create Windows-specific types that give developers full access to platform-native file metadata.

Those Windows-specific types need somewhere to live, and it shouldn't be the top level, where the natural names would conflict. System already declares `FileType` and `FileFlags` for other platforms, and [SYS-0012](0012-win32-opening-handles.md) and [SYS-0015](0015-win32-file-type.md) need Windows types with those names and different meanings. A top-level `Error` or `FileHandle` would collide with the standard library or Foundation. System has a shipped precedent for the alternative. `Mach` is a caseless `enum` that serves purely as a namespace for a family of platform-specific types. A `Win32` namespace follows that precedent.

### `Errno` can't express Windows failures

Every Windows failure in System is currently reported as an `Errno`, mapped either by the Microsoft C runtime's `_dosmaperr` table or by System's internal `_mapWindowsErrorToErrno`, which approximates that table with a few additions. The mapping's purpose is to make the POSIX shim behave: when `FileDescriptor.read` fails, something has to go in `errno`, and `_dosmaperr` is what the CRT would have put there. `Errno` is fit for that purpose, but unfit for reporting errors from a Win32-native API.

Many Windows failures have no POSIX analog, such as a sharing violation, a mapped-file conflict, or pending overlapped I/O. `Errno` has no value for them, so any mapping loses them, but System's mapping loses more than is appropriate for true Windows support.

**It folds several thousand codes onto sixteen.** The table names about fifty error codes and covers fewer than a hundred in total, while `winerror.h` defines several thousand. Every code the table does not recognize, such as `ERROR_NOT_SUPPORTED` (50), becomes `EINVAL`, indistinguishable from a genuinely invalid argument. Of the 32 failure codes this proposal names, 14 aren't in the table at all, and 24 end up as either `EINVAL` or `EACCES`.

**It merges failures that need different responses.** Everything from code 19 through 36 becomes `EACCES`:

| Code | Meaning | Maps to |
| --- | --- | --- |
| `ERROR_NOT_READY` (21) | The device is not ready | `EACCES` |
| `ERROR_CRC` (23) | Cyclic redundancy check failed | `EACCES` |
| `ERROR_WRITE_FAULT` (29) | Write fault on the device | `EACCES` |
| `ERROR_SHARING_VIOLATION` (32) | Another process holds an incompatible open | `EACCES` |
| `ERROR_LOCK_VIOLATION` (33) | A byte-range lock blocked the access | `EACCES` |

A media failure, a device that's not ready, and a sharing violation are three different problems with three different responses, and all of them are indistinguishable from a genuine `ERROR_ACCESS_DENIED`. `ERROR_SHARING_VIOLATION` matters most to Windows callers, because it's retryable.

**It turns control-flow signals into ordinary failures.** `ERROR_MORE_DATA` (234) is a retry instruction, and a caller that can't distinguish it from `EINVAL` can't write the grow-and-retry loop that Windows' variable-length query APIs require. `ERROR_NO_MORE_FILES` (18) ends an enumeration, but it maps to `ENOENT`.

**It misses even the POSIX analogs that exist.** `ERROR_NO_DATA` (232) is what's reported when writing to a pipe whose reader has closed, so `FileDescriptor.write` throws `EINVAL` where Linux and Darwin report `EPIPE`. `ERROR_FILE_TOO_LARGE` (223), which reports a file system limit, likewise becomes `EINVAL` rather than `EFBIG`.

None of this is a defect in `_mapWindowsErrorToErrno`. The shim's job is to match what the C runtime does, and it does. The problem is that the destination type can't carry the code Windows reported.

## Proposed solution

Add `Win32`, a namespace available on Windows and scoped to the Win32 layer, and `Win32.Error`, the error currency for everything in it. Also provide a public `Errno(approximating: Win32.Error)` conversion for callers who want a POSIX approximation (such as a cross-platform library that throws `Errno` on every platform), and document that it's lossy.

```swift
#if os(Windows)
do {
  // `Win32.FileHandle` and `open` are proposed separately, in SYS-0011 and SYS-0012.
  let handle = try Win32.FileHandle.open(path, access: .genericWrite)
  try handle.close()
} catch Win32.Error.sharingViolation {
  // Retryable: another process has the file open with an incompatible share mode.
} catch let error {
  log("open failed: \(error)")                   // localized system message
  log("open failed: \(error.debugDescription)")  // ERROR_ACCESS_DENIED (5, 0x5)
  throw Errno(approximating: error)              // an explicitly lossy conversion
}
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them.

### The `Win32` namespace

```swift
#if os(Windows)
/// A namespace for Win32 APIs on Windows.
///
/// The types and functions nested here wrap the Win32 base API, the
/// documented, ABI-stable system interface for desktop Windows.
@frozen
public enum Win32 {}
#else
@available(*, unavailable, message: "Win32 APIs are only available on Windows.")
public enum Win32 {
  public struct Error {}  // Each nested type gets an empty stub.
}
#endif
```

Other platforms get an unavailable stub for `Win32` and for each type nested in it, so naming one as a type reports that it's Windows-only. Their members aren't declared on other platforms.

### `Win32.Error`

```swift
extension Win32 {
  /// A Windows system error code.
  ///
  /// This represents a value reported by `GetLastError`, or a code that
  /// System synthesizes. See ``isSynthesized``.
  @frozen
  public struct Error: RawRepresentable, Swift.Error, Sendable, Hashable, Codable {
    /// The raw C error code.
    public let rawValue: DWORD

    /// Creates a strongly-typed error from a raw C error code.
    public init(rawValue: DWORD)

    /// Creates a strongly-typed error from a raw C error code.
    public init(_ rawValue: DWORD)

    /// The operation completed successfully.
    ///
    /// The corresponding C constant is `ERROR_SUCCESS`.
    public static var success: Error { get }

    // ... the curated set of named codes:
    public static var invalidFunction: Error { get }        // ERROR_INVALID_FUNCTION
    public static var fileNotFound: Error { get }           // ERROR_FILE_NOT_FOUND
    public static var pathNotFound: Error { get }           // ERROR_PATH_NOT_FOUND
    public static var accessDenied: Error { get }           // ERROR_ACCESS_DENIED
    public static var invalidHandle: Error { get }          // ERROR_INVALID_HANDLE
    public static var deviceNotReady: Error { get }         // ERROR_NOT_READY
    public static var cyclicRedundancyCheck: Error { get }  // ERROR_CRC
    public static var writeFault: Error { get }             // ERROR_WRITE_FAULT
    public static var sharingViolation: Error { get }       // ERROR_SHARING_VIOLATION
    public static var lockViolation: Error { get }          // ERROR_LOCK_VIOLATION
    public static var notLocked: Error { get }              // ERROR_NOT_LOCKED
    public static var negativeSeek: Error { get }           // ERROR_NEGATIVE_SEEK
    public static var endOfFile: Error { get }              // ERROR_HANDLE_EOF
    public static var brokenPipe: Error { get }             // ERROR_BROKEN_PIPE
    public static var notSupported: Error { get }           // ERROR_NOT_SUPPORTED
    public static var fileExists: Error { get }             // ERROR_FILE_EXISTS
    public static var invalidParameter: Error { get }       // ERROR_INVALID_PARAMETER
    public static var insufficientBuffer: Error { get }     // ERROR_INSUFFICIENT_BUFFER
    public static var invalidName: Error { get }            // ERROR_INVALID_NAME
    public static var badPathName: Error { get }            // ERROR_BAD_PATHNAME
    public static var alreadyExists: Error { get }          // ERROR_ALREADY_EXISTS
    public static var fileTooLarge: Error { get }           // ERROR_FILE_TOO_LARGE
    public static var diskFull: Error { get }               // ERROR_DISK_FULL
    public static var pipeBusy: Error { get }               // ERROR_PIPE_BUSY
    public static var noData: Error { get }                 // ERROR_NO_DATA
    public static var pipeNotConnected: Error { get }       // ERROR_PIPE_NOT_CONNECTED
    public static var moreData: Error { get }               // ERROR_MORE_DATA
    public static var notADirectory: Error { get }          // ERROR_DIRECTORY
    public static var operationAborted: Error { get }       // ERROR_OPERATION_ABORTED
    public static var ioPending: Error { get }              // ERROR_IO_PENDING
    public static var userMappedFile: Error { get }         // ERROR_USER_MAPPED_FILE
    public static var cannotResolveFileName: Error { get }  // ERROR_CANT_RESOLVE_FILENAME

    // ... and a code System synthesizes, which Windows never reports:
    public static var incompleteTransfer: Error { get }     // 0xA0535901

    /// Whether System synthesized this error instead of Windows reporting it.
    public var isSynthesized: Bool { get }
  }
}

extension Win32.Error: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { get }
  public var debugDescription: String { get }
}

extension Win32.Error {
  public static func ~= (_ lhs: Win32.Error, _ rhs: Swift.Error) -> Bool
}
```

The named constants are not exhaustive. They cover every code that System's Win32 APIs document plus codes that callers commonly branch on, and `rawValue` covers everything else. A `struct` over `DWORD` keeps unknown codes representable and round-trippable, which is required for a type modeling an error space of several thousand values that any application can extend with `SetLastError`.

The last code is System's own and uses a base of `0xA0535900`. Windows reserves bit 29 (`APPLICATION_ERROR_MASK`) for application-defined codes, and setting bit 31 makes the code negative so `HRESULT_FROM_WIN32` leaves it unchanged. `isSynthesized` checks for System's base.

System may reuse a Windows code if it accurately describes the condition, even for a check Windows doesn't make itself. For example, a wrapper throws `.invalidParameter` for an argument it rejects before calling Win32, such as an overlapped flag or a negative offset, and `.notADirectory` when a directory open doesn't resolve to a directory. System only synthesizes a code when no Windows code fits. One example is `.incompleteTransfer`, which is thrown in [SYS-0014](0014-win32-file-io.md) when a `WriteFile` succeeds without writing anything.

`~=` lets a `catch` clause match a `Win32.Error` pattern against an untyped error, as `Errno`'s does.

### `description` and `debugDescription`

Like `Errno`, `Win32.Error` provides a human-readable `description` using `FormatMessageW`. As with `strerror`, the message is localized to the system or thread locale, so it's suitable for display or logging, but not for programmatic matching. `FormatMessageW` allocates, so `description` should be avoided in hot paths. `description` strips the trailing `\r\n` that system messages end with, and falls back to a numeric rendering when `FormatMessageW` fails.

`debugDescription` gives the symbolic constant with the decimal and hexadecimal value, such as `ERROR_SHARING_VIOLATION (32, 0x20)`, and the numeric form alone for codes that have no name. It's locale-independent and suitable for tests or structured logs.

A synthesized code has no system message, so both properties render it from a local table instead.

### Capturing the last error

`GetLastError` is thread-local and volatile. The next Win32 call on the thread clobbers it, and so can an ARC release that runs a `deinit` between the failing call and the error read. Every wrapper in the namespace must capture the code into a `Win32.Error` immediately at the failure site.

Some Win32 functions return a value that can mean either success or failure, such as `GetFileType`'s `FILE_TYPE_UNKNOWN` ([SYS-0015](0015-win32-file-type.md)), and don't clear the last error when they succeed. In this case, a System wrapper must call `SetLastError(ERROR_SUCCESS)` before the function so users don't have to.

Certain Win32 functions may succeed and set the last error to a code that carries information. For example, `CreateFileW` with `OPEN_ALWAYS` or `CREATE_ALWAYS` can return a valid handle and set `ERROR_ALREADY_EXISTS` to report that the file already existed. A `throws` signature can't express this, so System APIs must surface it through parameter or return types instead. See [SYS-0012](0012-win32-opening-handles.md). If the code instead means the operation didn't happen, the wrapper throws it. For instance, a console `ReadFile` interrupted by Ctrl+C succeeds with `ERROR_OPERATION_ABORTED`, so the reads in [SYS-0014](0014-win32-file-io.md) throw `.operationAborted` instead of reporting the end of the file.

A Win32 function may also fail while `GetLastError` reports `ERROR_SUCCESS`. Wrappers report the error directly from the system, so a `throws(Win32.Error)` API can throw `.success`.

### Interoperating with `Errno`

The conversion to `Errno` is lossy:

```swift
extension Errno {
  /// The closest POSIX equivalent of a Windows system error.
  ///
  /// This mapping is lossy. It approximates the C runtime's `_dosmaperr`
  /// behavior, which folds Windows' several thousand system error codes onto
  /// sixteen ``Errno`` values. Unrecognized codes become
  /// ``Errno/invalidArgument``. Prefer handling ``Win32/Error`` directly.
  public init(approximating error: Win32.Error)
}
```

This gives the existing internal `Errno(windowsError:)` a public spelling. Its behavior does not change, because the POSIX shim still needs the behavior, but the lossiness becomes part of the contract instead of an implementation detail. The `approximating:` label carries that warning at the call site.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

`Win32` and everything in it is only available on Windows, so cross-platform callers must guard their uses. This is intentional so the platform dependency is visible at the use site rather than hidden behind a portable-looking type with unportable behavior.

## Future directions

### Later stages

These stages could follow the proposals in the **Introduction**:

| Future direction | Mentioned in |
| --- | --- |
| Querying file information | Below |
| Setting file information | Below |
| Security descriptors, ACLs, and SIDs | Below, [SYS-0012](0012-win32-opening-handles.md) |
| Directory enumeration, change notification, and creation | [SYS-0012](0012-win32-opening-handles.md) |
| Creating and querying named pipes | [SYS-0012](0012-win32-opening-handles.md), [SYS-0015](0015-win32-file-type.md) |
| Standard handles and console detection | [SYS-0011](0011-win32-filehandle.md), [SYS-0015](0015-win32-file-type.md) |
| Asynchronous I/O, including scatter/gather | [SYS-0011](0011-win32-filehandle.md), [SYS-0014](0014-win32-file-io.md) |
| Volume queries by path, including free space | [SYS-0017](0017-win32-volume-information.md) |
| `DeviceIoControl` and `FSCTL` codes | [SYS-0018](0018-win32-final-path-name.md) |
| Portable metadata over `Stat` and the Win32 types | [SYS-0006](0006-system-stat.md), [SYS-0012](0012-win32-opening-handles.md), [SYS-0017](0017-win32-volume-information.md) |

**Querying file information.** `GetFileInformationByHandle` and `GetFileInformationByHandleEx` provide file metadata on Windows: attributes, file identifiers, alignment, compression, remote protocol details, alternate data streams, and directory enumeration. A future proposal should nest those information classes and their associated types in `Win32`.

**Setting file information.** `SetFileInformationByHandle` is the natural companion and reaches semantics that have no `FileDescriptor` spelling at all, such as `FILE_DISPOSITION_POSIX_SEMANTICS` and `FILE_RENAME_POSIX_SEMANTICS`. It should follow once the query side has settled the shape of the information-class types.

**Security descriptors.** `GetSecurityInfo`, `SetSecurityInfo`, ACLs, and SIDs reach beyond the file system. They're the Windows analog of `FilePermissions` and `UserID`, and are large enough to be their own effort. That effort would build on the `Win32.SecurityDescriptor` that [SYS-0012](0012-win32-opening-handles.md) introduces.

### `Win32.HResult`

COM-shaped APIs in the Win32 surface (the `PathCch*` family in particular) report an `HRESULT` rather than a system error code, and System's Windows path canonicalization already flattens one with a private helper. The namespace will eventually need a public story for this, most likely a minimal `Win32.HResult` wrapper with a `var win32Error: Win32.Error?` that extracts the code only when the facility is `FACILITY_WIN32`. None of the proposals in this series need to surface it publicly, so it's left out for now.

## Alternatives considered

### Throw `Errno` from Win32 APIs too

Report failures from the new Win32 APIs as `Errno`, converting through the existing mapping table. This would be consistent with the rest of System and would avoid leaving Windows with two error types.

Rejected for the reasons in **`Errno` can't express Windows failures**.

### Extend `_mapWindowsErrorToErrno` instead of adding a type

Give the mapping table more entries and finer distinctions, so that `Errno` remains System's only error type on every platform.

Rejected because:

* A better table still couldn't express the failures that `Errno` has no values for, as **`Errno` can't express Windows failures** describes.
* Changing the table would change the `errno` values that existing `FileDescriptor` operations report, which would be a breaking behavior change. The shim should keep matching the C runtime.

### No namespace, prefixed top-level names

Spell the types `Win32Error`, `Win32FileHandle`, and so on, with no enclosing type.

Rejected because:

* A namespace is the canonical way to organize and document which of Windows' several overlapping API layers is being wrapped.
* `Mach` and `Mach.Port` already provide precedent in System.

### A separate `Win32System` module

Vend the Windows APIs from their own module instead of a namespace, possibly alongside a `POSIXSystem` module for System's Unix-only types.

Rejected because Swift modules don't namespace their top-level names. A top-level `Error` would shadow `Swift.Error` in any file that imports the module, and a `FileHandle` would clash with Foundation's, so the module would still need the `Win32` namespace, or prefixed names. Whether that namespace lives in its own module is a packaging choice that doesn't change these APIs.

### Name the namespace `Windows`

Name the namespace for the platform rather than the API layer. This may be safer if System later wraps something that's not Win32.

Rejected because:

* It's more vague and reads as a synonym for `os(Windows)`.
* The APIs it would future-proof against (the NT Native API, the Shell, WinRT) are explicitly excluded from this proposal.

### Expose a `CInterop.DWORD` typealias

Spell raw Win32 values through `CInterop`, so that `Win32.Error.rawValue` would be a `CInterop.DWORD`. This would match how `UserID` stores a `CInterop.UserID`.

Rejected because:

* `CInterop` aliases C types whose definitions vary by platform, such as `mode_t` and `uid_t`. `DWORD` has one definition, and every API that uses it is Windows-only.
* `Mach`, the precedent for this namespace, spells Darwin's types directly, such as `mach_port_name_t`.
* Code that reads or passes a raw value is calling Win32 functions, so it already imports `WinSDK`.

### Name the error type `Win32.ErrorCode`

`Win32.ErrorCode` is more literal, since Windows calls these "system error codes", and it would avoid shadowing `Swift.Error` inside the namespace.

Rejected because it's verbose and breaks the convention Foundation and other Swift projects follow, where error types are named like `POSIXError` and `URLError`, and `Code` names their nested code types. The shadowing only affects code written inside `extension Win32 { }`, which would be mostly System's own implementations.

### An `enum` with cases instead of a `struct`

Give `Win32.Error` a case per named code, making a `switch` over it exhaustive.

Rejected because an `enum` can't represent a code the library has not enumerated, and the Windows error space is open-ended.

### A public `Win32.Error.current`

A `GetLastError` wrapper, with a setter for `SetLastError`, would let callers read and clear the last error themselves.

Rejected because:

* Such an accessor can't be made correct by construction. Swift may insert an ARC release between the failing call and the read, and the caller's own intervening work could clobber the value, too. `Errno.current` is internal for the same reason.
* Callers using raw Win32 functions already have `GetLastError` and `SetLastError`, and can wrap a result with `Win32.Error.init(_:)`.

### Synthesize a code instead of throwing `.success`

When a Win32 function fails but `GetLastError` reports `ERROR_SUCCESS`, throw a synthesized code, so that a logged error doesn't read "The operation completed successfully."

Rejected because it trades fidelity for a friendlier log line. When Windows reports a failure, the thrown error is the code Windows reported, even `ERROR_SUCCESS`. System synthesizes codes only for results that Windows reports as success, like the `WriteFile` behind `.incompleteTransfer`. The case is rare, and `debugDescription` still identifies it as `ERROR_SUCCESS (0, 0x0)`.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.Error` | `DWORD` system error code |
| `Win32.Error.description` | `FormatMessageW` with `FORMAT_MESSAGE_FROM_SYSTEM`, `FORMAT_MESSAGE_ALLOCATE_BUFFER`, and `FORMAT_MESSAGE_IGNORE_INSERTS` |
| `Errno.init(approximating:)` | `_dosmaperr` (as `_mapWindowsErrorToErrno`) |

Testing was performed on an ARM64 Windows 11 VM (build 22631). The pipe error codes were reproduced on an x64 Windows 11 PC (build 26200).
