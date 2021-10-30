/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// POSIX Time Components
@frozen
public struct TimeComponents: Equatable, Hashable, Codable {
    
    public let second: Int
    
    public let minute: Int
    
    public let hour: Int
    
    public let dayOfMonth: Int
    
    public let month: Month
    
    public let year: Int
    
    public let weekday: Weekday
    
    public let dayOfYear: Int
}

public extension TimeComponents {
    
    @_alwaysEmitIntoClient
    init(time: Time) {
        self.init(.init(utc: time.rawValue))
    }
}

public extension Time {
    
    @_alwaysEmitIntoClient
    init(components: TimeComponents) {
        self.init(rawValue: .init(utc: .init(components)))
    }
}

// MARK: - Supporting Types

public extension TimeComponents {
    
    enum Weekday: Int, Codable, CaseIterable {
        
        case sunday
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
    }
    
    enum Month: Int, Codable, CaseIterable {
        
        case january
        case february
        case march
        case abril
        case may
        case june
        case july
        case august
        case september
        case october
        case november
        case december
    }
}

// MARK: - CustomStringConvertible

extension TimeComponents: CustomStringConvertible {
    
    public var description: String {
        return String(CInterop.TimeComponents(self))
    }
}

// MARK: - C Interop

internal extension TimeComponents {
    
    @usableFromInline
    init(_ cValue: CInterop.TimeComponents) {
        self.second = numericCast(cValue.tm_sec)
        self.minute = numericCast(cValue.tm_min)
        self.hour = numericCast(cValue.tm_hour)
        self.dayOfMonth = numericCast(cValue.tm_mday)
        self.month = TimeComponents.Month(rawValue: numericCast(cValue.tm_mon)) ?? .january
        self.year = 1900 + numericCast(cValue.tm_year)
        self.weekday = TimeComponents.Weekday(rawValue: numericCast(cValue.tm_wday)) ?? .sunday
        self.dayOfYear = numericCast(cValue.tm_yday)
    }
}

internal extension CInterop.TimeComponents {
    
    @usableFromInline
    init(_ value: TimeComponents) {
        self.init(
            tm_sec: numericCast(value.second),
            tm_min: numericCast(value.minute),
            tm_hour: numericCast(value.hour),
            tm_mday: numericCast(value.dayOfMonth),
            tm_mon: numericCast(value.month.rawValue),
            tm_year: numericCast(value.year - 1900),
            tm_wday: numericCast(value.weekday.rawValue),
            tm_yday: numericCast(value.dayOfYear),
            tm_isdst: -1,
            tm_gmtoff: 0,
            tm_zone: nil
        )
    }
    
    @usableFromInline
    init(utc time: CInterop.Time) {
        self.init()
        let _ = withUnsafePointer(to: time) {
            system_gmtime_r($0, &self)
        }
    }
    
    @usableFromInline
    init(local time: CInterop.Time) {
        self.init()
        let _ = withUnsafePointer(to: time) {
            system_localtime_r($0, &self)
        }
    }
}

internal extension String {
    
    @usableFromInline
    init(_ timeComponents: CInterop.TimeComponents) {
        self.init(_unsafeUninitializedCapacity: 26) { buffer in
            buffer.withMemoryRebound(to: CChar.self) { cString in
                withUnsafePointer(to: timeComponents) {
                    system_strlen(.init(system_asctime_r($0, cString.baseAddress!))) - 1
                }
            }
        }
    }
}

internal extension CInterop.Time {
    
    @usableFromInline
    init(utc timeComponents: CInterop.TimeComponents) {
        self = withUnsafePointer(to: timeComponents) {
            system_timegm($0)
        }
    }
    
    @usableFromInline
    init(local timeComponents: CInterop.TimeComponents) {
        self = withUnsafePointer(to: timeComponents) {
            system_timelocal($0)
        }
    }
}
