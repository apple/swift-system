/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Type capable of representing the processor time used by a process.
@frozen
public struct ProcessorTime: RawRepresentable, Equatable, Hashable, Codable {
    
    public var rawValue: CInterop.Clock
    
    public init(rawValue: CInterop.Clock) {
        self.rawValue = rawValue
    }
}

public extension ProcessorTime {
    
    /// Returns the approximate processor time used by the process
    /// since the beginning of an implementation-defined era related to the program's execution.
    static var current: ProcessorTime {
        return .init(rawValue: system_clock())
    }
}

public extension ProcessorTime {
    
    init(seconds: Double) {
        self.init(rawValue: .init(seconds * Double(_CLOCKS_PER_SEC)))
    }
    
    var seconds: Double {
        return Double(rawValue) / Double(_CLOCKS_PER_SEC)
    }
}

// MARK: - Arithmetic

public extension ProcessorTime {
    
    static func - (lhs: ProcessorTime, rhs: ProcessorTime) -> ProcessorTime {
        return .init(rawValue: lhs.rawValue - rhs.rawValue)
    }
    
    static func + (lhs: ProcessorTime, rhs: ProcessorTime) -> ProcessorTime {
        return .init(rawValue: lhs.rawValue + rhs.rawValue)
    }
}

// MARK: - Comparable

extension ProcessorTime: Comparable {
    
    public static func < (lhs: ProcessorTime, rhs: ProcessorTime) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func <= (lhs: ProcessorTime, rhs: ProcessorTime) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }
    
    public static func >= (lhs: ProcessorTime, rhs: ProcessorTime) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
    
    public static func > (lhs: ProcessorTime, rhs: ProcessorTime) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension ProcessorTime: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension ProcessorTime: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return rawValue.description
    }
    
    public var debugDescription: String {
        return description
    }
}
