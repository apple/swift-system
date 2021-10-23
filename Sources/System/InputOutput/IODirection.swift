/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Linux)

/// `ioctl` Data Direction
@frozen
public struct IODirection: OptionSet, Hashable, Codable {
    
    /// The raw C file permissions.
    @_alwaysEmitIntoClient
    public let rawValue: CInt
    
    /// Create a strongly-typed file permission from a raw C value.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }
    
    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }
}

public extension IODirection {
    
    @_alwaysEmitIntoClient
    static var none: IODirection { IODirection(0x00) }
    
    @_alwaysEmitIntoClient
    static var read: IODirection { IODirection(0x01) }
    
    @_alwaysEmitIntoClient
    static var write: IODirection { IODirection(0x02) }
}

#endif
