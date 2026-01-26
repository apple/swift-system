/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import SystemPackage

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

// MARK: - Socket Creation and Lifecycle

@available(System 99, *)
extension SocketDescriptor {
  /// Creates an endpoint for communication.
  ///
  /// - Parameters:
  ///   - domain: The protocol family for communication.
  ///   - type: The semantics of communication.
  ///   - protocol: The particular protocol to use. The default is `.default`,
  ///     which typically selects the appropriate protocol for the domain/type
  ///     combination (e.g., TCP for IPv4/stream).
  ///   - retryOnInterrupt: Whether to retry if interrupted. The default is `true`.
  /// - Returns: A new socket descriptor.
  ///
  /// The corresponding C function is `socket`.
  @_alwaysEmitIntoClient
  public static func open(
    _ domain: Domain,
    _ type: ConnectionType,
    protocol: ProtocolID = .default,
    retryOnInterrupt: Bool = true
  ) throws -> SocketDescriptor {
    try _open(domain, type, protocol: `protocol`, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal static func _open(
    _ domain: Domain,
    _ type: ConnectionType,
    protocol: ProtocolID,
    retryOnInterrupt: Bool
  ) -> Result<SocketDescriptor, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_socket(domain.rawValue, type.rawValue, `protocol`.rawValue)
    }.map(SocketDescriptor.init(rawValue:))
  }

  /// Closes the socket.
  ///
  /// The corresponding C function is `close`.
  @_alwaysEmitIntoClient
  public func close() throws {
    try _close().get()
  }

  @usableFromInline
  internal func _close() -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_close(self.rawValue)
    }
  }

  /// Shuts down part of a full-duplex connection.
  ///
  /// - Parameter how: Which parts of the connection to shut down.
  ///
  /// The corresponding C function is `shutdown`.
  @_alwaysEmitIntoClient
  public func shutdown(_ how: ShutdownKind) throws {
    try _shutdown(how).get()
  }

  @usableFromInline
  internal func _shutdown(_ how: ShutdownKind) -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_shutdown(self.rawValue, how.rawValue)
    }
  }
}

// MARK: - Connection Operations

@available(System 99, *)
extension SocketDescriptor {
  /// Binds a socket to an address.
  ///
  /// - Parameter address: The socket address to bind to.
  ///
  /// The corresponding C function is `bind`.
  @_alwaysEmitIntoClient
  public func bind(to address: SocketAddress) throws {
    try _bind(to: address).get()
  }

  @usableFromInline
  internal func _bind(to address: SocketAddress) -> Result<(), Errno> {
    address.withUnsafePointer { addr, len in
      nothingOrErrno(retryOnInterrupt: false) {
        system_bind(self.rawValue, addr, len)
      }
    }
  }

  /// Listens for connections on the socket.
  ///
  /// Only applies to sockets of type `.stream`.
  ///
  /// - Parameter backlog: The maximum length of the pending connections queue.
  ///
  /// The corresponding C function is `listen`.
  @_alwaysEmitIntoClient
  public func listen(backlog: Int) throws {
    try _listen(backlog: backlog).get()
  }

  @usableFromInline
  internal func _listen(backlog: Int) -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_listen(self.rawValue, CInt(backlog))
    }
  }

  /// Accepts a connection on the socket.
  ///
  /// - Parameter retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: A new socket descriptor for the accepted connection.
  ///
  /// The corresponding C function is `accept`.
  @_alwaysEmitIntoClient
  public func accept(retryOnInterrupt: Bool = true) throws -> SocketDescriptor {
    try _accept(retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _accept(retryOnInterrupt: Bool) -> Result<SocketDescriptor, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_accept(self.rawValue, nil, nil)
    }.map(SocketDescriptor.init(rawValue:))
  }

  /// Accepts a connection and returns the client's address.
  ///
  /// - Parameters:
  ///   - client: A socket address buffer to receive the client's address.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: A new socket descriptor for the accepted connection.
  ///
  /// The corresponding C function is `accept`.
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
    client._withUnsafeMutablePointer { addr, len in
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_accept(self.rawValue, addr, &len)
      }.map(SocketDescriptor.init(rawValue:))
    }
  }

  /// Initiates a connection on the socket.
  ///
  /// - Parameter address: The address to connect to.
  ///
  /// The corresponding C function is `connect`.
  @_alwaysEmitIntoClient
  public func connect(to address: SocketAddress) throws {
    try _connect(to: address).get()
  }

  @usableFromInline
  internal func _connect(to address: SocketAddress) -> Result<(), Errno> {
    address.withUnsafePointer { addr, len in
      nothingOrErrno(retryOnInterrupt: false) {
        system_connect(self.rawValue, addr, len)
      }
    }
  }
}

// MARK: - Send and Receive

