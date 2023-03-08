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

// - MARK: Commands

// TODO: Make below API as part of broader `fcntl` support.
extension FileDescriptor {
  /// Commands (and various constants) to pass to `fcntl`.
  internal struct Command: RawRepresentable, Hashable {
    internal let rawValue: CInt

    internal init(rawValue: CInt) { self.rawValue = rawValue }

    private init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Get open file description record locking information.
    ///
    /// The corresponding C constant is `F_GETLK`.
    internal static var getOFDLock: Command { Command(_F_OFD_GETLK) }

    /// Set open file description record locking information.
    ///
    /// The corresponding C constant is `F_SETLK`.
    internal static var setOFDLock: Command { Command(_F_OFD_SETLK) }

    /// Set open file description record locking information and wait until
    /// the request can be completed.
    ///
    /// The corresponding C constant is `F_SETLKW`.
    internal static var setOFDLockWait: Command { Command(_F_OFD_SETLKW) }

#if !os(Linux)
    /// Set open file description record locking information and wait until
    /// the request can be completed, returning on timeout.
    ///
    /// The corresponding C constant is `F_SETLKWTIMEOUT`.
    internal static var setOFDLockWaitTimout: Command {
      Command(_F_OFD_SETLKWTIMEOUT)
    }
#endif

  }
}
#endif
