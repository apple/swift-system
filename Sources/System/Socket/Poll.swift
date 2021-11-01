/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public extension FileDescriptor {
    
    /// Poll File Descriptor
    struct Poll {
        
        internal private(set) var bytes: CInterop.PollFileDescriptor
        
        internal init(_ bytes: CInterop.PollFileDescriptor) {
            self.bytes = bytes
        }
        
        // Initialize an events request.
        public init(fileDescriptor: FileDescriptor, events: FileEvents) {
            self.init(CInterop.PollFileDescriptor(fileDescriptor: fileDescriptor, events: events))
        }
        
        public var fileDescriptor: FileDescriptor {
            return FileDescriptor(rawValue: bytes.fd)
        }
        
        public var events: FileEvents {
            return FileEvents(rawValue: bytes.events)
        }
        
        public var returnedEvents: FileEvents {
            return FileEvents(rawValue: bytes.revents)
        }
    }
}

internal extension CInterop.PollFileDescriptor {
    
    init(fileDescriptor: FileDescriptor, events: FileEvents) {
        self.init(fd: fileDescriptor.rawValue, events: events.rawValue, revents: 0)
    }
}

// MARK: - Poll Operations

extension FileDescriptor {
    
    /// Wait for some event on a file descriptor.
    ///
    /// - Parameters:
    ///   - events: A bit mask specifying the events the application is interested in for the file descriptor.
    ///   - timeout: Specifies the minimum number of milliseconds that this method will block. Specifying a negative value in timeout means an infinite timeout. Specifying a timeout of zero causes this method to return immediately.
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: A bitmask filled by the kernel with the events that actually occurred.
    ///
    /// The corresponding C function is `poll`.
    public func poll(
        for events: FileEvents,
        timeout: Int = 0,
        retryOnInterrupt: Bool = true
    ) throws -> FileEvents {
        try _poll(
            events: events,
            timeout: CInt(timeout),
            retryOnInterrupt: retryOnInterrupt
        ).get()
    }
    
    /// `poll()`
    ///
    /// Wait for some event on a file descriptor.
    @usableFromInline
    internal func _poll(
        events: FileEvents,
        timeout: CInt,
        retryOnInterrupt: Bool
    ) -> Result<FileEvents, Errno> {
        var pollFD = CInterop.PollFileDescriptor(
            fd: self.rawValue,
            events: events.rawValue,
            revents: 0
        )
        return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_poll(&pollFD, 1, timeout)
        }.map { FileEvents(rawValue: events.rawValue) }
    }
}

extension FileDescriptor {
    
    /// wait for some event on file descriptors
    @usableFromInline
    internal static func _poll(
        _ pollFDs: inout [Poll],
        timeout: CInt,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        assert(pollFDs.isEmpty == false)
        let count = CInterop.FileDescriptorCount(pollFDs.count)
        return pollFDs.withUnsafeMutableBufferPointer { buffer in
            buffer.withMemoryRebound(to: CInterop.PollFileDescriptor.self) { cBuffer in
                nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
                    system_poll(
                        cBuffer.baseAddress!,
                        count,
                        timeout
                    )
                }
            }
        }
    }
}


extension Array where Element == FileDescriptor.Poll {
    
    /// Wait for some event on a set of file descriptors.
    ///
    /// - Parameters:
    ///   - fileDescriptors: An array of bit mask specifying the events the application is interested in for the file descriptors.
    ///   - timeout: Specifies the minimum number of milliseconds that this method will block. Specifying a negative value in timeout means an infinite timeout. Specifying a timeout of zero causes this method to return immediately.
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns:A array of bitmasks filled by the kernel with the events that actually occurred
    ///     for the corresponding file descriptors.
    ///
    /// The corresponding C function is `poll`.
    mutating func poll(
        timeout: Int = 0,
        retryOnInterrupt: Bool = true
    ) throws {
        guard isEmpty else { return }
        try FileDescriptor._poll(&self, timeout: CInt(timeout), retryOnInterrupt: retryOnInterrupt).get()
    }
}
