/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension SocketDescriptor {
  @frozen
  public struct Option: RawRepresentable, Hashable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    public var description: String { rawValue.description }

    // MARK: - Socket-level

    /// Enables recording of debugging information.
    ///
    /// The corresponding C constant is `SO_DEBUG`
    @_alwaysEmitIntoClient
    public static var debug: Option { Option(_SO_DEBUG) }

    /// Enables local address reuse.
    ///
    /// The corresponding C constant is `SO_REUSEADDR`
    @_alwaysEmitIntoClient
    public static var reuseAddress: Option { Option(_SO_REUSEADDR) }

    /// Enables duplicate address and port bindings.
    ///
    /// The corresponding C constant is `SO_REUSEPORT`
    @_alwaysEmitIntoClient
    public static var reusePort: Option { Option(_SO_REUSEPORT) }

    /// Enables keep connections alive.
    ///
    /// The corresponding C constant is `SO_KEEPALIVE`
    @_alwaysEmitIntoClient
    public static var keepAlive: Option { Option(_SO_KEEPALIVE) }

    /// Enables routing bypass for outgoing messages.
    ///
    /// The corresponding C constant is `SO_DONTROUTE`
    @_alwaysEmitIntoClient
    public static var doNotRoute: Option { Option(_SO_DONTROUTE) }

    /// linger on close if data present
    ///
    /// The corresponding C constant is `SO_LINGER`
    @_alwaysEmitIntoClient
    public static var linger: Option { Option(_SO_LINGER) }

    /// Enables permission to transmit broadcast messages.
    ///
    /// The corresponding C constant is `SO_BROADCAST`
    @_alwaysEmitIntoClient
    public static var broadcast: Option { Option(_SO_BROADCAST) }

    /// Enables reception of out-of-band data in band.
    ///
    /// The corresponding C constant is `SO_OOBINLINE`
    @_alwaysEmitIntoClient
    public static var outOfBand: Option { Option(_SO_OOBINLINE) }

    /// Set buffer size for output.
    ///
    /// The corresponding C constant is `SO_SNDBUF`
    @_alwaysEmitIntoClient
    public static var sendBufferSize: Option { Option(_SO_SNDBUF) }

    /// Set buffer size for input.
    ///
    /// The corresponding C constant is `SO_RCVBUF`
    @_alwaysEmitIntoClient
    public static var receiveBufferSize: Option { Option(_SO_RCVBUF) }

    /// Set minimum count for output.
    ///
    /// The corresponding C constant is `SO_SNDLOWAT`
    @_alwaysEmitIntoClient
    public static var sendLowWaterMark: Option { Option(_SO_SNDLOWAT) }

    /// Set minimum count for input.
    ///
    /// The corresponding C constant is `SO_RCVLOWAT`
    @_alwaysEmitIntoClient
    public static var receiveLowWaterMark: Option { Option(_SO_RCVLOWAT) }

    /// Set timeout value for output.
    ///
    /// The corresponding C constant is `SO_SNDTIMEO`
    @_alwaysEmitIntoClient
    public static var sendTimeout: Option { Option(_SO_SNDTIMEO) }

    /// Set timeout value for input.
    ///
    /// The corresponding C constant is `SO_RCVTIMEO`
    @_alwaysEmitIntoClient
    public static var receiveTimeout: Option { Option(_SO_RCVTIMEO) }

    /// Get the type of the socket (get only).
    ///
    /// The corresponding C constant is `SO_TYPE`
    @_alwaysEmitIntoClient
    public static var getType: Option { Option(_SO_TYPE) }

    /// Get and clear error on the socket (get only).
    ///
    /// The corresponding C constant is `SO_ERROR`
    @_alwaysEmitIntoClient
    public static var getError: Option { Option(_SO_ERROR) }

    /// Do not generate SIGPIPE, instead return EPIPE.
    ///
    /// TODO: better name...
    ///
    /// The corresponding C constant is `SO_NOSIGPIPE`
    @_alwaysEmitIntoClient
    public static var noSignal: Option { Option(_SO_NOSIGPIPE) }

    /// Number of bytes to be read (get only).
    ///
    /// For datagram oriented sockets, returns the size of the first packet
    ///
    /// TODO: better name...
    ///
    /// The corresponding C constant is `SO_NREAD`
    @_alwaysEmitIntoClient
    public static var getNumBytesToReceive: Option { Option(_SO_NREAD) }

    /// Number of bytes written not yet sent by the protocol (get only).
    ///
    /// The corresponding C constant is `SO_NWRITE`
    @_alwaysEmitIntoClient
    public static var getNumByteToSend: Option { Option(_SO_NWRITE) }

    /// Linger on close if data present with timeout in seconds.
    ///
    /// The corresponding C constant is `SO_LINGER_SEC`
    @_alwaysEmitIntoClient
    public static var longerSeconds: Option { Option(_SO_LINGER_SEC) }

    //
    // MARK: - TCP options
    //

    /// Send data before receiving a reply.
    ///
    /// The corresponding C constant is `TCP_NODELAY`.
    @_alwaysEmitIntoClient
    public static var tcpNoDelay: Option { Option(_TCP_NODELAY) }

    /// Set the maximum segment size.
    ///
    /// The corresponding C constant is `TCP_MAXSEG`.
    @_alwaysEmitIntoClient
    public static var tcpMaxSegmentSize: Option { Option(_TCP_MAXSEG) }

    /// Disable TCP option use.
    ///
    /// The corresponding C constant is `TCP_NOOPT`.
    @_alwaysEmitIntoClient
    public static var tcpNoOptions: Option { Option(_TCP_NOOPT) }

    /// Delay sending any data until socket is closed or send buffer is filled.
    ///
    /// The corresponding C constant is `TCP_NOPUSH`.
    @_alwaysEmitIntoClient
    public static var tcpNoPush: Option { Option(_TCP_NOPUSH) }

    /// Specify the amount of idle time (in seconds) before keepalive probes.
    ///
    /// The corresponding C constant is `TCP_KEEPALIVE`.
    @_alwaysEmitIntoClient
    public static var tcpKeepAlive: Option { Option(_TCP_KEEPALIVE) }

    /// Specify the timeout (in seconds) for new non-established TCP connections.
    ///
    /// The corresponding C constant is `TCP_CONNECTIONTIMEOUT`.
    @_alwaysEmitIntoClient
    public static var tcpConnectionTimeout: Option { Option(_TCP_CONNECTIONTIMEOUT) }

    /// Set the amout of time (in seconds) between successive keepalives sent to
    /// probe an unresponsive peer.
    ///
    /// The corresponding C constant is `TCP_KEEPINTVL`.
    @_alwaysEmitIntoClient
    public static var tcpKeepAliveInterval: Option { Option(_TCP_KEEPINTVL) }

    /// Set the number of times keepalive probe should be repeated if peer is not
    /// responding.
    ///
    /// The corresponding C constant is `TCP_KEEPCNT`.
    @_alwaysEmitIntoClient
    public static var tcpKeepAliveCount: Option { Option(_TCP_KEEPCNT) }

    /// Send a TCP acknowledgement for every other data packaet in a stream of
    /// received data packets, rather than for every 8.
    ///
    /// TODO: better name
    ///
    /// The corresponding C constant is `TCP_SENDMOREACKS`.
    @_alwaysEmitIntoClient
    public static var tcpSendMoreAcks: Option { Option(_TCP_SENDMOREACKS) }

    /// Use Explicit Congestion Notification (ECN).
    ///
    /// The corresponding C constant is `TCP_ENABLE_ECN`.
    @_alwaysEmitIntoClient
    public static var tcpUseExplicitCongestionNotification: Option { Option(_TCP_ENABLE_ECN) }

    /// Specify the maximum amount of unsent data in the send socket buffer.
    ///
    /// The corresponding C constant is `TCP_NOTSENT_LOWAT`.
    @_alwaysEmitIntoClient
    public static var tcpMaxUnsent: Option { Option(_TCP_NOTSENT_LOWAT) }

    /// Use TCP Fast Open feature. Accpet may return a socket that is in
    /// SYN_RECEIVED state but is readable and writable.
    ///
    /// The corresponding C constant is `TCP_FASTOPEN`.
    @_alwaysEmitIntoClient
    public static var tcpFastOpen: Option { Option(_TCP_FASTOPEN) }

    /// Optain TCP connection-level statistics.
    ///
    /// The corresponding C constant is `TCP_CONNECTION_INFO`.
    @_alwaysEmitIntoClient
    public static var tcpConnectionInfo: Option { Option(_TCP_CONNECTION_INFO) }

    //
    // MARK: - IP Options
    //

    /// Set to null to disable previously specified options.
    ///
    /// The corresponding C constant is `IP_OPTIONS`.
    @_alwaysEmitIntoClient
    public static var ipOptions: Option { Option(_IP_OPTIONS) }

    /// Set the type-of-service.
    ///
    /// The corresponding C constant is `IP_TOS`.
    @_alwaysEmitIntoClient
    public static var ipTypeOfService: Option { Option(_IP_TOS) }

    /// Set the time-to-live.
    ///
    /// The corresponding C constant is `IP_TTL`.
    @_alwaysEmitIntoClient
    public static var ipTimeToLive: Option { Option(_IP_TTL) }

    /// Causes `recvmsg` to return the destination IP address for a UPD
    /// datagram.
    ///
    /// The corresponding C constant is `IP_RECVDSTADDR`.
    @_alwaysEmitIntoClient
    public static var ipReceiveDestinationAddress: Option { Option(_IP_RECVDSTADDR) }

    /// Causes `recvmsg` to return the type-of-service filed of the ip header.
    ///
    /// The corresponding C constant is `IP_RECVTOS`.
    @_alwaysEmitIntoClient
    public static var ipReceiveTypeOfService: Option { Option(_IP_RECVTOS) }

    /// Change the time-to-live for outgoing multicast datagrams.
    ///
    /// The corresponding C constant is `IP_MULTICAST_TTL`.
    @_alwaysEmitIntoClient
    public static var ipMulticastTimeToLive: Option { Option(_IP_MULTICAST_TTL) }

    /// Override the default network interface for subsequent transmissions.
    ///
    /// The corresponding C constant is `IP_MULTICAST_IF`.
    @_alwaysEmitIntoClient
    public static var ipMulticastInterface: Option { Option(_IP_MULTICAST_IF) }

    /// Control whether or not subsequent datagrams are looped back.
    ///
    /// The corresponding C constant is `IP_MULTICAST_LOOP`.
    @_alwaysEmitIntoClient
    public static var ipMulticastLoop: Option { Option(_IP_MULTICAST_LOOP) }

    /// Join a multicast group.
    ///
    /// The corresponding C constant is `IP_ADD_MEMBERSHIP`.
    @_alwaysEmitIntoClient
    public static var ipAddMembership: Option { Option(_IP_ADD_MEMBERSHIP) }

    /// Leave a multicast group.
    ///
    /// The corresponding C constant is `IP_DROP_MEMBERSHIP`.
    @_alwaysEmitIntoClient
    public static var ipDropMembership: Option { Option(_IP_DROP_MEMBERSHIP) }

    /// Indicates the complete IP header is included with the data.
    ///
    /// Can only be used with `ConnectionType.raw` sockets.
    ///
    /// The corresponding C constant is `IP_HDRINCL`.
    @_alwaysEmitIntoClient
    public static var ipHeaderIncluded: Option { Option(_IP_HDRINCL) }

    //
    // MARK: - IPv6 Options
    //

    /// The default hop limit header field for outgoing unicast datagrams.
    ///
    /// A value of -1 resets to the default value.
    ///
    /// The corresponding C constant is `IPV6_UNICAST_HOPS`.
    @_alwaysEmitIntoClient
    public static var ipv6UnicastHops: Option { Option(_IPV6_UNICAST_HOPS) }

    /// The interface from which multicast packets will be sent.
    ///
    /// A value of 0 specifies the default interface.
    ///
    /// The corresponding C constant is `IPV6_MULTICAST_IF`.
    @_alwaysEmitIntoClient
    public static var ipv6MulticastInterface: Option { Option(_IPV6_MULTICAST_IF) }

    /// The default hop limit header field for outgoing multicast datagrams.
    ///
    /// The corresponding C constant is `IPV6_MULTICAST_HOPS`.
    @_alwaysEmitIntoClient
    public static var ipv6MulticastHops: Option { Option(_IPV6_MULTICAST_HOPS) }

    /// Whether multicast datagrams will be looped back.
    ///
    /// The corresponding C constant is `IPV6_MULTICAST_LOOP`.
    @_alwaysEmitIntoClient
    public static var ipv6MulticastLoop: Option { Option(_IPV6_MULTICAST_LOOP) }

    /// Join a multicast group.
    ///
    /// The corresponding C constant is `IPV6_JOIN_GROUP`.
    @_alwaysEmitIntoClient
    public static var ipv6JoinGroup: Option { Option(_IPV6_JOIN_GROUP) }

    /// Leave a multicast group.
    ///
    /// The corresponding C constant is `IPV6_LEAVE_GROUP`.
    @_alwaysEmitIntoClient
    public static var ipv6LeaveGroup: Option { Option(_IPV6_LEAVE_GROUP) }

    /// Allocation policy of ephemeral ports for when the kernel automatically
    /// binds a local address to this socket.
    ///
    /// TODO: portrange struct somewhere, with _DEFAULT, _HIGH, _LOW
    ///
    /// The corresponding C constant is `IPV6_PORTRANGE`.
    @_alwaysEmitIntoClient
    public static var ipv6PortRange: Option { Option(_IPV6_PORTRANGE) }

//    /// Whether additional information about subsequent packets will be
//    /// provided in `recvmsg` calls.
//    ///
//    /// The corresponding C constant is `IPV6_PKTINFO`.
//    @_alwaysEmitIntoClient
//    public static var ipv6ReceivePacketInfo: Option { Option(_IPV6_PKTINFO) }
//
//    /// Whether the hop limit header field from subsequent packets will
//    /// be provided in `recvmsg` calls.
//    ///
//    /// The corresponding C constant is `IPV6_HOPLIMIT`.
//    @_alwaysEmitIntoClient
//    public static var ipv6ReceiveHopLimit: Option { Option(_IPV6_HOPLIMIT) }
//
//    /// Whether hop-by-hop options from subsequent packets will
//    /// be provided in `recvmsg` calls.
//    ///
//    /// The corresponding C constant is `IPV6_HOPOPTS`.
//    @_alwaysEmitIntoClient
//    public static var ipv6ReceiveHopOptions: Option { Option(_IPV6_HOPOPTS) }
//
//    /// Whether destination options from subsequent packets will
//    /// be provided in `recvmsg` calls.
//    ///
//    /// The corresponding C constant is `IPV6_DSTOPTS`.
//    @_alwaysEmitIntoClient
//    public static var ipv6ReceiveDestinationOptions: Option { Option(_IPV6_DSTOPTS) }

    /// The value of the traffic class field for outgoing datagrams.
    ///
    /// The corresponding C constant is `IPV6_TCLASS`.
    @_alwaysEmitIntoClient
    public static var ipv6TrafficClass: Option { Option(_IPV6_TCLASS) }

    /// Whether traffic class header field from subsequent packets will
    /// be provided in `recvmsg` calls.
    ///
    /// The corresponding C constant is `IPV6_RECVTCLASS`.
    @_alwaysEmitIntoClient
    public static var ipv6ReceiveTrafficClass: Option { Option(_IPV6_RECVTCLASS) }

//    /// Whether the routing header from subsequent packets will
//    /// be provided in `recvmsg` calls.
//    ///
//    /// The corresponding C constant is `IPV6_RTHDR`.
//    @_alwaysEmitIntoClient
//    public static var ipv6ReceiveRoutingHeader: Option { Option(_IPV6_RTHDR) }
//
//    /// Get or set all header options and extension headers at one time
//    /// on the last packet sent or received.
//    ///
//    /// The corresponding C constant is `IPV6_PKTOPTIONS`.
//    @_alwaysEmitIntoClient
//    public static var ipv6PacketOptions: Option { Option(_IPV6_PKTOPTIONS) }

    /// The byte offset into a packet where 16-bit checksum is located.
    ///
    /// The corresponding C constant is `IPV6_CHECKSUM`.
    @_alwaysEmitIntoClient
    public static var ipv6Checksum: Option { Option(_IPV6_CHECKSUM) }

    /// Whether only IPv6 connections can be made to this socket.
    ///
    /// The corresponding C constant is `IPV6_V6ONLY`.
    @_alwaysEmitIntoClient
    public static var ipv6Only: Option { Option(_IPV6_V6ONLY) }

//    /// Whether the minimal IPv6 maximum transmission unit (MTU) size
//    /// will be used to avoid fragmentation for subsequenet outgoing
//    /// datagrams.
//    ///
//    /// The corresponding C constant is `IPV6_USE_MIN_MTU`.
//    @_alwaysEmitIntoClient
//    public static var ipv6UseMinimalMTU: Option { Option(_IPV6_USE_MIN_MTU) }
  }
}

