# Volume Information for `Win32.FileHandle`

* Proposal: [SYS-0017](0017-win32-volume-information.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md), [SYS-0012](0012-win32-opening-handles.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds a volume information query to the Win32 handle types. It builds on the `Win32.FileHandle` and `Win32.DirectoryHandle` types introduced in [SYS-0011](0011-win32-filehandle.md) and [SYS-0012](0012-win32-opening-handles.md).

## Motivation

### Volume capabilities decide which operations succeed

The file system a handle lives on determines what operations are supported. Hard links, sparse files, reparse points, named streams, and POSIX-like unlink and rename are all optional features that NTFS, ReFS, exFAT, FAT32, and network redirectors support to different degrees. A caller who can't query them has to attempt the operation and interpret the failure, which may not be informative.

`GetVolumeInformationByHandleW` reports those capabilities along with the file system name, the volume serial number, and the maximum component length. It complements the `StatFS` type that [SYS-0009](0009-system-statfs.md) proposes for Unix-like platforms.

## Proposed solution

Add `volumeInformation()` to `Win32.FileHandle` and `Win32.DirectoryHandle`.

```swift
#if os(Windows)
let handle = try Win32.FileHandle.open(path, access: .readAttributes)

// What can this volume do?
let volume = try handle.volumeInformation()
print(volume.fileSystemName)  // "NTFS"
if volume.flags.contains(.supportsHardLinks) {
  try createHardLink(from: path, to: backupPath)
}
try handle.close()
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them.

```swift
extension Win32 {
  /// Information about a file system volume.
  @frozen
  public struct VolumeInformation: Sendable, Hashable, Codable {
    /// The volume label, such as "System Reserved" or a user-defined label
    /// like "My Backup Drive".
    ///
    /// A volume with no label reports the empty string.
    ///
    /// The corresponding C parameter of `GetVolumeInformationByHandleW` is
    /// `lpVolumeNameBuffer`.
    public var name: String

    /// The name of the file system, such as `NTFS`, `ReFS`, `exFAT`, or
    /// `FAT32`.
    ///
    /// The corresponding C parameter of `GetVolumeInformationByHandleW` is
    /// `lpFileSystemNameBuffer`.
    public var fileSystemName: String

    /// The volume serial number assigned when the volume was formatted.
    ///
    /// This is not a durable identifier. Reformatting changes it, and it's
    /// not guaranteed to be unique across machines. A network redirector may
    /// report 0.
    ///
    /// The corresponding C parameter of `GetVolumeInformationByHandleW` is
    /// `lpVolumeSerialNumber`.
    public var serialNumber: UInt32

    /// The maximum length, in characters, of a single path component.
    ///
    /// The corresponding C parameter of `GetVolumeInformationByHandleW` is
    /// `lpMaximumComponentLength`.
    public var maximumComponentLength: Int

    /// The features this file system supports.
    ///
    /// The corresponding C parameter of `GetVolumeInformationByHandleW` is
    /// `lpFileSystemFlags`.
    public var flags: FileSystemFlags
  }

  /// Features a file system may support.
  @frozen
  public struct FileSystemFlags: OptionSet, Sendable, Hashable, Codable {
    public var rawValue: DWORD
    public init(rawValue: DWORD)

    public static var caseSensitiveSearch: FileSystemFlags { get }
    public static var casePreservedNames: FileSystemFlags { get }
    public static var unicodeOnDisk: FileSystemFlags { get }
    public static var persistentACLs: FileSystemFlags { get }
    public static var fileCompression: FileSystemFlags { get }
    public static var volumeQuotas: FileSystemFlags { get }
    public static var supportsSparseFiles: FileSystemFlags { get }
    public static var supportsReparsePoints: FileSystemFlags { get }
    public static var supportsRemoteStorage: FileSystemFlags { get }
    public static var returnsCleanupResultInfo: FileSystemFlags { get }
    public static var supportsPOSIXUnlinkRename: FileSystemFlags { get }
    public static var supportsBypassIO: FileSystemFlags { get }
    public static var supportsStreamSnapshots: FileSystemFlags { get }
    public static var supportsCaseSensitiveDirectories: FileSystemFlags { get }
    public static var volumeIsCompressed: FileSystemFlags { get }
    public static var supportsObjectIDs: FileSystemFlags { get }
    public static var supportsEncryption: FileSystemFlags { get }
    public static var namedStreams: FileSystemFlags { get }
    public static var readOnlyVolume: FileSystemFlags { get }
    public static var sequentialWriteOnce: FileSystemFlags { get }
    public static var supportsTransactions: FileSystemFlags { get }
    public static var supportsHardLinks: FileSystemFlags { get }
    public static var supportsExtendedAttributes: FileSystemFlags { get }
    public static var supportsOpenByFileID: FileSystemFlags { get }
    public static var supportsUSNJournal: FileSystemFlags { get }
    public static var supportsIntegrityStreams: FileSystemFlags { get }
    public static var supportsBlockRefcounting: FileSystemFlags { get }
    public static var supportsSparseVDL: FileSystemFlags { get }
    public static var daxVolume: FileSystemFlags { get }
    public static var supportsGhosting: FileSystemFlags { get }
  }
}

extension Win32.FileHandle {
  /// Returns information about the volume this file resides on.
  ///
  /// The corresponding C function is `GetVolumeInformationByHandleW`.
  public func volumeInformation() throws(Win32.Error) -> Win32.VolumeInformation
}

extension Win32.DirectoryHandle {
  /// Returns information about the volume this directory resides on.
  ///
  /// The corresponding C function is `GetVolumeInformationByHandleW`.
  public func volumeInformation() throws(Win32.Error) -> Win32.VolumeInformation
}
```

`Win32.VolumeInformation` is a plain struct of decoded values rather than a `RawRepresentable` wrapper over a C type because there is no single C struct to wrap; `GetVolumeInformationByHandleW` writes into five separate out-parameters. This departs from the convention followed by `Stat`, `FileDescriptor`, and the other System wrappers, but makes sense for the shape of the call.

Both string fields are copied eagerly. `GetVolumeInformationByHandleW` bounds each at `MAX_PATH + 1` characters, so the wrapper stack-allocates for both and returns `String`s rather than asking a caller to supply storage.

`maximumComponentLength` is an `Int` because callers compare it against string and path lengths. `serialNumber` is a `UInt32` because it is an opaque 32-bit identifier rather than a quantity. Like `Stat.generationNumber`, a decoded field uses a Swift type rather than the C `DWORD`.

`Win32.FileSystemFlags` covers every flag `WinNT.h` defines today, in bit order, so the set can be checked against the header. `rawValue` can carry any flag Windows adds later before this API is updated.

`caseSensitiveSearch` reports whether the *volume* supports case-sensitive lookup. Per-directory case sensitivity, which is what callers usually mean on modern Windows, is a separate setting, read with `GetFileInformationByHandleEx` and written with `SetFileInformationByHandle`. `supportsCaseSensitiveDirectories` reports whether the volume allows it.

`Win32.DirectoryHandle` gets this API, too. A directory handle names a file system object on a volume just as a file handle does.

Neither method requires access rights. In testing, `volumeInformation()` on a pipe reported the named-pipe file system, `NPFS`, as a pseudo-volume with a `maximumComponentLength` of `UInt32.max`. On `NUL`, it threw `.invalidFunction`.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

Everything here is behind `#if os(Windows)` and reached through `Win32.FileHandle` or `Win32.DirectoryHandle`, so cross-platform callers must guard their uses.

## Future directions

* **Path-based and volume-based variants.** `GetVolumeInformationW`, `GetVolumePathNameW`, and `GetVolumeNameForVolumeMountPointW` answer the same questions from a path or volume root rather than an open handle, and `GetDiskFreeSpaceExW` adds the capacity figures that the proposed `StatFS` type reports on Unix-like platforms.
* **A portable file system information type.** With the proposed `StatFS` for Unix-like platforms and `Win32.VolumeInformation` for Windows, we could implement a portable layer over both.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle.volumeInformation()` | `GetVolumeInformationByHandleW` |
| `Win32.VolumeInformation.name` | `lpVolumeNameBuffer` |
| `Win32.VolumeInformation.fileSystemName` | `lpFileSystemNameBuffer` |
| `Win32.VolumeInformation.serialNumber` | `lpVolumeSerialNumber` |
| `Win32.VolumeInformation.maximumComponentLength` | `lpMaximumComponentLength` |
| `Win32.VolumeInformation.flags` | `lpFileSystemFlags` |
| `Win32.FileSystemFlags` members | the matching `FILE_*` constant, such as `FILE_SUPPORTS_HARD_LINKS` for `.supportsHardLinks` |

Testing was performed on an ARM64 Windows 11 VM (build 22631), where the remote file was in a shared folder (not on an SMB share). The results for local handles were reproduced on an x64 Windows 11 PC (build 26200).
