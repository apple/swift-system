/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// POSIX Time
@frozen
public struct TimeInterval: Equatable, Hashable, Codable {
    
    public var seconds: Time
    
    public init(seconds: Time) {
        self.seconds = seconds
    }
}

public extension TimeInterval {
    
    static var zero: TimeInterval {
        return .init(seconds: 0)
    }
    
    static var min: TimeInterval {
        return .init(seconds: .min)
    }
    
    static var max: TimeInterval {
        return .init(seconds: .max)
    }
}

// MARK: - CustomStringConvertible

extension TimeInterval: CustomStringConvertible {
    
    public var description: String {
        return "\(seconds)s"
    }
}

// MARK: - Arithmetic

public extension TimeInterval {
    
    static func - (lhs: TimeInterval, rhs: TimeInterval) -> TimeInterval {
        return .init(
            seconds: lhs.seconds - rhs.seconds
        )
    }
    
    static func + (lhs: TimeInterval, rhs: TimeInterval) -> TimeInterval {
        return .init(
            seconds: lhs.seconds + rhs.seconds
        )
    }
}

// MARK: - Get and Set Current Time

public extension TimeInterval {
    
    /// Returns the system time (since Unix epoch).
    static func timeInvervalSince1970(
        retryOnInterrupt: Bool = true
    ) throws -> TimeInterval {
        return TimeInterval(seconds: try TimeInterval.Microseconds
            .timeInvervalSince1970(retryOnInterrupt: retryOnInterrupt)
            .seconds)
    }
    
    /// Sets the system time (since Unix epoch).
    func setTimeInvervalSince1970(
        _ timeInverval: TimeInterval,
        retryOnInterrupt: Bool = true
    ) throws {
        try Microseconds(seconds: timeInverval.seconds, microseconds: 0)
            .bytes
            .setTime(retryOnInterrupt: retryOnInterrupt)
            .get()
    }
}
