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

/// A socket descriptor.
///
/// A `SocketDescriptor` is a type-safe wrapper around an operating system
/// socket handle. It provides a strongly-typed interface for socket operations.
///
/// Unlike `FileDescriptor`, a `SocketDescriptor` explicitly represents a
/// socket rather than a general file descriptor, enabling socket-specific
/// operations like `bind`, `listen`, `accept`, and `connect`.
@frozen
@available(System 99, *)
public struct SocketDescriptor: RawRepresentable, Hashable, Codable, Sendable {
  /// The raw C socket handle.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly-typed socket descriptor from a raw C socket handle.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
}

@available(System 99, *)
extension SocketDescriptor {
  /// The file descriptor for this socket.
  ///
  /// On POSIX systems, sockets are file descriptors and can be used with
  /// file descriptor operations like `read`, `write`, and `close`.
  @_alwaysEmitIntoClient
  public var fileDescriptor: FileDescriptor {
    FileDescriptor(rawValue: rawValue)
  }

  /// Creates a socket descriptor from a file descriptor without verification.
  ///
  /// This initializer does not verify that the file descriptor actually
  /// refers to a socket. Use with caution.
  @_alwaysEmitIntoClient
  public init(unchecked fd: FileDescriptor) {
    self.init(rawValue: fd.rawValue)
  }
}

// MARK: - Domain (Protocol Family)

@available(System 99, *)
extension SocketDescriptor {
  /// Communications domain, identifying the protocol family.
  ///
  /// The domain specifies the protocol family to be used for communication.
  /// Common domains include `.ipv4` for IPv4, `.ipv6` for IPv6, and `.local`
  /// for Unix domain sockets.
  @frozen
  public struct Domain: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
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
    public static var unspecified: Domain { Domain(PF_UNSPEC) }

    /// Local (Unix domain) communication.
    ///
    /// The corresponding C constant is `PF_LOCAL` (also known as `PF_UNIX`).
    @_alwaysEmitIntoClient
    public static var local: Domain { Domain(PF_LOCAL) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "local")
    public static var unix: Domain { Domain(PF_UNIX) }

    /// Internet Protocol version 4.
    ///
    /// The corresponding C constant is `PF_INET`.
    @_alwaysEmitIntoClient
    public static var ipv4: Domain { Domain(PF_INET) }

    /// Internet Protocol version 6.
    ///
    /// The corresponding C constant is `PF_INET6`.
    @_alwaysEmitIntoClient
    public static var ipv6: Domain { Domain(PF_INET6) }

    /// Internal routing protocol.
    ///
    /// The corresponding C constant is `PF_ROUTE`.
    @_alwaysEmitIntoClient
    public static var routing: Domain { Domain(PF_ROUTE) }

    /// Internal key-management function.
    ///
    /// The corresponding C constant is `PF_KEY`.
    @_alwaysEmitIntoClient
    public static var keyManagement: Domain { Domain(PF_KEY) }

    #if SYSTEM_PACKAGE_DARWIN
    /// System domain.
    ///
    /// The corresponding C constant is `PF_SYSTEM`.
    @_alwaysEmitIntoClient
    public static var system: Domain { Domain(PF_SYSTEM) }

    /// Raw access to network device.
    ///
    /// The corresponding C constant is `PF_NDRV`.
    @_alwaysEmitIntoClient
    public static var networkDevice: Domain { Domain(PF_NDRV) }
    #endif

    public var description: String {
      switch self {
      case .unspecified: return "unspecified"
      case .local: return "local"
      case .ipv4: return "ipv4"
      case .ipv6: return "ipv6"
      case .routing: return "routing"
      case .keyManagement: return "keyManagement"
      #if SYSTEM_PACKAGE_DARWIN
      case .system: return "system"
      case .networkDevice: return "networkDevice"
      #endif
      default: return "Domain(\(rawValue))"
      }
    }
  }
}

// MARK: - Connection Type (Socket Type)

