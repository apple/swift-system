/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// TODO: @available(...)

// TODO: Windows uses a SOCKET type; doesn't have file descriptor
// equivalence

/// TODO
@frozen
public struct SocketDescriptor: RawRepresentable, Hashable {
  /// The raw C socket
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly-typed socket from a raw C socket
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
}

extension SocketDescriptor {
  /// The file descriptor for `self`.
  @_alwaysEmitIntoClient
  public var fileDescriptor: FileDescriptor {
    FileDescriptor(rawValue: rawValue)
  }

  /// Treat `fd` as a socket descriptor, without checking with the operating
  /// system that it actually refers to a socket
  @_alwaysEmitIntoClient
  public init(unchecked fd: FileDescriptor) {
    self.init(rawValue: fd.rawValue)
  }
}

extension FileDescriptor {
  /// Treat `self` as a socket descriptor, without checking with the operating
  /// system that it actually refers to a socket
  @_alwaysEmitIntoClient
  public var uncheckedSocket: SocketDescriptor {
    SocketDescriptor(unchecked: self)
  }
}

extension SocketDescriptor {
  /// Communications domain: the protocol family which should be used
  @frozen
  public struct Domain: RawRepresentable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Host-internal protocols, formerly called PF_UNIX,
    ///
    /// The corresponding C constant is `PF_LOCAL`
    @_alwaysEmitIntoClient
    public static var local: Domain { Domain(rawValue: _PF_LOCAL) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "local")
    public static var unix: Domain { Domain(rawValue: _PF_UNIX) }

    /// Internet version 4 protocols,
    ///
    /// The corresponding C constant is `PF_INET`
    @_alwaysEmitIntoClient
    public static var ipv4: Domain { Domain(rawValue: _PF_INET) }

    /// Internal Routing protocol,
    ///
    /// The corresponding C constant is `PF_ROUTE`
    @_alwaysEmitIntoClient
    public static var routing: Domain { Domain(rawValue: _PF_ROUTE) }

    /// Internal key-management function,
    ///
    /// The corresponding C constant is `PF_KEY`
    @_alwaysEmitIntoClient
    public static var keyManagement: Domain { Domain(rawValue: _PF_KEY) }

    /// Internet version 6 protocols,
    ///
    /// The corresponding C constant is `PF_INET6`
    @_alwaysEmitIntoClient
    public static var ipv6: Domain { Domain(rawValue: _PF_INET6) }

    /// System domain,
    ///
    /// The corresponding C constant is `PF_SYSTEM`
    @_alwaysEmitIntoClient
    public static var system: Domain { Domain(rawValue: _PF_SYSTEM) }

