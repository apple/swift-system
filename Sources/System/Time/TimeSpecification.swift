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
// time.h

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
/// Represents an elapsed time since a reference point.
///
/// The corresponding C type is `timeval`.
@frozen
public struct TimeSpecification: RawRepresentable {
  public typealias RawValue = CInterop.TimeSpecification

  /// The raw C timeval type.
  @_alwaysEmitIntoClient
  public var rawValue: RawValue

  /// Create a strongly-typed time value from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: RawValue) { self.rawValue = rawValue }
}

extension TimeSpecification {
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

  /// The remaining elapsed time in nanoseconds.
  ///
  /// This value must always be in the range [0, 999999999].
  ///
  /// The corresponding C property is `tv_nsec`.
  @_alwaysEmitIntoClient
  public var nanoseconds: CInterop.Nanoseconds {
    get { rawValue.tv_nsec }
    set { rawValue.tv_nsec = newValue }
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "nanoseconds")
  public var tv_nsec: CInterop.Nanoseconds { nanoseconds }
}

extension TimeSpecification {
  @_alwaysEmitIntoClient
  @inline(__always)
  private static let attosecondsPerNanoseconds: Int64 = 1_000_000_000

  /// Creates a new value, rounded to the closest possible representation.
  @_alwaysEmitIntoClient
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public init(_ duration: Duration) {
    let (seconds, attoseconds) = duration.components
    let nanoseconds = attoseconds / Self.attosecondsPerNanoseconds
    self.rawValue = .init(
      tv_sec: CInterop.Time(truncatingIfNeeded: seconds),
      tv_nsec: CInterop.Nanoseconds(nanoseconds))
  }

  /// Creates a new value, if the given duration can be represented exactly.
  @_alwaysEmitIntoClient
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public init?(exactly duration: Duration) {
    let (seconds, attoseconds) = duration.components
    guard
      let seconds = CInterop.Time(exactly: seconds),
      attoseconds.isMultiple(of: Self.attosecondsPerNanoseconds)
    else {
      return nil
    }
    let nanoseconds = attoseconds / Self.attosecondsPerNanoseconds
    self.rawValue = .init(
      tv_sec: CInterop.Time(truncatingIfNeeded: seconds),
      tv_nsec: CInterop.Nanoseconds(nanoseconds))
  }

  @_alwaysEmitIntoClient
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public var duration: Duration {
    let seconds = Int64(self.seconds)
    let attoseconds = Int64(self.nanoseconds) *
    Self.attosecondsPerNanoseconds
    return .init(
      secondsComponent: seconds,
      attosecondsComponent: attoseconds)
  }
}

extension TimeSpecification: AdditiveArithmetic {
  @_alwaysEmitIntoClient
  @inline(__always)
  private static let nanosecondsPerSecond: CInterop.Nanoseconds = 1_000_000_000

  @_alwaysEmitIntoClient
  public static var zero: Self {
    Self(rawValue: .init(tv_sec: 0, tv_nsec: 0))
  }

  @_alwaysEmitIntoClient
  public static func + (lhs: Self, rhs: Self) -> Self {
    var newValue = TimeSpecification.zero
    newValue.seconds = lhs.seconds + rhs.seconds
    newValue.nanoseconds = lhs.nanoseconds + rhs.nanoseconds
    if (newValue.nanoseconds >= Self.nanosecondsPerSecond) {
      newValue.seconds += 1
      newValue.nanoseconds -= Self.nanosecondsPerSecond
    }
    return newValue
  }

  @_alwaysEmitIntoClient
  public static func - (lhs: Self, rhs: Self) -> Self {
    var newValue = TimeSpecification.zero
    newValue.seconds = lhs.seconds - rhs.seconds;
    newValue.nanoseconds = lhs.nanoseconds - rhs.nanoseconds
    if (newValue.nanoseconds < 0) {
      newValue.seconds -= 1
      newValue.nanoseconds += Self.nanosecondsPerSecond
    }
    return newValue
  }
}

extension TimeSpecification: Comparable {
  @_alwaysEmitIntoClient
  public static func < (lhs: Self, rhs: Self) -> Bool {
    guard lhs.seconds == rhs.seconds else {
      return lhs.seconds < rhs.seconds
    }
    return lhs.nanoseconds < rhs.nanoseconds
  }
}

extension TimeSpecification: Equatable {
  @_alwaysEmitIntoClient
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.seconds == rhs.seconds && lhs.nanoseconds == rhs.nanoseconds
  }
}
#endif
