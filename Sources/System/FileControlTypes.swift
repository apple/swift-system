/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
import CSystem
#elseif os(Windows)
// Nothing
#else
#error("Unsupported Platform")
#endif

#if !os(Windows)

// MARK: - RawRepresentable wrappers
extension FileDescriptor {
  /// File descriptor flags.
  @frozen
  public struct Flags: OptionSet, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// The given file descriptor will be automatically closed in the
    /// successor process image when one of the execv(2) or posix_spawn(2)
    /// family of system calls is invoked.
    ///
    /// The corresponding C global is `FD_CLOEXEC`.
    @_alwaysEmitIntoClient
    public static var closeOnExec: Flags { Flags(rawValue: FD_CLOEXEC) }
  }

  /// File descriptor status flags.
  @frozen
  public struct StatusFlags: OptionSet, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    fileprivate init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Non-blocking I/O; if no data is available to a read
    /// call, or if a write operation would block, the read or
    /// write call throws `Errno.resourceTemporarilyUnavailable`.
    ///
    /// The corresponding C constant is `O_NONBLOCK`.
    @_alwaysEmitIntoClient
    public static var nonBlocking: StatusFlags { StatusFlags(O_NONBLOCK) }

    /// Force each write to append at the end of file; corre-
    /// sponds to `OpenOptions.append`.
    ///
    /// The corresponding C constant is `O_APPEND`.
    @_alwaysEmitIntoClient
    public static var append: StatusFlags { StatusFlags(O_APPEND) }

    /// Enable the SIGIO signal to be sent to the process
    /// group when I/O is possible, e.g., upon availability of
    /// data to be read.
    ///
    /// The corresponding C constant is `O_ASYNC`.
    @_alwaysEmitIntoClient
    public static var async: StatusFlags { StatusFlags(O_ASYNC) }
  }
}

#if !os(Linux)
extension FileDescriptor {
  /// Namespace for types used with `FileDescriptor.control`.
  @frozen
  public enum ControlTypes { }
}

extension FileDescriptor.ControlTypes {
  /// The corresponding C type is `fstore`.
  @frozen
  public struct Store: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.FStore

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.FStore) { self.rawValue = rawValue }

    @frozen
    public struct Flags: OptionSet, Sendable {
      @_alwaysEmitIntoClient
      public var rawValue: UInt32

      @_alwaysEmitIntoClient
      public init(rawValue: UInt32) { self.rawValue = rawValue }
    }

    @frozen
    public struct PositionMode: RawRepresentable, Hashable, Sendable {
      @_alwaysEmitIntoClient
      public var rawValue: CInt

      @_alwaysEmitIntoClient
      public init(rawValue: CInt) { self.rawValue = rawValue }
    }
  }

  /// The corresponding C type is `fpunchhole`
  @frozen
  public struct Punchhole: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.FPunchhole

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.FPunchhole) { self.rawValue = rawValue }

    @frozen
    public struct Flags: OptionSet, Sendable {
      @_alwaysEmitIntoClient
      public var rawValue: UInt32

      @_alwaysEmitIntoClient
      public init(rawValue: UInt32) { self.rawValue = rawValue }
    }
  }

  /// The corresponding C type is `radvisory`
  @frozen
  public struct ReadAdvisory: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.RAdvisory

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.RAdvisory) { self.rawValue = rawValue }
  }

  /// The corresponding C type is `log2phys`
  @frozen
  public struct LogicalToPhysical: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.Log2Phys

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.Log2Phys) { self.rawValue = rawValue }

    @frozen
    public struct Flags: OptionSet, Sendable {
      @_alwaysEmitIntoClient
      public let rawValue: UInt32

      @_alwaysEmitIntoClient
      public init(rawValue: UInt32) { self.rawValue = rawValue }
    }
  }
}

extension FileDescriptor.ControlTypes.Store.Flags {
  @_alwaysEmitIntoClient
  private init(_ rawSignedValue: Int32) {
    self.init(rawValue: UInt32(truncatingIfNeeded: rawSignedValue))
  }

  /// Allocate contiguous space. (Note that the file system may
  /// ignore this request if `length` is very large.)
  ///
  /// The corresponding C constant is `F_ALLOCATECONTIG`
  @_alwaysEmitIntoClient
  public var allocateContiguous: Self { .init(F_ALLOCATECONTIG) }

  /// Allocate all requested space or no space at all.
  ///
  /// The corresponding C constant is `F_ALLOCATEALL`
  @_alwaysEmitIntoClient
  public var allocateAllOrNone: Self { .init(F_ALLOCATEALL) }

  /// Allocate space that is not freed when close(2) is called.
  /// (Note that the file system may ignore this request.)
  ///
  /// The corresponding C constant is `F_ALLOCATEPERSIST`
  @_alwaysEmitIntoClient
  public var allocatePersist: Self { .init(F_ALLOCATEPERSIST) }
}