@available(System 99, *)
extension SocketDescriptor {
  @usableFromInline
  internal func _send(
    _ buffer: UnsafeRawBufferPointer,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_send(self.rawValue, buffer.baseAddress, buffer.count, flags.rawValue)
    }
  }

  /// Sends data on the socket.
  ///
  /// - Parameters:
  ///   - data: The data to send.
  ///   - flags: Message flags.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: The number of bytes sent.
  ///
  /// The corresponding C function is `send`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func send(
    _ data: RawSpan,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    try data.withUnsafeBytes { bytes throws(Errno) -> Int in
      try _send(bytes, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
    }
  }

  @usableFromInline
  internal func _receive(
    into buffer: UnsafeMutableRawBufferPointer,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_recv(self.rawValue, buffer.baseAddress, buffer.count, flags.rawValue)
    }
  }

  /// Receives data from the socket.
  ///
  /// - Parameters:
  ///   - buffer: The buffer to receive data into.
  ///   - flags: Message flags.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: The number of bytes received.
  ///
  /// After receiving,
  /// this method sets the buffer's initialized count to the number of bytes received.
  ///
  /// The corresponding C function is `recv`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func receive(
    into buffer: inout OutputRawSpan,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    try buffer.withUnsafeMutableBytes { buf, count throws(Errno) -> Int in
      let bytesRead = try _receive(into: buf, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
      count = bytesRead
      return bytesRead
    }
  }

  @usableFromInline
  internal func _send(
    _ buffer: UnsafeRawBufferPointer,
    to address: SocketAddress,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    address.withUnsafePointer { addr, addrlen in
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_sendto(
          self.rawValue,
          buffer.baseAddress,
          buffer.count,
          flags.rawValue,
          addr,
          addrlen
        )
      }
    }
  }

  /// Sends data to a specific address.
  ///
  /// - Parameters:
  ///   - data: The data to send.
  ///   - address: The destination address.
  ///   - flags: Message flags.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: The number of bytes sent.
  ///
  /// The corresponding C function is `sendto`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func send(
    _ data: RawSpan,
    to address: SocketAddress,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    try data.withUnsafeBytes { bytes throws(Errno) -> Int in
      try _send(bytes, to: address, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
    }
  }

  @usableFromInline
  internal func _receive(
    into buffer: UnsafeMutableRawBufferPointer,
    sender: inout SocketAddress,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    sender._withUnsafeMutablePointer { addr, len in
      valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_recvfrom(
          self.rawValue,
          buffer.baseAddress,
          buffer.count,
          flags.rawValue,
          addr,
          &len
        )
      }
    }
  }

  /// Receives data and returns the sender's address.
  ///
  /// - Parameters:
  ///   - buffer: The buffer to receive data into.
  ///   - sender: A buffer to receive the sender's address.
  ///   - flags: Message flags.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: The number of bytes received.
  ///
  /// After receiving,
  /// this method sets the buffer's initialized count to the number of bytes received.
  ///
  /// The corresponding C function is `recvfrom`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func receive(
    into buffer: inout OutputRawSpan,
    sender: inout SocketAddress,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    try buffer.withUnsafeMutableBytes { buf, count throws(Errno) -> Int in
      let bytesRead = try _receive(into: buf, sender: &sender, flags: flags, retryOnInterrupt: retryOnInterrupt).get()
      count = bytesRead
      return bytesRead
    }
  }
}

// MARK: - Message-based Send and Receive

