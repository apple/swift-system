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

  /// Bind a name to a socket.
  ///
  /// The corresponding C function is `bind`.
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

  /// Accept a connection on a socket.
  ///
  /// The corresponding C function is `accept`.
  @_alwaysEmitIntoClient
  public func accept(retryOnInterrupt: Bool = true) throws -> SocketDescriptor {
    try _accept(retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _accept(
    retryOnInterrupt: Bool
  ) -> Result<SocketDescriptor, Errno> {
    let fd = valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      return system_accept(self.rawValue, nil, nil)
    }
    return fd.map { SocketDescriptor(rawValue: $0) }
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
  @_alwaysEmitIntoClient
  public func accept(
    client: inout SocketAddress,
    retryOnInterrupt: Bool = true
  ) throws -> SocketDescriptor {
    try _accept(client: &client, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _accept(
    client: inout SocketAddress,
    retryOnInterrupt: Bool
  ) -> Result<SocketDescriptor, Errno> {
    client._withMutableCInterop(entireCapacity: true) { adr, adrlen in
      let fd = valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        return system_accept(self.rawValue, adr, &adrlen)
      }
      return fd.map { SocketDescriptor(rawValue: $0) }
    }
  }

  /// Initiate a connection on a socket.
  ///
  /// The corresponding C function is `connect`.
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

  // MARK: - Send and receive

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

  /// Send a message from a socket.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory that contains the data being sent.
  ///   - recipient: The socket address of the recipient.
  ///   - flags: see `send(2)`
  ///   - retryOnInterrupt: Whether to retry the send operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were sent.
  ///
  /// The corresponding C function is `sendto`.
  @_alwaysEmitIntoClient
  public func send(
    _ buffer: UnsafeRawBufferPointer,
    to recipient: SocketAddress,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _send(
      buffer,
      to: recipient,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _send(
    _ buffer: UnsafeRawBufferPointer,
    to recipient: SocketAddress,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) throws -> Result<Int, Errno> {
    recipient.withUnsafeCInterop { adr, adrlen in
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_sendto(
          self.rawValue,
          buffer.baseAddress,
          buffer.count,
          flags.rawValue,
          adr,
          adrlen)
      }
    }
  }

  /// Send a message from a socket.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory that contains the data being sent.
  ///   - recipient: The socket address of the recipient.
  ///   - ancillary: A buffer of ancillary/control messages.
  ///   - flags: see `send(2)`
  ///   - retryOnInterrupt: Whether to retry the send operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were sent.
  ///
  /// The corresponding C function is `sendmsg`.
  @_alwaysEmitIntoClient
  public func send(
    _ bytes: UnsafeRawBufferPointer,
    to recipient: SocketAddress? = nil,
    ancillary: AncillaryMessageBuffer,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _send(
      bytes,
      to : recipient,
      ancillary: ancillary,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _send(
    _ bytes: UnsafeRawBufferPointer,
    to recipient: SocketAddress?,
    ancillary: AncillaryMessageBuffer?,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    recipient._withUnsafeBytesOrNull { recipient in
      ancillary._withUnsafeBytesOrNull { ancillary in
        var iov = CInterop.IOVec()
        iov.iov_base = UnsafeMutableRawPointer(mutating: bytes.baseAddress)
        iov.iov_len = bytes.count
        return withUnsafePointer(to: &iov) { iov in
          var m = CInterop.MsgHdr()
          m.msg_name = UnsafeMutableRawPointer(mutating: recipient.baseAddress)
          m.msg_namelen = UInt32(recipient.count)
          m.msg_iov = UnsafeMutablePointer(mutating: iov)
          m.msg_iovlen = 1
          m.msg_control = UnsafeMutableRawPointer(mutating: ancillary.baseAddress)
          m.msg_controllen = CInterop.SockLen(ancillary.count)
          m.msg_flags = 0
          return withUnsafePointer(to: &m) { message in
            _sendmsg(message, flags.rawValue,
                     retryOnInterrupt: retryOnInterrupt)
          }
        }
      }
    }
  }

  private func _sendmsg(
    _ message: UnsafePointer<CInterop.MsgHdr>,
    _ flags: CInt,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_sendmsg(self.rawValue, message, flags)
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

  /// Receive a message from a socket.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to receive into.
  ///   - flags: see `recv(2)`
  ///   - sender: A socket address with enough capacity to hold an
  ///      address for the current socket domain/type. On return, `receive`
  ///      overwrites the contents with the address of the remote client.
  ///   - retryOnInterrupt: Whether to retry the receive operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were received.
  ///
  /// The corresponding C function is `recvfrom`.
  @_alwaysEmitIntoClient
  public func receive(
    into buffer: UnsafeMutableRawBufferPointer,
    sender: inout SocketAddress,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _receive(
      into: buffer,
      sender: &sender,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _receive(
    into buffer: UnsafeMutableRawBufferPointer,
    sender: inout SocketAddress,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) throws -> Result<Int, Errno> {
    sender._withMutableCInterop(entireCapacity: true) { adr, adrlen in
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_recvfrom(
          self.rawValue,
          buffer.baseAddress,
          buffer.count,
          flags.rawValue,
          adr,
          &adrlen)
      }
    }
  }

  /// Receive a message from a socket.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to receive into.
  ///   - flags: see `recv(2)`
  ///   - ancillary: A buffer of ancillary messages. On return, `receive`
  ///      overwrites the contents with received ancillary messages (if any).
  ///   - retryOnInterrupt: Whether to retry the receive operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were received, and the flags that
  ///     describe the received message.
  ///
  /// The corresponding C function is `recvmsg`.
  @_alwaysEmitIntoClient
  public func receive(
    into bytes: UnsafeMutableRawBufferPointer,
    ancillary: inout AncillaryMessageBuffer,
    flags: MessageFlags = [],
    retryOnInterrupt: Bool = true
  ) throws -> (received: Int, flags: MessageFlags) {
    return try _receive(
      into: bytes,
      sender: nil,
      ancillary: &ancillary,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  /// Receive a message from a socket.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to receive into.
  ///   - flags: see `recv(2)`
  ///   - sender: A socket address with enough capacity to hold an
  ///      address for the current socket domain/type. On return, `receive`
  ///      overwrites the contents with the address of the remote client.
  ///   - ancillary: A buffer of ancillary messages. On return, `receive`
  ///      overwrites the contents with received ancillary messages (if any).
  ///   - retryOnInterrupt: Whether to retry the receive operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were received, and the flags that
  ///     describe the received message.
  ///
  /// The corresponding C function is `recvmsg`.
  @_alwaysEmitIntoClient
  public func receive(
    into bytes: UnsafeMutableRawBufferPointer,
    sender: inout SocketAddress,
    ancillary: inout AncillaryMessageBuffer,
    flags: MessageFlags = [],
    retryOnInterrupt: Bool = true
  ) throws -> (received: Int, flags: MessageFlags) {
    return try _receive(
      into: bytes,
      sender: &sender,
      ancillary: &ancillary,
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _receive(
    into bytes: UnsafeMutableRawBufferPointer,
    sender: UnsafeMutablePointer<SocketAddress>?,
    ancillary: UnsafeMutablePointer<AncillaryMessageBuffer>?,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<(Int, MessageFlags), Errno> {
    let result: Result<Int, Errno>
    let receivedFlags: CInt
    (result, receivedFlags) =
      sender._withMutableCInteropOrNull(entireCapacity: true) { adr, adrlen in
        ancillary._withMutableCInterop(entireCapacity: true) { anc, anclen in
          var iov = CInterop.IOVec()
          iov.iov_base = bytes.baseAddress
          iov.iov_len = bytes.count
          return withUnsafePointer(to: &iov) { iov in
            var m = CInterop.MsgHdr()
            m.msg_name = UnsafeMutableRawPointer(adr)
            m.msg_namelen = adrlen
            m.msg_iov = UnsafeMutablePointer(mutating: iov)
            m.msg_iovlen = 1
            m.msg_control = anc
            m.msg_controllen = anclen
            m.msg_flags = 0
            let result = withUnsafeMutablePointer(to: &m) { m in
              _recvmsg(m, flags.rawValue, retryOnInterrupt: retryOnInterrupt)
            }
            if case .failure = result {
              adrlen = 0
              anclen = 0
            } else {
              adrlen = m.msg_namelen
              anclen = m.msg_controllen
            }
            return (result, m.msg_flags)
          }
        }
      }
    return result.map { ($0, MessageFlags(rawValue: receivedFlags)) }
  }

  private func _recvmsg(
    _ message: UnsafeMutablePointer<CInterop.MsgHdr>,
    _ flags: CInt,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_recvmsg(self.rawValue, message, flags)
    }
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

// Optional mapper helpers, for use in setting up message header structs.
extension Optional where Wrapped == SocketDescriptor.AncillaryMessageBuffer {
  fileprivate func _withUnsafeBytesOrNull<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    guard let buffer = self else {
      return try body(UnsafeRawBufferPointer(start: nil, count: 0))
    }
    return try buffer._withUnsafeBytes(body)
  }
}

extension Optional where Wrapped == SocketAddress {
  fileprivate func _withUnsafeBytesOrNull<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    guard let address = self else {
      return try body(UnsafeRawBufferPointer(start: nil, count: 0))
    }
    return try address.withUnsafeBytes(body)
  }
}
extension Optional where Wrapped == UnsafeMutablePointer<SocketAddress> {
  fileprivate func _withMutableCInteropOrNull<R>(
    entireCapacity: Bool,
    _ body: (
      UnsafeMutablePointer<CInterop.SockAddr>?,
      inout CInterop.SockLen
    ) throws -> R
  ) rethrows -> R {
    guard let ptr = self else {
      var c: CInterop.SockLen = 0
      let result = try body(nil, &c)
      precondition(c == 0)
      return result
    }
    return try ptr.pointee._withMutableCInterop(
      entireCapacity: entireCapacity,
      body)
  }
}

extension Optional
where Wrapped == UnsafeMutablePointer<SocketDescriptor.AncillaryMessageBuffer>
{
  internal func _withMutableCInterop<R>(
    entireCapacity: Bool,
    _ body: (UnsafeMutableRawPointer?, inout CInterop.SockLen) throws -> R
  ) rethrows -> R {
    guard let buffer = self else {
      var length: CInterop.SockLen = 0
      let r = try body(nil, &length)
      precondition(length == 0)
      return r
    }
    return try buffer.pointee._withMutableCInterop(
      entireCapacity: entireCapacity,
      body
    )
  }
}
