/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public extension Time {
    
    /// Microseconds
    @frozen
    struct Microseconds: RawRepresentable, Equatable, Hashable, Codable {
        
        public var rawValue: CInterop.Microseconds
        
        public init(rawValue: CInterop.Microseconds) {
            self.rawValue = rawValue
        }
    }
}

public extension Time.Microseconds {
    
    static var zero: Time.Microseconds {
        return 0
    }
    
    static var min: Time.Microseconds {
        return .init(rawValue: .min)
    }
    
    static var max: Time.Microseconds {
        return .init(rawValue: .max)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Time.Microseconds: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension Time.Microseconds: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue.description
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: - Arithmetic

public extension Time.Microseconds {
    
    static func - (lhs: Time.Microseconds, rhs: Time.Microseconds) -> Time.Microseconds {
        return .init(rawValue: lhs.rawValue - rhs.rawValue)
    }
    
    static func + (lhs: Time.Microseconds, rhs: Time.Microseconds) -> Time.Microseconds {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }
}

// MARK: - Comparable

extension Time.Microseconds: Comparable {
    
    public static func < (lhs: Time.Microseconds, rhs: Time.Microseconds) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func <= (lhs: Time.Microseconds, rhs: Time.Microseconds) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }
    
    public static func >= (lhs: Time.Microseconds, rhs: Time.Microseconds) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
    
    public static func > (lhs: Time.Microseconds, rhs: Time.Microseconds) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}
