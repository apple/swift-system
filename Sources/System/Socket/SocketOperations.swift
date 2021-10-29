/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension FileDescriptor {
    
    /// Creates an endpoint for communication and returns a descriptor.
    ///
    /// - Parameters:
    ///   - protocolID: The protocol which will be used for communication.
    ///   - retryOnInterrupt: Whether to retry the read operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The file descriptor of the opened socket.
    ///
    @_alwaysEmitIntoClient
    public static func socket<T: SocketProtocol>(
        _ protocolID: T,
        retryOnInterrupt: Bool = true
    ) throws -> FileDescriptor {
        try _socket(T.family, type: protocolID.type.rawValue, protocol: protocolID.rawValue, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    #if os(Linux)
    /// Creates an endpoint for communication and returns a descriptor.
    ///
    /// - Parameters:
    ///   - protocolID: The protocol which will be used for communication.
    ///   - flags: Flags to set when opening the socket.
    ///   - retryOnInterrupt: Whether to retry the read operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The file descriptor of the opened socket.
    ///
    @_alwaysEmitIntoClient
    public static func socket<T: SocketProtocol>(
        _ protocolID: T,
        flags: SocketFlags,
        retryOnInterrupt: Bool = true
    ) throws -> FileDescriptor {
        try _socket(T.family, type: protocolID.type.rawValue | flags.rawValue, protocol: protocolID.rawValue, retryOnInterrupt: retryOnInterrupt).get()
    }
    #endif
    
    @usableFromInline
    internal static func _socket(
        _ family: SocketAddressFamily,
        type: CInt,
        protocol protocolID: Int32,
        retryOnInterrupt: Bool
    ) -> Result<FileDescriptor, Errno> {
        valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_socket(family.rawValue, type, protocolID)
        }.map(FileDescriptor.init(socket:))
    }
    
    /// Creates an endpoint for communication and returns a descriptor.
    ///
    /// - Parameters:
    ///   - protocolID: The protocol which will be used for communication.
    ///   - flags: Flags to set when opening the socket.
    ///   - retryOnInterrupt: Whether to retry the read operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The file descriptor of the opened socket.
    ///
    @_alwaysEmitIntoClient
    public static func socket<Address: SocketAddress>(
        _ protocolID: Address.ProtocolID,
        bind address: Address,
        retryOnInterrupt: Bool = true
    ) throws -> FileDescriptor {
        return try _socket(
            address: address,
            type: protocolID.type.rawValue,
            protocol: protocolID.rawValue,
            retryOnInterrupt: retryOnInterrupt
        ).get()
    }
    
    #if os(Linux)
    /// Creates an endpoint for communication and returns a descriptor.
    ///
    /// - Parameters:
    ///   - protocolID: The protocol which will be used for communication.
    ///   - flags: Flags to set when opening the socket.
    ///   - retryOnInterrupt: Whether to retry the read operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The file descriptor of the opened socket.
    ///
    @_alwaysEmitIntoClient
    public static func socket<Address: SocketAddress>(
        _ protocolID: Address.ProtocolID,
        bind address: Address,
        flags: SocketFlags,
        retryOnInterrupt: Bool = true
    ) throws -> FileDescriptor {
        return try _socket(
            address: address,
            type: protocolID.type.rawValue | flags.rawValue,
            protocol: protocolID.rawValue,
            retryOnInterrupt: retryOnInterrupt
        ).get()
    }
    #endif
    
    @usableFromInline
    internal static func _socket<Address: SocketAddress>(
        address: Address,
        type: CInt,
        protocol protocolID: Int32,
        retryOnInterrupt: Bool
    ) -> Result<FileDescriptor, Errno> {
        return _socket(
            Address.family,
            type: type,
            protocol: protocolID,
            retryOnInterrupt: retryOnInterrupt
        )._closeIfThrows { fileDescriptor in
            fileDescriptor
                ._bind(address, retryOnInterrupt: retryOnInterrupt)
                .map { fileDescriptor }
        }
    }
    
    /// Assigns the address specified to the socket referred to by the file descriptor.
    ///
    ///  - Parameter address: Specifies the address to bind the socket.
    ///  - Parameter retryOnInterrupt: Whether to retry the open operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    ///
    /// The corresponding C function is `bind`.
    @_alwaysEmitIntoClient
    public func bind<Address: SocketAddress>(
        _ address: Address,
        retryOnInterrupt: Bool = true
    ) throws {
        try _bind(address, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    @usableFromInline
    internal func _bind<T: SocketAddress>(
        _ address: T,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            address.withUnsafePointer { (addressPointer, length) in
                system_bind(T.family.rawValue, addressPointer, length)
            }
        }
    }
    
    /// Set the option specified for the socket associated with the file descriptor.
    ///
    ///  - Parameter option: Socket option value to set.
    ///  - Parameter retryOnInterrupt: Whether to retry the open operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    ///
    /// The method corresponds to the C function `setsockopt`.
    @_alwaysEmitIntoClient
    public func setSocketOption<T: SocketOption>(
        _ option: T,
        retryOnInterrupt: Bool = true
    ) throws {
        try _setSocketOption(option, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    @usableFromInline
    internal func _setSocketOption<T: SocketOption>(
        _ option: T,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            option.withUnsafeBytes { bufferPointer in
                system_setsockopt(self.rawValue, T.ID.optionLevel.rawValue, T.id.rawValue, bufferPointer.baseAddress!, UInt32(bufferPointer.count))
            }
        }
    }
    
    ///  Retrieve the value associated with the option specified for the socket associated with the file descriptor.
    ///
    ///  - Parameter option: Type of `SocketOption` to retrieve.
    ///  - Parameter retryOnInterrupt: Whether to retry the open operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    ///
    /// The method corresponds to the C function `getsockopt`.
    @_alwaysEmitIntoClient
    public func getSocketOption<T: SocketOption>(
        _ option: T.Type,
        retryOnInterrupt: Bool = true
    ) throws -> T {
        return try _getSocketOption(option, retryOnInterrupt: retryOnInterrupt)
    }
    
    @usableFromInline
    internal func _getSocketOption<T: SocketOption>(
        _ option: T.Type,
        retryOnInterrupt: Bool
    ) throws -> T {
        return try T.withUnsafeBytes { bufferPointer in
            var length = UInt32(bufferPointer.count)
            guard system_getsockopt(self.rawValue, T.ID.optionLevel.rawValue, T.id.rawValue, bufferPointer.baseAddress!, &length) != -1 else {
                throw Errno.current
            }
        }
    }
    
    /// Send a message from a socket.
    ///
    /// - Parameters:
    ///   - buffer: The region of memory that contains the data being sent.
    ///   - flags: see `send(2)`
    ///   - retryOnInterrupt: Whether to retry the send operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The number of bytes that were sent.
    ///
    /// The corresponding C function is `send`.
    @_alwaysEmitIntoClient
    public func send(
      _ buffer: UnsafeRawBufferPointer,
      flags: MessageFlags = [],
      retryOnInterrupt: Bool = true
    ) throws -> Int {
      try _send(buffer, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// Send a message from a socket.
    ///
    /// - Parameters:
    ///   - data: The sequence of bytes being sent.
    ///   - address: Address of destination client.
    ///   - flags: see `send(2)`
    ///   - retryOnInterrupt: Whether to retry the send operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The number of bytes that were sent.
    ///
    /// The corresponding C function is `send`.
    public func send<Data>(
        _ data: Data,
        flags: MessageFlags = [],
        retryOnInterrupt: Bool = true
    ) throws -> Int where Data: Sequence, Data.Element == UInt8 {
        try data._withRawBufferPointer { dataPointer in
            _send(dataPointer, flags: flags, retryOnInterrupt: retryOnInterrupt)
        }.get()
    }

    @usableFromInline
    internal func _send(
      _ buffer: UnsafeRawBufferPointer,
      flags: MessageFlags,
      retryOnInterrupt: Bool
    ) -> Result<Int, Errno> {
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_send(self.rawValue, buffer.baseAddress!, buffer.count, flags.rawValue)
      }
    }
    
    /// Send a message from a socket.
    ///
    /// - Parameters:
    ///   - buffer: The region of memory that contains the data being sent.
    ///   - address: Address of destination client.
    ///   - flags: see `send(2)`
    ///   - retryOnInterrupt: Whether to retry the send operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The number of bytes that were sent.
    ///
    /// The corresponding C function is `send`.
    @_alwaysEmitIntoClient
    public func send<Address: SocketAddress>(
        _ buffer: UnsafeRawBufferPointer,
        to address: Address,
        flags: MessageFlags = [],
        retryOnInterrupt: Bool = true
    ) throws -> Int {
        try _send(buffer, to: address, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// Send a message from a socket.
    ///
    /// - Parameters:
    ///   - data: The sequence of bytes being sent.
    ///   - address: Address of destination client.
    ///   - flags: see `send(2)`
    ///   - retryOnInterrupt: Whether to retry the send operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The number of bytes that were sent.
    ///
    /// The corresponding C function is `send`.
    public func send<Address, Data>(
        _ data: Data,
        to address: Address,
        flags: MessageFlags = [],
        retryOnInterrupt: Bool = true
    ) throws -> Int where Address: SocketAddress, Data: Sequence, Data.Element == UInt8 {
        try data._withRawBufferPointer { dataPointer in
            _send(dataPointer, to: address, flags: flags, retryOnInterrupt: retryOnInterrupt)
        }.get()
    }
    
    /// `send()`
    @usableFromInline
    internal func _send<T: SocketAddress>(
        _ data: UnsafeRawBufferPointer,
        to address: T,
        flags: MessageFlags,
        retryOnInterrupt: Bool
    ) -> Result<Int, Errno> {
        valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            address.withUnsafePointer { (addressPointer, addressLength) in
                system_sendto(self.rawValue, data.baseAddress, data.count, flags.rawValue, addressPointer, addressLength)
            }
        }
    }
    
    /// Receive a message from a socket.
    ///
    /// - Parameters:
    ///   - buffer: The region of memory to receive into.
    ///   - flags: see `recv(2)`
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The number of bytes that were received.
    ///
    /// The corresponding C function is `recv`.
    @_alwaysEmitIntoClient
    public func receive(
      into buffer: UnsafeMutableRawBufferPointer,
      flags: MessageFlags = [],
      retryOnInterrupt: Bool = true
    ) throws -> Int {
      try _receive(
        into: buffer, flags: flags, retryOnInterrupt: retryOnInterrupt
      ).get()
    }

    @usableFromInline
    internal func _receive(
      into buffer: UnsafeMutableRawBufferPointer,
      flags: MessageFlags,
      retryOnInterrupt: Bool
    ) -> Result<Int, Errno> {
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_recv(self.rawValue, buffer.baseAddress!, buffer.count, flags.rawValue)
      }
    }
    
    @usableFromInline
    internal func _recieve(
        _ dataBuffer: UnsafeMutableRawBufferPointer,
        flags: MessageFlags,
        retryOnInterrupt: Bool
    ) -> Result<Int, Errno> {
        valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_recv(self.rawValue, dataBuffer.baseAddress, dataBuffer.count, flags.rawValue)
        }
    }
    /*
    @usableFromInline
    internal func _recieve<Address: SocketAddress>(
        _ dataBuffer: UnsafeMutableRawBufferPointer,
        from address: Address,
        flags: MessageFlags,
        retryOnInterrupt: Bool
    ) -> Result<Int, Errno> {
        valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            address.withUnsafePointer { (addressPointer, addressLength) in
                var addressLength = addressLength
                system_recvfrom(self.rawValue, dataBuffer.baseAddress, dataBuffer.count, flags.rawValue, addressPointer, &addressLength)
            }
        }
    }*/
    
    /// Listen for connections on a socket.
    ///
    /// Only applies to sockets of connection type `.stream`.
    ///
    /// - Parameters:
    ///   - backlog: the maximum length for the queue of pending connections
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    ///
    /// The corresponding C function is `listen`.
    @_alwaysEmitIntoClient
    public func listen(
        backlog: Int,
        retryOnInterrupt: Bool = true
    ) throws {
        try _listen(backlog: Int32(backlog), retryOnInterrupt: retryOnInterrupt).get()
    }
    
    @usableFromInline
    internal func _listen(
        backlog: Int32,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_listen(self.rawValue, backlog)
        }
    }
    
    /// Accept a connection on a socket.
    ///
    /// - Parameters:
    ///   - address: The type of the `SocketAddress` expected for the new connection.
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: A tuple containing the file descriptor and address of the new connection.
    ///
    /// The corresponding C function is `accept`.
    @_alwaysEmitIntoClient
    public func accept<Address: SocketAddress>(
        _ address: Address.Type,
        retryOnInterrupt: Bool = true
    ) throws -> (FileDescriptor, Address) {
        return try _accept(Address.self, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    @usableFromInline
    internal func _accept<Address: SocketAddress>(
        _ address: Address.Type,
        retryOnInterrupt: Bool
    ) -> Result<(FileDescriptor, Address), Errno> {
        var result: Result<CInt, Errno> = .success(0)
        let address = Address.withUnsafePointer { socketPointer, socketLength in
            var length = socketLength
            result = valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
                system_accept(self.rawValue, socketPointer, &length)
            }
        }
        return result.map { (FileDescriptor(socket: $0), address) }
    }
    
    /// Accept a connection on a socket.
    ///
    /// - Parameters:
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The file descriptor of the new connection.
    ///
    /// The corresponding C function is `accept`.
    @_alwaysEmitIntoClient
    public func accept(
        retryOnInterrupt: Bool = true
    ) throws -> FileDescriptor {
        return try _accept(retryOnInterrupt: retryOnInterrupt).get()
    }
    
    @usableFromInline
    internal func _accept(
        retryOnInterrupt: Bool
    ) -> Result<FileDescriptor, Errno> {
        var length: UInt32 = 0
        return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_accept(self.rawValue, nil, &length)
        }.map(FileDescriptor.init(socket:))
    }
    
    /// Initiate a connection on a socket.
    ///
    /// - Parameters:
    ///   - address: The peer address.
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns: The file descriptor of the new connection.
    ///
    /// The corresponding C function is `connect`.
    @_alwaysEmitIntoClient
    public func connect<Address: SocketAddress>(
        to address: Address,
        retryOnInterrupt: Bool = true
    ) throws {
        try _connect(to: address, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// The `connect()` function shall attempt to make a connection on a socket.
    @usableFromInline
    internal func _connect<Address: SocketAddress>(
        to address: Address,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            address.withUnsafePointer { (addressPointer, addressLength) in
                system_connect(self.rawValue, addressPointer, addressLength)
            }
        }
    }
    
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
    @_alwaysEmitIntoClient
    public static func poll(
        _ fileDescriptors: [(FileDescriptor, FileEvents)],
        timeout: Int = 0,
        retryOnInterrupt: Bool = true
    ) throws -> [(FileDescriptor, FileEvents)] {
        try _poll(fileDescriptors, timeout: CInt(timeout), retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// wait for some event on file descriptors
    @usableFromInline
    internal static func _poll(
        _ fileDescriptors: [(FileDescriptor, FileEvents)],
        timeout: CInt,
        retryOnInterrupt: Bool
    ) -> Result<[(FileDescriptor, FileEvents)], Errno> {
        var pollFDs = fileDescriptors.map {
                CInterop.PollFileDescriptor(
                    fd: $0.0.rawValue,
                    events: $0.1.rawValue,
                    revents: 0
                )
            }
        return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_poll(&pollFDs, CInterop.FileDescriptorCount(pollFDs.count), timeout)
        }.map { pollFDs.map { (FileDescriptor(rawValue: $0.fd), FileEvents(rawValue: $0.revents)) } }
    }
    
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

extension Sequence where Element == FileDescriptor {
    
    /// Wait for some event on a set of file descriptors.
    ///
    /// - Parameters:
    ///   - events: A bit mask specifying the events the application is interested in for the file descriptors.
    ///   - timeout: Specifies the minimum number of milliseconds that this method will block. Specifying a negative value in timeout means an infinite timeout. Specifying a timeout of zero causes this method to return immediately.
    ///   - retryOnInterrupt: Whether to retry the receive operation
    ///     if it throws ``Errno/interrupted``.
    ///     The default is `true`.
    ///     Pass `false` to try only once and throw an error upon interruption.
    /// - Returns:A array of bitmasks filled by the kernel with the events that actually occurred
    ///     for the corresponding file descriptors.
    ///
    /// The corresponding C function is `poll`.
    @_alwaysEmitIntoClient
    public func poll(
        for events: FileEvents,
        timeout: Int = 0,
        retryOnInterrupt: Bool = true
    ) throws -> [(FileDescriptor, FileEvents)] {
        try FileDescriptor._poll(
            self.map { ($0, events) },
            timeout: CInt(timeout),
            retryOnInterrupt: retryOnInterrupt
        ).get()
    }
}
