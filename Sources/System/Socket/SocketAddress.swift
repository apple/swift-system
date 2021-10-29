/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Socket Address
public protocol SocketAddress {
    
    /// Socket Protocol
    associatedtype ProtocolID: SocketProtocol
    
    /// Unsafe pointer closure
    func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result
    
    static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self
}

public extension SocketAddress {
    
    @_alwaysEmitIntoClient
    static var family: SocketAddressFamily {
        return ProtocolID.family
    }
}

/// IPv4 Socket Address
public struct UnixSocketAddress: SocketAddress, Equatable, Hashable {
    
    public typealias ProtocolID = UnixProtocol
    
    public var path: FilePath
    
    @_alwaysEmitIntoClient
    public init(path: FilePath) {
        self.path = path
    }
    
    public func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result {
        return try path.withPlatformString { platformString in
            var socketAddress = CInterop.UnixSocketAddress()
            socketAddress.sun_family = numericCast(Self.family.rawValue)
            withUnsafeMutableBytes(of: &socketAddress.sun_path) { pathBytes in
                pathBytes
                    .bindMemory(to: CInterop.PlatformChar.self)
                    .baseAddress!
                    .assign(from: platformString, count: path.length)
            }
            return try socketAddress.withUnsafePointer(body)
        }
    }
    
    public static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self {
        var socketAddress = CInterop.UnixSocketAddress()
        try socketAddress.withUnsafeMutablePointer(body)
        return withUnsafeBytes(of: socketAddress.sun_path) { pathPointer in
            Self.init(path: FilePath(platformString: pathPointer.baseAddress!.assumingMemoryBound(to: CInterop.PlatformChar.self)))
        }
    }
}

/// IPv4 Socket Address
public struct IPv4SocketAddress: SocketAddress, Equatable, Hashable {
    
    public typealias ProtocolID = IPv4Protocol
    
    public var address: IPv4Address
    
    public var port: UInt16
    
    @_alwaysEmitIntoClient
    public init(address: IPv4Address,
                port: UInt16) {
        
        self.address = address
        self.port = port
    }
    
    public func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result {
        
        var socketAddress = CInterop.IPv4SocketAddress()
        socketAddress.sin_family = numericCast(Self.family.rawValue)
        socketAddress.sin_port = port.networkOrder
        socketAddress.sin_addr = address.bytes
        return try socketAddress.withUnsafePointer(body)
    }
    
    public static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self {
        var socketAddress = CInterop.IPv4SocketAddress()
        try socketAddress.withUnsafeMutablePointer(body)
        return Self.init(
            address: IPv4Address(socketAddress.sin_addr),
            port: socketAddress.sin_port.networkOrder
        )
    }
}

/// IPv6 Socket Address
public struct IPv6SocketAddress: SocketAddress, Equatable, Hashable {
    
    public typealias ProtocolID = IPv6Protocol
    
    public var address: IPv6Address
    
    public var port: UInt16
    
    @_alwaysEmitIntoClient
    public init(address: IPv6Address,
                port: UInt16) {
        
        self.address = address
        self.port = port
    }
    
    public func withUnsafePointer<Result>(
      _ body: (UnsafePointer<CInterop.SocketAddress>, UInt32) throws -> Result
    ) rethrows -> Result {
        
        var socketAddress = CInterop.IPv6SocketAddress()
        socketAddress.sin6_family = numericCast(Self.family.rawValue)
        socketAddress.sin6_port = port.networkOrder
        socketAddress.sin6_addr = address.bytes
        return try socketAddress.withUnsafePointer(body)
    }
    
    public static func withUnsafePointer(
        _ body: (UnsafeMutablePointer<CInterop.SocketAddress>, UInt32) throws -> ()
    ) rethrows -> Self {
        var socketAddress = CInterop.IPv6SocketAddress()
        try socketAddress.withUnsafeMutablePointer(body)
        return Self.init(
            address: IPv6Address(socketAddress.sin6_addr),
            port: socketAddress.sin6_port.networkOrder
        )
    }
}
