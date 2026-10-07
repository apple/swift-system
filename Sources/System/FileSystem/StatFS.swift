//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if os(Windows)

/// A Swift wrapper of the C `statfs` struct.
///
/// - Note: Not available on Windows or WASI.
@available(Windows, unavailable, message: "Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
public struct StatFS {
  /// Creates a `StatFS` from a `FilePath`.
  public init(
    _ path: FilePath,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    fatalError("StatFS is unavailable on Windows")
  }

  /// Creates a `StatFS` from a null-terminated `UnsafePointer<CChar>` path.
  public init(
    _ path: UnsafePointer<CChar>,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    fatalError("StatFS is unavailable on Windows")
  }

  /// Creates a `StatFS` from a `FileDescriptor`.
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    fatalError("StatFS is unavailable on Windows")
  }
}

extension FileDescriptor {
  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FileDescriptor`.
  @available(Windows, unavailable, message: "Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
  public func statfs(retryOnInterrupt: Bool = true) throws(Errno) -> StatFS {
    fatalError("StatFS is unavailable on Windows")
  }
}

extension FilePath {
  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FilePath`.
  @available(Windows, unavailable, message: "Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
  public func statfs(retryOnInterrupt: Bool = true) throws(Errno) -> StatFS {
    fatalError("StatFS is unavailable on Windows")
  }
}

#elseif os(WASI)

/// A Swift wrapper of the C `statfs` struct.
///
/// - Note: Not available on Windows or WASI.
@available(*, unavailable, message: "wasi-libc doesn't implement statfs or statvfs.")
public struct StatFS {
  /// Creates a `StatFS` from a `FilePath`.
  public init(
    _ path: FilePath,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    fatalError("StatFS is unavailable on WASI")
  }

  /// Creates a `StatFS` from a null-terminated `UnsafePointer<CChar>` path.
  public init(
    _ path: UnsafePointer<CChar>,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    fatalError("StatFS is unavailable on WASI")
  }

  /// Creates a `StatFS` from a `FileDescriptor`.
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    fatalError("StatFS is unavailable on WASI")
  }
}

extension FileDescriptor {
  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FileDescriptor`.
  @available(*, unavailable, message: "wasi-libc doesn't implement statfs or statvfs.")
  public func statfs(retryOnInterrupt: Bool = true) throws(Errno) -> StatFS {
    fatalError("StatFS is unavailable on WASI")
  }
}

extension FilePath {
  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FilePath`.
  @available(*, unavailable, message: "wasi-libc doesn't implement statfs or statvfs.")
  public func statfs(retryOnInterrupt: Bool = true) throws(Errno) -> StatFS {
    fatalError("StatFS is unavailable on WASI")
  }
}

#else

// Must import here to use C statfs properties in @_alwaysEmitIntoClient APIs.
#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import CSystem
#if os(Linux)
import CSystemStatFS
#endif
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif canImport(Android)
import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

// MARK: - FileSystemID

/// A Swift wrapper of the C `f_fsid` file system ID found in a `statfs`
/// struct.
///
/// - Note: Not available on Windows or WASI.
@frozen
@available(System 199, *)
public struct FileSystemID: RawRepresentable, Sendable {

  /// The raw C file system ID.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.FileSystemID

  /// Creates a strongly-typed `FileSystemID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.FileSystemID) { self.rawValue = rawValue }

  /// Creates a strongly-typed `FileSystemID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: CInterop.FileSystemID) { self.rawValue = rawValue }
}

// `CInterop.FileSystemID` is the C `fsid_t` struct (a fixed two-element
// `int32_t` array), which provides no synthesized conformances.
@available(System 199, *)
extension FileSystemID {
  @_alwaysEmitIntoClient
  internal var _words: (Int32, Int32) {
    #if os(Linux) || os(Android)
    rawValue.__val
    #else
    rawValue.val
    #endif
  }

  @_alwaysEmitIntoClient
  internal init(_words words: (Int32, Int32)) {
    #if os(Linux) || os(Android)
    self.init(rawValue: CInterop.FileSystemID(__val: words))
    #else
    self.init(rawValue: CInterop.FileSystemID(val: words))
    #endif
  }
}