@available(System 99, *)
extension SocketDescriptor {
  /// Sends a message with optional ancillary data.
  ///
  /// - Parameters:
  ///   - data: The data to send.
  ///   - ancillaryMessages: Optional ancillary (control) messages to send.
  ///   - address: Optional destination address (for datagram sockets).
  ///   - flags: Message flags.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: The number of bytes sent.
  ///
  /// The corresponding C function is `sendmsg`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func sendMessage(
    _ data: RawSpan,
    ancillaryMessages: AncillaryMessageBuffer? = nil,
    to address: SocketAddress? = nil,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    try data.withUnsafeBytes { bytes throws(Errno) -> Int in
      try _sendMessage(
        bytes,
        ancillaryMessages: ancillaryMessages,
        to: address,
        flags: flags,
        retryOnInterrupt: retryOnInterrupt
      ).get()
    }
  }

  @usableFromInline
  internal func _sendMessage(
    _ buffer: UnsafeRawBufferPointer,
    ancillaryMessages: AncillaryMessageBuffer?,
    to address: SocketAddress?,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    var iov = CInterop.IOVec(
      iov_base: UnsafeMutableRawPointer(mutating: buffer.baseAddress),
      iov_len: buffer.count
    )

    var msg = CInterop.MsgHdr()
    msg.msg_iov = withUnsafeMutablePointer(to: &iov) { $0 }
    msg.msg_iovlen = 1

    func doSend(address: SocketAddress?) -> Result<Int, Errno> {
      if let address = address {
        return address.withUnsafePointer { addr, len in
          msg.msg_name = UnsafeMutableRawPointer(mutating: addr)
          msg.msg_namelen = len
          return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_sendmsg(self.rawValue, &msg, flags.rawValue)
          }
        }
      }
      return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_sendmsg(self.rawValue, &msg, flags.rawValue)
      }
    }

    if let ancillary = ancillaryMessages {
      return ancillary._withUnsafeBytes { controlBuffer in
        msg.msg_control = UnsafeMutableRawPointer(mutating: controlBuffer.baseAddress)
        msg.msg_controllen = CInterop.SockLen(controlBuffer.count)
        return doSend(address: address)
      }
    }
    return doSend(address: address)
  }

  /// Receives a message with optional ancillary data.
  ///
  /// - Parameters:
  ///   - buffer: The buffer to receive data into.
  ///   - ancillaryMessages: Buffer to receive ancillary (control) messages.
  ///                        Must have sufficient capacity pre-allocated.
  ///   - sender: Optional buffer to receive the sender's address.
  ///   - flags: Message flags.
  ///   - retryOnInterrupt: Whether to retry if interrupted.
  /// - Returns: The number of bytes received.
  ///
  /// After receiving,
  /// this method sets the buffer's initialized count to the number of bytes received.
  ///
  /// The corresponding C function is `recvmsg`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func receiveMessage(
    into buffer: inout OutputRawSpan,
    ancillaryMessages: inout AncillaryMessageBuffer,
    sender: inout SocketAddress?,
    flags: MessageFlags = .none,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    try buffer.withUnsafeMutableBytes { buf, count throws(Errno) -> Int in
      let bytesRead = try _receiveMessage(
        into: buf,
        ancillaryMessages: &ancillaryMessages,
        sender: &sender,
        flags: flags,
        retryOnInterrupt: retryOnInterrupt
      ).get()
      count = bytesRead  // Set initialized count to bytes received
      return bytesRead
    }
  }

  @usableFromInline
  internal func _receiveMessage(
    into buffer: UnsafeMutableRawBufferPointer,
    ancillaryMessages: inout AncillaryMessageBuffer,
    sender: inout SocketAddress?,
    flags: MessageFlags,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    var iov = CInterop.IOVec(
      iov_base: buffer.baseAddress,
      iov_len: buffer.count
    )

    var msg = CInterop.MsgHdr()
    msg.msg_iov = withUnsafeMutablePointer(to: &iov) { $0 }
    msg.msg_iovlen = 1

    func doRecv(sender: inout SocketAddress?) -> Result<Int, Errno> {
      if sender != nil {
        return sender!._withUnsafeMutablePointer { addr, len in
          msg.msg_name = UnsafeMutableRawPointer(addr)
          msg.msg_namelen = len
          return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_recvmsg(self.rawValue, &msg, flags.rawValue)
          }
        }
      }
      return valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_recvmsg(self.rawValue, &msg, flags.rawValue)
      }
    }

    return ancillaryMessages._withMutableCInterop(entireCapacity: true) {
      controlPtr, controlLen in
      msg.msg_control = controlPtr
      msg.msg_controllen = controlLen
      return doRecv(sender: &sender)
    }
  }
}

// MARK: - Socket Information

@available(System 99, *)
extension SocketDescriptor {
  /// Gets the local address of the socket.
  ///
  /// - Parameter address: A buffer to receive the local address.
  ///
  /// The corresponding C function is `getsockname`.
  @_alwaysEmitIntoClient
  public func getLocalAddress(into address: inout SocketAddress) throws {
    try _getLocalAddress(into: &address).get()
  }

  @usableFromInline
  internal func _getLocalAddress(into address: inout SocketAddress) -> Result<(), Errno> {
    address._withUnsafeMutablePointer { addr, len in
      nothingOrErrno(retryOnInterrupt: false) {
        system_getsockname(self.rawValue, addr, &len)
      }
    }
  }

  /// Gets the remote address of the socket.
  ///
  /// - Parameter address: A buffer to receive the peer address.
  ///
  /// The corresponding C function is `getpeername`.
  @_alwaysEmitIntoClient
  public func getPeerAddress(into address: inout SocketAddress) throws {
    try _getPeerAddress(into: &address).get()
  }

  @usableFromInline
  internal func _getPeerAddress(into address: inout SocketAddress) -> Result<(), Errno> {
    address._withUnsafeMutablePointer { addr, len in
      nothingOrErrno(retryOnInterrupt: false) {
        system_getpeername(self.rawValue, addr, &len)
      }
    }
  }
}
