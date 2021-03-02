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
  /// The raw C socket.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly-typed socket from a raw C socket.
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
  /// system that it actually refers to a socket.
  @_alwaysEmitIntoClient
  public init(unchecked fd: FileDescriptor) {
    self.init(rawValue: fd.rawValue)
  }
}

extension FileDescriptor {
  /// Treat `self` as a socket descriptor, without checking with the operating
  /// system that it actually refers to a socket.
  @_alwaysEmitIntoClient
  public var uncheckedSocket: SocketDescriptor {
    SocketDescriptor(unchecked: self)
  }
}

extension SocketDescriptor {
  /// Communications domain, identifying the protocol family that is being used.
  @frozen
  public struct Domain: RawRepresentable, Hashable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    /// Unspecified protocol.
    ///
    /// The corresponding C constant is `PF_UNSPEC`.
    @_alwaysEmitIntoClient
    public static var unspecified: Domain { Domain(_PF_UNSPEC) }

    /// Host-internal protocols, formerly called PF_UNIX.
    ///
    /// The corresponding C constant is `PF_LOCAL`.
    @_alwaysEmitIntoClient
    public static var local: Domain { Domain(_PF_LOCAL) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "local")
    public static var unix: Domain { Domain(_PF_UNIX) }

    /// Internet version 4 protocols.
    ///
    /// The corresponding C constant is `PF_INET`.
    @_alwaysEmitIntoClient
    public static var ipv4: Domain { Domain(_PF_INET) }

    /// Internal Routing protocol.
    ///
    /// The corresponding C constant is `PF_ROUTE`.
    @_alwaysEmitIntoClient
    public static var routing: Domain { Domain(_PF_ROUTE) }

    /// Internal key-management function.
    ///
    /// The corresponding C constant is `PF_KEY`.
    @_alwaysEmitIntoClient
    public static var keyManagement: Domain { Domain(_PF_KEY) }

    /// Internet version 6 protocols.
    ///
    /// The corresponding C constant is `PF_INET6`.
    @_alwaysEmitIntoClient
    public static var ipv6: Domain { Domain(_PF_INET6) }

    /// System domain.
    ///
    /// The corresponding C constant is `PF_SYSTEM`.
    @_alwaysEmitIntoClient
    public static var system: Domain { Domain(_PF_SYSTEM) }

    /// Raw access to network device.
    ///
    /// The corresponding C constant is `PF_NDRV`.
    @_alwaysEmitIntoClient
    public static var networkDevice: Domain { Domain(_PF_NDRV) }