    /// Raw access to network device
    ///
    /// The corresponding C constant is `PF_NDRV`
    @_alwaysEmitIntoClient
    public static var networkDevice: Domain { Domain(rawValue: _PF_NDRV) }
  }

  /// TODO
  @frozen
  public struct ConnectionType: RawRepresentable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Sequenced, reliable, two-way connection based byte streams.
    ///
    /// The corresponding C constant is `SOCK_STREAM`
    @_alwaysEmitIntoClient
    public static var stream: ConnectionType { ConnectionType(rawValue: _SOCK_STREAM) }

    /// Datagrams (connectionless, unreliable messages of a fixed (typically small) maximum length)
    ///
    /// The corresponding C constant is `SOCK_DGRAM`
    @_alwaysEmitIntoClient
    public static var datagram: ConnectionType { ConnectionType(rawValue: _SOCK_DGRAM) }

    /// Only available to the super user
    ///
    /// The corresponding C constant is `SOCK_RAW`
    @_alwaysEmitIntoClient
    public static var raw: ConnectionType { ConnectionType(rawValue: _SOCK_RAW) }
  }

  /// TODO
  @frozen
  public struct ProtocolID: RawRepresentable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// The default protocol for the domain and connection type combination.
    @_alwaysEmitIntoClient
    public static var `default`: ProtocolID { self.init(rawValue: 0) }
  }

  // TODO: option flags (SO_DEBUG)?

  // TODO:
  @frozen
  public struct MessageFlags: OptionSet {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    @_alwaysEmitIntoClient
    public static var none: MessageFlags { MessageFlags(0) }

    // MSG_OOB: process out-of-band data
    @_alwaysEmitIntoClient
    public static var outOfBand: MessageFlags { MessageFlags(_MSG_OOB) }

    // MSG_DONTROUTE: bypass routing, use direct interface
    @_alwaysEmitIntoClient
    public static var doNotRoute: MessageFlags { MessageFlags(_MSG_DONTROUTE) }

    // MSG_PEEK: peek at incoming message
    @_alwaysEmitIntoClient
    public static var peek: MessageFlags { MessageFlags(_MSG_PEEK) }

    // MSG_WAITALL: wait for full request or error
    @_alwaysEmitIntoClient
    public static var waitForAll: MessageFlags { MessageFlags(_MSG_WAITALL) }

    // TODO: any of the others? I'm going off of man pagees...
  }

  @frozen
  public struct ShutdownKind: RawRepresentable, Hashable, Codable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Further receives will be disallowed
    ///
    /// The corresponding C constant is `SHUT_RD`
    @_alwaysEmitIntoClient
    public static var read: ShutdownKind { ShutdownKind(rawValue: _SHUT_RD) }

    /// Further sends will be disallowed
    ///
    /// The corresponding C constant is `SHUT_RD`
    @_alwaysEmitIntoClient
    public static var write: ShutdownKind { ShutdownKind(rawValue: _SHUT_WR) }

    /// Further sends and receives will be disallowed
    ///
    /// The corresponding C constant is `SHUT_RDWR`
    @_alwaysEmitIntoClient
    public static var readWrite: ShutdownKind { ShutdownKind(rawValue: _SHUT_RDWR) }
  }

}

extension SocketDescriptor {
/*

 int     accept(int, struct sockaddr * __restrict, socklen_t * __restrict)
 int     bind(int, const struct sockaddr *, socklen_t) __DARWIN_ALIAS(bind);
 int     connect(int, const struct sockaddr *, socklen_t) __DARWIN_ALIAS_C(connect);
 int     getpeername(int, struct sockaddr * __restrict, socklen_t * __restrict)
 int     getsockname(int, struct sockaddr * __restrict, socklen_t * __restrict)
 int     getsockopt(int, int, int, void * __restrict, socklen_t * __restrict);
 int     listen(int, int) __DARWIN_ALIAS(listen);
 ssize_t recv(int, void *, size_t, int) __DARWIN_ALIAS_C(recv);
 ssize_t recvfrom(int, void *, size_t, int, struct sockaddr * __restrict,
     socklen_t * __restrict) __DARWIN_ALIAS_C(recvfrom);
 ssize_t recvmsg(int, struct msghdr *, int) __DARWIN_ALIAS_C(recvmsg);
 ssize_t send(int, const void *, size_t, int) __DARWIN_ALIAS_C(send);
 ssize_t sendmsg(int, const struct msghdr *, int) __DARWIN_ALIAS_C(sendmsg);
 ssize_t sendto(int, const void *, size_t,
     int, const struct sockaddr *, socklen_t) __DARWIN_ALIAS_C(sendto);
 int     setsockopt(int, int, int, const void *, socklen_t);
 int     shutdown(int, int);
 int     sockatmark(int) __OSX_AVAILABLE_STARTING(__MAC_10_5, __IPHONE_2_0);
 int     socket(int, int, int);
 int     socketpair(int, int, int, int *) __DARWIN_ALIAS(socketpair);

 #if !defined(_POSIX_C_SOURCE)
 int     sendfile(int, int, off_t, off_t *, struct sf_hdtr *, int);
 #endif  /* !_POSIX_C_SOURCE */

 #if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
 void    pfctlinput(int, struct sockaddr *);

 __API_AVAILABLE(macosx(10.11), ios(9.0), tvos(9.0), watchos(2.0))
 int connectx(int, const sa_endpoints_t *, sae_associd_t, unsigned int,
     const struct iovec *, unsigned int, size_t *, sae_connid_t *);

 __API_AVAILABLE(macosx(10.11), ios(9.0), tvos(9.0), watchos(2.0))
 int disconnectx(int, sae_associd_t, sae_connid_t);
 #endif  /* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */

 */
}

// TODO: socket addresses...

