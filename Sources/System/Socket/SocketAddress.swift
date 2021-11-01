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

/// Unix Socket Address
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
