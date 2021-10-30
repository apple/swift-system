/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Clock
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
@frozen
public struct Clock: RawRepresentable, Equatable, Hashable, Codable {
    
    public let rawValue: CInterop.ClockID.RawValue
    
    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.ClockID.RawValue) {
        self.rawValue = rawValue
    }
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public extension Clock {
    
    /// Get the precision.
    @_alwaysEmitIntoClient
    func precision(
        retryOnInterrupt: Bool = true
    ) throws -> TimeInterval.Nanoseconds {
        return try getValue(system_clock_getres, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// Get the current time.
    @_alwaysEmitIntoClient
    func time(
        retryOnInterrupt: Bool = true
    ) throws -> TimeInterval.Nanoseconds {
        return try getValue(system_clock_gettime, retryOnInterrupt: retryOnInterrupt).get()
    }
    
    /// Set the current time.
    @available(iOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @_alwaysEmitIntoClient
    func setTime(
        _ newValue: TimeInterval.Nanoseconds,
        retryOnInterrupt: Bool = true
    ) throws {
        try setValue(newValue, system_clock_settime, retryOnInterrupt: retryOnInterrupt).get()
    }
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
internal extension Clock {
    
    @_alwaysEmitIntoClient
    init(_ bytes: CInterop.ClockID) {
        self.init(rawValue: bytes.rawValue)
    }
    
    @_alwaysEmitIntoClient
    var bytes: CInterop.ClockID {
        return .init(rawValue: self.rawValue)
    }
    
    @usableFromInline
    func getValue(
        _ function: (CInterop.ClockID, UnsafeMutablePointer<CInterop.TimeIntervalNanoseconds>) -> Int32,
        retryOnInterrupt: Bool
    ) -> Result<TimeInterval.Nanoseconds, Errno> {
        var time = CInterop.TimeIntervalNanoseconds()
        return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            function(self.bytes, &time)
        }.map { TimeInterval.Nanoseconds(time) }
    }
    
    @usableFromInline
    func setValue(
        _ newValue: TimeInterval.Nanoseconds,
        _ function: (CInterop.ClockID, UnsafePointer<CInterop.TimeIntervalNanoseconds>) -> Int32,
        retryOnInterrupt: Bool
    ) -> Result<(), Errno> {
        withUnsafePointer(to: newValue.bytes) { time in
            nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
                function(self.bytes, time)
            }
        }
    }
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension Clock: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        let descriptions: [Clock: String] = [
            .realtime: "Clock.realtime",
            .monotonic: "Clock.monotonic",
            .processCPUTime: "Clock.processCPUTime",
            .threadCPUTime: "Clock.threadCPUTime",
            .monotonicRaw: "Clock.monotonicRaw",
            .monotonicRawApproximated: "Clock.monotonicRawApproximated",
            .uptimeRaw: "Clock.uptimeRaw",
            .uptimeRawApproximated: "Clock.uptimeRawApproximated"
        ]
        return descriptions[self] ?? "Clock(rawValue: \(rawValue))"
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: - Definitions

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public extension Clock {
    
    /// System-wide realtime clock. Setting this clock requires appropriate privileges.
    @_alwaysEmitIntoClient
    static var realtime: Clock { Clock(_CLOCK_REALTIME) }
    
    /// Clock that cannot be set and represents monotonic time since some unspecified starting point.
    @_alwaysEmitIntoClient
    static var monotonic: Clock { Clock(_CLOCK_MONOTONIC) }
    
    /// High-resolution per-process timer from the CPU.
    @_alwaysEmitIntoClient
    static var processCPUTime: Clock { Clock(_CLOCK_PROCESS_CPUTIME_ID) }
    
    /// Thread-specific CPU-time clock.
    @_alwaysEmitIntoClient
    static var threadCPUTime: Clock { Clock(_CLOCK_THREAD_CPUTIME_ID) }
        
    ///
    @_alwaysEmitIntoClient
    static var monotonicRaw: Clock { Clock(_CLOCK_MONOTONIC_RAW) }
    
    ///
    @_alwaysEmitIntoClient
    static var monotonicRawApproximated: Clock { Clock(_CLOCK_MONOTONIC_RAW_APPROX) }
    
    ///
    @_alwaysEmitIntoClient
    static var uptimeRaw: Clock { Clock(_CLOCK_UPTIME_RAW) }
    
    ///
    @_alwaysEmitIntoClient
    static var uptimeRawApproximated: Clock { Clock(_CLOCK_UPTIME_RAW_APPROX) }
}