extension SocketDescriptor {
  // TODO: Convenience/performance overloads for `Bool` and other concrete types

  @_alwaysEmitIntoClient
  public func getOption<T>(
    _ level: ProtocolID, _ option: Option
  ) throws -> T {
    try _getOption(level, option).get()
  }

  @usableFromInline
  internal func _getOption<T>(
    _ level: ProtocolID, _ option: Option
  ) -> Result<T, Errno> {
    // We can't zero-initialize `T` directly, nor can we pass an uninitialized `T`
    // to `withUnsafeMutableBytes(of:)`. Instead, we will allocate :-(
    let rawBuf = UnsafeMutableRawBufferPointer.allocate(
      byteCount: MemoryLayout<T>.stride,
      alignment: MemoryLayout<T>.alignment)
    rawBuf.initializeMemory(as: UInt8.self, repeating: 0)
    let resultPtr = rawBuf.baseAddress!.bindMemory(to: T.self, capacity: 1)
    defer {
      resultPtr.deinitialize(count: 1)
      rawBuf.deallocate()
    }

    var length: CInterop.SockLen = 0

    let success = system_getsockopt(
      self.rawValue,
      level.rawValue,
      option.rawValue,
      resultPtr, &length)

    return nothingOrErrno(success).map { resultPtr.pointee }
  }

  @_alwaysEmitIntoClient
  public func setOption<T>(
    _ level: ProtocolID, _ option: Option, to value: T
  ) throws {
    try _setOption(level, option, to: value).get()
  }

  @usableFromInline
  internal func _setOption<T>(
    _ level: ProtocolID, _ option: Option, to value: T
  ) -> Result<(), Errno> {
    let len = CInterop.SockLen(MemoryLayout<T>.stride)
    let success = withUnsafeBytes(of: value) {
      return system_setsockopt(
        self.rawValue,
        level.rawValue,
        option.rawValue,
        $0.baseAddress,
        len)
    }
    return nothingOrErrno(success)
  }
}
