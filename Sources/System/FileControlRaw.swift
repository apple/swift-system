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
#elseif os(Windows)
// Nothing
#else
#error("Unsupported Platform")
#endif


#if !os(Windows)

extension FileDescriptor {
  /// A namespace for types and values for `FileDescriptor.control()`, aka `fcntl`.
  ///
  /// TODO: a better name? "Internals", "Raw", "FCNTL"? I feel like a
  /// precedent would be useful for sysctl, ioctl, and other grab-bag
  /// things. "junk drawer" can be an anti-pattern, but is better than
  /// trashing the higher namespace.
  //  public
  internal enum Control {}

}
// - MARK: Commands

extension FileDescriptor.Control {
  /// Commands (and various constants) to pass to `fcntl`.
  //  @frozen
  //  public
  internal struct Command: RawRepresentable, Hashable {
//    @_alwaysEmitIntoClient
//    public
    internal let rawValue: CInt

//    @_alwaysEmitIntoClient
//    public
    internal init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }
    /// Get open file description record locking information.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.isLocked() or something like that
    ///
    /// The corresponding C constant is `F_GETLK`.
//    @_alwaysEmitIntoClient
//    public
    internal static var getOFDLock: Command { Command(_F_OFD_GETLK) }

    /// Set open file description record locking information.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.lock()
    ///
    /// The corresponding C constant is `F_SETLK`.
//    @_alwaysEmitIntoClient
//    public
    internal static var setOFDLock: Command { Command(_F_OFD_SETLK) }

    /// Set open file description record locking information and wait until
    /// the request can be completed.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.lock()
    ///
    /// The corresponding C constant is `F_SETLKW`.
//    @_alwaysEmitIntoClient
//    public
    internal static var setOFDLockWait: Command { Command(_F_OFD_SETLKW) }

#if !os(Linux)
    /// Set open file description record locking information and wait until
    /// the request can be completed, returning on timeout.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.lock()
    ///
    /// The corresponding C constant is `F_SETLKWTIMEOUT`.
//    @_alwaysEmitIntoClient
//    public
    internal static var setOFDLockWaitTimout: Command {
      Command(_F_OFD_SETLKWTIMEOUT)
    }
#endif

  }
}
#endif
