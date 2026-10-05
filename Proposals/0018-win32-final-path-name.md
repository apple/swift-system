# Final Path Name for `Win32.FileHandle`

* Proposal: [SYS-0018](0018-win32-final-path-name.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md), [SYS-0012](0012-win32-opening-handles.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds a method to the `Win32` handle types for getting the file's fully resolved path. It builds on the `Win32.FileHandle` and `Win32.DirectoryHandle` types introduced in [SYS-0011](0011-win32-filehandle.md) and [SYS-0012](0012-win32-opening-handles.md).

## Motivation

### Getting the resolved path of a file

System normalizes paths for every Windows file operation using `GetFullPathNameW` followed by `PathAllocCanonicalize`. Both functions are purely lexical. They resolve `.` and `..`, apply the current directory, and add the `\\?\` prefix when the result is long, without ever touching the file system.

That is the right tool for preparing a path string to hand to `CreateFileW`, but it can't tell a caller where the path resolved to. Windows symbolic links, directory junctions, and volume mount points are all reparse points, and a lexically canonical path says nothing about them.

`GetFinalPathNameByHandleW` answers the question: given a handle that is already open, what is the real path of the object behind it? A caller may need this when auditing a handle from another service, detecting that a path was redirected, or logging something a human will correlate with the file system. System has no spelling for it today.

Note that [SE-0529](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0529-filepath-in-stdlib.md) adds `FilePath.resolve()`, which achieves this by opening a handle of its own. The proposed API here allows callers who don't know the path to query the handle directly, e.g. for a handle that was inherited or duplicated, or when the file was renamed after it was opened.

## Proposed solution

Add `finalPath(volumeName:normalized:)` to `Win32.FileHandle` and `Win32.DirectoryHandle`.

```swift
#if os(Windows)
let handle = try Win32.FileHandle.open(path, access: .readAttributes)

// Where did this path actually land?
let resolved = try handle.finalPath()
print(resolved)  // \\?\D:\Data\real\file.txt
try handle.close()
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them.

```swift
extension Win32 {
  /// How the volume component of a resolved path is spelled.
  @frozen
  public struct VolumeNameFormat: RawRepresentable, Sendable, Hashable, Codable {
    public var rawValue: DWORD
    public init(rawValue: DWORD)

    /// A drive-letter path, such as `\\?\C:\dir\file`, or a UNC path such as
    /// `\\?\UNC\server\share\dir\file` for a file on a network share.
    ///
    /// The corresponding C constant is `VOLUME_NAME_DOS`.
    public static var dos: VolumeNameFormat { get }

    /// A volume GUID path, such as `\\?\Volume{...}\dir\file`.
    ///
    /// Use this for a volume with no assigned drive letter. A file on a
    /// network share has no volume GUID, so passing this format to
    /// ``Win32/FileHandle/finalPath(volumeName:normalized:)`` throws
    /// ``Win32Error/pathNotFound`` for such a file.
    ///
    /// The corresponding C constant is `VOLUME_NAME_GUID`.
    public static var guid: VolumeNameFormat { get }

    /// An NT device path, such as `\Device\HarddiskVolume2\dir\file`.
    ///
    /// - Note: Win32 path functions treat this as a path on the current drive.
    ///   For a path to open, use the ``Win32/VolumeNameFormat/dos`` or
    ///   ``Win32/VolumeNameFormat/guid`` format.
    ///
    /// The corresponding C constant is `VOLUME_NAME_NT`.
    public static var nt: VolumeNameFormat { get }

    /// A volume-relative path with no volume component, such as `\dir\file`.
    ///
    /// The corresponding C constant is `VOLUME_NAME_NONE`.
    public static var volumeRelative: VolumeNameFormat { get }
  }
}

extension Win32.FileHandle {
  /// Returns the fully resolved path of the file this handle refers to.
  ///
  /// Unlike lexical canonicalization, this resolves symbolic links, directory
  /// junctions, and volume mount points.
  ///
  /// - Parameters:
  ///   - volumeName: How to spell the volume component. The default,
  ///     ``Win32/VolumeNameFormat/dos``, throws
  ///     ``Win32Error/pathNotFound`` for a volume with no drive letter; use
  ///     ``Win32/VolumeNameFormat/guid`` in that case.
  ///   - normalized: Whether to return the canonical name of each component
  ///     rather than the names supplied when the file was opened.
  ///
  /// Requires no access rights. Throws for a handle with no path, such as
  /// ``Win32Error/badPathName`` for a pipe, ``Win32Error/invalidParameter``
  /// for `NUL`, and ``Win32Error/invalidFunction`` for a console or volume.
  ///
  /// The corresponding C function is `GetFinalPathNameByHandleW`.
  public func finalPath(
    volumeName: Win32.VolumeNameFormat = .dos,
    normalized: Bool = true
  ) throws(Win32Error) -> FilePath
}

extension Win32.DirectoryHandle {
  /// Returns the fully resolved path of the directory this handle refers to.
  ///
  /// The corresponding C function is `GetFinalPathNameByHandleW`.
  public func finalPath(
    volumeName: Win32.VolumeNameFormat = .dos,
    normalized: Bool = true
  ) throws(Win32Error) -> FilePath
}
```

`normalized` is a separate `Bool` rather than a member of `Win32.VolumeNameFormat`. `FILE_NAME_NORMALIZED` and `FILE_NAME_OPENED` are OR'd into the same `dwFlags`, but they are mutually exclusive. Modeling them in one option set would invite callers to pass a combination that means nothing.

`GetFinalPathNameByHandleW` reports a buffer that is too small by returning the required length rather than by failing, so the wrapper sizes, allocates, and retries. That loop is better implemented here instead of at every call site.

`Win32.DirectoryHandle` gets the same API. `GetFinalPathNameByHandleW` accepts a handle to a file or a directory, and resolving the path of an open directory is what a caller auditing a junction or a mount point needs.

A result in the `.dos` format always carries the `\\?\` prefix. In testing, a file on a network share resolved to `\\?\UNC\...`, and a drive letter defined with `DefineDosDevice` (e.g. via a call to `subst`) resolved to its target. `finalPath(volumeName:normalized:)` returns the path as Windows reports it; see **Alternatives considered**. SE-0529 doesn't specify which form `FilePath.resolve()` returns on Windows, and the two should agree.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

Everything here is behind `#if os(Windows)` and reached through `Win32.FileHandle` or `Win32.DirectoryHandle`, so cross-platform callers must guard their uses.

## Future directions

* **`DeviceIoControl` and the `FSCTL` family.** `FSCTL_GET_REPARSE_POINT`, `FSCTL_SET_SPARSE`, `FSCTL_QUERY_ALLOCATED_RANGES`, and `FSCTL_DUPLICATE_EXTENTS_TO_FILE` are useful file system operations but have no dedicated Win32 function. A general `DeviceIoControl` wrapper is an unbounded, untyped surface whose buffer-sizing and retry contract needs its own review, and typed wrappers over the individual control codes are comparable work.

## Alternatives considered

### Put `finalPath` on `FilePath` instead

A `FilePath.finalPath()` would be reachable without opening anything, and would look more like `realpath`.

Rejected because the standard library already owns that spelling. SE-0529 adds `FilePath.resolve()` and migrates `System.FilePath` to the stdlib, so a Windows-only `finalPath()` would be a near-duplicate sitting next to the cross-platform method.

Exposing this on the handle also keeps the access-rights and share-mode decisions where the caller already made them, and avoids a second open. There's no sharing conflict with a handle the caller is already holding and no window of time where the path could be redirected between the caller's open and the query.

### Strip the `\\?\` prefix when it isn't needed

Return `C:\dir\file` rather than `\\?\C:\dir\file` when the shorter form names the same file. Rust's `std::fs::canonicalize` returns the verbatim form, and the `dunce` crate exists to strip it.

Rejected because some paths only survive in verbatim form, such as a component with a trailing dot or space, a reserved name like `CON`, or a path longer than `MAX_PATH`. A caller that wants a display path can strip the prefix when it knows the result is safe.

### Fold `DeviceIoControl` into this proposal

It's the natural completion of the reparse-point story since without it, a caller can learn that a file is a reparse point but not what it points to.

Rejected on review size. See **Future directions** for what a separate proposal would need to settle.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle.finalPath(volumeName:normalized:)` | `GetFinalPathNameByHandleW` |
| `Win32.VolumeNameFormat.dos` / `.guid` / `.nt` / `.volumeRelative` | `VOLUME_NAME_DOS` / `VOLUME_NAME_GUID` / `VOLUME_NAME_NT` / `VOLUME_NAME_NONE` |
| `normalized: true` / `false` | `FILE_NAME_NORMALIZED` / `FILE_NAME_OPENED` |

Testing was performed on an ARM64 Windows 11 VM (build 22631), where the remote file was in a shared folder (not on an SMB share). The results for local handles were reproduced on an x64 Windows 11 PC (build 26200).
