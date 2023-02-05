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
/// A system provided timer which can be configured to run after an initial
/// delay and subsequent interval.
///
/// The corresponding C type is `int`.
@frozen
public struct IntervalTimer: RawRepresentable {
  public typealias RawValue = CInterop.IntervalTimer

  /// The raw C ITIMER value.
  @_alwaysEmitIntoClient
  public var rawValue: RawValue

  /// Create a strongly-typed interval timer from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: RawValue) { self.rawValue = rawValue }
}

extension IntervalTimer {
  /// A timer which decrements in real time.
  ///
  /// A `SIGALRM` signal is delivered when this timer expires.
  ///
  /// The corresponding C timer is `ITIMER_REAL`.
  @_alwaysEmitIntoClient
  public static var real: Self { Self(rawValue: _ITIMER_REAL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "real")
  public static var ITIMER_REAL: Self { real }

  /// A timer which decrements in process virtual time.
  ///
  /// The timer runs only while the process is executing. A `SIGVTALRM` signal
  /// is delivered when this timer expires.
  ///
  /// The corresponding C timer is `ITIMER_VIRTUAL`.
  @_alwaysEmitIntoClient
  public static var virtual: Self { Self(rawValue: _ITIMER_VIRTUAL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "virtual")
  public static var ITIMER_VIRTUAL: Self { virtual }

  /// A timer which decrements both in process virtual time and when the system
  /// is running on behalf of the process.
  ///
  /// This timer is designed to be used by interpreters when statistically
  /// profiling the execution of interpreted programs. A `SIGPROF` signal
  /// is delivered when this timer expires. Because this signal may interrupt
  /// in-progress system calls, programs using this timer must be prepared to
  /// restart interrupted system calls.
  ///
  /// The corresponding C timer is `ITIMER_PROF`.
  @_alwaysEmitIntoClient
  public static var profile: Self { Self(rawValue: _ITIMER_PROF) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "profile")
  public static var ITIMER_PROF: Self { profile }
}

extension IntervalTimer {
  /// Returns the current value for the timer.
  ///
  /// - Returns: The current value of the timer.
  ///
  /// The corresponding C function is `getitimer`.
  @_alwaysEmitIntoClient
  public func get() throws -> IntervalTimerValue {
    try _get().get()
  }

  @usableFromInline
  internal func _get() -> Result<IntervalTimerValue, Errno> {
    var currentValue = itimerval()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_getitimer(self.rawValue, &currentValue)
    }
    .map {
      IntervalTimerValue(rawValue: currentValue)
    }
  }

  /// Sets a timer to run on specified value.
  ///
  /// If the initial delay is non-zero, it indicates the time to the next timer
  /// expiration. If the interval is non-zero, it specifies a value to be used
  /// in reloading initial delay when the timer expires.
  ///
  /// Setting the initial delay to `0` disables the timer.
  /// Setting the interval to `0` causes a timer to be disabled after its next
  /// expiration, assuming initial delay is non-zero.
  ///
  /// - Parameters:
  ///   - newValue: The new interval to run the timer.
  /// - Returns: The previous value of the timer.
  ///
  /// The corresponding C function is `setitimer`.
  @_alwaysEmitIntoClient
  @discardableResult
  public func set(newValue: IntervalTimerValue) throws -> IntervalTimerValue {
    try _set(newValue: newValue).get()
  }

  @usableFromInline
  internal func _set(
    newValue: IntervalTimerValue
  ) -> Result<IntervalTimerValue, Errno> {
    var newValue = newValue.rawValue
    var oldValue = itimerval()
    return nothingOrErrno(retryOnInterrupt: false) {
      system_setitimer(self.rawValue, &newValue, &oldValue)
    }
    .map {
      IntervalTimerValue(rawValue: oldValue)
    }
  }
}
#endif
