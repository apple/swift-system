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
    public let rawValue: CInt

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
    public let rawValue: CInt

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
  // TODO: Flatten these out? Rename this somehow?
  @frozen
  public enum ControlTypes {
    /// TODO: preallocate description
    @frozen
    public struct Store: RawRepresentable, Sendable {
      @_alwaysEmitIntoClient
      public let rawValue: CInterop.FStore

      @_alwaysEmitIntoClient
      public init(rawValue: CInterop.FStore) { self.rawValue = rawValue }

      @frozen
      public struct Flags: OptionSet, Sendable {
        @_alwaysEmitIntoClient
        public let rawValue: UInt32

        @_alwaysEmitIntoClient
        public init(rawValue: UInt32) { self.rawValue = rawValue }
      }

      @frozen
      public struct PositionMode: RawRepresentable, Hashable, Sendable {
        @_alwaysEmitIntoClient
        public let rawValue: CInt

        @_alwaysEmitIntoClient
        public init(rawValue: CInt) { self.rawValue = rawValue }
      }
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

}

#endif // !os(Linux)

#endif // !os(Windows)