@available(System 99, *)
extension SocketDescriptor {
  /// The socket type, specifying the semantics of communication.
  ///
  /// The connection type determines how data is transmitted. Stream sockets
  /// provide reliable, ordered byte streams, while datagram sockets provide
  /// connectionless, unreliable messages.
  @frozen
  public struct ConnectionType: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    /// Sequenced, reliable, two-way, connection-based byte streams.
    ///
    /// The corresponding C constant is `SOCK_STREAM`.
    @_alwaysEmitIntoClient
    public static var stream: ConnectionType { ConnectionType(SOCK_STREAM) }

    /// Connectionless, unreliable datagrams of a fixed maximum length.
    ///
    /// The corresponding C constant is `SOCK_DGRAM`.
    @_alwaysEmitIntoClient
    public static var datagram: ConnectionType { ConnectionType(SOCK_DGRAM) }

    /// Raw network protocol access.
    ///
    /// The corresponding C constant is `SOCK_RAW`.
    @_alwaysEmitIntoClient
    public static var raw: ConnectionType { ConnectionType(SOCK_RAW) }

    /// Reliably-delivered message.
    ///
    /// The corresponding C constant is `SOCK_RDM`.
    @_alwaysEmitIntoClient
    public static var reliablyDeliveredMessage: ConnectionType {
      ConnectionType(SOCK_RDM)
    }

    /// Sequenced packet stream.
    ///
    /// The corresponding C constant is `SOCK_SEQPACKET`.
    @_alwaysEmitIntoClient
    public static var sequencedPacketStream: ConnectionType {
      ConnectionType(SOCK_SEQPACKET)
    }

    public var description: String {
      switch self {
      case .stream: return "stream"
      case .datagram: return "datagram"
      case .raw: return "raw"
      case .reliablyDeliveredMessage: return "rdm"
      case .sequencedPacketStream: return "seqpacket"
      default: return "ConnectionType(\(rawValue))"
      }
    }
  }
}

// MARK: - Protocol ID

@available(System 99, *)
extension SocketDescriptor {
  /// Identifies a particular protocol to use for communication.
  ///
  /// Protocol numbers are specific to the communication domain. Some symbolic
  /// names may have the same underlying value in different contexts.
  @frozen
  public struct ProtocolID: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    internal init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    /// Default protocol for the socket type.
    @_alwaysEmitIntoClient
    public static var `default`: ProtocolID { Self(0) }

    /// Internet Protocol (IP).
    ///
    /// The corresponding C constant is `IPPROTO_IP`.
    @_alwaysEmitIntoClient
    public static var ip: ProtocolID { Self(IPPROTO_IP) }

    /// Transmission Control Protocol (TCP).
    ///
    /// The corresponding C constant is `IPPROTO_TCP`.
    @_alwaysEmitIntoClient
    public static var tcp: ProtocolID { Self(IPPROTO_TCP) }

    /// User Datagram Protocol (UDP).
    ///
    /// The corresponding C constant is `IPPROTO_UDP`.
    @_alwaysEmitIntoClient
    public static var udp: ProtocolID { Self(IPPROTO_UDP) }

    /// IPv4 encapsulation.
    ///
    /// The corresponding C constant is `IPPROTO_IPV4`.
    @_alwaysEmitIntoClient
    public static var ipv4: ProtocolID { Self(IPPROTO_IPV4) }

    /// IPv6 header.
    ///
    /// The corresponding C constant is `IPPROTO_IPV6`.
    @_alwaysEmitIntoClient
    public static var ipv6: ProtocolID { Self(IPPROTO_IPV6) }

    /// Raw IP packet.
    ///
    /// The corresponding C constant is `IPPROTO_RAW`.
    @_alwaysEmitIntoClient
    public static var raw: ProtocolID { Self(IPPROTO_RAW) }

    public var description: String {
      rawValue.description
    }
  }
}

// MARK: - Message Flags

@available(System 99, *)
extension SocketDescriptor {
  /// Flags for send and receive operations.
  @frozen
  public struct MessageFlags: OptionSet, Sendable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    /// No flags.
    @_alwaysEmitIntoClient
    public static var none: MessageFlags { MessageFlags(0) }