@available(System 199, *)
extension FileSystemID: Equatable {
  @_alwaysEmitIntoClient
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs._words.0 == rhs._words.0 && lhs._words.1 == rhs._words.1
  }
}

@available(System 199, *)
extension FileSystemID: Hashable {
  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_words.0)
    hasher.combine(_words.1)
  }
}

@available(System 199, *)
extension FileSystemID: Codable {
  @_alwaysEmitIntoClient
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(_words.0)
    try container.encode(_words.1)
  }

  @_alwaysEmitIntoClient
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let val0 = try container.decode(Int32.self)
    let val1 = try container.decode(Int32.self)
    self.init(_words: (val0, val1))
  }
}

@available(System 199, *)
extension FileSystemID: CustomStringConvertible, CustomDebugStringConvertible {
  /// A textual representation of the file system ID.
  @inline(never)
  public var description: String {
    "FileSystemID(\(_words.0), \(_words.1))"
  }

  /// A textual representation of the file system ID, suitable for debugging.
  public var debugDescription: String { self.description }
}

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(Linux) || os(Android)
// MARK: - FileSystemType

/// A Swift wrapper of the C `f_type` file system type found in a `statfs`
/// struct.
///
/// - Note: Only available on Darwin, FreeBSD, Linux, and Android.
@frozen
@available(System 199, *)
public struct FileSystemType: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw C file system type.
  @_alwaysEmitIntoClient
  public var rawValue: UInt32

  /// Creates a strongly-typed `FileSystemType` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  /// Creates a strongly-typed `FileSystemType` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
#endif // SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(Linux) || os(Android)

#if SYSTEM_PACKAGE_DARWIN
// MARK: - FileSystemSubtype

/// A Swift wrapper of the C `f_fssubtype` file system subtype found in a
/// `statfs` struct on Darwin.
///
/// - Note: Only available on Darwin.
@frozen
@available(System 199, *)
public struct FileSystemSubtype: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw C file system subtype.
  @_alwaysEmitIntoClient
  public var rawValue: UInt32

  /// Creates a strongly-typed `FileSystemSubtype` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: UInt32) { self.rawValue = rawValue }

  /// Creates a strongly-typed `FileSystemSubtype` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: UInt32) { self.rawValue = rawValue }
}
#endif

// MARK: - StatFS

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
// Helpers for reading the fixed-size, NUL-terminated C character buffers
// (`f_fstypename`, `f_mntonname`, `f_mntfromname`) in Darwin/BSD `statfs`.
// If the buffer has no NUL (malformed), the entire buffer is used.
@available(System 199, *)
extension String {
  @usableFromInline
  internal init(_nullTerminatedBytes buffer: UnsafeRawBufferPointer) {
    let bytes = buffer.prefix { $0 != 0 }
    self = String(decoding: bytes, as: CInterop.PlatformUnicodeEncoding.self)
  }
}

@available(System 199, *)
extension FilePath {
  @usableFromInline
  internal init(_nullTerminatedBytes buffer: UnsafeRawBufferPointer) {
    let chars = buffer.bindMemory(to: CInterop.PlatformChar.self)
    guard let base = chars.baseAddress else {
      self = FilePath()
      return
    }
    self = if chars.firstIndex(of: 0) != nil {
      FilePath(platformString: base)
    } else {
      withUnsafeTemporaryAllocation(
        of: CInterop.PlatformChar.self,
        capacity: chars.count + 1
      ) { terminatedBuffer in
        terminatedBuffer.baseAddress!.initialize(from: base, count: chars.count)
        terminatedBuffer[chars.count] = 0
        return FilePath(platformString: terminatedBuffer.baseAddress!)
      }
    }
  }
}
#endif

/// A Swift wrapper of the C `statfs` struct.
///
/// - Note: Not available on Windows or WASI.
/// - Note: The numeric properties clamp when converting to or from the
///   underlying C field. Use `rawValue` for exact, unclamped access.
@frozen
@available(System 199, *)
public struct StatFS: RawRepresentable, Sendable, Hashable {

