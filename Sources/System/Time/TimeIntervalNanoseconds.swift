/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public extension TimeInterval {
    
    /// POSIX Time
    @frozen
    struct Nanoseconds: Equatable, Hashable, Codable {
        
        public var seconds: Time
        
        public var nanoseconds: Time.Nanoseconds
        
        public init(seconds: Time, nanoseconds: Time.Nanoseconds) {
            self.seconds = seconds
            self.nanoseconds = nanoseconds
        }
    }
}

public extension TimeInterval.Nanoseconds {
    
    static var zero: TimeInterval.Nanoseconds {
        return .init(seconds: 0, nanoseconds: 0)
    }
    
    static var min: TimeInterval.Nanoseconds {
        return .init(seconds: .min, nanoseconds: .min)
    }
    
    static var max: TimeInterval.Nanoseconds {
        return .init(seconds: .max, nanoseconds: .max)
    }
}

// MARK: - Time Conversion

public extension TimeInterval.Nanoseconds {
    
    init(seconds: Double) {
        let (integerValue, decimalValue) = system_modf(seconds)
        let nanoseconds = decimalValue * 1_000_000_000.0
        self.init(
            seconds: Time(rawValue: Int(integerValue)),
            nanoseconds: Time.Nanoseconds(rawValue: Int(nanoseconds))
        )
    }
}

public extension Double {
    
    init(_ timeInterval: TimeInterval.Nanoseconds) {
        let seconds = Double(timeInterval.seconds.rawValue)
        let nanoseconds = Double(timeInterval.nanoseconds.rawValue) / 1_000_000_000.0
        self = seconds + nanoseconds
    }
}

// MARK: - CustomStringConvertible

extension TimeInterval.Nanoseconds: CustomStringConvertible {
    
    public var description: String {
        return "\(seconds)s \(nanoseconds)ns"
    }
}

// MARK: - Arithmetic

public extension TimeInterval.Nanoseconds {
    
    static func + (lhs: TimeInterval.Nanoseconds, rhs: TimeInterval.Nanoseconds) -> TimeInterval.Nanoseconds {
        return .init(
            seconds: lhs.seconds + rhs.seconds,
            nanoseconds: lhs.nanoseconds + rhs.nanoseconds
        )
    }
}

public extension TimeInterval {
    
    static func + (lhs: TimeInterval, rhs: TimeInterval.Nanoseconds) -> TimeInterval.Nanoseconds {
        return .init(
            seconds: lhs.seconds + rhs.seconds,
            nanoseconds: rhs.nanoseconds
        )
    }
}

// MARK: - C Interop

internal extension TimeInterval.Nanoseconds {
    
    @usableFromInline
    init(_ bytes: CInterop.TimeIntervalNanoseconds) {
        self.seconds = .init(rawValue: bytes.tv_sec)
        self.nanoseconds = .init(rawValue: bytes.tv_nsec)
    }
    
    @usableFromInline
    var bytes: CInterop.TimeIntervalNanoseconds {
        .init(tv_sec: seconds.rawValue, tv_nsec: nanoseconds.rawValue)
    }
}
