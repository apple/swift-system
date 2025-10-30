//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !os(Windows)

// Must import here to use C stat properties in @_alwaysEmitIntoClient APIs.
#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Android)
import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

// MARK: - Stat

/// A Swift wrapper of the C `stat` struct.
///
/// - Note: Only available on Unix-like platforms.
@frozen
@available(System 99, *)
public struct Stat: RawRepresentable, Sendable {

  /// The raw C `stat` struct.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Stat

  /// Creates a Swift `Stat` from the raw C struct.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Stat) { self.rawValue = rawValue }

  // MARK: Stat.Flags

  /// Flags representing those passed to `fstatat()`.
  @frozen
  public struct Flags: OptionSet, Sendable, Hashable, Codable {

    /// The raw C flags.
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    /// Creates a strongly-typed `Stat.Flags` from raw C flags.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// If the path ends with a symbolic link, return information about the link itself.
    ///
    /// The corresponding C constant is `AT_SYMLINK_NOFOLLOW`.
    @_alwaysEmitIntoClient
    public static var symlinkNoFollow: Flags { Flags(rawValue: _AT_SYMLINK_NOFOLLOW) }

    #if SYSTEM_PACKAGE_DARWIN
    /// If the path ends with a symbolic link, return information about the link itself.
    /// If _any_ symbolic link is encountered during path resolution, return an error.
    ///
    /// The corresponding C constant is `AT_SYMLINK_NOFOLLOW_ANY`.
    /// - Note: Only available on Darwin.
    @_alwaysEmitIntoClient
    public static var symlinkNoFollowAny: Flags { Flags(rawValue: _AT_SYMLINK_NOFOLLOW_ANY) }
    #endif

    #if canImport(Darwin, _version: 346) || os(FreeBSD)
    /// If the path does not reside in the hierarchy beneath the starting directory, return an error.
    ///
    /// The corresponding C constant is `AT_RESOLVE_BENEATH`.
    /// - Note: Only available on Darwin and FreeBSD.
    @_alwaysEmitIntoClient
    public static var resolveBeneath: Flags { Flags(rawValue: _AT_RESOLVE_BENEATH) }
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
  @_alwaysEmitIntoClient
  public init(
    _ path: FilePath,
    followTargetSymlink: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try path.withPlatformString {
      Self._stat(
        $0,
        followTargetSymlink: followTargetSymlink,
        retryOnInterrupt: retryOnInterrupt
      )
    }.get()
  }

  /// Creates a `Stat` struct from an `UnsafePointer<CChar>` path.
  ///
  /// `followTargetSymlink` determines the behavior if `path` ends with a symbolic link.
  /// By default, `followTargetSymlink` is `true` and this initializer behaves like `stat()`.
  /// If `followTargetSymlink` is set to `false`, this initializer behaves like `lstat()` and
  /// returns information about the symlink itself.
  ///
  /// The corresponding C function is `stat()` or `lstat()` as described above.
  @_alwaysEmitIntoClient
  public init(
    _ path: UnsafePointer<CChar>,
    followTargetSymlink: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try Self._stat(
      path,
      followTargetSymlink: followTargetSymlink,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _stat(
    _ ptr: UnsafePointer<CChar>,
    followTargetSymlink: Bool,
    retryOnInterrupt: Bool
  ) -> Result<CInterop.Stat, Errno> {
    var result = CInterop.Stat()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      if followTargetSymlink {
        system_stat(ptr, &result)
      } else {
        system_lstat(ptr, &result)
      }
    }.map { result }
  }

  /// Creates a `Stat` struct from a `FileDescriptor`.
  ///
  /// The corresponding C function is `fstat()`.
  @_alwaysEmitIntoClient
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try Self._fstat(
      fd,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _fstat(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool
  ) -> Result<CInterop.Stat, Errno> {
    var result = CInterop.Stat()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fstat(fd.rawValue, &result)
    }.map { result }
  }

  /// Creates a `Stat` struct from a `FilePath` and `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public init(
    _ path: FilePath,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try path.withPlatformString {
      Self._fstatat(
        $0,
        relativeTo: _AT_FDCWD,
        flags: flags,
        retryOnInterrupt: retryOnInterrupt
      )
    }.get()
  }