extension FileDescriptor.ControlTypes.Store.PositionMode {
  /// Allocate from the physical end of file.  In this case, `length`
  /// indicates the number of newly allocated bytes desired.
  ///
  /// The corresponding C constant is `F_PEOFPOSMODE`
  @_alwaysEmitIntoClient
  public var physicalEndOfFile: Self { .init(rawValue: F_PEOFPOSMODE) }

  /// Allocate from the volume offset.
  ///
  /// The corresponding C constant is `F_VOLPOSMODE`
  @_alwaysEmitIntoClient
  public var volumeOffset: Self { .init(rawValue: F_VOLPOSMODE) }
}

extension FileDescriptor.ControlTypes.Store {
  /// The corresponding C field is `fst_flags`
  @_alwaysEmitIntoClient
  public var flags: Flags {
    get { .init(rawValue: rawValue.fst_flags) }
    set { rawValue.fst_flags = newValue.rawValue }
  }

  /// Indicates mode for offset field
  ///
  /// The corresponding C field is `fst_posmode`
  @_alwaysEmitIntoClient
  public var positionMode: PositionMode {
    get { .init(rawValue: rawValue.fst_posmode) }
    set { rawValue.fst_posmode = newValue.rawValue }
  }

  /// Start of the region
  ///
  /// The corresponding C field is `fst_offset`
  @_alwaysEmitIntoClient
  public var offset: Int64 {
    get { .init(rawValue.fst_offset) }
    set { rawValue.fst_offset = CInterop.Offset(newValue) }
  }

  /// Size of the region
  ///
  /// The corresponding C field is `fst_length`
  @_alwaysEmitIntoClient
  public var length: Int64 {
    get { .init(rawValue.fst_length) }
    set { rawValue.fst_length = CInterop.Offset(newValue) }
  }

  /// Output: number of bytes allocated
  ///
  /// The corresponding C field is `fst_bytesalloc`
  @_alwaysEmitIntoClient
  public var bytesAllocated: Int64 {
    get { .init(rawValue.fst_bytesalloc) }
    set { rawValue.fst_bytesalloc = CInterop.Offset(newValue) }
  }
}

extension FileDescriptor.ControlTypes.Punchhole {
  /// The corresponding C field is `fp_flags`
  @_alwaysEmitIntoClient
  public var flags: Flags {
    get { .init(rawValue: rawValue.fp_flags) }
    set { rawValue.fp_flags = newValue.rawValue }
  }

  // No API for the reserved field

  /// Start of the region
  ///
  /// The corresponding C field is `fp_offset`
  @_alwaysEmitIntoClient
  public var offset: Int64 {
    get { .init(rawValue.fp_offset) }
    set { rawValue.fp_offset = CInterop.Offset(newValue) }
  }

  /// Size of the region
  ///
  /// The corresponding C field is `fp_length`
  @_alwaysEmitIntoClient
  public var length: Int64 {
    get { .init(rawValue.fp_length) }
    set { rawValue.fp_length = CInterop.Offset(newValue) }
  }
}

extension FileDescriptor.ControlTypes.ReadAdvisory {
  /// Offset into the file
  ///
  /// The corresponding C field is `ra_offset`
  @_alwaysEmitIntoClient
  public var offset: Int64 {
    get { .init(rawValue.ra_offset) }
    set { rawValue.ra_offset = CInterop.Offset(newValue) }
  }

  /// Size of the read
  ///
  /// The corresponding C field is `ra_count`
  @_alwaysEmitIntoClient
  public var count: Int {
    get { .init(rawValue.ra_count) }
    set { rawValue.ra_count = CInt(newValue) }
  }
}

extension FileDescriptor.ControlTypes.LogicalToPhysical {
  /// The corresponding C field is `l2p_flags`
  @_alwaysEmitIntoClient
  public var flags: Flags {
    get { .init(rawValue: rawValue.l2p_flags) }
    set { rawValue.l2p_flags = newValue.rawValue }
  }

  /// When used with `logicalToPhysicalExtended`:
  /// - In: number of bytes to be queried;
  /// - Out: number of contiguous bytes allocated at this position */
  ///
  /// The corresponding C field is `l2p_contigbytes`
  @_alwaysEmitIntoClient
  public var contiguousBytes: Int64 {
    get { .init(rawValue.l2p_contigbytes) }
    set { rawValue.l2p_contigbytes = CInterop.Offset(newValue) }
  }

  /// When used with `logicalToPhysical`, bytes into file.
  ///
  /// When used with `logicalToPhysicalExtended`:
  /// - In: bytes into file
  /// - Out: bytes into device
  ///
  /// The corresponding C field is `l2p_devoffset`
  @_alwaysEmitIntoClient
  public var deviceOffset: Int64 {
    get { .init(rawValue.l2p_devoffset) }
    set { rawValue.l2p_devoffset = CInterop.Offset(newValue) }
  }
}

#endif // !os(Linux)

#endif // !os(Windows)
