/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

extension CInterop {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  /// The C `time_t` type
  public typealias Time = time_t
  /// The C `suseconds_t` type
  public typealias Microseconds = suseconds_t
  /// The C `long` type
  public typealias Nanoseconds = CLong
  /// The C `timeval` type
  public typealias TimeValue = timeval
  /// The C `timespec` type
  public typealias TimeSpecification = timespec
  /// The C `itimerval` type
  public typealias IntervalTimerValue = itimerval
  /// The C type of `ITIMER` values
  public typealias IntervalTimer = CInt
#endif
}