  /// Creates a `Stat` struct from a `FilePath` and `Flags`,
  /// including a `FileDescriptor` to resolve a relative path.
  ///
  /// If `path` is absolute (starts with a forward slash), then `fd` is ignored.
  /// If `path` is relative, it is resolved against the directory given by `fd`.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public init(
    _ path: FilePath,
    relativeTo fd: FileDescriptor,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try path.withPlatformString {
      Self._fstatat(
        $0,
        relativeTo: fd.rawValue,
        flags: flags,
        retryOnInterrupt: retryOnInterrupt
      )
    }.get()
  }

  /// Creates a `Stat` struct from an `UnsafePointer<CChar>` path and `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public init(
    _ path: UnsafePointer<CChar>,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try Self._fstatat(
      path,
      relativeTo: _AT_FDCWD,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  /// Creates a `Stat` struct from an `UnsafePointer<CChar>` path and `Flags`,
  /// including a `FileDescriptor` to resolve a relative path.
  ///
  /// If `path` is absolute (starts with a forward slash), then `fd` is ignored.
  /// If `path` is relative, it is resolved against the directory given by `fd`.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public init(
    _ path: UnsafePointer<CChar>,
    relativeTo fd: FileDescriptor,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try Self._fstatat(
      path,
      relativeTo: fd.rawValue,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _fstatat(
    _ path: UnsafePointer<CChar>,
    relativeTo fd: FileDescriptor.RawValue,
    flags: Stat.Flags,
    retryOnInterrupt: Bool
  ) -> Result<CInterop.Stat, Errno> {
    var result = CInterop.Stat()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fstatat(fd, path, &result, flags.rawValue)
    }.map { result }
  }


  // MARK: Properties

  /// ID of device containing file
  ///
  /// The corresponding C property is `st_dev`.
  @_alwaysEmitIntoClient
  public var deviceID: DeviceID {
    get { DeviceID(rawValue: rawValue.st_dev) }
    set { rawValue.st_dev = newValue.rawValue }
  }

  /// Inode number
  ///
  /// The corresponding C property is `st_ino`.
  @_alwaysEmitIntoClient
  public var inode: Inode {
    get { Inode(rawValue: rawValue.st_ino) }
    set { rawValue.st_ino = newValue.rawValue }
  }

  /// File mode
  ///
  /// The corresponding C property is `st_mode`.
  @_alwaysEmitIntoClient
  public var mode: FileMode {
    get { FileMode(rawValue: rawValue.st_mode) }
    set { rawValue.st_mode = newValue.rawValue }
  }

  /// File type for the given mode
  ///
  /// - Note: This property is equivalent to `mode.type`. Modifying this
  ///   property will update the underlying `st_mode` accordingly.
  @_alwaysEmitIntoClient
  public var type: FileType {
    get { mode.type }
    set {
      var newMode = mode
      newMode.type = newValue
      mode = newMode
    }
  }

  /// File permissions for the given mode
  ///
  /// - Note: This property is equivalent to `mode.permissions`. Modifying
  ///   this property will update the underlying `st_mode` accordingly.
  @_alwaysEmitIntoClient
  public var permissions: FilePermissions {
    get { mode.permissions }
    set {
      var newMode = mode
      newMode.permissions = newValue
      mode = newMode
    }
  }

  /// Number of hard links
  ///
  /// The corresponding C property is `st_nlink`.
  @_alwaysEmitIntoClient
  public var linkCount: Int {
    get { Int(rawValue.st_nlink) }
    set { rawValue.st_nlink = numericCast(newValue) }
  }

  /// User ID of owner
  ///
  /// The corresponding C property is `st_uid`.
  @_alwaysEmitIntoClient
  public var userID: UserID {
    get { UserID(rawValue: rawValue.st_uid) }
    set { rawValue.st_uid = newValue.rawValue }
  }

  /// Group ID of owner
  ///
  /// The corresponding C property is `st_gid`.
  @_alwaysEmitIntoClient
  public var groupID: GroupID {
    get { GroupID(rawValue: rawValue.st_gid) }
    set { rawValue.st_gid = newValue.rawValue }
  }

  /// Device ID (if special file)
  ///
  /// For character or block special files, the returned `DeviceID` may have
  /// meaningful major and minor values. For non-special files, this
  /// property is usually meaningless and often set to 0.
  ///
  /// The corresponding C property is `st_rdev`.
  @_alwaysEmitIntoClient
  public var specialDeviceID: DeviceID {
    get { DeviceID(rawValue: rawValue.st_rdev) }
    set { rawValue.st_rdev = newValue.rawValue }
  }

  /// Total size, in bytes
  ///
  /// The semantics of this property are tied to the underlying C `st_size` field,
  /// which can have file-system–dependent behavior. For example, this property
  /// can return different values for a file's data fork and resource fork, and some
  /// file systems report logical size rather than actual disk usage for compressed
  /// or cloned files.
  ///
  /// The corresponding C property is `st_size`.
  @_alwaysEmitIntoClient
  public var size: Int64 {
    get { Int64(rawValue.st_size) }
    set { rawValue.st_size = numericCast(newValue) }
  }

  /// Block size for file system I/O, in bytes
  ///
  /// The corresponding C property is `st_blksize`.
  @_alwaysEmitIntoClient
  public var preferredIOBlockSize: Int {
    get { Int(rawValue.st_blksize) }
    set { rawValue.st_blksize = numericCast(newValue) }
  }

  /// Number of 512-byte blocks allocated
  ///
  /// The semantics of this property are tied to the underlying C `st_blocks` field,
  /// which can have file-system–dependent behavior.
  ///
  /// The corresponding C property is `st_blocks`.
  @_alwaysEmitIntoClient
  public var blocksAllocated: Int64 {
    get { Int64(rawValue.st_blocks) }
    set { rawValue.st_blocks = numericCast(newValue) }
  }

  /// Total size allocated, in bytes
  ///
  /// The semantics of this property are tied to the underlying C `st_blocks` field,
  /// which can have file-system–dependent behavior.
  ///
  /// - Note: Calculated as `512 * blocksAllocated`.
  @_alwaysEmitIntoClient
  public var sizeAllocated: Int64 {
    512 * blocksAllocated
  }

  // NOTE: "st_" property names are used for the `timespec` properties so
  // we can reserve `accessTime`, `modificationTime`, etc. for potential
  // `UTCClock.Instant` properties in the future.

  /// Time of last access, given as a C `timespec` since the Epoch.
  ///
  /// The corresponding C property is `st_atim` (or `st_atimespec` on Darwin).
  @_alwaysEmitIntoClient
  public var st_atim: timespec {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_atimespec
      #else
      rawValue.st_atim
      #endif
    }
    set {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_atimespec = newValue
      #else
      rawValue.st_atim = newValue
      #endif
    }
  }

