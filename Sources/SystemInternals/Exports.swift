/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import CSystem

// TODO: Should CSystem just include all the header files we need?

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#else
#error("Unsupported Platform")
#endif

public typealias COffT = off_t

// MARK: syscalls and variables

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
public var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#else
public var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#endif

public func system_open(_ path: UnsafePointer<CChar>, _ oflag: Int32) -> CInt {
  open(path, oflag)
}

public func system_open(
  _ path: UnsafePointer<CChar>, _ oflag: Int32, _ mode: mode_t
) -> CInt {
  open(path, oflag, mode)
}

public func system_close(_ fd: Int32) -> Int32 {
  close(fd)
}

public func system_read(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
  read(fd, buf, nbyte)
}

public func system_pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  pread(fd, buf, nbyte, offset)
}

public func system_lseek(
  _ fd: Int32, _ off: off_t, _ whence: Int32
) -> off_t {
  lseek(fd, off, whence)
}

public func system_write(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
  write(fd, buf, nbyte)
}

public func system_pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  pwrite(fd, buf, nbyte, offset)
}

// MARK: C stdlib decls

public func system_strerror(_ __errnum: Int32) -> UnsafeMutablePointer<Int8>! {
  strerror(__errnum)
}

public func system_strlen(_ s: UnsafePointer<Int8>) -> Int {
  strlen(s)
}

