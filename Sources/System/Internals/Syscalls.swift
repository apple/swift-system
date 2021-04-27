/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
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
  _ fd: Int32, _ buf: UnsafeMutableRawPointer?, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(fd, buf, nbyte) }
#endif
  return read(fd, buf, nbyte)
}

// pread
internal func system_pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer?, _ nbyte: Int, _ offset: off_t
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
  _ fd: Int32, _ buf: UnsafeRawPointer?, _ nbyte: Int
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(fd, buf, nbyte) }
#endif
  return write(fd, buf, nbyte)
}

// pwrite
internal func system_pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer?, _ nbyte: Int, _ offset: off_t
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

#if !os(Windows)
internal func system_ftruncate(_ fd: Int32, _ length: off_t) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, length) }
#endif
  return ftruncate(fd, length)
}
#endif

#if !os(Windows)
internal func system_stat(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ buf: UnsafeMutablePointer<stat>
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, buf) }
#endif
  return stat(path, buf)
}

internal func system_lstat(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ buf: UnsafeMutablePointer<stat>
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, buf) }
#endif
  return lstat(path, buf)
}

internal func system_fstat(
  _ fd: Int32,
  _ buf: UnsafeMutablePointer<stat>
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, buf) }
#endif
  return fstat(fd, buf)
}

internal func system_fstatat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ buf: UnsafeMutablePointer<stat>,
  _ flag: Int32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, buf, flag) }
#endif
  return fstatat(fd, path, buf, flag)
}

internal func system_chmod(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return chmod(path, mode)
}

internal func system_lchmod(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return lchmod(path, mode)
}

internal func system_fchmod(
  _ fd: Int32,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, mode) }
#endif
  return fchmod(fd, mode)
}

internal func system_fchmodat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ mode: CInterop.Mode,
  _ flag: Int32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, mode, flag) }
#endif
  return fchmodat(fd, path, mode, flag)
}

internal func system_chown(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ userID: CInterop.UserID,
  _ groupID: CInterop.GroupID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, userID, groupID) }
#endif
  return chown(path, userID, groupID)
}

internal func system_lchown(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ userID: CInterop.UserID,
  _ groupID: CInterop.GroupID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, userID, groupID) }
#endif
  return lchown(path, userID, groupID)
}

internal func system_fchown(
  _ fd: Int32,
  _ userID: CInterop.UserID,
  _ groupID: CInterop.GroupID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, userID, groupID) }
#endif
  return fchown(fd, userID, groupID)
}

internal func system_fchownat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ userID: CInterop.UserID,
  _ groupID: CInterop.GroupID,
  _ flag: Int32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, userID, groupID, flag) }
#endif
  return fchownat(fd, path, userID, groupID, flag)
}

internal func system_chflags(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ flag: UInt32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, flag) }
#endif
  return chflags(path, flag)
}

internal func system_lchflags(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ flag: UInt32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, flag) }
#endif
  return lchflags(path, flag)
}

internal func system_fchflags(
  _ fd: Int32,
  _ flag: UInt32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, flag) }
#endif
  return fchflags(fd, flag)
}

#if ENABLE_MOCKING
internal var currentModeMask = CInterop.Mode(S_IWGRP|S_IWOTH)
#endif
internal func system_umask(
    _ cmask: CInterop.Mode
) -> CInterop.Mode {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockModeT(cmask) }
#endif
  return umask(cmask)
}

// mkfifo
internal func system_mkfifo(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return mkfifo(path, mode)
}

// mknod
internal func system_mknod(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ mode: CInterop.Mode,
  _ deviceID: CInterop.DeviceID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode, deviceID) }
#endif
  return mknod(path, mode, deviceID)
}

internal func system_mkdir(
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return mkdir(path, mode)
}

internal func system_mkdirat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, mode) }
#endif
  return mkdirat(fd, path, mode)
}

@available(macOS 10.13, *)
internal func system_futimens(
  _ fd: Int32,
  _ times: UnsafePointer<timespec> // FIXME: is this really nullable?
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, times) }
#endif
  return futimens(fd, times)
}

@available(macOS 10.13, *)
internal func system_utimensat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>?,
  _ times: UnsafePointer<timespec>, // FIXME: is this really nullable?
  _ flag: Int32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, times, flag) }
#endif
  return utimensat(fd, path, times, flag)
}
#endif