  /// Time of last modification, given as a C `timespec` since the Epoch.
  ///
  /// The corresponding C property is `st_mtim` (or `st_mtimespec` on Darwin).
  @_alwaysEmitIntoClient
  public var st_mtim: timespec {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_mtimespec
      #else
      rawValue.st_mtim
      #endif
    }
    set {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_mtimespec = newValue
      #else
      rawValue.st_mtim = newValue
      #endif
    }
  }

  /// Time of last status (inode) change, given as a C `timespec` since the Epoch.
  ///
  /// The corresponding C property is `st_ctim` (or `st_ctimespec` on Darwin).
  @_alwaysEmitIntoClient
  public var st_ctim: timespec {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_ctimespec
      #else
      rawValue.st_ctim
      #endif
    }
    set {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_ctimespec = newValue
      #else
      rawValue.st_ctim = newValue
      #endif
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Time of file creation, given as a C `timespec` since the Epoch.
  ///
  /// The corresponding C property is `st_birthtim` (or `st_birthtimespec` on Darwin).
  /// - Note: Only available on Darwin and FreeBSD.
  @_alwaysEmitIntoClient
  public var st_birthtim: timespec {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_birthtimespec
      #else
      rawValue.st_birthtim
      #endif
    }
    set {
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_birthtimespec = newValue
      #else
      rawValue.st_birthtim = newValue
      #endif
    }
  }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// File flags
  ///
  /// The corresponding C property is `st_flags`.
  /// - Note: Only available on Darwin, FreeBSD, and OpenBSD.
  @_alwaysEmitIntoClient
  public var flags: FileFlags {
    get { FileFlags(rawValue: rawValue.st_flags) }
    set { rawValue.st_flags = newValue.rawValue }
  }

  /// File generation number
  ///
  /// The file generation number is used to distinguish between different files
  /// that have used the same inode over time.
  ///
  /// The corresponding C property is `st_gen`.
  /// - Note: Only available on Darwin, FreeBSD, and OpenBSD.
  @_alwaysEmitIntoClient
  public var generationNumber: Int {
    get { Int(rawValue.st_gen) }
    set { rawValue.st_gen = numericCast(newValue)}
  }
  #endif
}

