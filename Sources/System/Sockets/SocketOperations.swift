/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension SocketDescriptor {
  /// Create an endpoint for communication.
  ///
  /// - Parameters:
  ///    - domain: Select the protocol family which should be used for
  ///      communication
  ///    - type: Specify the semantics of communication
  ///    - protocol: Specify a particular protocol to use with the socket.
  ///      (Zero by default, which often indicates a wildcard value in
  ///      domain/type combinations that only support a single protocol,
  ///      such as TCP for IPv4/stream.)
  ///   - retryOnInterrupt: Whether to retry the open operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  ///
  /// The corresponding C function is `socket`
  @_alwaysEmitIntoClient
  public static func open(
    _ domain: Domain,
    _ type: ConnectionType,
    _ protocol: ProtocolID = ProtocolID(rawValue: 0),
    retryOnInterrupt: Bool = true
  ) throws -> SocketDescriptor {
    try SocketDescriptor._open(
      domain, type, `protocol`, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _open(
    _ domain: Domain,
    _ type: ConnectionType,
    _ protocol: ProtocolID,
    retryOnInterrupt: Bool
  ) -> Result<SocketDescriptor, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_socket(domain.rawValue, type: type.rawValue, protocol: `protocol`.rawValue)
    }.map(SocketDescriptor.init(rawValue:))
  }

  /// Shutdown part of a full-duplex connection
  ///
  /// The corresponding C function is `shutdown`
  @_alwaysEmitIntoClient
  public func shutdown(_ how: ShutdownKind) throws {
    try _shutdown(how).get()
  }

  @usableFromInline
  internal func _shutdown(_ how: ShutdownKind) -> Result<(), Errno> {
    nothingOrErrno(system_shutdown(self.rawValue, how.rawValue))
  }

  /// Listen for connections on a socket.
  ///
  /// Only applies to sockets of connection type `.stream`.
  ///
  /// - Parameters:
  ///   - backlog: the maximum length for the queue of pending connections
  ///
  /// The corresponding C function is `listen`.
  @_alwaysEmitIntoClient
  public func listen(backlog: Int) throws {
    try _listen(backlog: backlog).get()
  }

  @usableFromInline
  internal func _listen(backlog: Int) -> Result<(), Errno> {
    nothingOrErrno(system_listen(self.rawValue, CInt(backlog)))
  }

  /// Send a message from a socket
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
  /// The corresponding C function is `send`
  public func send(
    _ buffer: UnsafeRawBufferPointer,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _send(buffer, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
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

  /// Receive a message from a socket
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
  /// The corresponding C function is `recv`
  public func receive(
    into buffer: UnsafeMutableRawBufferPointer,
    flags: MessageFlags = .none,
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

  /// Accept a connection on a socket.
  ///
  /// The corresponding C function is `accept`.
  @_alwaysEmitIntoClient
  public func accept(retryOnInterrupt: Bool = true) throws -> SocketDescriptor {
    try _accept(nil, nil, retryOnInterrupt: retryOnInterrupt).get()
  }

  /// Accept a connection on a socket.
  ///
  /// The corresponding C function is `accept`.
  ///
  /// - Parameter client: A socket address with enough capacity to hold an
  ///    address for the current socket domain/type. On return, `accept`
  ///    overwrites the contents with the address of the remote client.
  ///
  ///    Having this as an inout parameter allows you to reuse the same address
  ///    value across multiple connections, without reallocating it.
  public func accept(
    client: inout SocketAddress,
    retryOnInterrupt: Bool = true
  ) throws -> SocketDescriptor {
    try client._withMutableCInterop(entireCapacity: true) { adr, adrlen in
      try _accept(adr, &adrlen, retryOnInterrupt: retryOnInterrupt).get()
    }
  }

  @usableFromInline
  internal func _accept(
    _ address: UnsafeMutablePointer<CInterop.SockAddr>?,
    _ addressLength: UnsafeMutablePointer<CInterop.SockLen>?,
    retryOnInterrupt: Bool = true
  ) -> Result<SocketDescriptor, Errno> {
    let fd = valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      return system_accept(self.rawValue, address, addressLength)
    }
    return fd.map { SocketDescriptor(rawValue: $0) }
  }

  // TODO: acceptAndSockaddr or something that (tries to) returns the sockaddr
  // at least, for sockaddrs up to some sane length

  /// Bind a name to a socket
  ///
  /// The corresponding C function is `bind`
  @_alwaysEmitIntoClient
  public func bind(to address: SocketAddress) throws {
    try _bind(to: address).get()
  }

  @usableFromInline
  internal func _bind(to address: SocketAddress) -> Result<(), Errno> {
    let success = address.withUnsafeCInterop { addr, len in
      system_bind(self.rawValue, addr, len)
    }
    return nothingOrErrno(success)
  }

  /// Initiate a connection on a socket
  ///
  /// The corresponding C function is `connect`
  @_alwaysEmitIntoClient
  public func connect(to address: SocketAddress) throws {
    try _connect(to: address).get()
  }

  @usableFromInline
  internal func _connect(to address: SocketAddress) -> Result<(), Errno> {
    let success = address.withUnsafeCInterop { addr, len in
      system_connect(self.rawValue, addr, len)
    }
    return nothingOrErrno(success)
  }

}

// MARK: - Forward FileDescriptor methods
extension SocketDescriptor {
  /// Deletes a socket's file descriptor.
  ///
  /// This is equivalent to calling `fileDescriptor.close()`
  @_alwaysEmitIntoClient
  public func close() throws { try fileDescriptor.close() }

  /// Reads bytes from a socket.
  ///
  /// This is equivalent to calling `fileDescriptor.read(into:retryOnInterrupt:)`
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to read into.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were read.
  ///
  /// The corresponding C function is `read`.
  @_alwaysEmitIntoClient
  public func read(
    into buffer: UnsafeMutableRawBufferPointer, retryOnInterrupt: Bool = true
  ) throws -> Int {
    try fileDescriptor.read(into: buffer, retryOnInterrupt: retryOnInterrupt)
  }

  /// Writes the contents of a buffer to the socket.
  ///
  /// This is equivalent to `fileDescriptor.write(_:retryOnInterrupt:)`
  ///
  /// - Parameters:
  ///   - buffer: The region of memory that contains the data being written.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were written.
  ///
  /// After writing,
  /// this method increments the file's offset by the number of bytes written.
  /// To change the file's offset,
  /// call the ``seek(offset:from:)`` method.
  ///
  /// The corresponding C function is `write`.
  @_alwaysEmitIntoClient
  public func write(
    _ buffer: UnsafeRawBufferPointer, retryOnInterrupt: Bool = true
  ) throws -> Int {
    try fileDescriptor.write(buffer, retryOnInterrupt: retryOnInterrupt)
  }
}
