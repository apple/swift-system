/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if compiler(>=6.2) && $Lifetimes
#if os(Linux)
extension IORing.Request {
    /// A set of I/O events that can be monitored on a file descriptor.
    ///
    /// `PollEvents` represents the event mask used with io_uring poll operations to specify
    /// which I/O conditions to monitor on a file descriptor. These events correspond to the
    /// standard Posix poll events defined in the kernel's `poll.h` header.
    ///
    /// Use `PollEvents` with ``IORing/Request/pollAdd(_:pollEvents:isMultiShot:context:)``
    /// to register interest in specific I/O events. The poll operation completes when any of
    /// the specified events become active on the file descriptor.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Monitor a socket for incoming data
    /// let request = IORing.Request.pollAdd(
    ///     socketFD,
    ///     pollEvents: .pollin,
    ///     isMultiShot: true
    /// )
    /// ```
    public struct PollEvents: OptionSet, Hashable, Codable {
        public var rawValue: UInt32

        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        /// An event indicating data is available for reading.
        ///
        /// This event becomes active when data arrives on the file descriptor and can be read
        /// without blocking. For sockets, this includes when a new connection is available on
        /// a listening socket. Corresponds to the Posix `POLLIN` event flag.
        @inlinable
        public static var pollIn: PollEvents { PollEvents(rawValue: 0x0001) }

        /// An event indicating the file descriptor is ready for writing.
        ///
        /// This event becomes active when writing to the file descriptor will not block. For
        /// sockets, this indicates that send buffer space is available. Corresponds to the
        /// Posix `POLLOUT` event flag.
        @inlinable
        public static var pollOut: PollEvents { PollEvents(rawValue: 0x0004) }
    }
}
#endif
#endif