    public var description: String {
      switch self {
      case .unspecified: return "unspecified"
      case .local: return "local"
      case .ipv4: return "ipv4"
      case .ipv6: return "ipv6"
      case .routing: return "routing"
      case .keyManagement: return "keyManagement"
      case .system: return "system"
      case .networkDevice: return "networkDevice"
      default: return rawValue.description
      }
    }
  }

  /// The socket type, specifying the semantics of communication.
  @frozen
  public struct ConnectionType: RawRepresentable, Hashable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    /// Sequenced, reliable, two-way connection based byte streams.
    ///
    /// The corresponding C constant is `SOCK_STREAM`.
    @_alwaysEmitIntoClient
    public static var stream: ConnectionType { ConnectionType(_SOCK_STREAM) }

    /// Datagrams (connectionless, unreliable messages of a fixed (typically
    /// small) maximum length).
    ///
    /// The corresponding C constant is `SOCK_DGRAM`.
    @_alwaysEmitIntoClient
    public static var datagram: ConnectionType { ConnectionType(_SOCK_DGRAM) }

    /// Raw protocol interface. Only available to the super user.
    ///
    /// The corresponding C constant is `SOCK_RAW`.
    @_alwaysEmitIntoClient
    public static var raw: ConnectionType { ConnectionType(_SOCK_RAW) }

    /// Reliably delivered message.
    ///
    /// The corresponding C constant is `SOCK_RDM`.
    @_alwaysEmitIntoClient
    public static var reliablyDeliveredMessage: ConnectionType {
      ConnectionType(_SOCK_RDM)
    }

    /// Sequenced packet stream.
    ///
    /// The corresponding C constant is `SOCK_SEQPACKET`.
    @_alwaysEmitIntoClient
    public static var sequencedPacketStream: ConnectionType {
      ConnectionType(_SOCK_SEQPACKET)
    }

    public var description: String {
      switch self {
      case .stream: return "stream"
      case .datagram: return "datagram"
      case .raw: return "raw"
      case .reliablyDeliveredMessage: return "rdm"
      case .sequencedPacketStream: return "seqpacket"
      default: return rawValue.description
      }
    }
  }

  /// Identifies a particular protocol to be used for communication.
  ///
  /// Note that protocol numbers are particular to the communication domain
  /// that is being used. Accordingly, some of the symbolic names provided
  /// here may have the same underlying value -- they are provided merely
  /// for convenience.
  @frozen
  public struct ProtocolID: RawRepresentable, Hashable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    /// Internet Protocol (IP).
    ///
    /// This corresponds to the C constant `IPPROTO_IP`.
    @_alwaysEmitIntoClient
    public static var ip: ProtocolID { Self(_IPPROTO_IP) }

    /// Transmission Control Protocol (TCP).
    ///
    /// This corresponds to the C constant `IPPROTO_TCP`.
    @_alwaysEmitIntoClient
    public static var tcp: ProtocolID { Self(_IPPROTO_TCP) }

    /// User Datagram Protocol (UDP).
    ///
    /// This corresponds to the C constant `IPPROTO_UDP`.
    @_alwaysEmitIntoClient
    public static var udp: ProtocolID { Self(_IPPROTO_UDP) }

    /// IPv4 encapsulation.
    ///
    /// This corresponds to the C constant `IPPROTO_IPV4`.
    @_alwaysEmitIntoClient
    public static var ipv4: ProtocolID { Self(_IPPROTO_IPV4) }

    /// IPv6 header.
    ///
    /// This corresponds to the C constant `IPPROTO_IPV6`.
    @_alwaysEmitIntoClient
    public static var ipv6: ProtocolID { Self(_IPPROTO_IPV6) }

    /// Raw IP packet.
    ///
    /// This corresponds to the C constant `IPPROTO_RAW`.
    @_alwaysEmitIntoClient
    public static var raw: ProtocolID { Self(_IPPROTO_RAW) }

    /// Special protocol value representing socket-level options.
    ///
    /// The corresponding C constant is `SOL_SOCKET`.
    @_alwaysEmitIntoClient
    public static var socketOption: ProtocolID { Self(_SOL_SOCKET) }

    public var description: String {
      // Note: Can't return symbolic names here -- values have multiple
      // meanings based on the domain.
      rawValue.description
    }
  }

  /// Message flags.
  @frozen
  public struct MessageFlags: OptionSet, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    @_alwaysEmitIntoClient
    public static var none: MessageFlags { MessageFlags(0) }

    /// Process out-of-band data.
    ///
    /// The corresponding C constant is `MSG_OOB`.
    @_alwaysEmitIntoClient
    public static var outOfBand: MessageFlags { MessageFlags(_MSG_OOB) }

    /// Bypass routing, use direct interface.
    ///
    /// The corresponding C constant is `MSG_DONTROUTE`.
    @_alwaysEmitIntoClient
    public static var doNotRoute: MessageFlags { MessageFlags(_MSG_DONTROUTE) }

    /// Peek at incoming message.
    ///
    /// The corresponding C constant is `MSG_PEEK`.
    @_alwaysEmitIntoClient
    public static var peek: MessageFlags { MessageFlags(_MSG_PEEK) }

    /// Wait for full request or error.
    ///
    /// The corresponding C constant is `MSG_WAITALL`.
    @_alwaysEmitIntoClient
    public static var waitForAll: MessageFlags { MessageFlags(_MSG_WAITALL) }

    /// End-of-record condition -- the associated data completed a
    /// full record.
    ///
    /// The corresponding C constant is `MSG_EOR`.
    @_alwaysEmitIntoClient
    public static var endOfRecord: MessageFlags { MessageFlags(_MSG_EOR) }

    /// Datagram was truncated because it didn't fit in the supplied
    /// buffer.
    ///
    /// The corresponding C constant is `MSG_TRUNC`.
    @_alwaysEmitIntoClient
    public static var dataTruncated: MessageFlags { MessageFlags(_MSG_TRUNC) }

    /// Some ancillary data was discarded because it didn't fit
    /// in the supplied buffer.
    ///
    /// The corresponding C constant is `MSG_CTRUNC`.
    @_alwaysEmitIntoClient
    public static var ancillaryTruncated: MessageFlags { MessageFlags(_MSG_CTRUNC) }

    public var description: String {
      let descriptions: [(Element, StaticString)] = [
        (.outOfBand, ".outOfBand"),
        (.doNotRoute, ".doNotRoute"),
        (.peek, ".peek"),
        (.waitForAll, ".waitForAll"),
        (.endOfRecord, ".endOfRecord"),
        (.dataTruncated, ".dataTruncated"),
        (.ancillaryTruncated, ".ancillaryTruncated"),
      ]
      return _buildDescription(descriptions)
    }
  }

  /// Specify the part (or all) of a full-duplex connection to shutdown.
  @frozen
  public struct ShutdownKind: RawRepresentable, Hashable, Codable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Further receives will be disallowed
    ///
    /// The corresponding C constant is `SHUT_RD`.
    @_alwaysEmitIntoClient
    public static var read: ShutdownKind { ShutdownKind(rawValue: _SHUT_RD) }

    /// Further sends will be disallowed
    ///
    /// The corresponding C constant is `SHUT_RD`.
    @_alwaysEmitIntoClient
    public static var write: ShutdownKind { ShutdownKind(rawValue: _SHUT_WR) }

    /// Further sends and receives will be disallowed
    ///
    /// The corresponding C constant is `SHUT_RDWR`.
    @_alwaysEmitIntoClient
    public static var readWrite: ShutdownKind { ShutdownKind(rawValue: _SHUT_RDWR) }

    public var description: String {
      switch self {
      case .read: return "read"
      case .write: return "write"
      case .readWrite: return "readWrite"
      default: return rawValue.description
      }
    }
  }
}
