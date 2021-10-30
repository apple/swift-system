/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#elseif os(Windows)
import ucrt
#else
#error("Unsupported Platform")
#endif

// Interacting with the mocking system, tracing, etc., is a potentially significant
// amount of code size, so we hand outline that code for every syscall

// open
internal func system_open(
  _ path: UnsafePointer<CInterop.PlatformChar>, _ oflag: Int32
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(path: path, oflag)
  }
#endif
  return open(path, oflag)
}

internal func system_open(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ oflag: Int32, _ mode: CInterop.Mode
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(path: path, oflag, mode)
  }
#endif
  return open(path, oflag, mode)
}

// close
internal func system_close(_ fd: Int32) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd) }
#endif
  return close(fd)
}

// read
internal func system_read(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(fd, buf, nbyte) }
#endif
  return read(fd, buf, nbyte)
}

// pread
internal func system_pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(fd, buf, nbyte, offset) }
#endif
  return pread(fd, buf, nbyte, offset)
}

// lseek
internal func system_lseek(
  _ fd: Int32, _ off: off_t, _ whence: Int32
) -> off_t {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockOffT(fd, off, whence) }
#endif
  return lseek(fd, off, whence)
}

// write
internal func system_write(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(fd, buf, nbyte) }
#endif
  return write(fd, buf, nbyte)
}

// pwrite
internal func system_pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(fd, buf, nbyte, offset) }
#endif
  return pwrite(fd, buf, nbyte, offset)
}

internal func system_dup(_ fd: Int32) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd) }
  #endif
  return dup(fd)
}

internal func system_dup2(_ fd: Int32, _ fd2: Int32) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, fd2) }
  #endif
  return dup2(fd, fd2)
}
#if !os(Windows)
internal func system_pipe(_ fds: UnsafeMutablePointer<Int32>) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fds) }
#endif
  return pipe(fds)
}
#endif

@inline(__always)
internal func system_clock() -> CInterop.Clock {
  return clock()
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
@usableFromInline
internal func system_clock_getres(
    _ id: CInterop.ClockID,
    _ time: UnsafeMutablePointer<CInterop.TimeIntervalNanoseconds>
) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(id.rawValue, time) }
  #endif
  return clock_getres(id, time)
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
@usableFromInline
internal func system_clock_gettime(
    _ id: CInterop.ClockID,
    _ time: UnsafeMutablePointer<CInterop.TimeIntervalNanoseconds>
) -> Int32 {
  #if ENABLE_MOCKING
    if mockingEnabled { return _mock(id.rawValue, time) }
  #endif
  return clock_gettime(id, time)
}

@available(macOS 10.12, *)
@available(iOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@usableFromInline
internal func system_clock_settime(
    _ id: CInterop.ClockID,
    _ time: UnsafePointer<CInterop.TimeIntervalNanoseconds>
) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(id.rawValue, time) }
  #endif
  return clock_settime(id, time)
}

internal func system_gettimeofday(
    _ time: UnsafeMutablePointer<CInterop.TimeIntervalMicroseconds>,
    _ tz: UnsafeMutableRawPointer?
) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(time, tz) }
  #endif
  return gettimeofday(time, tz)
}

internal func system_settimeofday(
    _ time: UnsafePointer<CInterop.TimeIntervalMicroseconds>,
    _ tz: UnsafePointer<timezone>?
) -> Int32 {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(time, tz) }
  #endif
  return settimeofday(time, tz)
}

@discardableResult
internal func system_gmtime_r(
    _ time: UnsafePointer<CInterop.Time>,
    _ timeComponents: UnsafeMutablePointer<CInterop.TimeComponents>
) -> UnsafeMutablePointer<CInterop.TimeComponents> {
  #if ENABLE_MOCKING
  if mockingEnabled {
      let _ = _mock(time, timeComponents)
      return timeComponents
  }
  #endif
  return gmtime_r(time, timeComponents)
}

internal func system_timegm(
    _ time: UnsafePointer<CInterop.TimeComponents>
) -> CInterop.Time {
    return timegm(.init(mutating: time))
}

@discardableResult
internal func system_localtime_r(
    _ time: UnsafePointer<CInterop.Time>,
    _ timeComponents: UnsafeMutablePointer<CInterop.TimeComponents>
) -> UnsafeMutablePointer<CInterop.TimeComponents> {
  #if ENABLE_MOCKING
  if mockingEnabled {
      let _ = _mock(time, timeComponents)
      return timeComponents
  }
  #endif
  return localtime_r(time, timeComponents)
}

@discardableResult
internal func system_asctime_r(
    _ timeComponents: UnsafePointer<CInterop.TimeComponents>,
    _ string: UnsafeMutablePointer<CChar>
) -> UnsafeMutablePointer<CChar> {
  return asctime_r(timeComponents, string)
}

internal func system_timelocal(
    _ time: UnsafePointer<CInterop.TimeComponents>
) -> CInterop.Time {
  return timelocal(.init(mutating: time))
}

internal func system_modf(_ value: Double) -> (Double, Double) {
    var integerValue: Double = 0
    let decimalValue = modf(value, &integerValue)
    return (integerValue, decimalValue)
}
