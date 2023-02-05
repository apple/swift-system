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
/// The value an interval timer is configured to run on.
///
/// The corresponding C type is `itimerval`.
@frozen
public struct IntervalTimerValue: RawRepresentable {
  public typealias RawValue = CInterop.IntervalTimerValue

  /// The raw C itimerval type.
  @_alwaysEmitIntoClient
  public var rawValue: RawValue

  /// Create a strongly-typed internal timer value from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: RawValue) { self.rawValue = rawValue }
}

extension IntervalTimerValue {
  /// The initial delay before running the timer.
  ///
  /// Setting the initial delay to `0` disables the timer.
  ///
  /// The corresponding C property is `it_value`.
  @_alwaysEmitIntoClient
  public var initialDelay: TimeValue {
    get { TimeValue(rawValue: rawValue.it_value) }
    set { rawValue.it_value = newValue.rawValue }
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "initialDelay")
  public var it_value: TimeValue { initialDelay }

  /// The subsequent delay after the initial delay before running the timer.
  ///
  /// Setting the interval to `0` causes a timer to be disabled after its next
  /// expiration, assuming initial delay is non-zero.
  ///
  /// The corresponding C property is `it_interval`.
  @_alwaysEmitIntoClient
  public var interval: TimeValue {
    get { TimeValue(rawValue: rawValue.it_interval) }
    set { rawValue.it_interval = newValue.rawValue }
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "interval")
  public var it_interval: TimeValue { interval }
}
#endif
