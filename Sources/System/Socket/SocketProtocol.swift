/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// POSIX Socket Protocol
public protocol SocketProtocol: RawRepresentable {
    
    static var family: SocketAddressFamily { get }
    
    var type: SocketType { get }
    
    init?(rawValue: Int32)
    
    var rawValue: Int32 { get }
}

/// Unix Protocol Family
public enum UnixProtocol: Int32, Codable, SocketProtocol {
    
    case raw = 0
    
    @_alwaysEmitIntoClient
    public static var family: SocketAddressFamily { .unix }
    
    @_alwaysEmitIntoClient
    public var type: SocketType {
        switch self {
        case .raw: return .raw
        }
    }
}

/// IPv4 Protocol Family
public enum IPv4Protocol: Int32, Codable, SocketProtocol {
    
    case raw
    case tcp
    case udp
    
    @_alwaysEmitIntoClient
    public static var family: SocketAddressFamily { .ipv4 }
    
    @_alwaysEmitIntoClient
    public var type: SocketType {
        switch self {
        case .raw: return .raw
        case .tcp: return .stream
        case .udp: return .datagram
        }
    }
    
    @_alwaysEmitIntoClient
    public var rawValue: Int32 {
        switch self {
        case .raw: return _IPPROTO_RAW
        case .tcp: return _IPPROTO_TCP
        case .udp: return _IPPROTO_UDP
        }
    }
}

/// IPv6 Protocol Family
public enum IPv6Protocol: Int32, Codable, SocketProtocol {
    
    case raw
    case tcp
    case udp
    
    @_alwaysEmitIntoClient
    public static var family: SocketAddressFamily { .ipv6 }
    
    @_alwaysEmitIntoClient
    public var type: SocketType {
        switch self {
        case .raw: return .raw
        case .tcp: return .stream
        case .udp: return .datagram
        }
    }
    
    @_alwaysEmitIntoClient
    public var rawValue: Int32 {
        switch self {
        case .raw: return _IPPROTO_RAW
        case .tcp: return _IPPROTO_TCP
        case .udp: return _IPPROTO_UDP
        }
    }
}