// MARK: - Equatable and Hashable

@available(System 99, *)
extension Stat: Equatable {
  @_alwaysEmitIntoClient
  /// Compares the raw bytes of two `Stat` structs for equality.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return withUnsafeBytes(of: lhs.rawValue) { lhsBytes in
      withUnsafeBytes(of: rhs.rawValue) { rhsBytes in
        lhsBytes.elementsEqual(rhsBytes)
      }
    }
  }
}

@available(System 99, *)
extension Stat: Hashable {
  @_alwaysEmitIntoClient
  /// Hashes the raw bytes of this `Stat` struct.
  public func hash(into hasher: inout Hasher) {
    withUnsafeBytes(of: rawValue) { bytes in
      hasher.combine(bytes: bytes)
    }
  }
}

// MARK: - CustomStringConvertible and CustomDebugStringConvertible

// MARK: - FileDescriptor Extensions

@available(System 99, *)
extension FileDescriptor {

  /// Creates a `Stat` struct for the file referenced by this `FileDescriptor`.
  ///
  /// The corresponding C function is `fstat()`.
  @_alwaysEmitIntoClient
  public func stat(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat {
    try Stat(self, retryOnInterrupt: retryOnInterrupt)
  }
}

// MARK: - FilePath Extensions

@available(System 99, *)
extension FilePath {

  /// Creates a `Stat` struct for the file referenced by this `FilePath`.
  ///
  /// `followTargetSymlink` determines the behavior if `path` ends with a symbolic link.
  /// By default, `followTargetSymlink` is `true` and this initializer behaves like `stat()`.
  /// If `followTargetSymlink` is set to `false`, this initializer behaves like `lstat()` and
  /// returns information about the symlink itself.
  ///
  /// The corresponding C function is `stat()` or `lstat()` as described above.
  @_alwaysEmitIntoClient
  public func stat(
    followTargetSymlink: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat {
    try Stat(self, followTargetSymlink: followTargetSymlink, retryOnInterrupt: retryOnInterrupt)
  }

  /// Creates a `Stat` struct for the file referenced by this `FilePath` using the given `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public func stat(
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat {
    try Stat(self, flags: flags, retryOnInterrupt: retryOnInterrupt)
  }

  /// Creates a `Stat` struct for the file referenced by this `FilePath` using the given `Flags`,
  /// including a `FileDescriptor` to resolve a relative path.
  ///
  /// If `path` is absolute (starts with a forward slash), then `fd` is ignored.
  /// If `path` is relative, it is resolved against the directory given by `fd`.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public func stat(
    relativeTo fd: FileDescriptor,
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat {
    try Stat(self, relativeTo: fd, flags: flags, retryOnInterrupt: retryOnInterrupt)
  }
}

#endif // !os(Windows)