    /// Process out-of-band data.
    ///
    /// The corresponding C constant is `MSG_OOB`.
    @_alwaysEmitIntoClient
    public static var outOfBand: MessageFlags { MessageFlags(MSG_OOB) }

    /// Bypass routing, use direct interface.
    ///
    /// The corresponding C constant is `MSG_DONTROUTE`.
    @_alwaysEmitIntoClient
    public static var doNotRoute: MessageFlags { MessageFlags(MSG_DONTROUTE) }

    /// Peek at incoming message without removing it.
    ///
    /// The corresponding C constant is `MSG_PEEK`.
    @_alwaysEmitIntoClient
    public static var peek: MessageFlags { MessageFlags(MSG_PEEK) }

    /// Wait for full request or error.
    ///
    /// The corresponding C constant is `MSG_WAITALL`.
    @_alwaysEmitIntoClient
    public static var waitForAll: MessageFlags { MessageFlags(MSG_WAITALL) }

    /// End-of-record marker.
    ///
    /// The corresponding C constant is `MSG_EOR`.
    @_alwaysEmitIntoClient
    public static var endOfRecord: MessageFlags { MessageFlags(MSG_EOR) }

    /// Data was truncated.
    ///
    /// The corresponding C constant is `MSG_TRUNC`.
    @_alwaysEmitIntoClient
    public static var dataTruncated: MessageFlags { MessageFlags(MSG_TRUNC) }

    /// Control data was truncated.
    ///
    /// The corresponding C constant is `MSG_CTRUNC`.
    @_alwaysEmitIntoClient
    public static var controlTruncated: MessageFlags { MessageFlags(MSG_CTRUNC) }

    #if !SYSTEM_PACKAGE_DARWIN
    /// Do not generate SIGPIPE on broken pipe.
    ///
    /// The corresponding C constant is `MSG_NOSIGNAL`.
    @_alwaysEmitIntoClient
    public static var noSignal: MessageFlags { MessageFlags(MSG_NOSIGNAL) }
    #endif

    public var description: String {
      var descriptions: [(Element, StaticString)] = [
        (.outOfBand, ".outOfBand"),
        (.doNotRoute, ".doNotRoute"),
        (.peek, ".peek"),
        (.waitForAll, ".waitForAll"),
        (.endOfRecord, ".endOfRecord"),
        (.dataTruncated, ".dataTruncated"),
        (.controlTruncated, ".controlTruncated"),
      ]
      #if !SYSTEM_PACKAGE_DARWIN
      descriptions.append((.noSignal, ".noSignal"))
      #endif
      return _buildDescription(descriptions)
    }
  }
}

// MARK: - Shutdown Kind

@available(System 99, *)
extension SocketDescriptor {
  /// Specifies which parts of a full-duplex connection to shut down.
  @frozen
  public struct ShutdownKind: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Disallow further receives.
    ///
    /// The corresponding C constant is `SHUT_RD`.
    @_alwaysEmitIntoClient
    public static var read: ShutdownKind { ShutdownKind(rawValue: SHUT_RD) }

    /// Disallow further sends.
    ///
    /// The corresponding C constant is `SHUT_WR`.
    @_alwaysEmitIntoClient
    public static var write: ShutdownKind { ShutdownKind(rawValue: SHUT_WR) }

    /// Disallow further sends and receives.
    ///
    /// The corresponding C constant is `SHUT_RDWR`.
    @_alwaysEmitIntoClient
    public static var readWrite: ShutdownKind { ShutdownKind(rawValue: SHUT_RDWR) }

    public var description: String {
      switch self {
      case .read: return "read"
      case .write: return "write"
      case .readWrite: return "readWrite"
      default: return "ShutdownKind(\(rawValue))"
      }
    }
  }
}

// MARK: - Socket Option

@available(System 99, *)
extension SocketDescriptor {
  /// A generic socket option identifier.
  ///
  /// This type represents raw socket option constants that can be used
  /// with ancillary messages or generic get/set socket option operations.
  @frozen
  public struct Option: RawRepresentable, Hashable, Sendable, CustomStringConvertible {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

    public var description: String { "Option(\(rawValue))" }
  }
}
