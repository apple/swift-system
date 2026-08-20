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

/// A Swift wrapper of the C `statfs` struct on Darwin and BSD operating
/// systems, or the standard `statvfs` otherwise.
///
/// - Note: Only available on Unix-like platforms.
@available(Windows, unavailable, message: "StatFS is unavailable on Windows. Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
public struct StatFS {}

extension FileDescriptor {
  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FileDescriptor`.
  @available(Windows, unavailable, message: "StatFS is unavailable on Windows. Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
  public func statfs(retryOnInterrupt: Bool = true) throws(Errno) -> StatFS {
    fatalError("StatFS is unavailable on Windows")
  }
}

extension FilePath {
  /// Creates a `StatFS` for the file system containing the file referenced by
  /// this `FilePath`.
  @available(Windows, unavailable, message: "StatFS is unavailable on Windows. Consider using a Win32 API such as GetVolumeInformationW or GetDiskFreeSpaceExW instead.")
  public func statfs(retryOnInterrupt: Bool = true) throws(Errno) -> StatFS {
    fatalError("StatFS is unavailable on Windows")
  }
}

#else

// Must import here to use C statfs/statvfs properties in
// @_alwaysEmitIntoClient APIs.
#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif canImport(WASILibc)
import CSystem
import WASILibc
#elseif canImport(Android)
import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

// MARK: - FileSystemID

/// A Swift wrapper of the C `f_fsid` file system ID found in a `statfs` or
/// `statvfs` struct.
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

// On Darwin, FreeBSD, and OpenBSD, `CInterop.FileSystemID` is the C `fsid_t`
// struct (a fixed two-element `int32_t` array), which provides no synthesized
// conformances. Implement `Equatable`, `Hashable`, and `Codable` manually in
// terms of the underlying `val` members. On other platforms, the raw value is
// an integer, so the conformances are derived automatically.
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
@available(System 199, *)
extension FileSystemID: Equatable {
  @_alwaysEmitIntoClient
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue.val.0 == rhs.rawValue.val.0 && lhs.rawValue.val.1 == rhs.rawValue.val.1
  }
}

@available(System 199, *)
extension FileSystemID: Hashable {
  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue.val.0)
    hasher.combine(rawValue.val.1)
  }
}

@available(System 199, *)
extension FileSystemID: Codable {
  @_alwaysEmitIntoClient
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(rawValue.val.0)
    try container.encode(rawValue.val.1)
  }

  @_alwaysEmitIntoClient
  public init(from decoder: any Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let val0 = try container.decode(Int32.self)
    let val1 = try container.decode(Int32.self)
    self.init(rawValue: CInterop.FileSystemID(val: (val0, val1)))
  }
}
#else
@available(System 199, *)
extension FileSystemID: Equatable, Hashable, Codable {}
#endif

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
// MARK: - FileSystemType

/// A Swift wrapper of the C `f_type` file system type found in a `statfs`
/// struct on Darwin and FreeBSD.
///
/// - Note: Only available on Darwin and FreeBSD.
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
#endif

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

/// A Swift wrapper of the C `statfs` struct on Darwin and BSD operating
/// systems, or the standard `statvfs` otherwise.
///
/// - Note: Only available on Unix-like platforms.
/// - Note: The numeric properties clamp to the range of the underlying C
///   field in both directions. Use `rawValue` for exact, unclamped access.
@frozen
@available(System 199, *)
public struct StatFS: RawRepresentable, Sendable, Hashable {

  /// The raw C `statfs` struct on Darwin and BSD, or the `statvfs` struct
  /// otherwise.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.StatFS

  /// Creates a Swift `StatFS` from the raw C struct.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.StatFS) { self.rawValue = rawValue }

  // MARK: Initializers

  /// Creates a `StatFS` from a `FilePath`.
  ///
  /// The corresponding C function is `statfs()` on Darwin and BSD, or
  /// `statvfs()` otherwise.
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
  /// The corresponding C function is `statfs()` on Darwin and BSD, or
  /// `statvfs()` otherwise.
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
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      system_statfs(path, &result)
      #else
      system_statvfs(path, &result)
      #endif
    }.map { result }
  }

  /// Creates a `StatFS` from a `FileDescriptor`.
  ///
  /// The corresponding C function is `fstatfs()` on Darwin and BSD, or
  /// `fstatvfs()` otherwise.
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
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      system_fstatfs(fd.rawValue, &result)
      #else
      system_fstatvfs(fd.rawValue, &result)
      #endif
    }.map { result }
  }

  // MARK: Properties

  /// File system block size, in bytes.
  ///
  /// The corresponding C property is `f_bsize`.
  /// - Note: On Darwin and BSD, this is the fundamental size for block counts.
  ///   `statvfs` platforms use `fragmentSize` (`f_frsize`) instead.
  @_alwaysEmitIntoClient
  public var blockSize: Int {
    get { Int(clamping: rawValue.f_bsize) }
    set { rawValue.f_bsize = .init(clamping: newValue) }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// Block size for optimal data transfer, in bytes.
  ///
  /// The corresponding C property is `f_iosize`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public var preferredIOBlockSize: Int {
    get { Int(clamping: rawValue.f_iosize) }
    set { rawValue.f_iosize = .init(clamping: newValue) }
  }
  #else
  /// File system fragment size, in bytes.
  ///
  /// The corresponding C property is `f_frsize`.
  /// - Note: On `statvfs` platforms, this is the fundamental size for block
  ///   counts. Not present on Darwin or BSD, which use `blockSize` instead.
  @_alwaysEmitIntoClient
  public var fragmentSize: Int {
    get { Int(clamping: rawValue.f_frsize) }
    set { rawValue.f_frsize = .init(clamping: newValue) }
  }
  #endif

  /// The fundamental block size used for space calculations, in bytes.
  ///
  /// This is `blockSize` on Darwin and BSD (`statfs`), or `fragmentSize`
  /// otherwise (`statvfs`).
  @_alwaysEmitIntoClient
  internal var _fundamentalBlockSize: UInt64 {
    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    UInt64(clamping: rawValue.f_bsize)
    #else
    UInt64(clamping: rawValue.f_frsize)
    #endif
  }

  /// Multiplies a block count by the fundamental block size, saturating to
  /// `UInt64.max` on overflow.
  @_alwaysEmitIntoClient
  internal func _saturatingSpace(_ blocks: UInt64) -> UInt64 {
    let (result, overflow) = blocks.multipliedReportingOverflow(by: _fundamentalBlockSize)
    return overflow ? .max : result
  }

  /// Total number of blocks in the file system.
  ///
  /// The corresponding C property is `f_blocks`.
  /// - Note: In units of `blockSize` on Darwin and BSD (`statfs`), or
  ///   `fragmentSize` otherwise (`statvfs`).
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
  /// The corresponding C property is `f_bfree`.
  /// - Note: In units of `blockSize` on Darwin and BSD (`statfs`), or
  ///   `fragmentSize` otherwise (`statvfs`).
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
  /// The corresponding C property is `f_bavail`.
  /// - Note: In units of `blockSize` on Darwin and BSD (`statfs`), or
  ///   `fragmentSize` otherwise (`statvfs`). On FreeBSD and OpenBSD, the
  ///   underlying C property is signed; negative values are clamped to 0.
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
  /// The corresponding C property is `f_ffree`.
  /// - Note: On FreeBSD, this reports the inodes available to a non-superuser
  ///   rather than the total free count, and the underlying C field is signed
  ///   (negative values are clamped to 0); on other platforms, it is the total
  ///   number of free inodes.
  @_alwaysEmitIntoClient
  public var freeInodes: UInt64 {
    get { UInt64(clamping: rawValue.f_ffree) }
    set { rawValue.f_ffree = .init(clamping: newValue) }
  }

  #if !SYSTEM_PACKAGE_DARWIN && !os(FreeBSD)
  /// Number of free inodes available to non-superuser.
  ///
  /// The corresponding C property is `f_favail`, reported on the `statvfs`
  /// platforms and by OpenBSD's `statfs`.
  /// - Note: Darwin and FreeBSD `statfs` do not report it. On OpenBSD, the
  ///   underlying C property is signed; negative values are clamped to 0.
  @_alwaysEmitIntoClient
  public var availableInodes: UInt64 {
    get { UInt64(clamping: rawValue.f_favail) }
    set { rawValue.f_favail = .init(clamping: newValue) }
  }
  #endif

  #if !SYSTEM_PACKAGE_DARWIN
  /// Maximum length of a file name on the file system, in bytes.
  ///
  /// The corresponding C property is `f_namemax`, reported on the `statvfs`
  /// platforms and by FreeBSD and OpenBSD `statfs`.
  /// - Note: Darwin's `statfs` does not report it.
  @_alwaysEmitIntoClient
  public var maximumNameLength: Int {
    get { Int(clamping: rawValue.f_namemax) }
    set { rawValue.f_namemax = .init(clamping: newValue) }
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

  /// Mount flags indicating the options employed when mounting the file system.
  ///
  /// The corresponding C property is `f_flags` on Darwin and BSD, or `f_flag`
  /// otherwise.
  @_alwaysEmitIntoClient
  public var mountFlags: MountFlags {
    get {
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      MountFlags(rawValue: rawValue.f_flags)
      #else
      MountFlags(rawValue: rawValue.f_flag)
      #endif
    }
    set {
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      rawValue.f_flags = newValue.rawValue
      #else
      rawValue.f_flag = newValue.rawValue
      #endif
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// File system type.
  ///
  /// The corresponding C property is `f_type`.
  /// - Note: Only available on Darwin and FreeBSD, where this is an internal,
  ///   kernel-assigned VFS type index with no stable, public constants; it is
  ///   *not* a filesystem magic number like those found in the Linux `statfs`.
  ///   Prefer `typeName` to identify the file system in a readable format.
  @_alwaysEmitIntoClient
  public var type: FileSystemType {
    get { FileSystemType(rawValue: numericCast(rawValue.f_type)) }
    set { rawValue.f_type = numericCast(newValue.rawValue) }
  }
  #endif

  #if SYSTEM_PACKAGE_DARWIN
  /// File system subtype.
  ///
  /// The corresponding C property is `f_fssubtype`.
  /// - Note: Like `type`, this is a numeric value with no stable, public
  ///   constants. Only available on Darwin.
  @_alwaysEmitIntoClient
  public var subtype: FileSystemSubtype {
    get { FileSystemSubtype(rawValue: numericCast(rawValue.f_fssubtype)) }
    set { rawValue.f_fssubtype = numericCast(newValue.rawValue) }
  }
  #endif

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// User that mounted the file system.
  ///
  /// The corresponding C property is `f_owner`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public var owner: UserID {
    get { UserID(rawValue: rawValue.f_owner) }
    set { rawValue.f_owner = newValue.rawValue }
  }

  /// File system type name.
  ///
  /// The corresponding C property is `f_fstypename`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public var typeName: String {
    withUnsafeBytes(of: rawValue.f_fstypename) {
      String(_nullTerminatedBytes: $0)
    }
  }

  /// Directory where the file system is mounted, such as "/System/Volumes/Data".
  ///
  /// The corresponding C property is `f_mntonname`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public var mountPoint: FilePath {
    withUnsafeBytes(of: rawValue.f_mntonname) {
      FilePath(_nullTerminatedBytes: $0)
    }
  }

  /// The source of the mounted file system, such as "/dev/disk3s7".
  ///
  /// The corresponding C property is `f_mntfromname`.
  /// - Note: Only available on Darwin and BSD.
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
  /// Compares the meaningful file-system metadata fields of two `StatFS` values.
  ///
  /// Reserved/"spare" fields are not compared, and name buffers are compared
  /// only up to their NUL terminators.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.blockSize == rhs.blockSize,
          lhs.totalBlocks == rhs.totalBlocks,
          lhs.freeBlocks == rhs.freeBlocks,
          lhs.availableBlocks == rhs.availableBlocks,
          lhs.totalInodes == rhs.totalInodes,
          lhs.freeInodes == rhs.freeInodes,
          lhs.fileSystemID == rhs.fileSystemID,
          lhs.mountFlags == rhs.mountFlags else {
      return false
    }

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    guard lhs.preferredIOBlockSize == rhs.preferredIOBlockSize else {
      return false
    }
    #else
    guard lhs.fragmentSize == rhs.fragmentSize else {
      return false
    }
    #endif

    #if !SYSTEM_PACKAGE_DARWIN && !os(FreeBSD)
    guard lhs.availableInodes == rhs.availableInodes else {
      return false
    }
    #endif

    #if !SYSTEM_PACKAGE_DARWIN
    guard lhs.maximumNameLength == rhs.maximumNameLength else {
      return false
    }
    #endif

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    guard lhs.type == rhs.type else {
      return false
    }
    #endif

    #if SYSTEM_PACKAGE_DARWIN
    guard lhs.subtype == rhs.subtype else {
      return false
    }
    #endif

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    guard lhs.owner == rhs.owner,
          _nullTerminatedBytesEqual(lhs.rawValue.f_fstypename,
                                    rhs.rawValue.f_fstypename),
          _nullTerminatedBytesEqual(lhs.rawValue.f_mntonname,
                                    rhs.rawValue.f_mntonname),
          _nullTerminatedBytesEqual(lhs.rawValue.f_mntfromname,
                                    rhs.rawValue.f_mntfromname) else {
      return false
    }
    #endif

    return true
  }

  /// Hashes the meaningful file-system metadata fields of a `StatFS` struct.
  ///
  /// These are the same fields compared by `==`. Reserved/"spare" fields are
  /// not hashed, and name buffers are hashed only up to their NUL terminators.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(blockSize)
    hasher.combine(totalBlocks)
    hasher.combine(freeBlocks)
    hasher.combine(availableBlocks)
    hasher.combine(totalInodes)
    hasher.combine(freeInodes)
    hasher.combine(fileSystemID)
    hasher.combine(mountFlags)

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    hasher.combine(preferredIOBlockSize)
    #else
    hasher.combine(fragmentSize)
    #endif

    #if !SYSTEM_PACKAGE_DARWIN && !os(FreeBSD)
    hasher.combine(availableInodes)
    #endif

    #if !SYSTEM_PACKAGE_DARWIN
    hasher.combine(maximumNameLength)
    #endif

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    hasher.combine(type)
    #endif

    #if SYSTEM_PACKAGE_DARWIN
    hasher.combine(subtype)
    #endif

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    hasher.combine(owner)
    Self._combineNullTerminatedBytes(rawValue.f_fstypename, into: &hasher)
    Self._combineNullTerminatedBytes(rawValue.f_mntonname, into: &hasher)
    Self._combineNullTerminatedBytes(rawValue.f_mntfromname, into: &hasher)
    #endif
  }

  // Compares two fixed-size, NUL-terminated C character buffers (such as
  // `f_mntonname`) up to their first NUL terminator.
  @inline(__always)
  private static func _nullTerminatedBytesEqual<T>(_ lhs: T, _ rhs: T) -> Bool {
    withUnsafeBytes(of: lhs) { lhsBytes in
      withUnsafeBytes(of: rhs) { rhsBytes in
        lhsBytes.prefix { $0 != 0 }.elementsEqual(rhsBytes.prefix { $0 != 0 })
      }
    }
  }

  // Hashes a fixed-size, NUL-terminated C character buffer (such as
  // `f_mntonname`) up to its first NUL terminator.
  @inline(__always)
  private static func _combineNullTerminatedBytes<T>(
    _ value: T, into hasher: inout Hasher
  ) {
    withUnsafeBytes(of: value) { buffer in
      let bytes = buffer.prefix { $0 != 0 }
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
  /// The corresponding C function is `fstatfs()` on Darwin and BSD, or
  /// `fstatvfs()` otherwise.
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
  /// The corresponding C function is `statfs()` on Darwin and BSD, or
  /// `statvfs()` otherwise.
  @_alwaysEmitIntoClient
  public func statfs(
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> StatFS {
    try StatFS(self, retryOnInterrupt: retryOnInterrupt)
  }
}

#endif // !os(Windows)
