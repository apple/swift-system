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
// @available(System X.Y.Z, *)
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

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    /// If the path does not reside in the hierarchy beneath the starting directory, return an error.
    ///
    /// The corresponding C constant is `AT_RESOLVE_BENEATH`.
    /// - Note: Only available on Darwin and FreeBSD.
    @_alwaysEmitIntoClient
    public static var resolveBeneath: Flags { Flags(rawValue: _AT_RESOLVE_BENEATH) }
    #endif

    #if os(FreeBSD) || os(Linux) || os(Android)
    /// If the path is an empty string (or `NULL` since Linux 6.11),
    /// return information about the given file descriptor.
    ///
    /// The corresponding C constant is `AT_EMPTY_PATH`.
    /// - Note: Only available on FreeBSD, Linux, and Android.
    @_alwaysEmitIntoClient
    public static var emptyPath: Flags { Flags(rawValue: _AT_EMPTY_PATH) }
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

  /// Creates a `Stat` struct from an`UnsafePointer<CChar>` path.
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
  /// meaningful `.major` and `.minor` values. For non-special files, this
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
  /// The corresponding C property is `st_size`.
  @_alwaysEmitIntoClient
  public var size: Int64 {
    get { Int64(rawValue.st_size) }
    set { rawValue.st_size = numericCast(newValue) }
  }

  /// Block size for filesystem I/O, in bytes
  ///
  /// The corresponding C property is `st_blksize`.
  @_alwaysEmitIntoClient
  public var preferredIOBlockSize: Int {
    get { Int(rawValue.st_blksize) }
    set { rawValue.st_blksize = numericCast(newValue) }
  }

  /// Number of 512-byte blocks allocated
  ///
  /// The corresponding C property is `st_blocks`.
  @_alwaysEmitIntoClient
  public var blocksAllocated: Int64 {
    get { Int64(rawValue.st_blocks) }
    set { rawValue.st_blocks = numericCast(newValue) }
  }

  /// Total size allocated, in bytes
  ///
  /// - Note: Calculated as `512 * blocksAllocated`.
  @_alwaysEmitIntoClient
  public var sizeAllocated: Int64 {
    512 * blocksAllocated
  }

  // TODO: jflat - Change time properties to UTCClock.Instant when possible.

  /// Time of last access, given as a `Duration` since the Epoch
  ///
  /// The corresponding C property is `st_atim` (or `st_atimespec` on Darwin).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var accessTime: Duration {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      let timespec = rawValue.st_atimespec
      #else
      let timespec = rawValue.st_atim
      #endif
      return .seconds(timespec.tv_sec) + .nanoseconds(timespec.tv_nsec)
    }
    set {
      let (seconds, attoseconds) = newValue.components
      let timespec = timespec(
        tv_sec: numericCast(seconds),
        tv_nsec: numericCast(attoseconds / 1_000_000_000)
      )
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_atimespec = timespec
      #else
      rawValue.st_atim = timespec
      #endif
    }
  }

  /// Time of last modification, given as a `Duration` since the Epoch
  ///
  /// The corresponding C property is `st_mtim` (or `st_mtimespec` on Darwin).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var modificationTime: Duration {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      let timespec = rawValue.st_mtimespec
      #else
      let timespec = rawValue.st_mtim
      #endif
      return .seconds(timespec.tv_sec) + .nanoseconds(timespec.tv_nsec)
    }
    set {
      let (seconds, attoseconds) = newValue.components
      let timespec = timespec(
        tv_sec: numericCast(seconds),
        tv_nsec: numericCast(attoseconds / 1_000_000_000)
      )
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_mtimespec = timespec
      #else
      rawValue.st_mtim = timespec
      #endif
    }
  }

  /// Time of last status (inode) change, given as a `Duration` since the Epoch
  ///
  /// The corresponding C property is `st_ctim` (or `st_ctimespec` on Darwin).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var changeTime: Duration {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      let timespec = rawValue.st_ctimespec
      #else
      let timespec = rawValue.st_ctim
      #endif
      return .seconds(timespec.tv_sec) + .nanoseconds(timespec.tv_nsec)
    }
    set {
      let (seconds, attoseconds) = newValue.components
      let timespec = timespec(
        tv_sec: numericCast(seconds),
        tv_nsec: numericCast(attoseconds / 1_000_000_000)
      )
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_ctimespec = timespec
      #else
      rawValue.st_ctim = timespec
      #endif
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Time of file creation, given as a `Duration` since the Epoch
  ///
  /// The corresponding C property is `st_birthtim` (or `st_birthtimespec` on Darwin).
  /// - Note: Only available on Darwin and FreeBSD.
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var creationTime: Duration {
    get {
      #if SYSTEM_PACKAGE_DARWIN
      let timespec = rawValue.st_birthtimespec
      #else
      let timespec = rawValue.st_birthtim
      #endif
      return .seconds(timespec.tv_sec) + .nanoseconds(timespec.tv_nsec)
    }
    set {
      let (seconds, attoseconds) = newValue.components
      let timespec = timespec(
        tv_sec: numericCast(seconds),
        tv_nsec: numericCast(attoseconds / 1_000_000_000)
      )
      #if SYSTEM_PACKAGE_DARWIN
      rawValue.st_birthtimespec = timespec
      #else
      rawValue.st_birthtim = timespec
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

// TODO: jflat

// MARK: - FileDescriptor Extensions

// @available(System X.Y.Z, *)
extension FileDescriptor {

  /// Creates a `Stat` struct for the file referenced by this `FileDescriptor`.
  ///
  /// The corresponding C function is `fstat()`.
  @_alwaysEmitIntoClient
  public func stat(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat {
    try _fstat(
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fstat(
    retryOnInterrupt: Bool
  ) -> Result<Stat, Errno> {
    var result = CInterop.Stat()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fstat(self.rawValue, &result)
    }.map { Stat(rawValue: result) }
  }
}

// MARK: - FilePath Extensions

// @available(System X.Y.Z, *)
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
    try _stat(
      followTargetSymlink: followTargetSymlink,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _stat(
    followTargetSymlink: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Stat, Errno> {
    var result = CInterop.Stat()
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        if followTargetSymlink {
          system_stat(ptr, &result)
        } else {
          system_lstat(ptr, &result)
        }
      }.map { Stat(rawValue: result) }
    }
  }

  /// Creates a `Stat` struct for the file referenced by this`FilePath` using the given `Flags`.
  ///
  /// If `path` is relative, it is resolved against the current working directory.
  ///
  /// The corresponding C function is `fstatat()`.
  @_alwaysEmitIntoClient
  public func stat(
    flags: Stat.Flags,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Stat {
    try _fstatat(
      relativeTo: _AT_FDCWD,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  /// Creates a `Stat` struct for the file referenced by this`FilePath` using the given `Flags`,
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
    try _fstatat(
      relativeTo: fd.rawValue,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }
  
  @usableFromInline
  internal func _fstatat(
    relativeTo fd: FileDescriptor.RawValue,
    flags: Stat.Flags,
    retryOnInterrupt: Bool
  ) -> Result<Stat, Errno> {
    var result = CInterop.Stat()
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_fstatat(fd, ptr, &result, flags.rawValue)
      }.map { Stat(rawValue: result) }
    }
  }
}

#endif // !os(Windows)
