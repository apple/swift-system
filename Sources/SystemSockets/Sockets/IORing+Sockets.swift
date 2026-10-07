/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import SystemPackage

#if canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#endif

// MARK: - Socket requests

@available(System 199, *)
extension IORing.Request {
  /// Creates a socket.
  ///
  /// On success, the completion's ``IORing/Completion/result`` is the file
  /// descriptor of the new socket. Wrap it with
  /// `SocketDescriptor(rawValue:)`. The caller owns the socket and has to
  /// close it.
  ///
  /// The corresponding C function is `socket`, and the operation is
  /// `IORING_OP_SOCKET`. It requires Linux 5.19 or later.
  ///
  /// - Parameters:
  ///   - domain: The communication domain of the socket.
  ///   - type: The type of the socket.
  ///   - protocol: The protocol of the socket.
  ///   - flags: Flags for the new socket.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that creates the socket.
  public static func socket(
    _ domain: SocketDescriptor.Domain,
    _ type: SocketDescriptor.ConnectionType,
    protocol: SocketDescriptor.ProtocolID = .default,
    flags: SocketDescriptor.SocketFlags = [],
    context: UInt64 = 0
  ) -> IORing.Request {
    ._socket(
      domain: domain.rawValue,
      type: type.rawValue | flags.rawValue,
      protocol: `protocol`.rawValue,
      context: context
    )
  }

  /// Connects a socket to an address.
  ///
  /// The address is copied when the request is created. The kernel copies it
  /// again when the request is submitted, so `address` doesn't need to stay
  /// alive.
  ///
  /// The corresponding C function is `connect`, and the operation is
  /// `IORING_OP_CONNECT`.
  ///
  /// - Parameters:
  ///   - socket: The socket to connect.
  ///   - address: The address to connect to.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that connects the socket.
  public static func connect(
    _ socket: SocketDescriptor,
    to address: SocketAddress,
    context: UInt64 = 0
  ) -> IORing.Request {
    address.withUnsafePointer { address, length in
      ._connect(
        FileDescriptor(rawValue: socket.rawValue),
        to: address,
        length: length,
        context: context
      )
    }
  }

  /// Binds a socket to an address.
  ///
  /// The address is copied when the request is created. The kernel copies it
  /// again when the request is submitted, so `address` doesn't need to stay
  /// alive.
  ///
  /// The corresponding C function is `bind`, and the operation is
  /// `IORING_OP_BIND`. It requires Linux 6.11 or later.
  ///
  /// - Parameters:
  ///   - socket: The socket to bind.
  ///   - address: The address to bind to.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that binds the socket.
  public static func bind(
    _ socket: SocketDescriptor,
    to address: SocketAddress,
    context: UInt64 = 0
  ) -> IORing.Request {
    address.withUnsafePointer { address, length in
      ._bind(
        FileDescriptor(rawValue: socket.rawValue),
        to: address,
        length: length,
        context: context
      )
    }
  }

  /// Starts listening for connections on a socket.
  ///
  /// The corresponding C function is `listen`, and the operation is
  /// `IORING_OP_LISTEN`. It requires Linux 6.11 or later.
  ///
  /// - Parameters:
  ///   - socket: The socket to listen on.
  ///   - backlog: The maximum number of pending connections.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that starts listening.
  public static func listen(
    _ socket: SocketDescriptor,
    backlog: Int,
    context: UInt64 = 0
  ) -> IORing.Request {
    ._listen(
      FileDescriptor(rawValue: socket.rawValue),
      backlog: UInt32(clamping: backlog),
      context: context
    )
  }

  /// Accepts a connection on a listening socket.
  ///
  /// On success, the completion's ``IORing/Completion/result`` is the file
  /// descriptor of the accepted socket. Wrap it with
  /// `SocketDescriptor(rawValue:)`. The caller owns the socket and has to
  /// close it.
  ///
  /// The corresponding C function is `accept4`, and the operation is
  /// `IORING_OP_ACCEPT`.
  ///
  /// - Parameters:
  ///   - socket: The listening socket.
  ///   - flags: Flags for the accepted socket.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that accepts a connection.
  public static func accept(
    _ socket: SocketDescriptor,
    flags: SocketDescriptor.SocketFlags = [],
    context: UInt64 = 0
  ) -> IORing.Request {
    ._accept(
      FileDescriptor(rawValue: socket.rawValue),
      peerAddress: nil,
      peerAddressLength: nil,
      flags: flags.rawValue,
      context: context
    )
  }

