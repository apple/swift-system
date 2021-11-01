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
