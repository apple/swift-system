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
#else
#error("Unsupported Platform")
#endif

// Strip the mock_system prefix and the arg list suffix
private func originalSyscallName(_ s: String) -> String {
  precondition(s.starts(with: "mock_system_"))
  return String(s.dropFirst("mock_system_".count).prefix { $0.isLetter })
}

private func mockImpl(
  name: String,
  _ args: [AnyHashable]
) -> CInt {
  #if ENABLE_MOCKING
  let origName = originalSyscallName(name)
  guard let driver = currentMockingDriver else {
    fatalError("Mocking requested from non-mocking context")
  }
  driver.trace.add(Trace.Entry(name: origName, args))

  switch driver.forceErrno {
  case .none: break
  case .always(let e):
    errno = e
    return -1
  case .counted(let e, let count):
    assert(count >= 1)
    errno = e
    driver.forceErrno = count > 1 ? .counted(errno: e, count: count-1) : .none
    return -1
  }
  #else
  fatalError("Mocking uses in non-mocking-enabld build")
  #endif

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

// Interacting with the mocking system, tracing, etc., is a potentially significant
// amount of code size, so we hand outline that code for every syscall

// open
public func system_open(_ path: UnsafePointer<CChar>, _ oflag: Int32) -> CInt {
  if _fastPath(!mockingEnabled) { return open(path, oflag) }
  return mock_system_open(path, oflag)
}

@inline(never)
private func mock_system_open(_ path: UnsafePointer<CChar>, _ oflag: Int32) -> CInt {
  mock(String(cString: path), oflag)
}

public func system_open(
  _ path: UnsafePointer<CChar>, _ oflag: Int32, _ mode: mode_t
) -> CInt {
  if _fastPath(!mockingEnabled) { return open(path, oflag, mode) }
  return mock_system_open(path, oflag, mode)
}

@inline(never)
private func mock_system_open(
  _ path: UnsafePointer<CChar>, _ oflag: Int32, _ mode: mode_t
) -> CInt {
  mock(String(cString: path), oflag, mode)
}

// close
public func system_close(_ fd: Int32) -> Int32 {
  if _fastPath(!mockingEnabled) { return close(fd) }
  return mock_system_close(fd)
}

@inline(never)
private func mock_system_close(_ fd: Int32) -> Int32 {
  mock(fd)
}

// read
public func system_read(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
  if _fastPath(!mockingEnabled) { return read(fd, buf, nbyte) }
  return mock_system_read(fd, buf, nbyte)
}

@inline(never)
private func mock_system_read(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
  mockInt(fd, buf, nbyte)
}

// pread
public func system_pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  if _fastPath(!mockingEnabled) { return pread(fd, buf, nbyte, offset) }
  return mock_system_pread(fd, buf, nbyte, offset)
}

@inline(never)
private func mock_system_pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  mockInt(fd, buf, nbyte, offset)
}

// lseek
public func system_lseek(
  _ fd: Int32, _ off: off_t, _ whence: Int32
) -> off_t {
  if _fastPath(!mockingEnabled) { return lseek(fd, off, whence) }
  return mock_system_lseek(fd, off, whence)
}

@inline(never)
private func mock_system_lseek(
  _ fd: Int32, _ off: off_t, _ whence: Int32
) -> off_t {
  mockOffT(fd, off, whence)
}

// write
public func system_write(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
  if _fastPath(!mockingEnabled) { return write(fd, buf, nbyte) }
  return mock_system_write(fd, buf, nbyte)
}

@inline(never)
private func mock_system_write(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
  mockInt(fd, buf, nbyte)
}

// pwrite
public func system_pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  if _fastPath(!mockingEnabled) { return pwrite(fd, buf, nbyte, offset) }
  return mock_system_pwrite(fd, buf, nbyte, offset)
}

@inline(never)
private func mock_system_pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  mockInt(fd, buf, nbyte, offset)
}
