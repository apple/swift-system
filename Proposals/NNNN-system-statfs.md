# StatFS for Swift System

* Proposal: [SYS-NNNN](NNNN-system-statfs.md)
* Authors: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Awaiting review**
* Implementation: [apple/swift-system#361](https://github.com/apple/swift-system/pull/361)
* Review: ([pitch](https://forums.swift.org/t/pitch-statfs-and-supporting-types/88151))

#### Revision history

* **v1** Initial version

## Introduction

This proposal introduces a Swift-native `StatFS` type to the System library, providing comprehensive access to file system metadata on Unix-like platforms through type-safe, platform-aware APIs that wrap the underlying C `statfs` or `statvfs` system calls.

## Motivation

Currently, Swift developers who want to work with the file system's lowest level API can only do so through bridged C interfaces. These interfaces lack type safety and require writing non-idiomatic Swift, leading to errors and confusion.

The goal of the `StatFS` type is to provide a faithful and performant Swift wrapper around the underlying C system calls while adding type safety, platform abstraction, and improved discoverability/usability with clear naming. For more on the motivation behind System, see [https://www.swift.org/blog/swift-system](https://www.swift.org/blog/swift-system)

## Proposed solution

This proposal adds a `struct StatFS` that is available on Unix-like platforms. On Windows, the struct is declared but marked unavailable (see **Availability on Windows**). Windows-specific file-system API is discussed in **Future Directions**.

`StatFS` is a Swift wrapper around the C `statfs` or `statvfs` struct, which provides information about file systems. On Darwin and BSD operating systems, this type uses `statfs` for the additional information it provides. On other Unix-like operating systems, this type uses the standard `statvfs` interface. Computed properties like `.totalSpace` and `.availableSpace` are supplied for convenience.

```swift
// Get file system information from a path
let statfs = try StatFS("/")

// From FileDescriptor
let statfs = try fd.statfs()

// From FilePath
let statfs = try filePath.statfs()

print("File system ID: \(statfs.fileSystemID)")
print("Total space: \(statfs.totalSpace) bytes")
print("Available space: \(statfs.availableSpace) bytes")

// Check mount flags
if statfs.mountFlags.contains(.readOnly) {
  print("File system is read-only")
}

// Platform-specific information when available
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
print("File system is mounted at \(statfs.mountPoint)")
print("File system is mounted from \(statfs.mountSource)")
#endif
```

### Error Handling

All initializers use a typed `throws(Errno)` and require Swift 6.0 or later:

```swift
do {
  let statfs = try StatFS("/nonexistent/file")
} catch Errno.noSuchFileOrDirectory {
  print("File not found")
} catch {
  print("Other error: \(error)")
}
```

## Detailed design

See the **Appendix** section at the end of this proposal for a table view of Swift API to C mappings.

All API are marked `@_alwaysEmitIntoClient` for performance and to allow back-dating of availability, except `StatFS`'s `==` and `hash(into:)`, which are ordinary `public` API.

This proposal introduces a `MountFlags` type representing flags that could be present in a `statfs` or `statvfs` struct. On Darwin and BSD, these flags could also be passed to a future implementation of `mount`. (Linux `mount(2)` instead takes a separate `MS_*` set, distinct from the `ST_*` flags `statvfs` reports). Mount-specific flags are outside the scope of this proposal, see **Future Directions**. `MountFlags` uses a `CInterop` typealias for its `rawValue` to support different widths of integers used on different operating systems. Comments are omitted for space.


### `MountFlags`
```swift
/// Options employed when mounting a file system.
@frozen
public struct MountFlags: OptionSet, Sendable, Hashable, Codable {
  public let rawValue: CInterop.MountFlags
  public init(rawValue: CInterop.MountFlags)

  // Flags available on all platforms

  public static var readOnly: MountFlags { get }
  public static var synchronous: MountFlags { get }
  public static var noExecution: MountFlags { get }
  public static var noSetUserID: MountFlags { get }
  public static var noAccessTime: MountFlags { get }

  // Flags available on all platforms except FreeBSD

  #if !os(FreeBSD)
  public static var noDevices: MountFlags { get }
  #endif

  // Flags available on Linux, WASI, and Android

  #if os(Linux) || os(WASI) || os(Android)
  public static var mandatoryLockingPermitted: MountFlags { get }
  public static var noDirectoryAccessTime: MountFlags { get }
  public static var relativeAccessTime: MountFlags { get }
  #endif

  // Flags available on Linux and WASI only

  #if os(Linux) || os(WASI)
  public static var write: MountFlags { get }
  public static var appendOnly: MountFlags { get }
  public static var immutable: MountFlags { get }
  #endif

  // Flags available on Linux, Android, and FreeBSD

  #if os(Linux) || os(Android) || os(FreeBSD)
  public static var noSymlinkFollow: MountFlags { get }
  #endif

  // Flags available on Darwin, FreeBSD, and OpenBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  public static var asynchronous: MountFlags { get }
  public static var exported: MountFlags { get }
  public static var local: MountFlags { get }
  public static var quota: MountFlags { get }
  public static var rootFileSystem: MountFlags { get }
  #endif

  // Flags available on Darwin and FreeBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  public static var union: MountFlags { get }
  public static var automounted: MountFlags { get }
  public static var multiLabel: MountFlags { get }
  #endif

  // Flags available on FreeBSD and OpenBSD

  #if os(FreeBSD) || os(OpenBSD)
  public static var exportedReadOnly: MountFlags { get }
  public static var exportedByDefault: MountFlags { get }
  public static var exportedAnonymously: MountFlags { get }
  public static var softUpdates: MountFlags { get }
  #endif

  // Flags available on Darwin only

  #if SYSTEM_PACKAGE_DARWIN
  public static var contentProtection: MountFlags { get }
  public static var removable: MountFlags { get }
  public static var quarantine: MountFlags { get }
  public static var volumeFileSystem: MountFlags { get }
  public static var noBrowsing: MountFlags { get }
  public static var ignoreOwnership: MountFlags { get }
  public static var journaled: MountFlags { get }
  public static var noUserExtendedAttributes: MountFlags { get }
  public static var deferWrites: MountFlags { get }
  public static var noSymlinkFollowAtMountPoint: MountFlags { get }
  public static var snapshot: MountFlags { get }
  public static var strictAccessTime: MountFlags { get }
  #endif

  // Flags available on FreeBSD only

  #if os(FreeBSD)
  public static var exportedKerberos: MountFlags { get }
  public static var exportedPublic: MountFlags { get }
  public static var posixACLs: MountFlags { get }
  public static var geomJournaled: MountFlags { get }
  public static var excludedFromDiskFreeReports: MountFlags { get }
  public static var nfs4ACLs: MountFlags { get }
  public static var noClusterRead: MountFlags { get }
  public static var noClusterWrite: MountFlags { get }
  public static var setUserIDDirectory: MountFlags { get }
  public static var softUpdateJournaling: MountFlags { get }
  public static var untrusted: MountFlags { get }
  public static var mountedByUser: MountFlags { get }
  public static var verified: MountFlags { get }
  #endif

  // Flags available on OpenBSD only

  #if os(OpenBSD)
  public static var noPermissionChecks: MountFlags { get }
  public static var writeExecuteAllowed: MountFlags { get }
  #endif
}
```

### `FileSystemID`, `FileSystemType`, and `FileSystemSubtype`

```swift
@frozen
public struct FileSystemID: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: CInterop.FileSystemID
  public init(rawValue: CInterop.FileSystemID)
  public init(_ rawValue: CInterop.FileSystemID)
}

// `FileSystemType` is available on Darwin and FreeBSD where `statfs` reports `f_type`.
// `FileSystemSubtype` is Darwin-only. Both are `UInt32` on every platform that
// provides them, so no `CInterop` typealias is needed.

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@frozen
public struct FileSystemType: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: UInt32
  public init(rawValue: UInt32)
  public init(_ rawValue: UInt32)
}
#endif

#if SYSTEM_PACKAGE_DARWIN
@frozen
public struct FileSystemSubtype: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: UInt32
  public init(rawValue: UInt32)
  public init(_ rawValue: UInt32)
}
#endif
```

On Linux, Android, and WASI, `CInterop.FileSystemID` is the integer type used by `statvfs` for `f_fsid`, so `FileSystemID` derives its `Equatable`, `Hashable`, and `Codable` conformances automatically. On Darwin, FreeBSD, and OpenBSD, however, `CInterop.FileSystemID` is the C `fsid_t` struct (a fixed two-element `int32_t` array), which provides no synthesized conformances. On those platforms, `FileSystemID` implements `Equatable`, `Hashable`, and `Codable` manually in terms of the underlying `val` members.

### `StatFS`

`StatFS` offers initializers that accept a `FilePath`, null-terminated `UnsafePointer<CChar>`, or `FileDescriptor`. Instance methods on `FileDescriptor` and `FilePath` are also provided, shown below.

The underlying C fields for each numeric property vary in signedness and width across platforms. Rather than create a platform-dependent type for each, we choose one fixed integer type per property — `Int` or `UInt64` — and clamp when getting or setting the value.

Block sizes and lengths (`blockSize`, `preferredIOBlockSize`, `fragmentSize`, and `maximumNameLength`) are exposed as `Int`. Most modern file systems report 4KiB block sizes by default, and in practice, the highest value seen on specialized (often network) file systems is on the order of 1MiB. The preferred I/O size could similarly reach values around 16MiB. These are still orders of magnitude smaller than `Int.max`, even for 32-bit platforms.

Block and inode counts, and the space values computed from them, are exposed as `UInt64` to preserve their full unsigned range on every platform. Real-world values can exceed `Int64.max`, and space computations can overflow and saturate to `UInt64.max`. Clamping lets us report `0` for the signed "available to non-superuser" counts that some BSDs allow to go negative.

```swift
/// A Swift wrapper of the C `statfs` struct on Darwin and BSD operating systems,
/// or the standard `statvfs` otherwise.
///
/// - Note: Only available on Unix-like platforms.
@frozen
public struct StatFS: RawRepresentable, Sendable, Hashable {
  /// The raw C `statfs` struct on Darwin and BSD, or the `statvfs` struct otherwise.
  public var rawValue: CInterop.StatFS

  /// Creates a Swift `StatFS` from the raw C struct.
  public init(rawValue: CInterop.StatFS)

  /// Creates a `StatFS` from a `FilePath`.
  ///
  /// The corresponding C function is `statfs()` on Darwin and BSD, or `statvfs()` otherwise.
  public init(
    _ path: FilePath,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `StatFS` from a null-terminated `UnsafePointer<CChar>` path.
  ///
  /// The corresponding C function is `statfs()` on Darwin and BSD, or `statvfs()` otherwise.
  public init(
    _ path: UnsafePointer<CChar>,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `StatFS` from a `FileDescriptor`.
  ///
  /// The corresponding C function is `fstatfs()` on Darwin and BSD, or `fstatvfs()` otherwise.
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// File system block size, in bytes.
  ///
  /// The corresponding C property is `f_bsize`.
  /// - Note: On Darwin and BSD, this is the fundamental size for block counts.
  ///   `statvfs` platforms use `fragmentSize` (`f_frsize`) instead.
  public var blockSize: Int { get set }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// Block size for optimal data transfer, in bytes.
  ///
  /// The corresponding C property is `f_iosize`.
  /// - Note: Only available on Darwin and BSD.
  public var preferredIOBlockSize: Int { get set }
  #else
  /// File system fragment size, in bytes.
  ///
  /// The corresponding C property is `f_frsize`.
  /// - Note: On `statvfs` platforms, this is the fundamental size for block
  ///   counts. Not present on Darwin or BSD, which use `blockSize` instead.
  public var fragmentSize: Int { get set }
  #endif

  /// Total number of blocks in the file system.
  ///
  /// The corresponding C property is `f_blocks`.
  /// - Note: In units of `blockSize` on Darwin and BSD (`statfs`), or
  ///   `fragmentSize` otherwise (`statvfs`).
  public var totalBlocks: UInt64 { get set }

  /// Total size of the file system, in bytes.
  ///
  /// - Note: Computed for convenience as `totalBlocks` times the fundamental
  ///   block size (see `totalBlocks`). Saturates to `UInt64.max` on overflow.
  public var totalSpace: UInt64 { get }

  /// Number of free blocks in the file system.
  ///
  /// The corresponding C property is `f_bfree`.
  /// - Note: In units of `blockSize` on Darwin and BSD (`statfs`), or
  ///   `fragmentSize` otherwise (`statvfs`).
  public var freeBlocks: UInt64 { get set }

  /// Free space in the file system, in bytes.
  ///
  /// - Note: Computed for convenience as `freeBlocks` times the fundamental
  ///   block size (see `freeBlocks`). Saturates to `UInt64.max` on overflow.
  public var freeSpace: UInt64 { get }

  /// Number of free blocks available to non-superuser.
  ///
  /// The corresponding C property is `f_bavail`.
  /// - Note: In units of `blockSize` on Darwin and BSD (`statfs`), or
  ///   `fragmentSize` otherwise (`statvfs`). On FreeBSD and OpenBSD, the
  ///   underlying C property is signed; negative values are clamped to 0.
  public var availableBlocks: UInt64 { get set }

  /// Available space in the file system for non-superuser, in bytes.
  ///
  /// - Note: Computed for convenience as `availableBlocks` times the fundamental
  ///   block size (see `availableBlocks`). Saturates to `UInt64.max` on overflow.
  public var availableSpace: UInt64 { get }

  /// Total number of inodes in the file system.
  ///
  /// The corresponding C property is `f_files`.
  public var totalInodes: UInt64 { get set }

  /// Number of free inodes in the file system.
  ///
  /// The corresponding C property is `f_ffree`.
  /// - Note: On FreeBSD, this reports the inodes available to a non-superuser
  ///   rather than the total free count, and the underlying C field is signed
  ///   (negative values are clamped to 0); on other platforms, it is the total
  ///   number of free inodes.
  public var freeInodes: UInt64 { get set }

  #if !SYSTEM_PACKAGE_DARWIN && !os(FreeBSD)
  /// Number of free inodes available to non-superuser.
  ///
  /// The corresponding C property is `f_favail`, reported on the `statvfs`
  /// platforms and by OpenBSD's `statfs`.
  /// - Note: Darwin and FreeBSD `statfs` do not report it. On OpenBSD, the
  ///   underlying C property is signed; negative values are clamped to 0.
  public var availableInodes: UInt64 { get set }
  #endif

  #if !SYSTEM_PACKAGE_DARWIN
  /// Maximum length of a file name on the file system, in bytes.
  ///
  /// The corresponding C property is `f_namemax`, reported on the `statvfs`
  /// platforms and by FreeBSD and OpenBSD `statfs`.
  /// - Note: Darwin's `statfs` does not report it.
  public var maximumNameLength: Int { get set }
  #endif

  /// File system ID.
  ///
  /// The corresponding C property is `f_fsid`.
  public var fileSystemID: FileSystemID { get set }

  /// Mount flags indicating the options employed when mounting the file system.
  ///
  /// The corresponding C property is `f_flags` on Darwin and BSD, or `f_flag` otherwise.
  public var mountFlags: MountFlags { get set }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// File system type.
  ///
  /// The corresponding C property is `f_type`.
  /// - Note: Only available on Darwin and FreeBSD, where this is an internal,
  ///   kernel-assigned VFS type index with no stable, public constants; it is
  ///   *not* a filesystem magic number like those found in the Linux `statfs`.
  ///   Prefer `typeName` to identify the file system in a readable format.
  public var type: FileSystemType { get set }
  #endif

  #if SYSTEM_PACKAGE_DARWIN
  /// File system subtype.
  ///
  /// The corresponding C property is `f_fssubtype`.
  /// - Note: Like `type`, this is a numeric value with no stable, public
  ///   constants. Only available on Darwin.
  public var subtype: FileSystemSubtype { get set }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// User that mounted the file system.
  ///
  /// The corresponding C property is `f_owner`.
  /// - Note: Only available on Darwin and BSD.
  public var owner: UserID { get set }

  /// File system type name.
  ///
  /// The corresponding C property is `f_fstypename`.
  /// - Note: Only available on Darwin and BSD.
  public var typeName: String { get }

  /// Directory where the file system is mounted, such as "/System/Volumes/Data".
  ///
  /// The corresponding C property is `f_mntonname`.
  /// - Note: Only available on Darwin and BSD.
  public var mountPoint: FilePath { get }

  /// The source of the mounted file system, such as "/dev/disk3s7".
  ///
  /// The corresponding C property is `f_mntfromname`.
  /// - Note: Only available on Darwin and BSD.
  public var mountSource: FilePath { get }
  #endif

  /// Compares the meaningful file-system metadata fields of two `StatFS` values.
  ///
  /// Reserved/"spare" fields are not compared, and name buffers are compared
  /// only up to their NUL terminators.
  public static func == (lhs: Self, rhs: Self) -> Bool

  /// Hashes the meaningful file-system metadata fields of a `StatFS` struct.
  ///
  /// These are the same fields compared by `==`. Reserved/"spare" fields are
  /// not hashed, and name buffers are hashed only up to their NUL terminators.
  public func hash(into hasher: inout Hasher)
}
```

`typeName`, `mountPoint`, and `mountSource` are get-only because they are backed by fixed-size C character buffers, which a non-throwing setter could not safely fill without risking silent truncation. Callers that need to write these fields can do so through `rawValue` directly.

`StatFS` conforms to `Hashable` (and therefore `Equatable`) by comparing and hashing its meaningful, publicly exposed fields, so two `StatFS` values are equal when their observable contents match. A byte-wise comparison would be unreliable because the bytes following each name buffer's NUL terminator are unspecified, and both structs may carry reserved/spare padding.

#### FileDescriptor and FilePath Extensions
```swift
extension FileDescriptor {
  /// Creates a `StatFS` for the file system containing the file referenced by this `FileDescriptor`.
  ///
  /// The corresponding C function is `fstatfs()` on Darwin and BSD, or `fstatvfs()` otherwise.
  public func statfs(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> StatFS
}

extension FilePath {
  /// Creates a `StatFS` for the file system containing the file referenced by this `FilePath`.
  ///
  /// The corresponding C function is `statfs()` on Darwin and BSD, or `statvfs()` otherwise.
  public func statfs(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> StatFS
}
```

### CInterop Extensions

This proposal extends the existing `CInterop` namespace with platform-appropriate typealiases for the underlying C types. Each is used as the `rawValue` for a corresponding strongly-typed representation.

```swift
extension CInterop {
  public typealias StatFS
  public typealias FileSystemID
  public typealias MountFlags
}
```

### Availability on Windows

Windows has no `statfs`/`statvfs`. Rather than omit the type there, where usage would fail with an unhelpful `cannot find 'StatFS' in scope`, we declare an unavailable stub with a message suggesting the relevant Win32 APIs. In the future, these could be replaced by dedicated System APIs.

```swift
#if os(Windows)
@available(Windows, unavailable, message: "StatFS is unavailable on Windows. Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
public struct StatFS {}
#else
// ...
#endif
```

Marking the type covers its initializers and members. The `FileDescriptor.statfs()` and `FilePath.statfs()` methods will also get a matching unavailable stub with the same message.

### WASI Support

WASI is included for parity, and `statvfs`/`fstatvfs` are present in `wasi-libc`, so this API compiles and links there. However, in the current `wasi-libc`, `statvfs` and `fstatvfs` are unconditional stubs (in `libc-bottom-half/sources/posix.c`) that set `errno` to `ENOSYS` and return `-1`:

```c
int statvfs(const char *__restrict path, struct statvfs *__restrict buf) {
    // TODO: We plan to support this eventually in WASI, but not yet.
    errno = ENOSYS;
    return -1;
}
```

As a result, on WASI these `StatFS` initializers will always fail at runtime and throw `Errno.noFunction`. Callers targeting WASI must therefore be prepared for `StatFS` to be effectively unavailable at runtime. We keep the API surface available on WASI so that code remains source-compatible across Unix-like platforms and can benefit automatically if WASI gains real `statvfs` support in the future.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility  

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

This feature can be freely adopted and un-adopted in source code with no deployment constraints and without affecting source or ABI compatibility.

## Future directions

To remain faithful to the underlying system calls, we don't anticipate extending `StatFS`. However, the types introduced in this proposal could serve as the foundation of broader file system APIs in Swift.

For instance, on Darwin and BSD, `MountFlags` could be useful for a future `mount()` implementation, and a future Swift wrapper of `getfsstat()` could return an array of `StatFS` structs.

A Linux `mount(2)` wrapper would look different. There, the flags `statvfs` reports (`ST_*`) are a distinct set from the flags `mount(2)` accepts (`MS_*`), so a mount wrapper would need its own input type rather than reusing `MountFlags`. The `MS_*` set also mixes per-mount options with operation selectors like bind, move, remount, and propagation changes, so an idiomatic wrapper would likely split these into separate functions. A new implementation might also prefer the newer `fsopen` / `fsmount` / `move_mount` family over classic `mount(2)`. Because Darwin, FreeBSD, and Linux each take a different `mount` signature, any such wrapper would be platform-specific.

While this proposal does not include `StatFS` on Windows, a separate proposal should provide Swift-native wrappers of idiomatic `GetVolumeInformation` and `DeviceIoControl` functions with their associated types.

A more general `FileSystemInfo` API could then build on these OS-specific types to provide an ergonomic, cross-platform abstraction for file system metadata. These future cross-platform APIs might be better implemented outside of System, such as in Foundation or another dedicated package.

## Alternatives considered

### `FileSystemInfo` as the lowest-level type

An alternative approach could be to have a more general `FileSystemInfo` type be the lowest level of abstraction provided by the System library. This type would then handle all the `statfs` or Windows-specific struct storage and accessors. However, this alternative:

- Is inconsistent with System's philosophy of providing low-level system abstractions.
- Introduces an even larger number of system-specific APIs on each type.
- Misses out on the familiarity of the `statfs` name. Developers know what to look for and what to expect from this type.

### Single combined type for both file and file system metadata

Combining `Stat` [SYS-0006] and `StatFS` into a single type was considered but rejected because file and file system information serve different purposes and are typically needed in different contexts. Storing and/or initializing both `stat` and `statfs` structs unnecessarily reduces performance when one isn't needed.

### Separate `StatFS` and `StatVFS` types

Having separate types for `statfs` and `statvfs` would increase cognitive overhead and confusion for developers deciding which to choose. It would require additional documentation explaining differences that are transparently handled by platform availability, and would require duplicate code. On operating systems where `statfs` exposes additional information, such as Darwin and FreeBSD, `statvfs` is just a wrapper around `statfs`, so there's little upside to providing a `StatVFS` type here. One upside might be that all properties of `StatVFS` would be available where the struct itself is available, but this likely doesn't outweigh the cost of having two types.

### Only have `FilePath` and `FileDescriptor` extensions rather than initializers that accept these types

While having `.statfs()` functions on `FilePath` and `FileDescriptor` is preferred for ergonomics and function chaining, this technique might lack the discoverability of having an initializer on `StatFS` directly. This proposal therefore includes both the initializers and extensions.

### Expose `type` and `subtype` as raw integers

`FileSystemType` and `FileSystemSubtype` wrap opaque `UInt32` values with no stable, public constants, so exposing `type` and `subtype` as bare `UInt32` was considered. We keep the wrapper types for fidelity to the underlying struct and for consistency with `FileSystemID`, which is similarly opaque. The wrappers also give these fields distinct types, avoiding accidental cross-comparisons and granting flexibility to add members later, if desired.

### Make `StatFS` unavailable on WASI

Making the API unavailable on WASI would prevent developers from writing code that is otherwise portable across Unix-like platforms. When calling `try StatFS(...)`, clients are expected to handle a potential `Errno`, so including the WASI stub doesn't degrade ergonomics here. Including the API now also keeps the availability coupled: once `wasi-libc` gains real `statvfs` support, System picks it up automatically without needing to track it.

## Acknowledgments

Thank you to Michael Ilseman for discussions on the shape and future directions of this API.

## Appendix

### Swift API to C Mapping

The following tables show the mapping between Swift APIs and their underlying C system calls across different operating systems:

#### `StatFS` Initializer Mappings

The `retryOnInterrupt: Bool = true` parameter is omitted for clarity.


| Swift API | Darwin / FreeBSD / OpenBSD | Linux / Android / WASI |
|-----------|----------------------------|------------------------|
| `StatFS(_ path: UnsafePointer<CChar>)` | `statfs()` | `statvfs()`|
| `StatFS(_ path: FilePath)` | `statfs()` | `statvfs()`|
| `FilePath.statfs()` | `statfs()` | `statvfs()` |
| | | |
| `StatFS(_ fd: FileDescriptor)` | `fstatfs()` | `fstatvfs()`|
| `FileDescriptor.statfs()` | `fstatfs()` | `fstatvfs()` |

#### `StatFS` Property Mappings

`"` denotes the same property name across all operating systems.

| Swift Property | Darwin (`statfs`) | FreeBSD (`statfs`) | OpenBSD (`statfs`) | Linux (`statvfs`) | Android (`statvfs`) | WASI (`statvfs`) |
|----------------|-------------------|--------------------|--------------------|-------------------|---------------------|------------------|
| `blockSize` | `f_bsize` | " | " | " | " | " |
| `preferredIOBlockSize` | `f_iosize` | `f_iosize` | `f_iosize` | N/A | N/A | N/A |
| `fragmentSize` | N/A | N/A | N/A | `f_frsize` | `f_frsize` | `f_frsize` |
| `totalBlocks` | `f_blocks` | " | " | " | " | " |
| `freeBlocks` | `f_bfree` | " | " | " | " | " |
| `availableBlocks` | `f_bavail` | " | " | " | " | " |
| `totalInodes` | `f_files` | " | " | " | " | " |
| `freeInodes` | `f_ffree` | " | " | " | " | " |
| `availableInodes` | N/A | N/A | `f_favail` | `f_favail` | `f_favail` | `f_favail` |
| `maximumNameLength` | N/A | `f_namemax` | `f_namemax` | `f_namemax` | `f_namemax` | `f_namemax` |
| `fileSystemID` | `f_fsid` | " | " | " | " | " |
| `mountFlags` | `f_flags` | `f_flags` | `f_flags` | `f_flag` | `f_flag` | `f_flag` |
| `type` | `f_type` | `f_type` | N/A | N/A | N/A | N/A |
| `subtype` | `f_fssubtype` | N/A | N/A | N/A | N/A | N/A |
| `owner` | `f_owner` | `f_owner` | `f_owner` | N/A | N/A | N/A |
| `typeName` | `f_fstypename` | `f_fstypename` | `f_fstypename` | N/A | N/A | N/A |
| `mountPoint` | `f_mntonname` | `f_mntonname` | `f_mntonname` | N/A | N/A | N/A |
| `mountSource` | `f_mntfromname` | `f_mntfromname` | `f_mntfromname` | N/A | N/A | N/A |

#### `MountFlags` Mappings

| Swift Flag | Darwin | FreeBSD | OpenBSD | Linux | Android | WASI |
|------------|--------|---------|---------|-------|---------|------|
| `readOnly` | `MNT_RDONLY` | `MNT_RDONLY` | `MNT_RDONLY` | `ST_RDONLY` | `ST_RDONLY` | `ST_RDONLY` |
| `synchronous` | `MNT_SYNCHRONOUS` | `MNT_SYNCHRONOUS` | `MNT_SYNCHRONOUS` | `ST_SYNCHRONOUS` | `ST_SYNCHRONOUS` | `ST_SYNCHRONOUS` |
| `noExecution` | `MNT_NOEXEC` | `MNT_NOEXEC` | `MNT_NOEXEC` | `ST_NOEXEC` | `ST_NOEXEC` | `ST_NOEXEC` |
| `noSetUserID` | `MNT_NOSUID` | `MNT_NOSUID` | `MNT_NOSUID` | `ST_NOSUID` | `ST_NOSUID` | `ST_NOSUID` |
| `noAccessTime` | `MNT_NOATIME` | `MNT_NOATIME` | `MNT_NOATIME` | `ST_NOATIME` | `ST_NOATIME` | `ST_NOATIME` |
| `noDevices` | `MNT_NODEV` | N/A | `MNT_NODEV` | `ST_NODEV` | `ST_NODEV` | `ST_NODEV` |
| `mandatoryLockingPermitted` | N/A | N/A | N/A | `ST_MANDLOCK` | `ST_MANDLOCK` | `ST_MANDLOCK` |
| `noDirectoryAccessTime` | N/A | N/A | N/A | `ST_NODIRATIME` | `ST_NODIRATIME` | `ST_NODIRATIME` |
| `relativeAccessTime` | N/A | N/A | N/A | `ST_RELATIME` | `ST_RELATIME` | `ST_RELATIME` |
| `write` | N/A | N/A | N/A | `ST_WRITE` | N/A | `ST_WRITE` |
| `appendOnly` | N/A | N/A | N/A | `ST_APPEND` | N/A | `ST_APPEND` |
| `immutable` | N/A | N/A | N/A | `ST_IMMUTABLE` | N/A | `ST_IMMUTABLE` |
| `noSymlinkFollow` | N/A | `MNT_NOSYMFOLLOW` | N/A | `ST_NOSYMFOLLOW` | `ST_NOSYMFOLLOW` | N/A |
| `asynchronous` | `MNT_ASYNC` | `MNT_ASYNC` | `MNT_ASYNC` | N/A | N/A | N/A |
| `exported` | `MNT_EXPORTED` | `MNT_EXPORTED` | `MNT_EXPORTED` | N/A | N/A | N/A |
| `local` | `MNT_LOCAL` | `MNT_LOCAL` | `MNT_LOCAL` | N/A | N/A | N/A |
| `quota` | `MNT_QUOTA` | `MNT_QUOTA` | `MNT_QUOTA` | N/A | N/A | N/A |
| `rootFileSystem` | `MNT_ROOTFS` | `MNT_ROOTFS` | `MNT_ROOTFS` | N/A | N/A | N/A |
| `union` | `MNT_UNION` | `MNT_UNION` | N/A | N/A | N/A | N/A |
| `automounted` | `MNT_AUTOMOUNTED` | `MNT_AUTOMOUNTED` | N/A | N/A | N/A | N/A |
| `multiLabel` | `MNT_MULTILABEL` | `MNT_MULTILABEL` | N/A | N/A | N/A | N/A |
| `exportedReadOnly` | N/A | `MNT_EXRDONLY` | `MNT_EXRDONLY` | N/A | N/A | N/A |
| `exportedByDefault` | N/A | `MNT_DEFEXPORTED` | `MNT_DEFEXPORTED` | N/A | N/A | N/A |
| `exportedAnonymously` | N/A | `MNT_EXPORTANON` | `MNT_EXPORTANON` | N/A | N/A | N/A |
| `softUpdates` | N/A | `MNT_SOFTDEP` | `MNT_SOFTDEP` | N/A | N/A | N/A |
| `contentProtection` | `MNT_CPROTECT` | N/A | N/A | N/A | N/A | N/A |
| `removable` | `MNT_REMOVABLE` | N/A | N/A | N/A | N/A | N/A |
| `quarantine` | `MNT_QUARANTINE` | N/A | N/A | N/A | N/A | N/A |
| `volumeFileSystem` | `MNT_DOVOLFS` | N/A | N/A | N/A | N/A | N/A |
| `noBrowsing` | `MNT_DONTBROWSE` | N/A | N/A | N/A | N/A | N/A |
| `ignoreOwnership` | `MNT_IGNORE_OWNERSHIP` | N/A | N/A | N/A | N/A | N/A |
| `journaled` | `MNT_JOURNALED` | N/A | N/A | N/A | N/A | N/A |
| `noUserExtendedAttributes` | `MNT_NOUSERXATTR` | N/A | N/A | N/A | N/A | N/A |
| `deferWrites` | `MNT_DEFWRITE` | N/A | N/A | N/A | N/A | N/A |
| `noSymlinkFollowAtMountPoint` | `MNT_NOFOLLOW` | N/A | N/A | N/A | N/A | N/A |
| `snapshot` | `MNT_SNAPSHOT` | N/A | N/A | N/A | N/A | N/A |
| `strictAccessTime` | `MNT_STRICTATIME` | N/A | N/A | N/A | N/A | N/A |
| `exportedKerberos` | N/A | `MNT_EXKERB` | N/A | N/A | N/A | N/A |
| `exportedPublic` | N/A | `MNT_EXPUBLIC` | N/A | N/A | N/A | N/A |
| `posixACLs` | N/A | `MNT_ACLS` | N/A | N/A | N/A | N/A |
| `geomJournaled` | N/A | `MNT_GJOURNAL` | N/A | N/A | N/A | N/A |
| `excludedFromDiskFreeReports` | N/A | `MNT_IGNORE` | N/A | N/A | N/A | N/A |
| `nfs4ACLs` | N/A | `MNT_NFS4ACLS` | N/A | N/A | N/A | N/A |
| `noClusterRead` | N/A | `MNT_NOCLUSTERR` | N/A | N/A | N/A | N/A |
| `noClusterWrite` | N/A | `MNT_NOCLUSTERW` | N/A | N/A | N/A | N/A |
| `setUserIDDirectory` | N/A | `MNT_SUIDDIR` | N/A | N/A | N/A | N/A |
| `softUpdateJournaling` | N/A | `MNT_SUJ` | N/A | N/A | N/A | N/A |
| `untrusted` | N/A | `MNT_UNTRUSTED` | N/A | N/A | N/A | N/A |
| `mountedByUser` | N/A | `MNT_USER` | N/A | N/A | N/A | N/A |
| `verified` | N/A | `MNT_VERIFIED` | N/A | N/A | N/A | N/A |
| `noPermissionChecks` | N/A | N/A | `MNT_NOPERM` | N/A | N/A | N/A |
| `writeExecuteAllowed` | N/A | N/A | `MNT_WXALLOWED` | N/A | N/A | N/A |
