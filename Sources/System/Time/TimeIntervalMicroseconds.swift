/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public extension TimeInterval {
    
    /// POSIX Time
    @frozen
    struct Microseconds: Equatable, Hashable, Codable {
        
        public var seconds: Time
        
        public var microseconds: Time.Microseconds
        
        public init(seconds: Time, microseconds: Time.Microseconds) {
            self.seconds = seconds
            self.microseconds = microseconds
        }
    }
}

// MARK: - Time Conversion

public extension TimeInterval.Microseconds {
    
    init(seconds: Double) {
        let (integerValue, decimalValue) = system_modf(seconds)
        let microseconds = decimalValue * 1_000_000.0
        self.init(
            seconds: Time(rawValue: Int(integerValue)),
            microseconds: Time.Microseconds(rawValue: Int32(microseconds))
        )
    }
}

public extension Double {
    
    init(_ timeInterval: TimeInterval.Microseconds) {
        let seconds = Double(timeInterval.seconds.rawValue)
        let microseconds = Double(timeInterval.microseconds.rawValue) / 1_000_000.0
        self = seconds + microseconds
    }
}

public extension TimeInterval.Microseconds {
    
    static var zero: TimeInterval.Microseconds {
        return .init(seconds: 0, microseconds: 0)
    }
    
    static var min: TimeInterval.Microseconds {
        return .init(seconds: .min, microseconds: .min)
    }
    
    static var max: TimeInterval.Microseconds {
        return .init(seconds: .max, microseconds: .max)
    }
}

// MARK: - CustomStringConvertible

extension TimeInterval.Microseconds: CustomStringConvertible {
    
    public var description: String {
        "\(seconds)s \(microseconds)µs"
    }
}

// MARK: - Arithmetic

public extension TimeInterval.Microseconds {
    
    static func + (lhs: TimeInterval.Microseconds, rhs: TimeInterval.Microseconds) -> TimeInterval.Microseconds {
        return .init(
            seconds: lhs.seconds + rhs.seconds,
            microseconds: lhs.microseconds + rhs.microseconds
        )
    }
}

public extension TimeInterval {
    
    static func + (lhs: TimeInterval, rhs: TimeInterval.Microseconds) -> TimeInterval.Microseconds {
        return .init(
            seconds: lhs.seconds + rhs.seconds,
            microseconds: rhs.microseconds
        )
    }
}

// MARK: - C Interop

internal extension TimeInterval.Microseconds {
    
    @usableFromInline
    init(_ bytes: CInterop.TimeIntervalMicroseconds) {
        self.seconds = .init(rawValue: bytes.tv_sec)
        self.microseconds = .init(rawValue: bytes.tv_usec)
    }
    
    @usableFromInline
    var bytes: CInterop.TimeIntervalMicroseconds {
        .init(tv_sec: seconds.rawValue, tv_usec: microseconds.rawValue)
    }
}

// MARK: - Get and Set Current Time

public extension TimeInterval.Microseconds {
    
    /// Returns the system time (since Unix epoch).
    static func timeInvervalSince1970(
        retryOnInterrupt: Bool = true
    ) throws -> TimeInterval.Microseconds {
        return try .init(.getTime(retryOnInterrupt: retryOnInterrupt).get())
    }
    
    /// Sets the system time (since Unix epoch).
    func setTimeInvervalSince1970(
        _ timeInverval: TimeInterval.Microseconds,
        retryOnInterrupt: Bool = true
    ) throws {
        try bytes.setTime(retryOnInterrupt: retryOnInterrupt).get()
    }
}

internal extension CInterop.TimeIntervalMicroseconds {
    
    @usableFromInline
    static func getTime(retryOnInterrupt: Bool) -> Result<CInterop.TimeIntervalMicroseconds, Errno> {
        var time = CInterop.TimeIntervalMicroseconds()
        return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            // The use of the timezone structure is obsolete; the tz argument
            // should normally be specified as NULL.
            system_gettimeofday(&time, nil)
        }.map { time }
    }
    
    func setTime(retryOnInterrupt: Bool) -> Result<(), Errno> {
        withUnsafePointer(to: self) { time in
            nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
                system_settimeofday(time, nil)
            }
        }
    }
}
