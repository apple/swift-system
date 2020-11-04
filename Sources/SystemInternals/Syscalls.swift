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

#if ENABLE_MOCKING
// Strip the mock_system prefix and the arg list suffix
private func originalSyscallName(_ s: String) -> String {
  precondition(s.starts(with: "system_"))
  return String(s.dropFirst("system_".count).prefix { $0.isLetter })
}

private func mockImpl(
  name: String,
  _ args: [AnyHashable]
) -> CInt {
  let origName = originalSyscallName(name)
  guard let driver = currentMockingDriver else {
    fatalError("Mocking requested from non-mocking context")
  }
  driver.trace.add(Trace.Entry(name: origName, args))

  switch driver.forceErrno {
  case .none: break
  case .always(let e):
    system_errno = e
    return -1
  case .counted(let e, let count):
    assert(count >= 1)
    system_errno = e
    driver.forceErrno = count > 1 ? .counted(errno: e, count: count-1) : .none
    return -1
  }

  return 0
}

private func mock(
  name: String = #function, _ args: AnyHashable...
) -> CInt {
  precondition(mockingEnabled)
  return mockImpl(name: name, args)
}
private func mockInt(
  name: String = #function, _ args: AnyHashable...
) -> Int {
  Int(mockImpl(name: name, args))
}

private func mockOffT(
  name: String = #function, _ args: AnyHashable...
) -> off_t {
  off_t(mockImpl(name: name, args))
}
#endif // ENABLE_MOCKING

// Interacting with the mocking system, tracing, etc., is a potentially significant
// amount of code size, so we hand outline that code for every syscall

// open
public func system_open(_ path: UnsafePointer<CChar>, _ oflag: Int32) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return mock(String(cString: path), oflag) }
#endif
  return open(path, oflag)
}

public func system_open(
  _ path: UnsafePointer<CChar>, _ oflag: Int32, _ mode: CModeT
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return mock(String(cString: path), oflag, mode) }
#endif
  return open(path, oflag, mode)
}

// close
public func system_close(_ fd: Int32) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return mock(fd) }
#endif
  return close(fd)
}

// read
public func system_read(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return mockInt(fd, buf, nbyte) }
#endif
  return read(fd, buf, nbyte)
}

// pread
public func system_pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return mockInt(fd, buf, nbyte, offset) }
#endif
  return pread(fd, buf, nbyte, offset)
}

// lseek
public func system_lseek(
  _ fd: Int32, _ off: off_t, _ whence: Int32
) -> off_t {
#if ENABLE_MOCKING
  if mockingEnabled { return mockOffT(fd, off, whence) }
#endif
  return lseek(fd, off, whence)
}

// write
public func system_write(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return mockInt(fd, buf, nbyte) }
#endif
  return write(fd, buf, nbyte)
}

// pwrite
public func system_pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return mockInt(fd, buf, nbyte, offset) }
#endif
  return pwrite(fd, buf, nbyte, offset)
}

