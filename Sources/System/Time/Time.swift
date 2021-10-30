/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// POSIX Time
@frozen
public struct Time: RawRepresentable, Equatable, Hashable, Codable {
    
    public var rawValue: CInterop.Time
    
    public init(rawValue: CInterop.Time) {
        self.rawValue = rawValue
    }
}

public extension Time {
    
    static var zero: Time {
        return 0
    }
    
    static var min: Time {
        return .init(rawValue: .min)
    }
    
    static var max: Time {
        return .init(rawValue: .max)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Time: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension Time: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue.description
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: - Arithmetic

public extension Time {
    
    static func - (lhs: Time, rhs: Time) -> Time {
        return .init(rawValue: lhs.rawValue - rhs.rawValue)
    }
    
    static func + (lhs: Time, rhs: Time) -> Time {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }
}

// MARK: - Comparable

extension Time: Comparable {
    
    public static func < (lhs: Time, rhs: Time) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func <= (lhs: Time, rhs: Time) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }
    
    public static func >= (lhs: Time, rhs: Time) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
    
    public static func > (lhs: Time, rhs: Time) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}
