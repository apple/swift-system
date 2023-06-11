/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

// Specification:
// - POSIX.1-2017
// - IEEE Std 1003.1™-2017
// - The Open Group Technical Standard Base Specifications, Issue 7
// Reference: https://pubs.opengroup.org/onlinepubs/9699919799
// sys/time.h

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
/// Represents an elapsed time since a reference point.
///
/// The corresponding C type is `timeval`.
@frozen
public struct TimeValue: RawRepresentable {
  public typealias RawValue = CInterop.TimeValue

  /// The raw C timeval type.
  @_alwaysEmitIntoClient
  public var rawValue: RawValue

  /// Create a strongly-typed time value from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: RawValue) { self.rawValue = rawValue }
}

extension TimeValue {
  /// The elapsed time in seconds.
  ///
  /// The corresponding C property is `tv_sec`.
  @_alwaysEmitIntoClient
  public var seconds: CInterop.Time {
    get { rawValue.tv_sec }
    set { rawValue.tv_sec = newValue }
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "seconds")
  public var tv_sec: CInterop.Time { seconds }

  /// The remaining elapsed time in microseconds.
  ///
  /// This value must always be in the range [0, 999999].
  ///
  /// The corresponding C property is `tv_usec`.
  @_alwaysEmitIntoClient
  public var microseconds: CInterop.Microseconds {
    get { rawValue.tv_usec }
    set { rawValue.tv_usec = newValue }
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "microseconds")
  public var tv_usec: CInterop.Microseconds { microseconds }
}

extension TimeValue {
  @_alwaysEmitIntoClient
  @inline(__always)
  private static let attosecondsPerMicrosecond: Int64 = 1_000_000_000_000

  /// Creates a new value, rounded to the closest possible representation.
  @_alwaysEmitIntoClient
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public init(_ duration: Duration) {
    let (seconds, attoseconds) = duration.components
    let microseconds = attoseconds / Self.attosecondsPerMicrosecond
    self.rawValue = .init(
      tv_sec: CInterop.Time(truncatingIfNeeded: seconds),
      tv_usec: CInterop.Microseconds(microseconds))
  }

  /// Creates a new value, if the given duration can be represented exactly.
  @_alwaysEmitIntoClient
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public init?(exactly duration: Duration) {
    let (seconds, attoseconds) = duration.components
    guard
      let seconds = CInterop.Time(exactly: seconds),
      attoseconds.isMultiple(of: Self.attosecondsPerMicrosecond)
    else {
      return nil
    }
    let microseconds = attoseconds / Self.attosecondsPerMicrosecond
    self.rawValue = .init(
      tv_sec: CInterop.Time(truncatingIfNeeded: seconds),
      tv_usec: CInterop.Microseconds(microseconds))
  }

  @_alwaysEmitIntoClient
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var duration: Duration {
    let seconds = Int64(self.seconds)
    let attoseconds = Int64(self.microseconds) *
    Self.attosecondsPerMicrosecond
    return .init(
      secondsComponent: seconds,
      attosecondsComponent: attoseconds)
  }
}

extension TimeValue: AdditiveArithmetic {
  @_alwaysEmitIntoClient
  @inline(__always)
  private static let microsecondsPerSecond: CInterop.Microseconds = 1_000_000

  @_alwaysEmitIntoClient
  public static var zero: TimeValue {
    Self(rawValue: .init(tv_sec: 0, tv_usec: 0))
  }

  @_alwaysEmitIntoClient
  public static func + (lhs: Self, rhs: Self) -> Self {
    var newValue = TimeValue.zero
    newValue.seconds = lhs.seconds + rhs.seconds
    newValue.microseconds = lhs.microseconds + rhs.microseconds
    if (newValue.microseconds >= Self.microsecondsPerSecond) {
      newValue.seconds += 1
      newValue.microseconds -= Self.microsecondsPerSecond
    }
    return newValue
  }

  @_alwaysEmitIntoClient
  public static func - (lhs: Self, rhs: Self) -> Self {
    var newValue = TimeValue.zero
    newValue.seconds = lhs.seconds - rhs.seconds;
    newValue.microseconds = lhs.microseconds - rhs.microseconds
    if (newValue.microseconds < 0) {
      newValue.seconds -= 1
      newValue.microseconds += Self.microsecondsPerSecond
    }
    return newValue
  }
}

extension TimeValue: Comparable {
  @_alwaysEmitIntoClient
  public static func < (lhs: Self, rhs: Self) -> Bool {
    guard lhs.seconds == rhs.seconds else {
      return lhs.seconds < rhs.seconds
    }
    return lhs.microseconds < rhs.microseconds
  }
}

extension TimeValue: Equatable {
  @_alwaysEmitIntoClient
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.seconds == rhs.seconds && lhs.microseconds == rhs.microseconds
  }
}
#endif
