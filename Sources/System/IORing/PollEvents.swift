/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if compiler(>=6.2) && $Lifetimes
#if os(Linux)
extension IORing.Request {
    /// A set of I/O events that can be monitored on a file descriptor.
    ///
    /// `PollEvents` represents the event mask used with io_uring poll
    /// operations to specify which I/O conditions to monitor on a file
    /// descriptor. These events correspond to the standard POSIX poll events
    /// defined in the kernel's `poll.h` header.
    ///
    /// Use `PollEvents` with
    /// ``IORing/Request/pollAdd(_:pollEvents:isMultiShot:context:)`` to
    /// register interest in specific I/O events. The poll operation completes
    /// when any of the specified events become active on the file descriptor.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Monitor a socket for incoming data
    /// let request = IORing.Request.pollAdd(
    ///     socketFD,
    ///     pollEvents: .pollIn,
    ///     isMultiShot: true
    /// )
    /// ```
    public struct PollEvents: OptionSet, Hashable, Codable, CaseIterable {
        public var rawValue: UInt32

        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        @usableFromInline
        init(_ event: Event) {
            self.rawValue = event.rawValue
        }

        @usableFromInline
        enum Event: UInt32, RawRepresentable, Hashable, CaseIterable {
            case pollIn = 0x0001
            case pollOut = 0x0004
            case pollErr = 0x0008
            case pollHup = 0x0010
            case pollNval = 0x0020
        }

        public static var allCases: [PollEvents] {
            Event.allCases.map(PollEvents.init(_:))
        }

        /// An event indicating data is available for reading.
        ///
        /// This event becomes active when data arrives on the file descriptor
        /// and can be read without blocking. For sockets, this includes when
        /// a new connection is available on a listening socket. Corresponds
        /// to the POSIX `POLLIN` event flag.
        @inlinable
        public static var pollIn: PollEvents { PollEvents(.pollIn) }

        /// An event indicating the file descriptor is ready for writing.
        ///
        /// This event becomes active when writing to the file descriptor will
        /// not block. For sockets, this indicates that send buffer space is
        /// available. Corresponds to the POSIX `POLLOUT` event flag.
        @inlinable
        public static var pollOut: PollEvents { PollEvents(.pollOut) }

        /// An event indicating an error condition on the file descriptor.
        ///
        /// The kernel reports this event whether or not it was requested, so
        /// it can appear in a completion's result mask even when the poll
        /// asked only for ``pollIn`` or ``pollOut``. Requesting it explicitly
        /// has no effect. Corresponds to the POSIX `POLLERR` event flag.
        @_alwaysEmitIntoClient
        public static var pollErr: PollEvents { PollEvents(.pollErr) }

        /// An event indicating the peer closed its end of the channel.
        ///
        /// For a pipe this means the writing end was closed; for a socket, that
        /// the connection was shut down. A descriptor reporting this event will
        /// never become readable again, so treating it as "not ready yet" and
        /// polling again will not make progress.
        ///
        /// The kernel reports this event whether or not it was requested, and
        /// requesting it explicitly has no effect. Corresponds to the POSIX
        /// `POLLHUP` event flag.
        @_alwaysEmitIntoClient
        public static var pollHup: PollEvents { PollEvents(.pollHup) }

        /// An event indicating that the object a descriptor refers to is no
        /// longer valid.
        ///
        /// This arises when the descriptor itself resolves, but the thing it
        /// refers to has since become invalid. For example, the disconnection
        /// of a sound device could cause this event.
        ///
        /// Note that a descriptor which simply does not resolve would
        /// return the EBADF error code (Errno.badFileDescriptor).
        ///
        /// The kernel reports this event whether or not it was requested, and
        /// requesting it explicitly has no effect. Corresponds to the POSIX
        /// `POLLNVAL` event flag.
        @_alwaysEmitIntoClient
        public static var pollNval: PollEvents { PollEvents(.pollNval) }
    }
}
#endif
#endif