  /// Accepts a connection on a listening socket and writes the peer's
  /// address into the given storage.
  ///
  /// Before submitting the request, set the value that `peerAddressLength`
  /// points to to the size of the storage that `peerAddress` points to. When
  /// the request completes, the kernel has written the peer's address and its
  /// length there.
  ///
  /// - Important: The kernel writes to `peerAddress` and `peerAddressLength`
  ///   when the request completes, so both have to stay valid until the
  ///   completion has been consumed.
  ///
  /// The corresponding C function is `accept4`, and the operation is
  /// `IORING_OP_ACCEPT`.
  ///
  /// - Parameters:
  ///   - socket: The listening socket.
  ///   - peerAddress: The storage for the peer's address.
  ///   - peerAddressLength: The size of the storage, replaced with the length
  ///     of the peer's address.
  ///   - flags: Flags for the accepted socket.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that accepts a connection.
  public static func accept(
    _ socket: SocketDescriptor,
    peerAddress: UnsafeMutablePointer<CInterop.SockAddr>,
    peerAddressLength: UnsafeMutablePointer<CInterop.SockLen>,
    flags: SocketDescriptor.SocketFlags = [],
    context: UInt64 = 0
  ) -> IORing.Request {
    ._accept(
      FileDescriptor(rawValue: socket.rawValue),
      peerAddress: peerAddress,
      peerAddressLength: peerAddressLength,
      flags: flags.rawValue,
      context: context
    )
  }

  /// Sends bytes on a connected socket.
  ///
  /// On success, the completion's ``IORing/Completion/result`` is the number
  /// of bytes sent, which can be less than the size of `buffer`.
  ///
  /// Unlike a write request, a send request doesn't raise `SIGPIPE` when the
  /// connection is closed for writing. io_uring sets `MSG_NOSIGNAL` for it,
  /// so the completion fails with ``Errno/brokenPipe`` instead.
  ///
  /// - Important: The kernel reads from `buffer` until the request completes,
  ///   so it has to stay valid until the completion has been consumed.
  ///
  /// The corresponding C function is `send`, and the operation is
  /// `IORING_OP_SEND`.
  ///
  /// - Parameters:
  ///   - buffer: The bytes to send.
  ///   - socket: The socket to send on.
  ///   - flags: Flags for sending.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that sends the bytes.
  public static func send(
    _ buffer: UnsafeRawBufferPointer,
    to socket: SocketDescriptor,
    flags: SocketDescriptor.MessageFlags = .none,
    context: UInt64 = 0
  ) -> IORing.Request {
    ._send(
      buffer,
      to: FileDescriptor(rawValue: socket.rawValue),
      flags: flags.rawValue,
      context: context
    )
  }

  /// Receives bytes from a connected socket.
  ///
  /// On success, the completion's ``IORing/Completion/result`` is the number
  /// of bytes received. Zero means that the peer closed its side of the
  /// connection.
  ///
  /// - Important: The kernel writes into `buffer` until the request completes,
  ///   so it has to stay valid until the completion has been consumed.
  ///
  /// The corresponding C function is `recv`, and the operation is
  /// `IORING_OP_RECV`.
  ///
  /// - Parameters:
  ///   - socket: The socket to receive from.
  ///   - buffer: The buffer to receive into.
  ///   - flags: Flags for receiving.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that receives bytes.
  public static func receive(
    _ socket: SocketDescriptor,
    into buffer: UnsafeMutableRawBufferPointer,
    flags: SocketDescriptor.MessageFlags = .none,
    context: UInt64 = 0
  ) -> IORing.Request {
    ._receive(
      FileDescriptor(rawValue: socket.rawValue),
      into: buffer,
      flags: flags.rawValue,
      context: context
    )
  }

  /// Shuts down one or both directions of a socket.
  ///
  /// The corresponding C function is `shutdown`, and the operation is
  /// `IORING_OP_SHUTDOWN`. It requires Linux 5.11 or later.
  ///
  /// - Parameters:
  ///   - socket: The socket to shut down.
  ///   - how: The directions to shut down.
  ///   - context: A value passed through to the completion.
  /// - Returns: A request that shuts down the socket.
  public static func shutdown(
    _ socket: SocketDescriptor,
    _ how: SocketDescriptor.ShutdownKind,
    context: UInt64 = 0
  ) -> IORing.Request {
    ._shutdown(
      FileDescriptor(rawValue: socket.rawValue),
      how: how.rawValue,
      context: context
    )
  }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
