# Opening Files and Directories as `Win32` Handles

* Proposal: [SYS-0012](0012-win32-opening-handles.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds opening, duplication, reopening, and inheritance control to `Win32.FileHandle`, the type introduced in [SYS-0011](0011-win32-filehandle.md), along with `Win32.DirectoryHandle` for directories.

## Motivation

`Win32.FileHandle` needs a way to be opened, and mirroring `FileDescriptor` would carry over three of its gaps.

### Directories can't be opened

`CreateFileW` returns a handle to a directory only if it's passed `FILE_FLAG_BACKUP_SEMANTICS`. Without that flag, the call fails. `FileDescriptor.OpenOptions` doesn't support it, and System's `open` adapter never sets the flag.

So `FileDescriptor.open(someDirectory, .readOnly)` succeeds on Linux and Darwin but fails on Windows, and no option a caller can pass changes that. Every Windows API that takes a directory handle, including enumeration, change notification, and per-directory case sensitivity, is unreachable from System today.

### `FileDescriptor.OpenOptions` supports a fraction of `CreateFileW`

System's `open` adapter calls `CreateFileW`, wraps the result with `_open_osfhandle`, and hardcodes `FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE` on every open. That default is correct for making System on Windows behave like POSIX when an open file is deleted or renamed, but it isn't configurable. A caller can't request exclusive access, which on Windows is the main mechanism for mandatory sharing control and has no POSIX `open` equivalent.

The rest of the mapping is similarly narrow. The adapter maps `_O_CREAT`, `_O_EXCL`, and `_O_TRUNC` onto a creation disposition, maps the access mode onto `GENERIC_READ` and `GENERIC_WRITE`, and passes through `_O_NOINHERIT`, `_O_SEQUENTIAL`, `_O_RANDOM`, `_O_TEMPORARY`, and `_O_SHORT_LIVED`. Since `FileDescriptor.OpenOptions` is limited to its `CInt` of `oflag` bits, these options plus `FilePermissions` make up the entire surface, and neither can express:

* Handle flags, such as `FILE_FLAG_WRITE_THROUGH` and `FILE_FLAG_NO_BUFFERING` for durable and unbuffered I/O, and `FILE_FLAG_OPEN_REPARSE_POINT`, which opens a symbolic link or junction itself rather than its target, as `FileDescriptor.OpenOptions.symlink` does on Darwin.
* A security descriptor that mode bits can't describe. The adapter converts the permissions into access control entries for the current user, the user's primary group, and Everyone, but a caller can't grant access to any other principal, such as the SYSTEM account or the Administrators group. The example in **`Win32.SecurityDescriptor`** grants access to exactly those two.
* Fine-grained access rights, such as `FILE_READ_ATTRIBUTES`, which opens a file for metadata access only. Those opens can succeed in cases where a read open would be denied.

### Handle lifetime operations have no spelling

`FileDescriptor.OpenOptions.closeOnExec` maps to `_O_NOINHERIT`, so the adapter does set `bInheritHandle` at creation time, but `DuplicateHandle` and `SetHandleInformation` have no true `FileDescriptor` equivalent. There is no way to duplicate a handle with a chosen access mask or inheritability, and no way to make an already-open handle inheritable before spawning a child process.

## Proposed solution

Give `Win32.FileHandle` a `CreateFileW` wrapper whose parameters model Win32's own argument structure rather than POSIX `oflag` bits. Add `Win32.DirectoryHandle` for directories, with the same ownership model.

```swift
#if os(Windows)
// Open a directory. `FILE_FLAG_BACKUP_SEMANTICS` is applied automatically.
// `dir` has no read or write surface, and closes at the end of this scope.
let dir = try Win32.DirectoryHandle.open("C:\\Users\\me\\Documents")

// Ask for exclusive access (no sharing).
let exclusive = try Win32.FileHandle.open(
  path, access: [.genericRead, .genericWrite], shareMode: []
)
try exclusive.close() // Handles may be closed explicitly for error handling.

// Open for metadata only. This succeeds where a read open would be denied.
let meta = try Win32.FileHandle.open(path, access: .readAttributes)
try meta.close()

// Create if absent, and find out if the file already existed.
let log = try Win32.FileHandle.openOrCreate(logPath, access: .genericWrite)
if !log.existed { try writeHeader(to: log.handle) }
try log.handle.close()
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them. These APIs only support synchronous handles and reject `FILE_FLAG_OVERLAPPED` on open; see **No `.overlapped`**.

### Opening

```swift
extension Win32.FileHandle {
  /// Opens or creates a file, device, or pipe.
  ///
  /// - Parameters:
  ///   - path: The path to open.
  ///   - access: The requested access rights. An empty set requests neither
  ///     read nor write access, which allows for querying metadata where a
  ///     read open could be denied.
  ///   - shareMode: How the file may be shared with other opens while this
  ///     handle is alive. The default is `[.read, .write, .delete]`, matching
  ///     POSIX `open` behavior. Pass `[]` for exclusive access, which is what
  ///     `CreateFileW` does for a `dwShareMode` of 0.
  ///   - disposition: Whether to create, open, or truncate.
  ///     ``Win32/CreationDisposition/truncateExisting`` and
  ///     ``Win32/CreationDisposition/createAlways`` fail with
  ///     ``Win32Error/userMappedFile`` while a view of the file is mapped.
  ///   - attributes: File attributes to apply when the file is created, or
  ///     when ``Win32/CreationDisposition/createAlways`` overwrites an
  ///     existing one. Otherwise ignored. The default `[]` requests no
  ///     attributes, as does ``Win32/FileAttributes/normal`` which is valid
  ///     only on its own.
  ///     With ``Win32/CreationDisposition/createAlways``, overwriting a
  ///     ``Win32/FileAttributes/hidden`` or ``Win32/FileAttributes/system``
  ///     file fails with ``Win32Error/accessDenied`` unless `attributes`
  ///     matches those bits.
  ///   - flags: Caching, semantic, and lifetime flags for this handle.
  ///   - inheritable: Whether child processes created with handle inheritance
  ///     enabled receive a copy of this handle. Applies whether the file is
  ///     created or opened.
  ///   - securityDescriptor: The security descriptor to apply when the file
  ///     is created. Ignored when an existing file is opened. This descriptor
  ///     is borrowed, not consumed.
  ///   - templateFile: A handle whose attributes and extended attributes are
  ///     applied to a newly created file. Must have been opened with
  ///     ``Win32/AccessMask/genericRead`` access. Ignored when an existing
  ///     file is opened. This handle is borrowed, not consumed.
  ///
  /// Throws ``Win32Error/invalidParameter`` if `flags` contains
  /// `FILE_FLAG_OVERLAPPED`, which ``Win32/FileHandle`` does not support, or
  /// if `attributes` contains a bit that can't be set at creation.
  ///
  /// Opening a directory without ``Win32/FileFlags/backupSemantics`` fails
  /// with ``Win32Error/accessDenied``. To open one, use
  /// ``Win32/DirectoryHandle/open(_:access:shareMode:flags:inheritable:)``.
  ///
  /// The corresponding C function is `CreateFileW`.
  public static func open(
    _ path: FilePath,
    access: Win32.AccessMask,
    shareMode: Win32.ShareMode = [.read, .write, .delete],
    disposition: Win32.CreationDisposition = .openExisting,
    attributes: Win32.FileAttributes = [],
    flags: Win32.FileFlags = [],
    inheritable: Bool = false,
    securityDescriptor: borrowing Win32.SecurityDescriptor? = nil,
    templateFile: borrowing Win32.FileHandle? = nil
  ) throws(Win32Error) -> Win32.FileHandle

  /// The result of ``openOrCreate(_:access:shareMode:overwriteExisting:attributes:flags:inheritable:securityDescriptor:templateFile:)``.
  @frozen
  public struct OpenOrCreateResult: ~Copyable, Sendable {
    /// The open handle.
    public let handle: Win32.FileHandle

    /// Whether the file already existed.
    public let existed: Bool
  }

  /// Opens a file, creating it if it does not exist, and reports whether it
  /// already existed.
  ///
  /// - Parameters:
  ///   - overwriteExisting: Whether to overwrite the contents of a file that
  ///     already exists. `false` corresponds to `OPEN_ALWAYS`, and `true` to
  ///     `CREATE_ALWAYS`. `CREATE_ALWAYS` also applies `attributes` to an
  ///     existing file, and fails with ``Win32Error/userMappedFile`` while a
  ///     view of the file is mapped.
  ///
  /// All other parameters and errors behave as they do on
  /// ``open(_:access:shareMode:disposition:attributes:flags:inheritable:securityDescriptor:templateFile:)``.
  ///
  /// The corresponding C function is `CreateFileW`.
  public static func openOrCreate(
    _ path: FilePath,
    access: Win32.AccessMask,
    shareMode: Win32.ShareMode = [.read, .write, .delete],
    overwriteExisting: Bool = false,
    attributes: Win32.FileAttributes = [],
    flags: Win32.FileFlags = [],
    inheritable: Bool = false,
    securityDescriptor: borrowing Win32.SecurityDescriptor? = nil,
    templateFile: borrowing Win32.FileHandle? = nil
  ) throws(Win32Error) -> OpenOrCreateResult
}
```

Notes on the signature:

* **`shareMode` defaults to read, write, and delete.** That is not the Windows default, but it matches what callers coming from POSIX expect, what System's existing `open` adapter already hardcodes, and Rust's `std::fs::OpenOptions` default. A communications device such as a serial port requires a `shareMode` of `[]`.
* **`inheritable` defaults to `false`**, like Rust's `std::fs::File` and unlike `FileDescriptor.open`, whose handles are inherited unless `FileDescriptor.OpenOptions.closeOnExec` is passed.
* **`disposition` is a single choice, not an option set.** `CREATE_NEW`, `CREATE_ALWAYS`, `OPEN_EXISTING`, `OPEN_ALWAYS`, and `TRUNCATE_EXISTING` are mutually exclusive. `FileDescriptor.OpenOptions` conflates creation and truncation into a bitmask because POSIX `open` does. Win32 does not.
* **`attributes` and `flags` are separate parameters.** `CreateFileW` takes them OR'd together into a single `dwFlagsAndAttributes`. Attributes are properties of the file, and flags are properties of this handle. The wrapper combines them, but first rejects any `attributes` bit that can't be set at creation, since some attribute values collide with flags.
* **`inheritable` and `securityDescriptor` replace a raw `SECURITY_ATTRIBUTES` pointer.** The wrapper builds the struct from these two fields plus the boilerplate `nLength` field.
* **`securityDescriptor` and `templateFile` borrow an optional binding.** Both are `borrowing` parameters of noncopyable optional type, so the borrow only happens when the argument is already typed `Win32.SecurityDescriptor?` or `Win32.FileHandle?`. Passing a non-optional variable fails to compile with a request to add `consume`, which destroys the descriptor or closes the template handle. An inline call result is consumed without a diagnostic since nothing else holds it. See **Future directions** for the language features that would remove this wrinkle.
* **`openOrCreate` reports file existence in the return type.** With `OPEN_ALWAYS` or `CREATE_ALWAYS`, `CreateFileW` returns a valid handle for an existing file and sets the last error to `ERROR_ALREADY_EXISTS`. We shouldn't throw this error on success, so `openOrCreate` reports it via `OpenOrCreateResult.existed`.
  - Note: `CreateFileW` sets the last error on every success, to `ERROR_ALREADY_EXISTS` or `ERROR_SUCCESS`, so a stale error is never misread as "already existed".
  - Note: The `.openAlways` and `.createAlways` dispositions remain reachable through `open`, where they discard `existed`.

### Opening a directory

```swift
extension Win32 {
  /// An open directory.
  ///
  /// Opening one applies `FILE_FLAG_BACKUP_SEMANTICS`. This type has no
  /// read or write surface, because `ReadFile` and `WriteFile` fail on a
  /// directory handle.
  ///
  /// The corresponding C type is `HANDLE`.
  @frozen @safe
  public struct DirectoryHandle: ~Copyable, Sendable {
    @unsafe
    public init?(unsafelyAdopting raw: HANDLE?)

    @unsafe
    public var unsafeRawHandle: HANDLE { get }

    @unsafe
    public consuming func relinquish() -> HANDLE

    public consuming func close() throws(Win32Error)
  }
}

extension Win32.DirectoryHandle {
  /// Opens a directory.
  ///
  /// `FILE_FLAG_BACKUP_SEMANTICS` is added to `flags` automatically. Without
  /// that flag, `CreateFileW` fails on a directory.
  ///
  /// Throws ``Win32Error/invalidParameter`` if `flags` contains
  /// `FILE_FLAG_OVERLAPPED`, which ``Win32/DirectoryHandle`` does not support.
  ///
  /// Throws ``Win32Error/notDirectory`` if the opened handle is not a
  /// directory, after closing the handle.
  ///
  /// The corresponding C function is `CreateFileW`.
  public static func open(
    _ path: FilePath,
    access: Win32.AccessMask = .listDirectory,
    shareMode: Win32.ShareMode = [.read, .write, .delete],
    flags: Win32.FileFlags = [],
    inheritable: Bool = false
  ) throws(Win32Error) -> Win32.DirectoryHandle
}
```

Developers may be unaware that `FILE_FLAG_BACKUP_SEMANTICS` is required to open a directory. A separate `Win32.DirectoryHandle` type makes this common use case reachable without that knowledge. The type also removes the read and write surface that `ReadFile` and `WriteFile` reject at runtime.

`Win32.DirectoryHandle` has the ownership model and conformances of `Win32.FileHandle`, described in [SYS-0011](0011-win32-filehandle.md).

`Win32.DirectoryHandle` has no `disposition`, `attributes`, `securityDescriptor`, or `templateFile` parameter. Creating a directory requires `CreateDirectoryW`, not `CreateFileW`, and should be considered in a future proposal.

`FILE_FLAG_BACKUP_SEMANTICS` allows a directory to be opened, but does not require the returned handle to be a directory. `open` verifies the result: after `CreateFileW` succeeds, it calls `GetFileInformationByHandleEx` with `FileStandardInfo`, which needs no access rights, to confirm the object is a directory. If not, it throws `.notDirectory`. Without that check, a regular-file path would yield a `Win32.DirectoryHandle` that fails every directory operation.

### Path handling

`open` will canonicalize `path` similar to how `FileDescriptor.open` does on Windows. `GetFullPathNameW` resolves the path against the current directory, collapses dot segments, and turns device names such as `NUL` into `\\.\NUL`. Then, unless the result starts with `\\.\`, `PathAllocCanonicalize` with `PATHCCH_ALLOW_LONG_PATHS` applies the `\\?\` prefix when the result exceeds `MAX_PATH`.

However, `open` will pass a path that starts with `\\?\` to `CreateFileW` untouched, since that prefix means "pass this path through verbatim". `FileDescriptor` doesn't exempt it, and in testing, `GetFullPathNameW` stripped trailing dots and collapsed `..` even inside a `\\?\` path, so `FileDescriptor.open` opens `\\?\C:\dir\name.` as `name` rather than `name.`.

A failed `PathAllocCanonicalize` reports an `HRESULT`, but `open` throws `Win32Error`, so System will convert the `FACILITY_WIN32` errors internally. A public `HResult` remains future work as described in [SYS-0010](0010-win32-namespace-and-error.md).

### Supporting types for `open`

| Type | Wraps | Notable members |
| --- | --- | --- |
| `Win32.AccessMask` | `DWORD` `OptionSet` | `.genericRead`, `.genericWrite`, `.readData`, `.listDirectory`, `.readAttributes`, `.delete`, see below |
| `Win32.ShareMode` | `DWORD` `OptionSet` | `.read`, `.write`, `.delete` |
| `Win32.CreationDisposition` | `DWORD` `RawRepresentable` | `.createNew`, `.createAlways`, `.openExisting`, `.openAlways`, `.truncateExisting` |
| `Win32.FileFlags` | `DWORD` `OptionSet` | `.backupSemantics`, `.noBuffering`, `.writeThrough`, `.sequentialScan`, `.randomAccess`, `.deleteOnClose`, `.openReparsePoint`, `.posixSemantics`, `.openNoRecall`, `.sessionAware` |
| `Win32.FileAttributes` | `DWORD` `OptionSet` | `.normal`, `.readOnly`, `.hidden`, `.system`, `.archive`, `.temporary`, `.offline`, `.encrypted` |
| `Win32.SecurityDescriptor` | `PSECURITY_DESCRIPTOR` | `init(sddl:)`, see below |

These option-set and raw-value types conform to `Sendable`, `Hashable`, and `Codable`, matching `FileDescriptor.OpenOptions` and `FileDescriptor.SeekOrigin`.

`Win32.FileAttributes` is introduced here because `CreateFileW` requires it. Only the subset above is meaningful at creation time, and `open` and `openOrCreate` reject any other bit. A future proposal covering file information queries should extend this type to the full set of reported values.

#### `Win32.AccessMask`

`Win32.AccessMask` covers the rights `CreateFileW` accepts in `dwDesiredAccess`. The generic rights are `.genericRead`, `.genericWrite`, `.genericExecute`, and `.genericAll`. The standard rights are `.delete`, `.readControl`, `.writeDAC`, `.writeOwner`, and `.synchronize`.

The specific rights occupy the low 16 bits, and Windows gives four of them a second name for directories. Both spellings are vended by `Win32.AccessMask`:

| Value | File spelling | Directory spelling |
| --- | --- | --- |
| `0x1` | `.readData` | `.listDirectory` |
| `0x2` | `.writeData` | `.addFile` |
| `0x4` | `.appendData` | `.addSubdirectory` |
| `0x20` | `.execute` | `.traverse` |

Each pair of spellings names one bit, so `mask.contains(.listDirectory)` is true of any mask holding `.readData`; vending both names trades that ambiguity for a faithful mapping of the underlying type. The remaining specific rights have one name each: `.readExtendedAttributes` (`0x8`), `.writeExtendedAttributes` (`0x10`), `.deleteChild` (`0x40`, meaningful only on a directory), `.readAttributes` (`0x80`), and `.writeAttributes` (`0x100`).

`.maximumAllowed` doesn't name a right at all. It asks the system to grant every right the access check finds the caller entitled to, and like the generic rights, it never appears in a mask reported back. `CreateFileW` also adds `.readAttributes` and `.synchronize` to every request, which is why an empty `access` can still query metadata.

#### No `.overlapped`

A `Win32.FileHandle` is always synchronous, as [SYS-0011](0011-win32-filehandle.md) describes. `Win32.FileFlags` vends `.overlapped` as an unavailable member so the restriction is discoverable:

```swift
@available(*, unavailable, message: "Overlapped handles are not supported")
public static var overlapped: FileFlags { get }
```

`Win32.FileFlags(rawValue:)` can still carry the bit, so every entry point that takes `flags` rejects it with `.invalidParameter` before calling Win32. Rejecting `attributes` bits that can't be set at creation also keeps `0x40000000` in `attributes` from reaching `CreateFileW` as the same flag.

#### `Win32.SecurityDescriptor`

```swift
extension Win32 {
  /// A Windows security descriptor.
  ///
  /// This type owns its storage and releases it with `LocalFree`.
  ///
  /// The corresponding C type is `PSECURITY_DESCRIPTOR`.
  @frozen @safe
  public struct SecurityDescriptor: ~Copyable, Sendable {
    /// Parses a Security Descriptor Definition Language string.
    ///
    /// The corresponding C function is
    /// `ConvertStringSecurityDescriptorToSecurityDescriptorW` with
    /// `SDDL_REVISION_1`.
    public init(sddl: String) throws(Win32Error)

    /// Adopts a descriptor allocated with `LocalAlloc`, taking ownership.
    ///
    /// Returns `nil` if `raw` is `NULL`.
    @unsafe
    public init?(unsafelyAdopting raw: PSECURITY_DESCRIPTOR?)

    /// The raw C pointer. Valid only while this value is alive.
    @unsafe
    public var unsafeRawPointer: PSECURITY_DESCRIPTOR { get }

    /// Gives up ownership and returns the raw pointer.
    ///
    /// The caller becomes responsible for releasing it with `LocalFree`.
    @unsafe
    public consuming func relinquish() -> PSECURITY_DESCRIPTOR
  }
}
```

`Win32.SecurityDescriptor` mirrors the handle types: owning, noncopyable, and `Sendable`. Win32 functions return descriptors in `LocalAlloc` memory that no Swift value owns, so a borrowing wrapper isn't feasible. Without a safe constructor, every use of `securityDescriptor:` would require `@unsafe` adoption, so this proposal provides SDDL parsing to start:

```swift
let sd: Win32.SecurityDescriptor? = try .init(sddl: "D:P(A;;GA;;;SY)(A;;GA;;;BA)")
let file = try Win32.FileHandle.open(
  path, access: .genericWrite, disposition: .createNew, securityDescriptor: sd
)
```

Descriptors from elsewhere, such as `GetSecurityInfo`, can arrive through `init?(unsafelyAdopting:)`, and the typed APIs in **Future directions** can extend the type without changing `open`'s signature.

### Duplication, reopening, and inheritance

```swift
extension Win32.FileHandle {
  /// Duplicates this handle within the current process.
  ///
  /// - Parameters:
  ///   - access: The duplicate's access rights. `nil` requests the same
  ///     rights this handle has.
  ///   - inheritable: Whether child processes created with handle inheritance
  ///     enabled receive a copy of the duplicate.
  ///
  /// - Returns: A new owned handle. The caller must close it.
  ///
  /// The corresponding C function is `DuplicateHandle`.
  public func duplicate(
    access: Win32.AccessMask? = nil,
    inheritable: Bool = false
  ) throws(Win32Error) -> Win32.FileHandle

  /// Re-opens this handle's file as a new file object, with its own file
  /// pointer, access rights, share mode, and flags.
  ///
  /// Unlike ``open(_:access:shareMode:disposition:attributes:flags:inheritable:securityDescriptor:templateFile:)``,
  /// this doesn't resolve a path, so it reaches the same file even if that
  /// file was renamed or its path now names a different file. Unlike
  /// ``duplicate(access:inheritable:)``, the result doesn't share this
  /// handle's file pointer.
  ///
  /// Like any open, the request must be compatible with the share modes of
  /// the file's other open handles, including this one.
  ///
  /// Throws ``Win32Error/invalidParameter`` if `flags` contains
  /// `FILE_FLAG_OVERLAPPED`.
  ///
  /// The corresponding C function is `ReOpenFile`.
  public func reopen(
    access: Win32.AccessMask,
    shareMode: Win32.ShareMode = [.read, .write, .delete],
    flags: Win32.FileFlags = []
  ) throws(Win32Error) -> Win32.FileHandle

  /// Whether child processes created with handle inheritance enabled receive
  /// a copy of this handle.
  ///
  /// The corresponding C functions are `GetHandleInformation` and
  /// `SetHandleInformation` with `HANDLE_FLAG_INHERIT`.
  public func isInheritable() throws(Win32Error) -> Bool
  public func setInheritable(_ value: Bool) throws(Win32Error)
}
```

`Win32.DirectoryHandle` gets the same four members. Its `duplicate` and `reopen` return a `Win32.DirectoryHandle`, and its `reopen` adds `FILE_FLAG_BACKUP_SEMANTICS`.

`duplicate(access:inheritable:)` covers the common same-process case and mirrors `FileDescriptor.duplicate(as:retryOnInterrupt:)`. A `nil` `access` passes `DUPLICATE_SAME_ACCESS`. Duplicating into another process requires a target process handle and is out of scope for this proposal.

`reopen(access:shareMode:flags:)` is the path-free way to get an independent file pointer, a narrower access mask, or different flags, such as `.noBuffering`, for a file already open. `ReOpenFile` takes no attributes, since those only apply when a file is created.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

Everything here sits behind `#if os(Windows)`, so cross-platform callers must guard their uses.

## Future directions

[SYS-0010](0010-win32-namespace-and-error.md) lists the rest of this series and the stages that could follow it.

* **Directory operations.** `Win32.DirectoryHandle` is the entry point for enumeration with `FileIdBothDirectoryInfo`, change notification with `ReadDirectoryChangesW`, and per-directory case sensitivity. Creation with `CreateDirectoryW` belongs there too.
* **Named pipes.** `Win32.FileHandle.open` connects to an existing pipe today, but creating one requires `CreateNamedPipeW` and its pipe mode, instance count, and timeout parameters, or `CreatePipe` for an anonymous pair. `Win32.AccessMask` withholds `FILE_CREATE_PIPE_INSTANCE`, a third spelling of `0x4`, until then. A named-pipe API should also let a client choose an impersonation level, since `open` can set one only through raw `SECURITY_SQOS_PRESENT` and level bits in `Win32.FileFlags`, which share values with flags such as `.openNoRecall`.
* **Security descriptors.** `Win32.SecurityDescriptor` initially covers only SDDL parsing and could be extended: reading a descriptor with `GetSecurityInfo`, applying one with `SetSecurityInfo`, rendering one to SDDL with `ConvertSecurityDescriptorToStringSecurityDescriptorW`, and typed ACL and SID APIs. All of these allocate with `LocalAlloc`, so they fit the existing `deinit`; an API that frees another way, such as `CreatePrivateObjectSecurity`, would need a different type.
* **A cross-platform `FileInfo`.** [SYS-0006](0006-system-stat.md) future directions describe an ergonomic metadata abstraction over `Stat` and the Windows types, and this series builds the underlying Windows types.
* **Borrowing `securityDescriptor` and `templateFile` without an annotation.** `Ref<Win32.SecurityDescriptor>?` and `Ref<Win32.FileHandle>?` ([SE-0519](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0519-ref-mutableref-types.md)) would let callers pass a non-optional value directly, as in `templateFile: Ref(template)`. `Ref` is available in Swift 6.4, but adopting it requires raising System's minimum toolchain, and its lifetime checking is still maturing.

## Alternatives considered

### Extend `FileDescriptor.OpenOptions` instead

Add the missing `CreateFileW` capabilities, such as share modes and handle flags, to `FileDescriptor.OpenOptions` on Windows.

Rejected because:

* It gives Windows-only meanings to portable `FileDescriptor.OpenOptions` members, on a type documented and used as a cross-platform POSIX file descriptor.
* It leaves out duplication with a chosen access mask, reopening, and changing inheritance, no matter which options are added.

### Enable `FileDescriptor.OpenOptions.directory` on Windows

Lifting the `#if !os(Windows)` on `FileDescriptor.OpenOptions.directory` is implementable: set `FILE_FLAG_BACKUP_SEMANTICS`, then fail with `ENOTDIR` if the resulting handle lacks `FILE_ATTRIBUTE_DIRECTORY`. Setting the flag on every open would fix portability more broadly.

Rejected because:

* The POSIX and Windows semantics are inverted. `O_DIRECTORY` restricts an open that POSIX already allows, while `FILE_FLAG_BACKUP_SEMANTICS` allows one `CreateFileW` would otherwise refuse. So `FileDescriptor.OpenOptions.directory` would be required to open a directory on Windows but optional on POSIX, and `FileDescriptor.open(someDirectory, .readOnly)` would still fail on Windows.
* Setting the flag on every open would override file security checks for a process that has enabled `SE_BACKUP_NAME` or `SE_RESTORE_NAME`.
* The useful directory operations on Windows require a `HANDLE` anyway.

### One handle type with a `.backupSemantics` flag

Keep a single `Win32.FileHandle` and let callers pass `flags: .backupSemantics` to open a directory. One fewer type, and perfectly faithful to `CreateFileW`.

Rejected for the reasons in **Opening a directory**:

* A separate type makes the directory use-case reachable without knowing about the flag.
* `Win32.FileHandle` would have a read and write surface that fails at runtime on a directory handle.

### A general `Win32.Handle` protocol

Windows `HANDLE` is polymorphic across object types, so a `~Copyable` protocol with `close()`, `duplicate(access:inheritable:)`, and the inheritance members is tempting.

Rejected for now because:

* It would deduplicate five members across two types at the cost of a public protocol.
* The lifetime operations may not lift cleanly to a third kind anyway, since a search handle from `FindFirstFileW` closes with `FindClose` rather than `CloseHandle`. A protocol can be added later if needed.

### Return a result struct from a single `open`

`open` would return `Win32.FileHandle.OpenOrCreateResult` for every disposition, and `openOrCreate` would not exist, de-duplicating the parameter list and doc comment across two declarations.

Rejected because it makes every caller go through `.handle`, when only the minority that passes the `.openAlways` or `.createAlways` disposition cares whether the file existed.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.DirectoryHandle` | `HANDLE` |
| `Win32.SecurityDescriptor` | `PSECURITY_DESCRIPTOR` |
| `Win32.SecurityDescriptor.init(sddl:)` | `ConvertStringSecurityDescriptorToSecurityDescriptorW` with `SDDL_REVISION_1` |
| `Win32.SecurityDescriptor.deinit` | `LocalFree` |
| `Win32.FileHandle.open(_:access:shareMode:disposition:attributes:flags:inheritable:securityDescriptor:templateFile:)` | `CreateFileW` |
| `Win32.FileHandle.openOrCreate(_:access:shareMode:overwriteExisting:attributes:flags:inheritable:securityDescriptor:templateFile:)` | `CreateFileW` with `OPEN_ALWAYS`, or `CREATE_ALWAYS` when `overwriteExisting` |
| `Win32.FileHandle.OpenOrCreateResult.existed` | `ERROR_ALREADY_EXISTS` after a successful `OPEN_ALWAYS` or `CREATE_ALWAYS` |
| `Win32.DirectoryHandle.open(_:access:shareMode:flags:inheritable:)` | `CreateFileW` with `FILE_FLAG_BACKUP_SEMANTICS` |
| `Win32.FileHandle.duplicate(access:inheritable:)` | `DuplicateHandle` |
| `Win32.FileHandle.reopen(access:shareMode:flags:)` | `ReOpenFile` |
| `Win32.FileHandle.isInheritable()` | `GetHandleInformation` with `HANDLE_FLAG_INHERIT` |
| `Win32.FileHandle.setInheritable(_:)` | `SetHandleInformation` with `HANDLE_FLAG_INHERIT` |
| `Win32.AccessMask` | `dwDesiredAccess` |
| `Win32.ShareMode` | `dwShareMode` |
| `Win32.CreationDisposition` | `dwCreationDisposition` |
| `Win32.FileFlags` and `Win32.FileAttributes` | `dwFlagsAndAttributes` |
| `inheritable:` and `securityDescriptor:` | `lpSecurityAttributes` (`SECURITY_ATTRIBUTES`) |
| `templateFile:` | `hTemplateFile` |

Testing was performed on an ARM64 Windows 11 VM (build 22631), with every file on a local NTFS volume. All results were reproduced on an x64 Windows 11 PC (build 26200).
