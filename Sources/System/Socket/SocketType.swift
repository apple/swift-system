/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// POSIX Socket Type
@frozen
public struct SocketType: RawRepresentable, Hashable, Codable {
    
  /// The raw socket type identifier.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly-typed socket type from a raw socket type identifier.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
    
  @_alwaysEmitIntoClient
  private init(_ cValue: CInterop.SocketType) {
      #if os(Linux)
      self.init(rawValue: numericCast(cValue.rawValue))
      #else
      self.init(rawValue: cValue)
      #endif
  }
}

public extension SocketType {
    
    /// Stream socket
    ///
    /// Provides sequenced, reliable, two-way, connection-based byte streams.
    /// An out-of-band data transmission mechanism may be supported.
    @_alwaysEmitIntoClient
    static var stream: SocketType { SocketType(_SOCK_STREAM) }
    
    /// Supports datagrams (connectionless, unreliable messages of a fixed maximum length).
    @_alwaysEmitIntoClient
    static var datagram: SocketType { SocketType(_SOCK_DGRAM) }
    
    /// Provides raw network protocol access.
    @_alwaysEmitIntoClient
    static var raw: SocketType { SocketType(_SOCK_RAW) }
    
    /// Provides a reliable datagram layer that does not guarantee ordering.
    @_alwaysEmitIntoClient
    static var reliableDatagramMessage: SocketType { SocketType(_SOCK_RDM) }
    
    /// Provides a sequenced, reliable, two-way connection-based data transmission
    /// path for datagrams of fixed maximum length; a consumer is required to read
    /// an entire packet with each input system call.
    @_alwaysEmitIntoClient
    static var sequencedPacket: SocketType { SocketType(_SOCK_SEQPACKET) }
}

#if os(Linux)
public extension SocketType {
    
    /// Datagram Congestion Control Protocol
    ///
    /// Linux specific way of getting packets at the dev level.
    @_alwaysEmitIntoClient
    static var datagramCongestionControlProtocol: SocketType { SocketType(_SOCK_DCCP) }
}
#endif
