/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Input / Output Request identifier for manipulating underlying device parameters of special files.
public protocol IOControlID: RawRepresentable {
    
    /// Create a strongly-typed I/O request from a raw C IO request.
    init?(rawValue: CUnsignedLong)
    
    /// The raw C IO request ID.
    var rawValue: CUnsignedLong { get }
}

#if os(Linux)
public extension IOControlID {
    
    @_alwaysEmitIntoClient
    init(type: IOType, direction: IODirection, code: CInt, size: CInt) {
        self.init(rawValue: _IOC(direction, type, nr, size))
    }
}
#endif

public protocol IOControlInteger {
    
    associatedtype ID: IOControlID
    
    static var id: ID { get }
    
    var intValue: Int32 { get }
}

public protocol IOControlValue {
    
    associatedtype ID: IOControlID
    
    static var id: ID { get }
    
    mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result
}

