# Stat for Swift System

* Proposal: [SE-NNNN](NNNN-system-stat.md)
* Authors: [Jonathan Flat](https://github.com/jrflat), [Michael Ilseman](https://github.com/milseman), [Rauhul Varma](https://github.com/rauhul)
* Review Manager: TBD
* Status: **Awaiting review**
* Implementation: [apple/swift-system#256](https://github.com/apple/swift-system/pull/256)
* Review: ([pitch](https://forums.swift.org/t/pitch-stat-types-for-swift-system/81616))

## Introduction

This proposal introduces a Swift-native `Stat` type to the System library, providing comprehensive access to file metadata on Unix-like platforms through type-safe, platform-aware APIs that wrap the C `stat` types and system calls.

## Motivation

Currently, Swift developers who want to work with the file system's lowest level API can only do so through bridged C interfaces. These interfaces lack type safety and require writing non-idiomatic Swift, leading to errors and confusion.

The goal of the `Stat` type is to provide a faithful and performant Swift wrapper around the underlying C system calls while adding type safety, platform abstraction, and improved discoverability/usability with clear naming. For more on the motivation behind System, see [https://www.swift.org/blog/swift-system](https://www.swift.org/blog/swift-system)

## Proposed solution

This proposal adds a `struct Stat` that is available on Unix-like platforms. See discussion on Windows-specific API in **Future Directions**.

### `Stat` - File Metadata
A Swift wrapper around the C `stat` struct that provides type-safe access to file metadata:

```swift
// Get file status from path String
let stat = try Stat("/path/to/file")

// From FileDescriptor
let stat = try fd.stat()

// From FilePath
let stat = try filePath.stat()

// `followTargetSymlink: true` (default) behaves like `stat()`
// `followTargetSymlink: false` behaves like `lstat()`
let stat = try symlinkPath.stat(followTargetSymlink: false)

// Supply flags and optional file descriptor to use the `fstatat()` variant
let stat = try Stat("path/to/file", relativeTo: fd, flags: .symlinkNoFollow)

print("Size: \(stat.size) bytes")
print("Type: \(stat.type)") // .regular, .directory, .symbolicLink, etc.
print("Permissions: \(stat.permissions)")
print("Modified: \(stat.modificationTime)")

// Platform-specific information when available
#if canImport(Darwin) || os(FreeBSD)
print("Creation time: \(stat.creationTime)")
#endif
```

### Error Handling

All initializers throw the existing `Errno` type:

```swift
do {
  let stat = try Stat("/nonexistent/file")
} catch Errno.noSuchFileOrDirectory {
  print("File not found")
} catch {
  print("Other error: \(error)")
}
```

These initializers use a typed `throws(Errno)` and require Swift 6.0 or later.

## Detailed design

See the **Appendix** section at the end of this proposal for a table view of Swift API to C mappings.

All API are marked `@_alwaysEmitIntoClient` for performance and back-dating of availability.

### FileType

This proposal introduces `FileType` and `FileMode` types to represent `mode_t` values from the C `stat` struct. The type and permissions of a `FileMode` can be modified for convenience, and `FileMode` handles the respective bit masking.

```swift
/// A file type matching those contained in a C `mode_t`.
///
/// - Note: Only available on Unix-like platforms.
@frozen
public struct FileType: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw file-type bits from the C mode.
  public var rawValue: CInterop.Mode

  /// Creates a strongly-typed file type from the raw C value.
  ///
  /// - Note: `rawValue` should only contain the mode's file-type bits. Otherwise,
  ///   use `FileMode(rawValue:)` to get a strongly-typed `FileMode`, then
  ///   call `.type` to get the properly masked `FileType`.
  public init(rawValue: CInterop.Mode)

  /// Directory
  ///
  /// The corresponding C constant is `S_IFDIR`.
  public static var directory: FileType { get }

  /// Character special device
  ///
  /// The corresponding C constant is `S_IFCHR`.
  public static var characterSpecial: FileType { get }

  /// Block special device
  ///
  /// The corresponding C constant is `S_IFBLK`.
  public static var blockSpecial: FileType { get }

  /// Regular file
  ///
  /// The corresponding C constant is `S_IFREG`.
  public static var regular: FileType { get }

  /// FIFO (or pipe)
  ///
  /// The corresponding C constant is `S_IFIFO`.
  public static var pipe: FileType { get }

  /// Symbolic link
  ///
  /// The corresponding C constant is `S_IFLNK`.
  public static var symbolicLink: FileType { get }

  /// Socket
  ///
  /// The corresponding C constant is `S_IFSOCK`.
  public static var socket: FileType { get }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Whiteout file
  ///
  /// The corresponding C constant is `S_IFWHT`.
  public static var whiteout: FileType { get }
  #endif
}
```

### FileMode
```swift
/// A strongly-typed file mode representing a C `mode_t`.
///
/// - Note: Only available on Unix-like platforms.
@frozen
public struct FileMode: RawRepresentable, Sendable, Hashable, Codable {
  
  /// The raw C mode.
  public var rawValue: CInterop.Mode

  /// Creates a strongly-typed `FileMode` from the raw C value.
  public init(rawValue: CInterop.Mode)

  /// Creates a `FileMode` from the given file type and permissions.
  ///
  /// - Note: This initializer masks the inputs with their respective bit masks.
  public init(type: FileType, permissions: FilePermissions)

  /// The file's type, from the mode's file-type bits.
  ///
  /// Setting this property will mask the `newValue` with the file-type bit mask `S_IFMT`.
  public var type: FileType { get set }

  /// The file's permissions, from the mode's permission bits.
  ///
  /// Setting this property will mask the `newValue` with the permissions bit mask `0o7777`.
  public var permissions: FilePermissions { get set }
}
```

### Supporting ID Types

This proposal also uses new `DeviceID`, `UserID`, `GroupID`, and `Inode` types to represent the respective C data types found in `stat`. These are strongly-typed structs instead of `CInterop` typealiases to prevent ambiguity in future System implementations and to allow for added functionality.

For example, with an implementation of `chown`, a developer might accidentally misplace user and group parameters with no warning if both were a typealias of the underlying `unsigned int`. Furthermore, a strongly-typed `DeviceID` would allow us to add functionality such as a `makedev` function, or `major` and `minor` getters.

For now, we define the following for use in `Stat`.

```swift
@frozen
public struct UserID: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: CInterop.UserID
  public init(rawValue: CInterop.UserID)
}

@frozen
public struct GroupID: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: CInterop.GroupID
  public init(rawValue: CInterop.GroupID)
}

@frozen
public struct DeviceID: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: CInterop.DeviceID
  public init(rawValue: CInterop.DeviceID)
}

@frozen
public struct Inode: RawRepresentable, Sendable, Hashable, Codable {
  public var rawValue: CInterop.Inode
  public init(rawValue: CInterop.Inode)
}
```

Each type stores a `CInterop` typealias to ensure an appropriate `rawValue` for the current platform. Added functionality is outside the scope of this proposal and will be included in a future proposal.

### FileFlags

A new `FileFlags` type represents file-specific flags found in a `stat` struct on Darwin, FreeBSD, and OpenBSD. This type would also be useful for an implementation of `chflags()`.

```swift
/// File-specific flags found in the `st_flags` property of a `stat` struct
/// or used as input to `chflags()`.
///
/// - Note: Only available on Darwin, FreeBSD, and OpenBSD.
@frozen
public struct FileFlags: OptionSet, Sendable, Hashable, Codable {
  
  /// The raw C flags.
  public let rawValue: CInterop.FileFlags

  /// Creates a strongly-typed `FileFlags` from the raw C value.
  public init(rawValue: CInterop.FileFlags)

  // MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

  /// Do not dump the file during backups.
  ///
  /// The corresponding C constant is `UF_NODUMP`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var noDump: FileFlags { get }

  /// File may not be changed.
  ///
  /// The corresponding C constant is `UF_IMMUTABLE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var userImmutable: FileFlags { get }

  /// Writes to the file may only append.
  ///
  /// The corresponding C constant is `UF_APPEND`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var userAppend: FileFlags { get }

  /// File has been archived.
  ///
  /// The corresponding C constant is `SF_ARCHIVED`.
  /// - Note: This flag may only be changed by the superuser.
  public static var archived: FileFlags { get }

  /// File may not be changed.
  ///
  /// The corresponding C constant is `SF_IMMUTABLE`.
  /// - Note: This flag may only be changed by the superuser.
  public static var systemImmutable: FileFlags { get }

  /// Writes to the file may only append.
  ///
  /// The corresponding C constant is `SF_APPEND`.
  /// - Note: This flag may only be changed by the superuser.
  public static var systemAppend: FileFlags { get }

  // MARK: Flags Available on Darwin and FreeBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Directory is opaque when viewed through a union mount.
  ///
  /// The corresponding C constant is `UF_OPAQUE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var opaque: FileFlags { get }

  /// File is compressed at the file system level.
  ///
  /// The corresponding C constant is `UF_COMPRESSED`.
  /// - Note: This flag is read-only. Attempting to change it will result in undefined behavior.
  public static var compressed: FileFlags { get }

  /// File is tracked for the purpose of document IDs.
  ///
  /// The corresponding C constant is `UF_TRACKED`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var tracked: FileFlags { get }

  /// File should not be displayed in a GUI.
  ///
  /// The corresponding C constant is `UF_HIDDEN`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var hidden: FileFlags { get }

  /// File requires an entitlement for writing.
  ///
  /// The corresponding C constant is `SF_RESTRICTED`.
  /// - Note: This flag may only be changed by the superuser.
  public static var restricted: FileFlags { get }

  /// File may not be removed or renamed.
  ///
  /// The corresponding C constant is `SF_NOUNLINK`.
  /// - Note: This flag may only be changed by the superuser.
  public static var systemNoUnlink: FileFlags { get }
  #endif

  // MARK: Flags Available on Darwin only

  #if SYSTEM_PACKAGE_DARWIN
  /// File requires an entitlement for reading and writing.
  ///
  /// The corresponding C constant is `UF_DATAVAULT`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var dataVault: FileFlags { get }

  /// File is a firmlink.
  ///
  /// Firmlinks are used by macOS to create transparent links between
  /// the read-only system volume and writable data volume. For example,
  /// the `/Applications` folder on the system volume is a firmlink to
  /// the `/Applications` folder on the data volume, allowing the user
  /// to see both system- and user-installed applications in a single folder.
  ///
  /// The corresponding C constant is `SF_FIRMLINK`.
  /// - Note: This flag may only be changed by the superuser.
  public static var firmlink: FileFlags { get }

  /// File is a dataless placeholder (content is stored remotely).
  ///
  /// The system will attempt to materialize the file when accessed according to
  /// the dataless file materialization policy of the accessing thread or process.
  /// See `getiopolicy_np(3)`.
  ///
  /// The corresponding C constant is `SF_DATALESS`.
  /// - Note: This flag is read-only. Attempting to change it will result in undefined behavior.
  public static var dataless: FileFlags { get }
  #endif

  // MARK: Flags Available on FreeBSD Only

  #if os(FreeBSD)
  /// File may not be removed or renamed.
  ///
  /// The corresponding C constant is `UF_NOUNLINK`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var userNoUnlink: FileFlags { get }

  /// File has the Windows offline attribute.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_OFFLINE` attribute,
  /// but otherwise provide no special handling when it's set.
  ///
  /// The corresponding C constant is `UF_OFFLINE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var offline: FileFlags { get }

  /// File is read-only.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_READONLY` attribute.
  ///
  /// The corresponding C constant is `UF_READONLY`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var readOnly: FileFlags { get }

  /// File contains a Windows reparse point.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_REPARSE_POINT` attribute.
  ///
  /// The corresponding C constant is `UF_REPARSE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var reparse: FileFlags { get }

  /// File is sparse.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_SPARSE_FILE` attribute,
  /// or to indicate a sparse file.
  ///
  /// The corresponding C constant is `UF_SPARSE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var sparse: FileFlags { get }

  /// File has the Windows system attribute.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_SYSTEM` attribute,
  /// but otherwise provide no special handling when it's set.
  ///
  /// The corresponding C constant is `UF_SYSTEM`.
  /// - Note: This flag may be changed by the file owner or superuser.
  public static var system: FileFlags { get }

  /// File is a snapshot.
  ///
  /// The corresponding C constant is `SF_SNAPSHOT`.
  /// - Note: This flag may only be changed by the superuser.
  public static var snapshot: FileFlags { get }
  #endif
}
```

### Stat

`Stat` can be initialized from a `FilePath`, `UnsafePointer<CChar>`,  or `FileDescriptor`. This proposal also includes functions on `FileDescriptor` and `FilePath` for creating a `Stat` object, seen in the section below.

The initializer accepting a `FileDescriptor` corresponds to `fstat()`. If the file descriptor points to a symlink, this will return information about the symlink itself.

In the non-`FileDescriptor` case, one form of the initializer takes a `followTargetSymlink: Bool = true` parameter. The default `true` corresponds to `stat()` and will follow a symlink at the end of the path. Setting `followTargetSymlink: false` corresponds to `lstat()` and will return information about the symlink itself.

The other form of the initializer receives a path, which can be optionally resolved against a given file descriptor, and a set of `Stat.Flags`. These APIs correspond to the `fstatat()` system call and use a default file descriptor of `AT_FDCWD` if one isn't supplied.

```swift
/// A Swift wrapper of the C `stat` struct.
///
/// - Note: Only available on Unix-like platforms.
@frozen
public struct Stat: RawRepresentable, Sendable {

  /// The raw C `stat` struct.
  public var rawValue: CInterop.Stat

  /// Creates a Swift `Stat` from the raw C struct.
  public init(rawValue: CInterop.Stat)

  // MARK: Stat.Flags

  /// Flags representing those passed to `fstatat()`.
  @frozen
  public struct Flags: OptionSet, Sendable, Hashable, Codable {

    /// The raw C flags.
    public let rawValue: CInt

    /// Creates a strongly-typed `Stat.Flags` from raw C flags.
    public init(rawValue: CInt)

    /// If the path ends with a symbolic link, return information about the link itself.
    ///
    /// The corresponding C constant is `AT_SYMLINK_NOFOLLOW`.
    public static var symlinkNoFollow: Flags { get }

    #if SYSTEM_PACKAGE_DARWIN
    /// If the path ends with a symbolic link, return information about the link itself.
    /// If _any_ symbolic link is encountered during path resolution, return an error.
    ///
    /// The corresponding C constant is `AT_SYMLINK_NOFOLLOW_ANY`.
    /// - Note: Only available on Darwin.
    public static var symlinkNoFollowAny: Flags { get }
    #endif

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    /// If the path does not reside in the hierarchy beneath the starting directory, return an error.
    ///
    /// The corresponding C constant is `AT_RESOLVE_BENEATH`.
    /// - Note: Only available on Darwin and FreeBSD.
    public static var resolveBeneath: Flags { get }
    #endif

    #if os(FreeBSD) || os(Linux) || os(Android)
    /// If the path is an empty string (or `NULL` since Linux 6.11),
    /// return information about the given file descriptor.
    ///
    /// The corresponding C constant is `AT_EMPTY_PATH`.
    /// - Note: Only available on FreeBSD, Linux, and Android.
    public static var emptyPath: Flags { get }
    #endif
  }

  // MARK: Initializers
  
  /// Creates a `Stat` struct from a `FilePath`.
  ///
  /// `followTargetSymlink` determines the behavior if `path` ends with a symbolic link.
  /// By default, `followTargetSymlink` is `true` and this initializer behaves like `stat()`.
  /// If `followTargetSymlink` is set to `false`, this initializer behaves like `lstat()` and
  /// returns information about the symlink itself.
  ///
  /// The corresponding C function is `stat()` or `lstat()` as described above.
  public init(
    _ path: FilePath,
    followTargetSymlink: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `Stat` struct from an`UnsafePointer<CChar>` path.
  ///
  /// `followTargetSymlink` determines the behavior if `path` ends with a symbolic link.
  /// By default, `followTargetSymlink` is `true` and this initializer behaves like `stat()`.
  /// If `followTargetSymlink` is set to `false`, this initializer behaves like `lstat()` and
  /// returns information about the symlink itself.
  ///
  /// The corresponding C function is `stat()` or `lstat()` as described above.
  public init(
    _ path: UnsafePointer<CChar>,
    followTargetSymlink: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `Stat` struct from a `FileDescriptor`.
  ///
  /// The corresponding C function is `fstat()`.
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno)
  
  /// Creates a `Stat` struct from a `FilePath` and `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  public init(
    _ path: FilePath,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno)
  
  /// Creates a `Stat` struct from a `FilePath` and `Flags`,
  /// including a `FileDescriptor` to resolve a relative path.
  ///
  /// If `path` is absolute (starts with a forward slash), then `fd` is ignored.
  /// If `path` is relative, it is resolved against the directory given by `fd`.
  ///
  /// The corresponding C function is `fstatat()`.
  public init(
    _ path: FilePath,
    relativeTo fd: FileDescriptor,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno)
  
  /// Creates a `Stat` struct from an `UnsafePointer<CChar>` path and `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  public init(
    _ path: UnsafePointer<CChar>,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  /// Creates a `Stat` struct from an `UnsafePointer<CChar>` path and `Flags`,
  /// including a `FileDescriptor` to resolve a relative path.
  ///
  /// If `path` is absolute (starts with a forward slash), then `fd` is ignored.
  /// If `path` is relative, it is resolved against the directory given by `fd`.
  ///
  /// The corresponding C function is `fstatat()`.
  public init(
    _ path: UnsafePointer<CChar>,
    relativeTo fd: FileDescriptor,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno)

  // MARK: Properties

  /// ID of device containing file
  ///
  /// The corresponding C property is `st_dev`.
  public var deviceID: DeviceID { get set }

  /// Inode number
  ///
  /// The corresponding C property is `st_ino`.
  public var inode: Inode { get set }

  /// File mode
  ///
  /// The corresponding C property is `st_mode`.
  public var mode: FileMode { get set }

  /// File type for the given mode
  public var type: FileType { get set }

  /// File permissions for the given mode
  public var permissions: FilePermissions { get set }

  /// Number of hard links
  ///
  /// The corresponding C property is `st_nlink`.
  public var linkCount: Int { get set }

  /// User ID of owner
  ///
  /// The corresponding C property is `st_uid`.
  public var userID: UserID { get set }

  /// Group ID of owner
  ///
  /// The corresponding C property is `st_gid`.
  public var groupID: GroupID { get set }

  /// Device ID (if special file)
  ///
  /// For character or block special files, the returned `DeviceID` may have
  /// meaningful `.major` and `.minor` values. For non-special files, this
  /// property is usually meaningless and often set to 0.
  ///
  /// The corresponding C property is `st_rdev`.
  public var specialDeviceID: DeviceID { get set }

  /// Total size, in bytes
  ///
  /// The corresponding C property is `st_size`.
  public var size: Int64 { get set }

  /// Block size for filesystem I/O, in bytes
  ///
  /// The corresponding C property is `st_blksize`.
  public var preferredIOBlockSize: Int { get set }

  /// Number of 512-byte blocks allocated
  ///
  /// The corresponding C property is `st_blocks`.
  public var blocksAllocated: Int64 { get set }

  /// Total size allocated, in bytes
  ///
  /// - Note: Calculated as `512 * blocksAllocated`.
  public var sizeAllocated: Int64 { get }

  /// Time of last access, given as a `UTCClock.Instant`
  ///
  /// The corresponding C property is `st_atim` (or `st_atimespec` on Darwin).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var accessTime: UTCClock.Instant { get set }

  /// Time of last modification, given as a `UTCClock.Instant`
  ///
  /// The corresponding C property is `st_mtim` (or `st_mtimespec` on Darwin).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var modificationTime: UTCClock.Instant { get set }

  /// Time of last status (inode) change, given as a `UTCClock.Instant`
  ///
  /// The corresponding C property is `st_ctim` (or `st_ctimespec` on Darwin).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var changeTime: UTCClock.Instant { get set }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Time of file creation, given as a `UTCClock.Instant`
  ///
  /// The corresponding C property is `st_birthtim` (or `st_birthtimespec` on Darwin).
  /// - Note: Only available on Darwin and FreeBSD.
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var creationTime: UTCClock.Instant { get set }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// File flags
  ///
  /// The corresponding C property is `st_flags`.
  /// - Note: Only available on Darwin, FreeBSD, and OpenBSD.
  public var flags: FileFlags { get set }

  /// File generation number
  ///
  /// The file generation number is used to distinguish between different files
  /// that have used the same inode over time.
  ///
  /// The corresponding C property is `st_gen`.
  /// - Note: Only available on Darwin, FreeBSD, and OpenBSD.
  public var generationNumber: Int { get set }
  #endif
}

// MARK: - Equatable and Hashable

extension Stat: Equatable {
  /// Compares the raw bytes of two `Stat` structs for equality.
  public static func == (lhs: Self, rhs: Self) -> Bool
}

extension Stat: Hashable {
  /// Hashes the raw bytes of this `Stat` struct.
  public func hash(into hasher: inout Hasher)
}
```

### FileDescriptor and FilePath Extensions

```swift
extension FileDescriptor {

  /// Creates a `Stat` struct for the file referenced by this `FileDescriptor`.
  ///
  /// The corresponding C function is `fstat()`.
  public func stat(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat
}

extension FilePath {

  /// Creates a `Stat` struct for the file referenced by this `FilePath`.
  ///
  /// `followTargetSymlink` determines the behavior if `path` ends with a symbolic link.
  /// By default, `followTargetSymlink` is `true` and this initializer behaves like `stat()`.
  /// If `followTargetSymlink` is set to `false`, this initializer behaves like `lstat()` and
  /// returns information about the symlink itself.
  ///
  /// The corresponding C function is `stat()` or `lstat()` as described above.
  public func stat(
    followTargetSymlink: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat
  
  /// Creates a `Stat` struct for the file referenced by this`FilePath` using the given `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  public func stat(
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat

  /// Creates a `Stat` struct for the file referenced by this`FilePath` using the given `Flags`,
  /// including a `FileDescriptor` to resolve a relative path.
  ///
  /// If `path` is absolute (starts with a forward slash), then `fd` is ignored.
  /// If `path` is relative, it is resolved against the directory given by `fd`.
  ///
  /// The corresponding C function is `fstatat()`.
  public func stat(
    relativeTo fd: FileDescriptor,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat
}
```

### CInterop Extensions

This proposal extends the existing `CInterop` namespace with platform-appropriate typealiases for the underlying C types. These typealiases are used as the `rawValue` for their strongly-typed representations.

```swift
extension CInterop {
  public typealias Stat
  public typealias Inode
  public typealias UserID
  public typealias GroupID
  public typealias DeviceID
  public typealias FileFlags
}
```

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility  

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

This feature can be freely adopted and un-adopted in source code with no deployment constraints and without affecting source or ABI compatibility.

## Future directions

To remain faithful to the underlying system calls, we don't anticipate extending `Stat`. However, the types introduced in this proposal could serve as the foundation of broader file system APIs in Swift.

While this proposal does not include `Stat` on Windows, a separate proposal should provide Swift-native wrappers of idiomatic `GetFileInformation` functions with their associated types.

A more general `FileInfo` API could then build on these OS-specific types to provide an ergonomic, cross-platform abstraction for file metadata. These future cross-platform APIs might be better implemented outside of System, such as in Foundation, the standard library, or somewhere in between. They could provide additional information or conveniences, such as reading and modifying extended attributes or setting file timestamps.

In the future, more functionality could be added to types such as `DeviceID`.

## Alternatives considered

### `FileInfo` as the lowest-level type
An alternative approach could be to have a more general `FileInfo` type be the lowest level of abstraction provided by the System library. This type would then handle all the `stat` or Windows-specific struct storage and accessors. However, this alternative:

- Is inconsistent with System's philosophy of providing low-level system abstractions.
- Introduces an even larger number of system-specific APIs on each type.
- Misses out on the familiarity of the `stat` name. Developers know what to look for and what to expect from this type.

### Single combined type for both file and file system metadata
Combining `Stat` and `StatFS` (separate proposal) into a single type was considered but rejected because file and file system information serve different purposes and are typically needed in different contexts. Storing and/or initializing both `stat` and `statfs` structs unnecessarily reduces performance when one isn't needed.

### Making `Stat` available on Windows
It's possible to make `Stat` available on Windows and use either the non-native `_stat` functions from CRT or populate the information via a separate `GetFileInformation` call. However, many of the `stat` fields are not- or less-applicable on Windows and are treated as such by `_stat`. For instance, `st_uid` is always zero on Windows, `st_ino` has no meaning in FAT, HPFS, or NTFS file systems, and `st_mode` can only specify a regular file, directory, or character special, with the executable bit depending entirely on the file's path extension.

Rather than forcing Windows file metadata semantics into a cross-platform `Stat` type, we should instead create Windows-specific types that give developers full access to platform-native file metadata. Combined with a higher-level `FileInfo` type that _is_ cross-platform, this gives the best of both low-level and platform-agnostic APIs.

### Only have `FilePath` and `FileDescriptor` extensions rather than initializers that accept these types
While having `.stat()` functions on `FilePath` and `FileDescriptor` is preferred for ergonomics and function chaining, this technique might lack the discoverability of having an initializer on `Stat` directly. This proposal therefore includes both the initializers and extensions.

### Types for time properties

`UTCClock.Instant` was chosen over alternatives such as `Duration` or a new `Timespec` type to provide a comparable instant in time rather than a duration since the Epoch. This would depend on lowering `UTCClock` to System or the standard library, which could be discussed in a separate pitch or proposal.

### Type names

`Stat` was chosen over alternatives like `FileStat` or `FileStatus` for its brevity and likeness to the "stat" system call. Unlike generic names such as `FileInfo` or `FileMetadata`, `Stat` emphasizes the platform-specific nature of this type.

`Inode` was similarly chosen over alternatives like `FileIndex` or `FileID` to emphasize the platform-specific nature. `IndexNode` is a bit verbose, and despite its etymology, "inode" is now ubiquitous and understood as a single word, making the capitalization `Inode` preferable to `INode`.


## Acknowledgments

These new APIs build on excellent types currently available in the System library.

## Appendix

### Swift API to C Mappings

The following tables show the mapping between Swift APIs and their underlying C system calls across different operating systems:

#### `Stat` Initializer Mappings

The `retryOnInterrupt: Bool = true` parameter is omitted for clarity.

| Swift API | Unix-like Platforms |
|-----------|---------------------|
| `Stat(_ path: FilePath, followTargetSymlink: true)` | `stat()` |
| `Stat(_ path: UnsafePointer<CChar>, followTargetSymlink: true)` | `stat()` |
||
| `Stat(_ path: FilePath, followTargetSymlink: false)` | `lstat()` |
| `Stat(_ path: UnsafePointer<CChar>, followTargetSymlink: false)` | `lstat()` |
||
| `Stat(_ path: FilePath, relativeTo: FileDescriptor, flags: Stat.Flags)` | `fstatat()` |
| `Stat(_ path: UnsafePointer<CChar>, relativeTo: FileDescriptor, flags: Stat.Flags)` | `fstatat()` |
||
| `Stat(_ fd: FileDescriptor)` | `fstat()` |
| `FileDescriptor.stat()` | `fstat()` |
||
| `FilePath.stat(followTargetSymlink: true)` | `stat()` |
| `FilePath.stat(followTargetSymlink: false)` | `lstat()` |
| `FilePath.stat(relativeTo: FileDescriptor, flags: Stat.Flags)` | `fstatat()` |

#### `Stat` Property Mappings

`"` denotes the same property name across all operating systems.

| Swift Property | Darwin | FreeBSD | OpenBSD | Linux | Android | WASI |
|----------------|--------|---------|---------|-------|---------|------|
| `deviceID` | `st_dev` | " | " | " | " | " |
| `inode` | `st_ino` | " | " | " | " | " |
| `mode` | `st_mode` | " | " | " | " | " |
| `linkCount` | `st_nlink` | " | " | " | " | " |
| `userID` | `st_uid` | " | " | " | " | " |
| `groupID` | `st_gid` | " | " | " | " | " |
| `specialDeviceID` | `st_rdev` | " | " | " | " | " |
| `size` | `st_size` | " | " | " | " | " |
| `preferredIOBlockSize` | `st_blksize` | " | " | " | " | " |
| `blocksAllocated` | `st_blocks` | " | " | " | " | " |
| `accessTime` | `st_atimespec` | `st_atim` | `st_atim` | `st_atim` | `st_atim` | `st_atim` |
| `modificationTime` | `st_mtimespec` | `st_mtim` | `st_mtim` | `st_mtim` | `st_mtim` | `st_mtim` |
| `changeTime` | `st_ctimespec` | `st_ctim` | `st_ctim` | `st_ctim` | `st_ctim` | `st_ctim` |
| `creationTime` | `st_birthtimespec` | `st_birthtim` | N/A | N/A | N/A | N/A |
| `flags` | `st_flags` | `st_flags` | `st_flags` | N/A | N/A | N/A |
| `generationNumber` | `st_gen` | `st_gen` | `st_gen` | N/A | N/A | N/A |

#### `Stat.Flags` Mappings

| Swift Flag | Darwin | FreeBSD | OpenBSD | Linux | Android | WASI |
|------------|--------|---------|---------|-------|---------|------|
| `symlinkNoFollow` | `AT_SYMLINK_NOFOLLOW` | `AT_SYMLINK_NOFOLLOW` | `AT_SYMLINK_NOFOLLOW` | `AT_SYMLINK_NOFOLLOW` | `AT_SYMLINK_NOFOLLOW` | `AT_SYMLINK_NOFOLLOW` |
| `symlinkNoFollowAny` | `AT_SYMLINK_NOFOLLOW_ANY` | N/A | N/A | N/A | N/A | N/A |
| `resolveBeneath` | `AT_RESOLVE_BENEATH` | `AT_RESOLVE_BENEATH` | N/A | N/A | N/A | N/A |
| `emptyPath` | N/A | `AT_EMPTY_PATH` | N/A | `AT_EMPTY_PATH` | `AT_EMPTY_PATH` | N/A |

#### `FileFlags` Mappings

**Note:** `FileFlags` is only available on Darwin, FreeBSD, and OpenBSD.

| Swift Flag | Darwin | FreeBSD | OpenBSD |
|------------|--------|---------|---------|
| `noDump` | `UF_NODUMP` | `UF_NODUMP` | `UF_NODUMP` |
| `userImmutable` | `UF_IMMUTABLE` | `UF_IMMUTABLE` | `UF_IMMUTABLE` |
| `userAppend` | `UF_APPEND` | `UF_APPEND` | `UF_APPEND` |
| `archived` | `SF_ARCHIVED` | `SF_ARCHIVED` | `SF_ARCHIVED` |
| `systemImmutable` | `SF_IMMUTABLE` | `SF_IMMUTABLE` | `SF_IMMUTABLE` |
| `systemAppend` | `SF_APPEND` | `SF_APPEND` | `SF_APPEND` |
| `opaque` | `UF_OPAQUE` | `UF_OPAQUE` | N/A |
| `compressed` | `UF_COMPRESSED` | `UF_COMPRESSED` | N/A |
| `tracked` | `UF_TRACKED` | `UF_TRACKED` | N/A |
| `hidden` | `UF_HIDDEN` | `UF_HIDDEN` | N/A |
| `restricted` | `SF_RESTRICTED` | `SF_RESTRICTED` | N/A |
| `systemNoUnlink` | `SF_NOUNLINK` | `SF_NOUNLINK` | N/A |
| `dataVault` | `UF_DATAVAULT` | N/A | N/A |
| `firmlink` | `SF_FIRMLINK` | N/A | N/A |
| `dataless` | `SF_DATALESS` | N/A | N/A |
| `userNoUnlink` | N/A | `UF_NOUNLINK` | N/A |
| `offline` | N/A | `UF_OFFLINE` | N/A |
| `readOnly` | N/A | `UF_READONLY` | N/A |
| `reparse` | N/A | `UF_REPARSE` | N/A |
| `sparse` | N/A | `UF_SPARSE` | N/A |
| `system` | N/A | `UF_SYSTEM` | N/A |
| `snapshot` | N/A | `SF_SNAPSHOT` | N/A |
