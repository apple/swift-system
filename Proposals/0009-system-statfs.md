# StatFS for Swift System

* Proposal: [SYS-0009](0009-system-statfs.md)
* Authors: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Awaiting review**
* Implementation: [apple/swift-system#361](https://github.com/apple/swift-system/pull/361)
* Review: ([pitch](https://forums.swift.org/t/pitch-statfs-and-supporting-types/88151))

#### Revision history

* **v1** Initial version
* **v2** Use `statfs` on Linux and Android, make `StatFS` unavailable on WASI, omit Linux flags the kernel never reports, add descriptions for `MountFlags` and `FileSystemID`, and back-deploy `CInterop.StatFS` with `CInterop.statfs(_:_:)` for migration
* **v3** Rename `MountFlags` constants for consistency, remove `type` on Darwin and FreeBSD, and remove the `statfs()` methods on `FilePath` and `FileDescriptor`, eliminating the need for `CInterop` back-deployment
* **v4** Add `FileSystemTypeName` wrapper

## Introduction

This proposal introduces a Swift-native `StatFS` type to the System library, providing comprehensive access to file system metadata on Unix-like platforms through type-safe, platform-aware APIs that wrap the underlying C `statfs` system calls.

## Motivation

Currently, Swift developers who want to work with the file system's lowest level API can only do so through bridged C interfaces. These interfaces lack type safety and require writing non-idiomatic Swift, leading to errors and confusion.

The C `statfs` interfaces add a few problems of their own:

- On Linux, Swift's Glibc module doesn't export `statfs`, so calling it requires a C shim.
- Block counts are in units of `f_bsize` on Darwin and BSD, but `f_frsize` on Linux and Android, so computing space in bytes requires platform-specific code.
- Field widths and signedness vary by platform and C library. For example, `f_bavail` is signed on FreeBSD and OpenBSD.

The goal of the `StatFS` type is to provide a faithful and performant Swift wrapper around the underlying C system calls while adding type safety, platform abstraction, and improved discoverability/usability with clear naming. For more on the motivation behind System, see [https://www.swift.org/blog/swift-system](https://www.swift.org/blog/swift-system).

## Proposed solution

This proposal adds a `struct StatFS` that is available on Unix-like platforms. On Windows and WASI, the struct is declared but marked unavailable (see **Availability on Windows and WASI**). Windows-specific file system APIs and WASI support are discussed in **Future directions**.

`StatFS` is a Swift wrapper around the C `statfs` struct, which provides information about file systems. This type uses `statfs` rather than the POSIX `statvfs` for the additional information it provides, such as the file system type. Computed properties like `.totalSpace` and `.availableSpace` are supplied for convenience.

```swift
// Get file system information from a path
let statfs = try StatFS("/")

// From FileDescriptor
let fdStatFS = try StatFS(fd)

// From FilePath
let pathStatFS = try StatFS(filePath)

print("File system ID: \(statfs.fileSystemID)")
print("Total space: \(statfs.totalSpace) bytes")
print("Available space: \(statfs.availableSpace) bytes")

// Check mount flags
if statfs.mountFlags.contains(.readOnly) {
  print("File system is read-only")
}

// Platform-specific information when available
#if os(anyAppleOS) || os(FreeBSD) || os(OpenBSD)
print("File system is mounted at \(statfs.mountPoint)")
print("File system is mounted from \(statfs.mountSource)")
#endif

#if os(anyAppleOS)
if statfs.typeName == .apfs {
  print("File system is APFS")
}
#endif
```

### Error handling

The throwing initializers use a typed `throws(Errno)` and require Swift 6.0 or later:

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

All APIs are marked `@_alwaysEmitIntoClient` for performance, except `StatFS`'s `==` and `hash(into:)`, and descriptions, which are ordinary `public` APIs.

### `MountFlags`

This proposal introduces a `MountFlags` type representing flags that could be present in a `statfs` struct. On Darwin and BSD, many of these flags could also be passed to a future implementation of `mount`, though some, like `local` and `rootFileSystem`, only describe state the kernel reports. (Linux `mount(2)` instead takes a separate `MS_*` set, distinct from the `ST_*` flags `statfs` reports.) Mount-specific flags are outside the scope of this proposal (see **Future directions**).

`MountFlags` uses a `CInterop` typealias for its `rawValue` to support different widths of integers used on different operating systems. On Linux and Android, `CInterop.MountFlags` is `CUnsignedLong` rather than the type of `f_flags`, which varies by C library (glibc's is a signed `long`).

Glibc and musl also define `ST_WRITE`, `ST_APPEND`, and `ST_IMMUTABLE`, but Linux never reports them in `f_flags`, so `MountFlags` omits them. For space, doc comments are omitted for flags that aren't available on Darwin.

```swift
/// Flags describing a mounted file system.
///
/// These are the flags reported in the `f_flags` field of a `statfs` struct.
/// Some reflect options employed when mounting the file system, while others,
/// like `local` and `rootFileSystem`, describe state the kernel reports.
///
/// - Note: Not available on Windows or WASI.
@frozen
public struct MountFlags: OptionSet, Sendable, Hashable, Codable {
  /// The raw C flags.
  public let rawValue: CInterop.MountFlags

  /// Creates a strongly-typed `MountFlags` from the raw C value.
  public init(rawValue: CInterop.MountFlags)

  // Flags available on all platforms

  /// The file system is mounted read-only, even for the super-user.
  ///
  /// The corresponding C constant is `MNT_RDONLY` on Darwin and BSD,
  /// or `ST_RDONLY` otherwise.
  public static var readOnly: MountFlags { get }

  /// The file system is written to synchronously.
  ///
  /// The corresponding C constant is `MNT_SYNCHRONOUS` on Darwin and BSD,
  /// or `ST_SYNCHRONOUS` otherwise.
  public static var synchronous: MountFlags { get }

  /// Programs may not be executed from the file system.
  ///
  /// The corresponding C constant is `MNT_NOEXEC` on Darwin and BSD,
  /// or `ST_NOEXEC` otherwise.
  public static var noExecution: MountFlags { get }

  /// Set-user-ID and set-group-ID (setuid and setgid) bits are not honored on
  /// the file system.
  ///
  /// The corresponding C constant is `MNT_NOSUID` on Darwin and BSD,
  /// or `ST_NOSUID` otherwise.
  public static var noSetUserID: MountFlags { get }

  /// Access times are not updated on the file system.
  ///
  /// - Note: On OpenBSD, access time may still be updated when the
  ///   modification or status-change time is also being updated.
  ///
  /// The corresponding C constant is `MNT_NOATIME` on Darwin and BSD,
  /// or `ST_NOATIME` otherwise.
  public static var noAccessTime: MountFlags { get }

  // Flags available on all platforms except FreeBSD

  #if !os(FreeBSD)
  /// Special files may not be interpreted on the file system.
  ///
  /// - Note: Not available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_NODEV` on Darwin and OpenBSD,
  /// or `ST_NODEV` otherwise.
  public static var noDevices: MountFlags { get }
  #endif

  // Flags available on Linux and Android

  #if os(Linux) || os(Android)
  public static var mandatoryLocking: MountFlags { get }
  public static var noDirectoryAccessTime: MountFlags { get }
  public static var relativeAccessTime: MountFlags { get }
  #endif

  // Flags available on Linux, Android, and FreeBSD

  #if os(Linux) || os(Android) || os(FreeBSD)
  public static var noSymlinkFollowing: MountFlags { get }
  #endif

  // Flags available on Darwin, FreeBSD, and OpenBSD

  #if os(anyAppleOS) || os(FreeBSD) || os(OpenBSD)
  /// The file system is written to asynchronously.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_ASYNC`.
  public static var asynchronous: MountFlags { get }

  /// The file system is exported for use over the network via NFS.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_EXPORTED`.
  public static var exported: MountFlags { get }

  /// The file system is stored locally, rather than being accessed over a network.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_LOCAL`.
  public static var local: MountFlags { get }

  /// Quotas are enabled on the file system.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_QUOTA`.
  public static var quotasEnabled: MountFlags { get }

  /// The file system is the root file system.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_ROOTFS`.
  public static var rootFileSystem: MountFlags { get }
  #endif

  // Flags available on Darwin and FreeBSD

  #if os(anyAppleOS) || os(FreeBSD)
  /// The file system is unioned with the underlying file system, rather than
  /// obscuring it.
  ///
  /// - Note: Only available on Darwin and FreeBSD.
  ///
  /// The corresponding C constant is `MNT_UNION`.
  public static var union: MountFlags { get }

  /// The file system was mounted by the automounter.
  ///
  /// - Note: Only available on Darwin and FreeBSD. See `automount(8)`.
  ///
  /// The corresponding C constant is `MNT_AUTOMOUNTED`.
  public static var automounted: MountFlags { get }

  /// The file system maintains Mandatory Access Control (MAC) labels for
  /// individual objects.
  ///
  /// - Note: Only available on Darwin and FreeBSD.
  ///
  /// The corresponding C constant is `MNT_MULTILABEL`.
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

  #if os(anyAppleOS)
  /// Per-file encrypted data protection is enabled on the file system.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_CPROTECT`.
  public static var contentProtection: MountFlags { get }

  /// The file system resides on removable media.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_REMOVABLE`.
  public static var removable: MountFlags { get }

  /// The file system is quarantined.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_QUARANTINE`.
  public static var quarantined: MountFlags { get }

  /// The file system supports volfs.
  ///
  /// - Note: Only available on Darwin. Deprecated since Mac OS X 10.5.
  ///
  /// The corresponding C constant is `MNT_DOVOLFS`.
  public static var supportsVolfs: MountFlags { get }

  /// The file system should not be presented to the user for browsing
  /// (e.g. hidden in Finder).
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_DONTBROWSE`.
  public static var noBrowsing: MountFlags { get }

  /// The file system ignores ownership information.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_IGNORE_OWNERSHIP`.
  public static var ignoresOwnership: MountFlags { get }

  /// The file system is journaled.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_JOURNALED`.
  public static var journaled: MountFlags { get }

  /// User extended attributes are not allowed on the file system.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_NOUSERXATTR`.
  public static var noUserExtendedAttributes: MountFlags { get }

  /// The file system defers writes.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_DEFWRITE`.
  public static var defersWrites: MountFlags { get }

  /// Symbolic links are not followed when resolving the mount point.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_NOFOLLOW`.
  public static var noSymlinkFollowingAtMountPoint: MountFlags { get }

  /// The file system is a snapshot.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_SNAPSHOT`.
  public static var snapshot: MountFlags { get }

  /// Access times are always updated when files are read. Without this flag,
  /// the file system may skip some access time updates for performance.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_STRICTATIME`.
  public static var strictAccessTime: MountFlags { get }
  #endif

  // Flags available on FreeBSD only

  #if os(FreeBSD)
  public static var exportedWithKerberos: MountFlags { get }
  public static var exportedPublicly: MountFlags { get }
  public static var posixACLs: MountFlags { get }
  public static var geomJournaled: MountFlags { get }
  public static var excludedFromDiskFreeReports: MountFlags { get }
  public static var nfs4ACLs: MountFlags { get }
  public static var noClusteredReads: MountFlags { get }
  public static var noClusteredWrites: MountFlags { get }
  public static var setUserIDDirectories: MountFlags { get }
  public static var softUpdatesJournaling: MountFlags { get }
  public static var untrusted: MountFlags { get }
  public static var userMounted: MountFlags { get }
  public static var verified: MountFlags { get }
  #endif

  // Flags available on OpenBSD only

  #if os(OpenBSD)
  public static var noPermissionChecks: MountFlags { get }
  public static var writeExecuteAllowed: MountFlags { get }
  #endif
}

extension MountFlags: CustomStringConvertible, CustomDebugStringConvertible {
  /// A textual representation of the mount flags.
  public var description: String { get }

  /// A textual representation of the mount flags, suitable for debugging.
  public var debugDescription: String { get }
}
```

Like `FilePermissions`, `MountFlags` describes itself by listing its flags, such as `[.readOnly, .local]`.

### `FileSystemID`, `FileSystemType`, `FileSystemSubtype`, and `FileSystemTypeName`

```swift
/// A Swift wrapper of the C `f_fsid` file system ID found in a `statfs`
/// struct.
///
/// - Note: Not available on Windows or WASI.
@frozen
public struct FileSystemID: RawRepresentable, Sendable, Hashable, Codable {
  /// The raw C file system ID.
  public var rawValue: CInterop.FileSystemID

  /// Creates a strongly-typed `FileSystemID` from the raw C value.
  public init(rawValue: CInterop.FileSystemID)

  /// Creates a strongly-typed `FileSystemID` from the raw C value.
  public init(_ rawValue: CInterop.FileSystemID)
}

extension FileSystemID: CustomStringConvertible, CustomDebugStringConvertible {
  /// A textual representation of the file system ID.
  public var description: String { get }

  /// A textual representation of the file system ID, suitable for debugging.
  public var debugDescription: String { get }
}

// `FileSystemType` is available on Linux and Android, where `f_type` is the
// file system's magic number. Darwin and FreeBSD report a kernel-assigned
// index in `f_type`, so `typeName` identifies the file system there instead.
// `FileSystemSubtype` is Darwin-only. Both fit in a `UInt32` on every platform
// that provides them, so no `CInterop` typealias is needed.

#if os(Linux) || os(Android)
/// A Swift wrapper of the C `f_type` file system type found in a `statfs`
/// struct.
///
/// - Note: Only available on Linux and Android.
@frozen
public struct FileSystemType: RawRepresentable, Sendable, Hashable, Codable {
  /// The raw C file system type.
  public var rawValue: UInt32

  /// Creates a strongly-typed `FileSystemType` from the raw C value.
  public init(rawValue: UInt32)

  /// Creates a strongly-typed `FileSystemType` from the raw C value.
  public init(_ rawValue: UInt32)
}
#endif

#if os(anyAppleOS)
/// A Swift wrapper of the C `f_fssubtype` file system subtype found in a
/// `statfs` struct on Darwin.
///
/// - Note: Only available on Darwin.
@frozen
public struct FileSystemSubtype: RawRepresentable, Sendable, Hashable, Codable {
  /// The raw C file system subtype.
  public var rawValue: UInt32

  /// Creates a strongly-typed `FileSystemSubtype` from the raw C value.
  public init(rawValue: UInt32)

  /// Creates a strongly-typed `FileSystemSubtype` from the raw C value.
  public init(_ rawValue: UInt32)
}
#endif

#if os(anyAppleOS) || os(FreeBSD) || os(OpenBSD)
/// A Swift wrapper of the C `f_fstypename` file system type name found in a
/// `statfs` struct.
///
/// - Note: Only available on Darwin and BSD.
@frozen
public struct FileSystemTypeName: RawRepresentable, Sendable, Hashable, Codable, ExpressibleByStringLiteral {
  /// The raw file system type name.
  public var rawValue: String

  /// Creates a strongly-typed `FileSystemTypeName` from the raw name.
  public init(rawValue: String)

  /// Creates a strongly-typed `FileSystemTypeName` from the raw name.
  public init(_ rawValue: String)

  /// Creates a `FileSystemTypeName` from a string literal, such as `"apfs"`.
  public init(stringLiteral value: String)

  // Type names available on Darwin only

  #if os(anyAppleOS)
  /// The Apple File System (APFS).
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding `f_fstypename` value is `"apfs"`.
  public static var apfs: FileSystemTypeName { get }

  /// The Mac OS Extended file system (HFS Plus).
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding `f_fstypename` value is `"hfs"`.
  public static var hfs: FileSystemTypeName { get }
  #endif
}

extension FileSystemTypeName: CustomStringConvertible, CustomDebugStringConvertible {
  /// The file system type name, such as `apfs`.
  public var description: String { get }

  /// The file system type name as a quoted string, such as `"apfs"`.
  public var debugDescription: String { get }
}
#endif
```

`CInterop.FileSystemID` is the C `fsid_t` struct (a fixed two-element `int32_t` array), which provides no synthesized conformances. `FileSystemID` implements `Equatable`, `Hashable`, and `Codable` manually in terms of its elements, named `val` on Darwin and BSD and `__val` on Linux and Android. It encodes them as an unkeyed container of two `Int32` values and describes itself by listing them, such as `FileSystemID(16777239, 26)`.

`FileSystemTypeName` wraps `f_fstypename` so that well-known type names can be offered as constants, such as `.apfs`. It conforms to `ExpressibleByStringLiteral` so comparisons against names without a constant like `statfs.typeName == "nfs"` still read naturally. This proposal only provides constants for `"apfs"` and `"hfs"`. Other names can be added in the future when their stability is confirmed.

### `StatFS`

`StatFS` offers initializers that accept a `FilePath`, null-terminated `UnsafePointer<CChar>`, or `FileDescriptor`.

The underlying C fields for each numeric property vary in signedness and width across platforms. Rather than create a platform-dependent type for each, we choose one fixed integer type per property — `Int` or `UInt64` — and clamp when getting or setting the value.

Block sizes and lengths (`blockSize`, `preferredIOBlockSize`, `fragmentSize`, and `maximumNameLength`) are exposed as `Int`. Most modern file systems report 4KiB block sizes by default, and in practice, the highest value seen on specialized (often network) file systems is on the order of 1MiB. The preferred I/O size could similarly reach values around 16MiB. These are still orders of magnitude smaller than `Int.max`, even for 32-bit platforms.

Block and inode counts, and the space values computed from them, are exposed as `UInt64` to preserve their full unsigned range on every platform. Real-world values can exceed `Int64.max`, and space computations can overflow and saturate to `UInt64.max`. Clamping lets us report `0` for the signed "available to non-superuser" counts that some BSDs allow to go negative.

```swift
/// A Swift wrapper of the C `statfs` struct.
///
/// - Note: Not available on Windows or WASI.
/// - Note: The numeric properties clamp when converting to or from the
///   underlying C field. Use `rawValue` for exact, unclamped access.
@frozen
public struct StatFS: RawRepresentable, Sendable, Hashable {
  /// The raw C `statfs` struct.
  public var rawValue: CInterop.StatFS

  /// Creates a Swift `StatFS` from the raw C struct.
  public init(rawValue: CInterop.StatFS)

  /// Creates a `StatFS` from a `FilePath`.
  ///
  /// The corresponding C function is `statfs()`.
  public init(
    _ path: FilePath,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `StatFS` from a null-terminated `UnsafePointer<CChar>` path.
  ///
  /// The corresponding C function is `statfs()`.
  public init(
    _ path: UnsafePointer<CChar>,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `StatFS` from a `FileDescriptor`.
  ///
  /// The corresponding C function is `fstatfs()`.
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// File system block size, in bytes.
  ///
  /// - Note: On Darwin and BSD, this is the fundamental size for block counts.
  ///   Other platforms use `fragmentSize` (`f_frsize`) instead.
  ///
  /// The corresponding C property is `f_bsize`.
  public var blockSize: Int { get set }

  #if os(anyAppleOS) || os(FreeBSD) || os(OpenBSD)
  /// Block size for optimal data transfer, in bytes.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_iosize`.
  public var preferredIOBlockSize: Int { get set }
  #else
  /// File system fragment size, in bytes.
  ///
  /// - Note: On Linux and Android, this is the fundamental size for block
  ///   counts. Not present on Darwin or BSD, which use `blockSize` instead.
  ///
  /// The corresponding C property is `f_frsize`.
  public var fragmentSize: Int { get set }
  #endif

  /// Total number of blocks in the file system.
  ///
  /// - Note: In units of `blockSize` on Darwin and BSD, or `fragmentSize`
  ///   otherwise.
  ///
  /// The corresponding C property is `f_blocks`.
  public var totalBlocks: UInt64 { get set }

  /// Total size of the file system, in bytes.
  ///
  /// - Note: Computed for convenience as `totalBlocks` times the fundamental
  ///   block size (see `totalBlocks`). Saturates to `UInt64.max` on overflow.
  public var totalSpace: UInt64 { get }

  /// Number of free blocks in the file system.
  ///
  /// - Note: In units of `blockSize` on Darwin and BSD, or `fragmentSize`
  ///   otherwise.
  ///
  /// The corresponding C property is `f_bfree`.
  public var freeBlocks: UInt64 { get set }

  /// Free space in the file system, in bytes.
  ///
  /// - Note: Computed for convenience as `freeBlocks` times the fundamental
  ///   block size (see `freeBlocks`). Saturates to `UInt64.max` on overflow.
  public var freeSpace: UInt64 { get }

  /// Number of free blocks available to non-superuser.
  ///
  /// - Note: In units of `blockSize` on Darwin and BSD, or `fragmentSize`
  ///   otherwise. On FreeBSD and OpenBSD, the underlying C property is
  ///   signed; negative values are clamped to 0.
  ///
  /// The corresponding C property is `f_bavail`.
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
  /// - Note: On FreeBSD, this reports the inodes available to a non-superuser
  ///   rather than the total free count, and the underlying C field is signed
  ///   (negative values are clamped to 0); on other platforms, it is the total
  ///   number of free inodes.
  ///
  /// The corresponding C property is `f_ffree`.
  public var freeInodes: UInt64 { get set }

  #if os(OpenBSD)
  /// Number of free inodes available to non-superuser.
  ///
  /// - Note: Darwin, FreeBSD, Linux, and Android `statfs` do not report it.
  ///   On OpenBSD, the underlying C property is signed; negative values are
  ///   clamped to 0.
  ///
  /// The corresponding C property is `f_favail`.
  public var availableInodes: UInt64 { get set }
  #endif

  #if !os(anyAppleOS)
  /// Maximum length of a file name on the file system, in bytes.
  ///
  /// - Note: Darwin's `statfs` does not report it.
  ///
  /// The corresponding C property is `f_namelen` on Linux and Android, or
  /// `f_namemax` otherwise.
  public var maximumNameLength: Int { get set }
  #endif

  /// File system ID.
  ///
  /// The corresponding C property is `f_fsid`.
  public var fileSystemID: FileSystemID { get set }

  /// Flags describing how the file system is mounted.
  ///
  /// - Note: On Linux, the kernel also sets an `ST_VALID` bit in `f_flags`
  ///   to mark the field as filled in. It isn't a mount flag, so this
  ///   property omits it like glibc's `statvfs` and Bionic's `statfs` do.
  ///   The setter preserves it.
  ///
  /// The corresponding C property is `f_flags`.
  public var mountFlags: MountFlags { get set }

  #if os(Linux) || os(Android)
  /// File system type.
  ///
  /// - Note: This is the file system's magic number, such as `0xEF53` for
  ///   ext4. Only available on Linux and Android. On Darwin and BSD, use
  ///   `typeName` to identify the file system.
  ///
  /// The corresponding C property is `f_type`.
  public var type: FileSystemType { get set }
  #endif

  #if os(anyAppleOS)
  /// File system subtype.
  ///
  /// - Note: This is a numeric value whose meaning depends on `typeName`,
  ///   with no stable, public constants. Only available on Darwin.
  ///
  /// The corresponding C property is `f_fssubtype`.
  public var subtype: FileSystemSubtype { get set }
  #endif

  #if os(anyAppleOS) || os(FreeBSD) || os(OpenBSD)
  /// User that mounted the file system.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_owner`.
  public var owner: UserID { get set }

  /// File system type name, such as "apfs".
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_fstypename`.
  public var typeName: FileSystemTypeName { get }

  /// Directory where the file system is mounted, such as "/System/Volumes/Data".
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_mntonname`.
  public var mountPoint: FilePath { get }

  /// The source of the mounted file system, such as "/dev/disk3s7".
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_mntfromname`.
  public var mountSource: FilePath { get }
  #endif

  /// Compares the file system metadata fields of two `StatFS` values,
  /// including fields not exposed as properties, such as `f_flags_ext` on
  /// Darwin.
  ///
  /// Fields are compared by their raw C values. Reserved/"spare" fields and
  /// OpenBSD's `mount_info` union are not compared. Name buffers are compared
  /// only up to their NUL terminators.
  public static func == (lhs: Self, rhs: Self) -> Bool

  /// Hashes the file system metadata fields of a `StatFS` struct.
  ///
  /// These are the same fields compared by `==`. Reserved/"spare" fields are
  /// not hashed, and name buffers are hashed only up to their NUL terminators.
  public func hash(into hasher: inout Hasher)
}
```

`typeName`, `mountPoint`, and `mountSource` are get-only because they are backed by fixed-size C character buffers, which a non-throwing setter could not safely fill without risking silent truncation. Callers that need to write these fields can do so through `rawValue` directly.

`StatFS` conforms to `Hashable` (and therefore `Equatable`) by comparing and hashing the raw values of its C fields, as `Stat` does, so two `StatFS` values are equal when their `rawValue`s match in every meaningful field. Comparing the clamped properties instead would treat different raw values like two negative `f_bavail` counts as equal, and would ignore fields without a property. A byte-wise comparison would be unreliable because the bytes following each name buffer's NUL terminator are unspecified, and the struct may carry reserved/spare padding.

### CInterop extensions

This proposal extends the existing `CInterop` namespace with platform-appropriate typealiases for the underlying C types. Each is used as the `rawValue` for a corresponding strongly-typed representation.

```swift
extension CInterop {
  /// The C `statfs` struct.
  public typealias StatFS = statfs

  public typealias FileSystemID = fsid_t

  #if os(anyAppleOS) || os(OpenBSD)
  public typealias MountFlags = UInt32
  #elseif os(FreeBSD)
  public typealias MountFlags = UInt64
  #else
  public typealias MountFlags = CUnsignedLong
  #endif
}
```

All three have the same availability as the rest of this proposal.

### Vending `struct statfs` on glibc platforms

Unlike the Musl and Android modules, Swift's Glibc module doesn't export `<sys/vfs.h>`, which declares `struct statfs`. On glibc platforms, System therefore vends `struct statfs` from a new module, `CSystemStatFS`, that contains only this header, and re-exports it so clients can access `rawValue`'s fields under `MemberImportVisibility`. As a result, importing System on glibc platforms also brings C's `statfs()` and `fstatfs()` into scope. The Glibc module does export `fsid_t`, so accessing the `__val` field of a `CInterop.FileSystemID` under `MemberImportVisibility` requires importing Glibc.

### Availability on Windows and WASI

Windows has no `statfs`/`statvfs`. Rather than omit the type there, where usage would fail with an unhelpful `cannot find 'StatFS' in scope`, we declare an unavailable stub with a message suggesting the relevant Win32 APIs. In the future, the message could suggest dedicated System APIs instead.

`wasi-libc` has no `statfs`, and in the current `wasi-libc`, `statvfs` and `fstatvfs` are unconditional stubs (in `libc-bottom-half/sources/posix.c`) that set `errno` to `ENOSYS` and return `-1`:

```c
int statvfs(const char *__restrict path, struct statvfs *__restrict buf) {
    // TODO: We plan to support this eventually in WASI, but not yet.
    errno = ENOSYS;
    return -1;
}
```

As a result, `StatFS` initializers would always fail at runtime on WASI and throw `Errno.noFunction`, so WASI gets an unavailable stub as well.

```swift
#if os(Windows)
@available(Windows, unavailable, message: "Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
public struct StatFS {
  public init(_ path: FilePath, retryOnInterrupt: Bool = true) throws(Errno)
  public init(_ path: UnsafePointer<CChar>, retryOnInterrupt: Bool = true) throws(Errno)
  public init(_ fd: FileDescriptor, retryOnInterrupt: Bool = true) throws(Errno)
}
#elseif os(WASI)
@available(*, unavailable, message: "wasi-libc doesn't implement statfs or statvfs.")
public struct StatFS {
  // The same three initializers
}
#else
// ...
#endif
```

Marking the type covers the three throwing initializers each stub declares. The other types and `CInterop` additions in this proposal aren't declared on either platform.

## Source compatibility

This proposal is additive, but on glibc platforms, clients that already vend `struct statfs` from their own module (since Swift's Glibc module doesn't export it) may need to import both that module and System in each file that accesses `statfs` fields. When two modules declare the same C struct, `MemberImportVisibility` attributes its fields to the module the compiler reaches the struct through first, which can differ between debug and release builds. In testing, a client that used `StatFS.rawValue` in one file and its own module's `statfs` in another built in debug but failed in release, reporting a missing import of `CSystemStatFS`.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

This feature can be freely adopted and un-adopted in source code with no deployment constraints and without affecting source or ABI compatibility.

## Future directions

To remain faithful to the underlying system calls, we don't anticipate extending `StatFS`. However, the types introduced in this proposal could serve as the foundation of broader file system APIs in Swift.

For instance, on Darwin and BSD, `MountFlags` could be useful for a future `mount()` implementation, and a future Swift wrapper of `getfsstat()` could return an array of `StatFS` structs.

A Linux `mount(2)` wrapper would look different. There, the flags `statfs` reports (`ST_*`) are a distinct set from the flags `mount(2)` accepts (`MS_*`), so a mount wrapper would need its own input type rather than reusing `MountFlags`. The `MS_*` set also mixes per-mount options with operation selectors like bind, move, remount, and propagation changes, so an idiomatic wrapper would likely split these into separate functions. A new implementation might also prefer the newer `fsopen` / `fsmount` / `move_mount` family over classic `mount(2)`. Because Linux's `mount` signature differs from Darwin's and BSD's, any such wrapper would be platform-specific.

Once `wasi-libc` implements `statvfs`, a future proposal could make `StatFS` available on WASI by wrapping `statvfs` and `fstatvfs`.

On Darwin, `f_flags_ext` reports extended flags such as `MNT_EXT_ROOT_DATA_VOL` and `MNT_EXT_FSKIT`. They're reachable through `rawValue` today, and a future proposal could expose them as their own option set.

If Swift's Glibc module exports `<sys/vfs.h>` in the future, `CSystemStatFS` would become redundant. System could keep re-exporting it, but accessing `rawValue`'s fields under `MemberImportVisibility` would then require importing Glibc, as with `CInterop.Stat`.

While this proposal does not include `StatFS` on Windows, SYS-0017 proposes `volumeInformation()` on `Win32.FileHandle`, a Swift-native wrapper of `GetVolumeInformationByHandleW`. Other volume APIs, such as `GetDiskFreeSpaceExW` and `DeviceIoControl`, could follow with their associated types.

A more general `FileSystemInfo` API could then build on these OS-specific types to provide an ergonomic, cross-platform abstraction for file system metadata. These future cross-platform APIs might be better implemented outside of System, such as in Foundation or another dedicated package.

## Alternatives considered

### `FileSystemInfo` as the lowest-level type

An alternative approach could be to have a more general `FileSystemInfo` type be the lowest level of abstraction provided by the System library. This type would then handle all the `statfs` or Windows-specific struct storage and accessors. However, this alternative:

- Is inconsistent with System's philosophy of providing low-level system abstractions.
- Introduces an even larger number of system-specific APIs on each type.
- Misses out on the familiarity of the `statfs` name. Developers know what to look for and what to expect from this type.

### Single combined type for both file and file system metadata

Combining `Stat` ([SYS-0006](https://github.com/apple/swift-system/blob/main/Proposals/0006-system-stat.md)) and `StatFS` into a single type was considered but rejected because file and file system information serve different purposes and are typically needed in different contexts. Storing and/or initializing both `stat` and `statfs` structs unnecessarily reduces performance when one isn't needed.

### Separate `StatFS` and `StatVFS` types

Having separate types for `statfs` and `statvfs` would increase cognitive overhead and confusion for developers deciding which to choose. It would require additional documentation explaining differences that are transparently handled by platform availability, and would require duplicate code. On operating systems where `statfs` exposes additional information, such as Darwin, FreeBSD, and Linux, `statvfs` is just a wrapper around `statfs`, so there's little upside to providing a `StatVFS` type here. One upside might be that all properties of `StatVFS` would be available where the struct itself is available, but this likely doesn't outweigh the cost of having two types.

### Use `statvfs` on Linux and Android

`statvfs` is the POSIX interface, and the Glibc, Musl, and Android modules all export it, so System wouldn't need a `CSystemStatFS` module, which can conflict with clients' own `statfs` modules (see **Source compatibility**). However, on Linux, `statvfs` is also a wrapper around `statfs`, and it drops useful information: 1) with Bionic or glibc before 2.39, `f_type`, the file system magic number (such as `0xEF53` for ext4) that Linux code conventionally uses to identify a file system is absent; and 2) with musl or 32-bit platforms, half of the 2-word `fsid_t` is omitted. `statvfs`'s only extra field, `f_favail`, is a copy of `f_ffree` in glibc, musl, and Bionic.

### Add `statfs()` methods to `FilePath` and `FileDescriptor`

Like `FilePath.stat()` and `FileDescriptor.stat()` in [SYS-0006](https://github.com/apple/swift-system/blob/main/Proposals/0006-system-stat.md), `StatFS` could offer `statfs()` methods alongside its initializers. However, `statfs` describes the file system containing a file rather than the file itself, so it's not as closely tied to the individual `FilePath` or `FileDescriptor`. The proposed initializers can still chain, as in `try StatFS(path).availableSpace`.

The methods would also shadow the C `statfs` struct initializer and function inside extensions of those types, so existing code that calls them unqualified there would no longer compile. [SYS-0008](0008-backdeploy-cinterop-stat.md) back-deployed `CInterop.stat(_:_:)` as a migration path for the same issue with `stat()`. Leaving out the methods avoids the break and the need for new `CInterop` APIs. They could always be added later, along with a migration path, if desired.

### Expose `type` and `subtype` as raw integers

`FileSystemType` and `FileSystemSubtype` wrap `UInt32` values that, except for Linux magic numbers, have no stable, public constants, so exposing `type` and `subtype` as bare `UInt32` was considered. We keep the wrapper types for fidelity to the underlying struct and for consistency with `FileSystemID`, which is similarly opaque. The wrappers also give these fields distinct types, avoiding accidental cross-comparisons and granting flexibility to add members later, if desired.

### Expose `typeName` as a `String`

`typeName` could be a `String` like Foundation's `volumeTypeName` resource value. Unlike Linux magic numbers, type names are already readable, so `typeName == "apfs"` works about as well as a constant would. However, a wrapper allows us to provide constants like `.apfs`, which help with discoverability and avoid mistakes like comparing against `"APFS"`. And `ExpressibleByStringLiteral` allows us to still keep the ergonomics of literal comparison.

### Make `StatFS` available on WASI

`StatFS` could wrap `statvfs` and `fstatvfs` on WASI, as v1 of this proposal did. This would let developers write code that is otherwise portable across Unix-like platforms, and since clients calling `try StatFS(...)` are expected to handle a potential `Errno`, the always-failing calls wouldn't degrade ergonomics. It would also keep the availability coupled: once `wasi-libc` gains real `statvfs` support, System would pick it up automatically without needing to track it.

However, the portability would only be at compile time, since every call would throw `Errno.noFunction`. The WASI mappings, such as reading `mountFlags` from `f_flag` and an integer `FileSystemID` that other platforms can't decode, would also be designed against `wasi-libc`'s stubs. Leaving WASI out also lets `StatFS` wrap `statfs` on every platform where it's available, instead of `statvfs` on WASI alone. Making `StatFS` available later is additive, while reshaping it after it ships would be source-breaking.

## Acknowledgments

Thank you to Michael Ilseman for discussions on the shape and future directions of this API.

## Appendix

### Swift API to C mapping

The following tables show the mapping between Swift APIs and their underlying C system calls across different operating systems:

#### `StatFS` function mappings

The `retryOnInterrupt: Bool = true` parameter is omitted for clarity.

| Swift API | Darwin / BSD / Linux / Android |
|-----------|--------------------------------|
| `StatFS(_ path: UnsafePointer<CChar>)` | `statfs()` |
| `StatFS(_ path: FilePath)` | `statfs()` |
| | |
| `StatFS(_ fd: FileDescriptor)` | `fstatfs()` |

#### `StatFS` property mappings

`"` denotes the same property name across all operating systems.

| Swift Property | Darwin | FreeBSD | OpenBSD | Linux | Android |
|----------------|--------|---------|---------|-------|---------|
| `blockSize` | `f_bsize` | " | " | " | " |
| `preferredIOBlockSize` | `f_iosize` | `f_iosize` | `f_iosize` | N/A | N/A |
| `fragmentSize` | N/A | N/A | N/A | `f_frsize` | `f_frsize` |
| `totalBlocks` | `f_blocks` | " | " | " | " |
| `freeBlocks` | `f_bfree` | " | " | " | " |
| `availableBlocks` | `f_bavail` | " | " | " | " |
| `totalInodes` | `f_files` | " | " | " | " |
| `freeInodes` | `f_ffree` | " | " | " | " |
| `availableInodes` | N/A | N/A | `f_favail` | N/A | N/A |
| `maximumNameLength` | N/A | `f_namemax` | `f_namemax` | `f_namelen` | `f_namelen` |
| `fileSystemID` | `f_fsid` | " | " | " | " |
| `mountFlags` | `f_flags` | " | " | " | " |
| `type` | N/A | N/A | N/A | `f_type` | `f_type` |
| `subtype` | `f_fssubtype` | N/A | N/A | N/A | N/A |
| `owner` | `f_owner` | `f_owner` | `f_owner` | N/A | N/A |
| `typeName` | `f_fstypename` | `f_fstypename` | `f_fstypename` | N/A | N/A |
| `mountPoint` | `f_mntonname` | `f_mntonname` | `f_mntonname` | N/A | N/A |
| `mountSource` | `f_mntfromname` | `f_mntfromname` | `f_mntfromname` | N/A | N/A |

#### `MountFlags` mappings

| Swift Flag | Darwin | FreeBSD | OpenBSD | Linux | Android |
|------------|--------|---------|---------|-------|---------|
| `readOnly` | `MNT_RDONLY` | `MNT_RDONLY` | `MNT_RDONLY` | `ST_RDONLY` | `ST_RDONLY` |
| `synchronous` | `MNT_SYNCHRONOUS` | `MNT_SYNCHRONOUS` | `MNT_SYNCHRONOUS` | `ST_SYNCHRONOUS` | `ST_SYNCHRONOUS` |
| `noExecution` | `MNT_NOEXEC` | `MNT_NOEXEC` | `MNT_NOEXEC` | `ST_NOEXEC` | `ST_NOEXEC` |
| `noSetUserID` | `MNT_NOSUID` | `MNT_NOSUID` | `MNT_NOSUID` | `ST_NOSUID` | `ST_NOSUID` |
| `noAccessTime` | `MNT_NOATIME` | `MNT_NOATIME` | `MNT_NOATIME` | `ST_NOATIME` | `ST_NOATIME` |
| `noDevices` | `MNT_NODEV` | N/A | `MNT_NODEV` | `ST_NODEV` | `ST_NODEV` |
| `mandatoryLocking` | N/A | N/A | N/A | `ST_MANDLOCK` | `ST_MANDLOCK` |
| `noDirectoryAccessTime` | N/A | N/A | N/A | `ST_NODIRATIME` | `ST_NODIRATIME` |
| `relativeAccessTime` | N/A | N/A | N/A | `ST_RELATIME` | `ST_RELATIME` |
| `noSymlinkFollowing` | N/A | `MNT_NOSYMFOLLOW` | N/A | `ST_NOSYMFOLLOW` | `ST_NOSYMFOLLOW` |
| `asynchronous` | `MNT_ASYNC` | `MNT_ASYNC` | `MNT_ASYNC` | N/A | N/A |
| `exported` | `MNT_EXPORTED` | `MNT_EXPORTED` | `MNT_EXPORTED` | N/A | N/A |
| `local` | `MNT_LOCAL` | `MNT_LOCAL` | `MNT_LOCAL` | N/A | N/A |
| `quotasEnabled` | `MNT_QUOTA` | `MNT_QUOTA` | `MNT_QUOTA` | N/A | N/A |
| `rootFileSystem` | `MNT_ROOTFS` | `MNT_ROOTFS` | `MNT_ROOTFS` | N/A | N/A |
| `union` | `MNT_UNION` | `MNT_UNION` | N/A | N/A | N/A |
| `automounted` | `MNT_AUTOMOUNTED` | `MNT_AUTOMOUNTED` | N/A | N/A | N/A |
| `multiLabel` | `MNT_MULTILABEL` | `MNT_MULTILABEL` | N/A | N/A | N/A |
| `exportedReadOnly` | N/A | `MNT_EXRDONLY` | `MNT_EXRDONLY` | N/A | N/A |
| `exportedByDefault` | N/A | `MNT_DEFEXPORTED` | `MNT_DEFEXPORTED` | N/A | N/A |
| `exportedAnonymously` | N/A | `MNT_EXPORTANON` | `MNT_EXPORTANON` | N/A | N/A |
| `softUpdates` | N/A | `MNT_SOFTDEP` | `MNT_SOFTDEP` | N/A | N/A |
| `contentProtection` | `MNT_CPROTECT` | N/A | N/A | N/A | N/A |
| `removable` | `MNT_REMOVABLE` | N/A | N/A | N/A | N/A |
| `quarantined` | `MNT_QUARANTINE` | N/A | N/A | N/A | N/A |
| `supportsVolfs` | `MNT_DOVOLFS` | N/A | N/A | N/A | N/A |
| `noBrowsing` | `MNT_DONTBROWSE` | N/A | N/A | N/A | N/A |
| `ignoresOwnership` | `MNT_IGNORE_OWNERSHIP` | N/A | N/A | N/A | N/A |
| `journaled` | `MNT_JOURNALED` | N/A | N/A | N/A | N/A |
| `noUserExtendedAttributes` | `MNT_NOUSERXATTR` | N/A | N/A | N/A | N/A |
| `defersWrites` | `MNT_DEFWRITE` | N/A | N/A | N/A | N/A |
| `noSymlinkFollowingAtMountPoint` | `MNT_NOFOLLOW` | N/A | N/A | N/A | N/A |
| `snapshot` | `MNT_SNAPSHOT` | N/A | N/A | N/A | N/A |
| `strictAccessTime` | `MNT_STRICTATIME` | N/A | N/A | N/A | N/A |
| `exportedWithKerberos` | N/A | `MNT_EXKERB` | N/A | N/A | N/A |
| `exportedPublicly` | N/A | `MNT_EXPUBLIC` | N/A | N/A | N/A |
| `posixACLs` | N/A | `MNT_ACLS` | N/A | N/A | N/A |
| `geomJournaled` | N/A | `MNT_GJOURNAL` | N/A | N/A | N/A |
| `excludedFromDiskFreeReports` | N/A | `MNT_IGNORE` | N/A | N/A | N/A |
| `nfs4ACLs` | N/A | `MNT_NFS4ACLS` | N/A | N/A | N/A |
| `noClusteredReads` | N/A | `MNT_NOCLUSTERR` | N/A | N/A | N/A |
| `noClusteredWrites` | N/A | `MNT_NOCLUSTERW` | N/A | N/A | N/A |
| `setUserIDDirectories` | N/A | `MNT_SUIDDIR` | N/A | N/A | N/A |
| `softUpdatesJournaling` | N/A | `MNT_SUJ` | N/A | N/A | N/A |
| `untrusted` | N/A | `MNT_UNTRUSTED` | N/A | N/A | N/A |
| `userMounted` | N/A | `MNT_USER` | N/A | N/A | N/A |
| `verified` | N/A | `MNT_VERIFIED` | N/A | N/A | N/A |
| `noPermissionChecks` | N/A | N/A | `MNT_NOPERM` | N/A | N/A |
| `writeExecuteAllowed` | N/A | N/A | `MNT_WXALLOWED` | N/A | N/A |
