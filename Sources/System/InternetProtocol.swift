/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Internet Protocol Address
@frozen
public enum IPAddress: Equatable, Hashable, Codable {
    
    /// IPv4
    case v4(IPv4Address)
    
    /// IPv6
    case v6(IPv6Address)
}

public extension IPAddress {
    
    @_alwaysEmitIntoClient
    func withUnsafeBytes<Result>(_ body: ((UnsafeRawBufferPointer) -> (Result))) -> Result {
        switch self {
        case let .v4(address):
            return address.withUnsafeBytes(body)
        case let .v6(address):
            return address.withUnsafeBytes(body)
        }
    }
}

extension IPAddress: RawRepresentable {
    
    public init?(rawValue: String) {
        
        if let address = IPv4Address(rawValue: rawValue) {
            self = .v4(address)
        } else if let address = IPv6Address(rawValue: rawValue) {
            self = .v6(address)
        } else {
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case let .v4(address): return address.rawValue
        case let .v6(address): return address.rawValue
        }
    }
}

extension IPAddress: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue
    }
    
    public var debugDescription: String {
        return description
    }
}

/// IPv4 Socket Address
@frozen
public struct IPv4Address: Equatable, Hashable, Codable {
    
    @usableFromInline
    internal let bytes: CInterop.IPv4Address
    
    @_alwaysEmitIntoClient
    public init(_ bytes: CInterop.IPv4Address) {
        self.bytes = bytes
    }
    
    @_alwaysEmitIntoClient
    public func withUnsafeBytes<Result>(_ body: ((UnsafeRawBufferPointer) -> (Result))) -> Result {
        Swift.withUnsafeBytes(of: bytes, body)
    }
}

public extension IPv4Address {
    
    /// Initialize with raw bytes.
    @_alwaysEmitIntoClient
    init(_ byte0: UInt8, _ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8) {
        self.init(unsafeBitCast((byte0, byte1, byte2, byte3), to: CInterop.IPv4Address.self))
    }
}

public extension IPAddress {
    
    /// Initialize with a IP v4 address.
    @_alwaysEmitIntoClient
    init(_ byte0: UInt8, _ byte1: UInt8, _ byte2: UInt8, _ byte3: UInt8) {
        self = .v4(IPv4Address(byte0, byte1, byte2, byte3))
    }
}

public extension IPv4Address {
    
    @_alwaysEmitIntoClient
    static var any: IPv4Address { IPv4Address(_INADDR_ANY) }
    
    @_alwaysEmitIntoClient
    static var loopback: IPv4Address { IPv4Address(_INADDR_LOOPBACK) }
}

extension IPv4Address: RawRepresentable {
    
    @_alwaysEmitIntoClient
    public init?(rawValue: String) {
        guard let bytes = CInterop.IPv4Address(rawValue) else {
            return nil
        }
        self.init(bytes)
    }
    
    @_alwaysEmitIntoClient
    public var rawValue: String {
        return try! String(bytes)
    }
}

extension IPv4Address: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue
    }
    
    public var debugDescription: String {
        return description
    }
}

/// IPv6 Socket Address
@frozen
public struct IPv6Address: Equatable, Hashable, Codable {
    
    @usableFromInline
    internal let bytes: CInterop.IPv6Address
    
    @_alwaysEmitIntoClient
    public init(_ bytes: CInterop.IPv6Address) {
        self.bytes = bytes
    }
    
    @_alwaysEmitIntoClient
    public func withUnsafeBytes<Result>(_ body: ((UnsafeRawBufferPointer) -> (Result))) -> Result {
        Swift.withUnsafeBytes(of: bytes, body)
    }
}

public extension IPv6Address {
    
    /// Initialize with bytes
    @_alwaysEmitIntoClient
    init(_ byte0: UInt16, _ byte1: UInt16, _ byte2: UInt16, _ byte3: UInt16, _ byte4: UInt16, _ byte5: UInt16, _ byte6: UInt16, _ byte7: UInt16) {
        self.init(unsafeBitCast((byte0.bigEndian, byte1.bigEndian, byte2.bigEndian, byte3.bigEndian, byte4.bigEndian, byte5.bigEndian, byte6.bigEndian, byte7.bigEndian), to: CInterop.IPv6Address.self))
    }
}

public extension IPAddress {
    
    /// Initialize with a IP v6 address.
    @_alwaysEmitIntoClient
    init(_ byte0: UInt16, _ byte1: UInt16, _ byte2: UInt16, _ byte3: UInt16, _ byte4: UInt16, _ byte5: UInt16, _ byte6: UInt16, _ byte7: UInt16) {
        self = .v6(IPv6Address(byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7))
    }
}

public extension IPv6Address {
    
    @_alwaysEmitIntoClient
    static var any: IPv6Address { IPv6Address(_INADDR6_ANY) }
    
    @_alwaysEmitIntoClient
    static var loopback: IPv6Address { IPv6Address(_INADDR6_LOOPBACK) }
}

extension IPv6Address: RawRepresentable {
    
    @_alwaysEmitIntoClient
    public init?(rawValue: String) {
        guard let bytes = CInterop.IPv6Address(rawValue) else {
            return nil
        }
        self.init(bytes)
    }
    
    @_alwaysEmitIntoClient
    public var rawValue: String {
        return try! String(bytes)
    }
}

extension IPv6Address: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue
    }
    
    public var debugDescription: String {
        return description
    }
}
