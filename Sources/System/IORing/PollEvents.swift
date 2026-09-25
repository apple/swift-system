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
    /// `PollEvents` represents the event mask used with `io_uring` poll
    /// operations to specify which I/O conditions to monitor on a file
    /// descriptor. These events correspond to the standard POSIX poll events
    /// defined in the kernel's `poll.h` header.
    ///
    /// Use `PollEvents` with
    /// ``IORing/Request/pollAdd(_:events:isMultiShot:context:)`` to
    /// register interest in specific I/O events. The poll operation completes
    /// when any of the specified events become active on the file descriptor.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Monitor a socket for incoming data
    /// let request = IORing.Request.pollAdd(
    ///     socketFD,
    ///     events: .readable,
    ///     isMultiShot: true
    /// )
    /// ```
    public struct PollEvents: OptionSet, Hashable, Codable {
        public let rawValue: UInt32

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
            case readable = 0x0001
            case priorityData = 0x0002
            case writable = 0x0004
            case error = 0x0008
            case hangUp = 0x0010
            case invalidDescriptor = 0x0020
            case peerClosed = 0x2000
        }

        /// An event indicating data is available for reading.
        ///
        /// This event becomes active when data arrives on the file descriptor
        /// and can be read without blocking. For sockets, this includes when
        /// a new connection is available on a listening socket. Corresponds
        /// to the POSIX `POLLIN` event flag.
        @inlinable
        public static var readable: PollEvents { PollEvents(.readable) }

        /// An event indicating out-of-band data is available for reading.
        ///
        /// For sockets this signals urgent data; it is also used to report
        /// exceptional conditions on descriptors that have no other way to
        /// signal them, such as a `sysfs` attribute that has changed value.
        /// Corresponds to the POSIX `POLLPRI` event flag.
        @inlinable
        public static var priorityData: PollEvents { PollEvents(.priorityData) }

        /// An event indicating the file descriptor is ready for writing.
        ///
        /// This event becomes active when writing to the file descriptor will
        /// not block. For sockets, this indicates that send buffer space is
        /// available. Corresponds to the POSIX `POLLOUT` event flag.
        @inlinable
        public static var writable: PollEvents { PollEvents(.writable) }

        /// An event indicating an error condition on the file descriptor.
        ///
        /// The kernel reports this event whether or not it was requested, so
        /// it can appear in a completion's result mask even when the poll
        /// asked only for ``readable`` or ``writable``. Requesting it
        /// explicitly has no effect. Corresponds to the POSIX `POLLERR` event
        /// flag.
        @inlinable
        public static var error: PollEvents { PollEvents(.error) }

        /// An event indicating the peer closed its end of the channel.
        ///
        /// For a pipe this means the writing end was closed; for a socket, that
        /// the connection was shut down.
        ///
        /// The kernel reports this event whether or not it was requested, and
        /// requesting it explicitly has no effect. Corresponds to the POSIX
        /// `POLLHUP` event flag.
        public static var hangUp: PollEvents { PollEvents(.hangUp) }

        /// An event indicating that the object a descriptor refers to is no
        /// longer valid.
        ///
        /// This arises when the descriptor itself resolves, but the thing it
        /// refers to has since become invalid. For example, the disconnection
        /// of a sound device could cause this event.
        ///
        /// A descriptor that doesn't resolve at all would make the request
        /// fail with ``Errno/badFileDescriptor`` instead.
        ///
        /// The kernel reports this event whether or not it was requested, and
        /// requesting it explicitly has no effect. Corresponds to the POSIX
        /// `POLLNVAL` event flag.
        @inlinable
        public static var invalidDescriptor: PollEvents {
            PollEvents(.invalidDescriptor)
        }

        /// An event indicating the peer closed its writing end of a stream
        /// socket, or shut it down for writing.
        ///
        /// Unlike ``hangUp``, this event can arrive while the connection is
        /// still half-open: data already in flight can still be read, and the
        /// local end can still write. Once both directions are shut down,
        /// ``hangUp`` is reported alongside this event.
        ///
        /// Unlike `poll(2)`, `io_uring` reports this event whether or not it
        /// was requested, and requesting it explicitly has no effect.
        /// Corresponds to the Linux `POLLRDHUP` event flag.
        @inlinable
        public static var peerClosed: PollEvents { PollEvents(.peerClosed) }
    }
}
#endif
#endif