  /// The raw C `statfs` struct.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.StatFS

  /// Creates a Swift `StatFS` from the raw C struct.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.StatFS) { self.rawValue = rawValue }

  // MARK: Initializers

  /// Creates a `StatFS` from a `FilePath`.
  ///
  /// The corresponding C function is `statfs()`.
  @_alwaysEmitIntoClient
  public init(
    _ path: FilePath,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try path.withPlatformString {
      Self._statfs($0, retryOnInterrupt: retryOnInterrupt)
    }.get()
  }

  /// Creates a `StatFS` from a null-terminated `UnsafePointer<CChar>` path.
  ///
  /// The corresponding C function is `statfs()`.
  @_alwaysEmitIntoClient
  public init(
    _ path: UnsafePointer<CChar>,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try Self._statfs(
      path, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _statfs(
    _ path: UnsafePointer<CChar>,
    retryOnInterrupt: Bool
  ) -> Result<CInterop.StatFS, Errno> {
    var result = CInterop.StatFS()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_statfs(path, &result)
    }.map { result }
  }

  /// Creates a `StatFS` from a `FileDescriptor`.
  ///
  /// The corresponding C function is `fstatfs()`.
  @_alwaysEmitIntoClient
  public init(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    self.rawValue = try Self._fstatfs(
      fd, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _fstatfs(
    _ fd: FileDescriptor,
    retryOnInterrupt: Bool
  ) -> Result<CInterop.StatFS, Errno> {
    var result = CInterop.StatFS()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fstatfs(fd.rawValue, &result)
    }.map { result }
  }

  // MARK: Properties

  /// File system block size, in bytes.
  ///
  /// - Note: On Darwin and BSD, this is the fundamental size for block counts.
  ///   Other platforms use `fragmentSize` (`f_frsize`) instead.
  ///
  /// The corresponding C property is `f_bsize`.
  @_alwaysEmitIntoClient
  public var blockSize: Int {
    get { Int(clamping: rawValue.f_bsize) }
    set { rawValue.f_bsize = .init(clamping: newValue) }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// Block size for optimal data transfer, in bytes.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_iosize`.
  @_alwaysEmitIntoClient
  public var preferredIOBlockSize: Int {
    get { Int(clamping: rawValue.f_iosize) }
    set { rawValue.f_iosize = .init(clamping: newValue) }
  }
  #else
  /// File system fragment size, in bytes.
  ///
  /// - Note: On Linux and Android, this is the fundamental size for block
  ///   counts. Not present on Darwin or BSD, which use `blockSize` instead.
  ///
  /// The corresponding C property is `f_frsize`.
  @_alwaysEmitIntoClient
  public var fragmentSize: Int {
    get { Int(clamping: rawValue.f_frsize) }
    set { rawValue.f_frsize = .init(clamping: newValue) }
  }
  #endif

  /// The fundamental block size used for space calculations, in bytes.
  ///
  /// This is `blockSize` on Darwin and BSD, or `fragmentSize` otherwise.
  @_alwaysEmitIntoClient
  internal var _fundamentalBlockSize: UInt64 {
    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    UInt64(clamping: rawValue.f_bsize)
    #else
    UInt64(clamping: rawValue.f_frsize)
    #endif
  }

  @_alwaysEmitIntoClient
  internal func _saturatingSpace(_ blocks: UInt64) -> UInt64 {
    let (result, overflow) = blocks.multipliedReportingOverflow(by: _fundamentalBlockSize)
    return overflow ? .max : result
  }

  /// Total number of blocks in the file system.
  ///
  /// - Note: In units of `blockSize` on Darwin and BSD, or `fragmentSize`
  ///   otherwise.
  ///
  /// The corresponding C property is `f_blocks`.
  @_alwaysEmitIntoClient
  public var totalBlocks: UInt64 {
    get { UInt64(clamping: rawValue.f_blocks) }
    set { rawValue.f_blocks = .init(clamping: newValue) }
  }

  /// Total size of the file system, in bytes.
  ///
  /// - Note: Computed for convenience as `totalBlocks` times the fundamental
  ///   block size (see `totalBlocks`). Saturates to `UInt64.max` on overflow.
  @_alwaysEmitIntoClient
  public var totalSpace: UInt64 { _saturatingSpace(totalBlocks) }

  /// Number of free blocks in the file system.
  ///
  /// - Note: In units of `blockSize` on Darwin and BSD, or `fragmentSize`
  ///   otherwise.
  ///
  /// The corresponding C property is `f_bfree`.
  @_alwaysEmitIntoClient
  public var freeBlocks: UInt64 {
    get { UInt64(clamping: rawValue.f_bfree) }
    set { rawValue.f_bfree = .init(clamping: newValue) }
  }

  /// Free space in the file system, in bytes.
  ///
  /// - Note: Computed for convenience as `freeBlocks` times the fundamental
  ///   block size (see `freeBlocks`). Saturates to `UInt64.max` on overflow.
  @_alwaysEmitIntoClient
  public var freeSpace: UInt64 { _saturatingSpace(freeBlocks) }

  /// Number of free blocks available to non-superuser.
  ///
  /// - Note: In units of `blockSize` on Darwin and BSD, or `fragmentSize`
  ///   otherwise. On FreeBSD and OpenBSD, the underlying C property is
  ///   signed; negative values are clamped to 0.
  ///
  /// The corresponding C property is `f_bavail`.
  @_alwaysEmitIntoClient
  public var availableBlocks: UInt64 {
    get { UInt64(clamping: rawValue.f_bavail) }
    set { rawValue.f_bavail = .init(clamping: newValue) }
  }

  /// Available space in the file system for non-superuser, in bytes.
  ///
  /// - Note: Computed for convenience as `availableBlocks` times the fundamental
  ///   block size (see `availableBlocks`). Saturates to `UInt64.max` on overflow.
  @_alwaysEmitIntoClient
  public var availableSpace: UInt64 { _saturatingSpace(availableBlocks) }

  /// Total number of inodes in the file system.
  ///
  /// The corresponding C property is `f_files`.
  @_alwaysEmitIntoClient
  public var totalInodes: UInt64 {
    get { UInt64(clamping: rawValue.f_files) }
    set { rawValue.f_files = .init(clamping: newValue) }
  }

  /// Number of free inodes in the file system.
  ///
  /// - Note: On FreeBSD, this reports the inodes available to a non-superuser
  ///   rather than the total free count, and the underlying C field is signed
  ///   (negative values are clamped to 0); on other platforms, it is the total
  ///   number of free inodes.
  ///
  /// The corresponding C property is `f_ffree`.
  @_alwaysEmitIntoClient
  public var freeInodes: UInt64 {
    get { UInt64(clamping: rawValue.f_ffree) }
    set { rawValue.f_ffree = .init(clamping: newValue) }
  }

  #if os(OpenBSD)
  /// Number of free inodes available to non-superuser.
  ///
  /// - Note: Darwin, FreeBSD, Linux, and Android `statfs` do not report it.
  ///   On OpenBSD, the underlying C property is signed; negative values are
  ///   clamped to 0.
  ///
  /// The corresponding C property is `f_favail`.
  @_alwaysEmitIntoClient
  public var availableInodes: UInt64 {
    get { UInt64(clamping: rawValue.f_favail) }
    set { rawValue.f_favail = .init(clamping: newValue) }
  }
  #endif

  #if !SYSTEM_PACKAGE_DARWIN
  /// Maximum length of a file name on the file system, in bytes.
  ///
  /// - Note: Darwin's `statfs` does not report it.
  ///
  /// The corresponding C property is `f_namelen` on Linux and Android, or
  /// `f_namemax` otherwise.
  @_alwaysEmitIntoClient
  public var maximumNameLength: Int {
    get {
      #if os(Linux) || os(Android)
      Int(clamping: rawValue.f_namelen)
      #else
      Int(clamping: rawValue.f_namemax)
      #endif
    }
    set {
      #if os(Linux) || os(Android)
      rawValue.f_namelen = .init(clamping: newValue)
      #else
      rawValue.f_namemax = .init(clamping: newValue)
      #endif
    }
  }
  #endif

  /// File system ID.
  ///
  /// The corresponding C property is `f_fsid`.
  @_alwaysEmitIntoClient
  public var fileSystemID: FileSystemID {
    get { FileSystemID(rawValue: rawValue.f_fsid) }
    set { rawValue.f_fsid = newValue.rawValue }
  }

  /// Flags describing how the file system is mounted.
  ///
  /// - Note: On Linux, the kernel also sets an `ST_VALID` bit in `f_flags`
  ///   to mark the field as filled in. It isn't a mount flag, so this
  ///   property omits it like glibc's `statvfs` and Bionic's `statfs` do.
  ///   The setter preserves it.
  ///
  /// The corresponding C property is `f_flags`.
  @_alwaysEmitIntoClient
  public var mountFlags: MountFlags {
    get {
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      MountFlags(rawValue: rawValue.f_flags)
      #elseif os(Linux) || os(Android)
      MountFlags(rawValue: CInterop.MountFlags(truncatingIfNeeded: rawValue.f_flags) & ~_ST_VALID_BIT)
      #endif
    }
    set {
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      rawValue.f_flags = newValue.rawValue
      #elseif os(Linux) || os(Android)
      let valid = CInterop.MountFlags(truncatingIfNeeded: rawValue.f_flags) & _ST_VALID_BIT
      rawValue.f_flags = .init(truncatingIfNeeded: newValue.rawValue | valid)
      #endif
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(Linux) || os(Android)
  /// File system type.
  ///
  /// - Note: On Linux and Android, this is the file system's magic number,
  ///   such as `0xEF53` for ext4. On Darwin and FreeBSD, it's an internal,
  ///   kernel-assigned VFS type index with no stable, public constants;
  ///   prefer `typeName` to identify the file system in a readable format.
  ///   Not available on OpenBSD.
  ///
  /// The corresponding C property is `f_type`.
  @_alwaysEmitIntoClient
  public var type: FileSystemType {
    get {
      #if os(Linux) || os(Android)
      // glibc's `f_type` is a signed `long` and can be negative.
      FileSystemType(rawValue: UInt32(truncatingIfNeeded: rawValue.f_type))
      #else
      FileSystemType(rawValue: rawValue.f_type)
      #endif
    }
    set {
      #if os(Linux) || os(Android)
      rawValue.f_type = .init(truncatingIfNeeded: newValue.rawValue)
      #else
      rawValue.f_type = newValue.rawValue
      #endif
    }
  }
  #endif

  #if SYSTEM_PACKAGE_DARWIN
  /// File system subtype.
  ///
  /// - Note: Like `type`, this is a numeric value with no stable, public
  ///   constants. Only available on Darwin.
  ///
  /// The corresponding C property is `f_fssubtype`.
  @_alwaysEmitIntoClient
  public var subtype: FileSystemSubtype {
    get { FileSystemSubtype(rawValue: rawValue.f_fssubtype) }
    set { rawValue.f_fssubtype = newValue.rawValue }
  }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// User that mounted the file system.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_owner`.
  @_alwaysEmitIntoClient
  public var owner: UserID {
    get { UserID(rawValue: rawValue.f_owner) }
    set { rawValue.f_owner = newValue.rawValue }
  }

  /// File system type name.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_fstypename`.
  @_alwaysEmitIntoClient
  public var typeName: String {
    withUnsafeBytes(of: rawValue.f_fstypename) {
      String(_nullTerminatedBytes: $0)
    }
  }

  /// Directory where the file system is mounted, such as "/System/Volumes/Data".
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_mntonname`.
  @_alwaysEmitIntoClient
  public var mountPoint: FilePath {
    withUnsafeBytes(of: rawValue.f_mntonname) {
      FilePath(_nullTerminatedBytes: $0)
    }
  }

  /// The source of the mounted file system, such as "/dev/disk3s7".
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C property is `f_mntfromname`.
  @_alwaysEmitIntoClient
  public var mountSource: FilePath {
    withUnsafeBytes(of: rawValue.f_mntfromname) {
      FilePath(_nullTerminatedBytes: $0)
    }
  }
  #endif
}

// MARK: - StatFS Equatable & Hashable

@available(System 199, *)
extension StatFS {
  /// Compares the file system metadata fields of two `StatFS` values,
  /// including fields not exposed as properties, such as `f_flags_ext` on
  /// Darwin.
  ///
  /// Fields are compared by their raw C values. Reserved/"spare" fields and
  /// OpenBSD's `mount_info` union are not compared. Name buffers are compared
  /// only up to their NUL terminators.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.rawValue.f_bsize == rhs.rawValue.f_bsize,
          lhs.rawValue.f_blocks == rhs.rawValue.f_blocks,
          lhs.rawValue.f_bfree == rhs.rawValue.f_bfree,
          lhs.rawValue.f_bavail == rhs.rawValue.f_bavail,
          lhs.rawValue.f_files == rhs.rawValue.f_files,
          lhs.rawValue.f_ffree == rhs.rawValue.f_ffree,
          lhs.fileSystemID == rhs.fileSystemID else {
      return false
    }

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    guard lhs.rawValue.f_iosize == rhs.rawValue.f_iosize,
          lhs.rawValue.f_flags == rhs.rawValue.f_flags,
          lhs.rawValue.f_owner == rhs.rawValue.f_owner,
          _nullTerminatedBytesEqual(lhs.rawValue.f_fstypename,
                                    rhs.rawValue.f_fstypename),
          _nullTerminatedBytesEqual(lhs.rawValue.f_mntonname,
                                    rhs.rawValue.f_mntonname),
          _nullTerminatedBytesEqual(lhs.rawValue.f_mntfromname,
                                    rhs.rawValue.f_mntfromname) else {
      return false
    }
    #elseif os(Linux) || os(Android)
    guard lhs.rawValue.f_type == rhs.rawValue.f_type,
          lhs.rawValue.f_frsize == rhs.rawValue.f_frsize,
          lhs.rawValue.f_flags == rhs.rawValue.f_flags,
          lhs.rawValue.f_namelen == rhs.rawValue.f_namelen else {
      return false
    }
    #endif

    #if SYSTEM_PACKAGE_DARWIN
    guard lhs.rawValue.f_type == rhs.rawValue.f_type,
          lhs.rawValue.f_fssubtype == rhs.rawValue.f_fssubtype,
          lhs.rawValue.f_flags_ext == rhs.rawValue.f_flags_ext else {
      return false
    }
    #elseif os(FreeBSD)
    guard lhs.rawValue.f_version == rhs.rawValue.f_version,
          lhs.rawValue.f_type == rhs.rawValue.f_type,
          lhs.rawValue.f_namemax == rhs.rawValue.f_namemax,
          lhs.rawValue.f_syncwrites == rhs.rawValue.f_syncwrites,
          lhs.rawValue.f_asyncwrites == rhs.rawValue.f_asyncwrites,
          lhs.rawValue.f_syncreads == rhs.rawValue.f_syncreads,
          lhs.rawValue.f_asyncreads == rhs.rawValue.f_asyncreads else {
      return false
    }
    #elseif os(OpenBSD)
    guard lhs.rawValue.f_favail == rhs.rawValue.f_favail,
          lhs.rawValue.f_namemax == rhs.rawValue.f_namemax,
          lhs.rawValue.f_syncwrites == rhs.rawValue.f_syncwrites,
          lhs.rawValue.f_syncreads == rhs.rawValue.f_syncreads,
          lhs.rawValue.f_asyncwrites == rhs.rawValue.f_asyncwrites,
          lhs.rawValue.f_asyncreads == rhs.rawValue.f_asyncreads,
          lhs.rawValue.f_ctime == rhs.rawValue.f_ctime,
          _nullTerminatedBytesEqual(lhs.rawValue.f_mntfromspec,
                                    rhs.rawValue.f_mntfromspec) else {
      return false
    }
    #endif

    return true
  }

  /// Hashes the file system metadata fields of a `StatFS` struct.
  ///
  /// These are the same fields compared by `==`. Reserved/"spare" fields are
  /// not hashed, and name buffers are hashed only up to their NUL terminators.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue.f_bsize)
    hasher.combine(rawValue.f_blocks)
    hasher.combine(rawValue.f_bfree)
    hasher.combine(rawValue.f_bavail)
    hasher.combine(rawValue.f_files)
    hasher.combine(rawValue.f_ffree)
    hasher.combine(fileSystemID)

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    hasher.combine(rawValue.f_iosize)
    hasher.combine(rawValue.f_flags)
    hasher.combine(rawValue.f_owner)
    Self._combineNullTerminatedBytes(rawValue.f_fstypename, into: &hasher)
    Self._combineNullTerminatedBytes(rawValue.f_mntonname, into: &hasher)
    Self._combineNullTerminatedBytes(rawValue.f_mntfromname, into: &hasher)
    #elseif os(Linux) || os(Android)
    hasher.combine(rawValue.f_type)
    hasher.combine(rawValue.f_frsize)
    hasher.combine(rawValue.f_flags)
    hasher.combine(rawValue.f_namelen)
    #endif

    #if SYSTEM_PACKAGE_DARWIN
    hasher.combine(rawValue.f_type)
    hasher.combine(rawValue.f_fssubtype)
    hasher.combine(rawValue.f_flags_ext)
    #elseif os(FreeBSD)
    hasher.combine(rawValue.f_version)
    hasher.combine(rawValue.f_type)
    hasher.combine(rawValue.f_namemax)
    hasher.combine(rawValue.f_syncwrites)
    hasher.combine(rawValue.f_asyncwrites)
    hasher.combine(rawValue.f_syncreads)
    hasher.combine(rawValue.f_asyncreads)
    #elseif os(OpenBSD)
    hasher.combine(rawValue.f_favail)
    hasher.combine(rawValue.f_namemax)
    hasher.combine(rawValue.f_syncwrites)
    hasher.combine(rawValue.f_syncreads)
    hasher.combine(rawValue.f_asyncwrites)
    hasher.combine(rawValue.f_asyncreads)
    hasher.combine(rawValue.f_ctime)
    Self._combineNullTerminatedBytes(rawValue.f_mntfromspec, into: &hasher)
    #endif
  }

  @inline(__always)
  private static func _nullTerminatedBytesEqual<T>(_ lhs: T, _ rhs: T) -> Bool {
    withUnsafeBytes(of: lhs) { lhsBytes in
      withUnsafeBytes(of: rhs) { rhsBytes in
        lhsBytes.prefix { $0 != 0 }.elementsEqual(rhsBytes.prefix { $0 != 0 })
      }
    }
  }

  // Feeds the length first so adjacent buffers can't run together.
  @inline(__always)
  private static func _combineNullTerminatedBytes<T>(
    _ value: T, into hasher: inout Hasher
  ) {
    withUnsafeBytes(of: value) { buffer in
      let bytes = buffer.prefix { $0 != 0 }
      hasher.combine(bytes.count)
      hasher.combine(bytes: .init(rebasing: bytes))
    }
  }
}

// MARK: - FileDescriptor Extensions

@available(System 199, *)
extension FileDescriptor {

  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FileDescriptor`.
  ///
  /// The corresponding C function is `fstatfs()`.
  @_alwaysEmitIntoClient
  public func statfs(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> StatFS {
    try StatFS(self, retryOnInterrupt: retryOnInterrupt)
  }
}

// MARK: - FilePath Extensions

@available(System 199, *)
extension FilePath {

  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FilePath`.
  ///
  /// The corresponding C function is `statfs()`.
  @_alwaysEmitIntoClient
  public func statfs(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> StatFS {
    try StatFS(self, retryOnInterrupt: retryOnInterrupt)
  }
}

#endif // !os(Windows) && !os(WASI)
