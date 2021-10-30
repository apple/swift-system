/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public extension Time {
    
    /// Nanoseconds
    @frozen
    struct Nanoseconds: RawRepresentable, Equatable, Hashable, Codable {
        
        public var rawValue: CInterop.Nanoseconds
        
        public init(rawValue: CInterop.Nanoseconds) {
            self.rawValue = rawValue
        }
    }
}

public extension Time.Nanoseconds {
    
    static var zero: Time.Nanoseconds {
        return 0
    }
    
    static var min: Time.Nanoseconds {
        return .init(rawValue: .min)
    }
    
    static var max: Time.Nanoseconds {
        return .init(rawValue: .max)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Time.Nanoseconds: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension Time.Nanoseconds: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue.description
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: - Arithmetic

public extension Time.Nanoseconds {
    
    static func - (lhs: Time.Nanoseconds, rhs: Time.Nanoseconds) -> Time.Nanoseconds {
        return .init(rawValue: lhs.rawValue - rhs.rawValue)
    }
    
    static func + (lhs: Time.Nanoseconds, rhs: Time.Nanoseconds) -> Time.Nanoseconds {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }
}

// MARK: - Comparable

extension Time.Nanoseconds: Comparable {
    
    public static func < (lhs: Time.Nanoseconds, rhs: Time.Nanoseconds) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func <= (lhs: Time.Nanoseconds, rhs: Time.Nanoseconds) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }
    
    public static func >= (lhs: Time.Nanoseconds, rhs: Time.Nanoseconds) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
    
    public static func > (lhs: Time.Nanoseconds, rhs: Time.Nanoseconds) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}
