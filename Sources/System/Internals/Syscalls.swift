/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif os(Windows)
import ucrt
#elseif canImport(Android)
import Android
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
#if os(Android)
  var zero = UInt8.zero
  return withUnsafeMutablePointer(to: &zero) {
    // this pread has a non-nullable `buf` pointer
    pread(fd, buf ?? UnsafeMutableRawPointer($0), nbyte, offset)
  }
#else
  return pread(fd, buf, nbyte, offset)
#endif
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
#if os(Android)
  var zero = UInt8.zero
  return withUnsafeMutablePointer(to: &zero) {
    // this pwrite has a non-nullable `buf` pointer
    pwrite(fd, buf ?? UnsafeRawPointer($0), nbyte, offset)
  }
#else
  return pwrite(fd, buf, nbyte, offset)
#endif
}

#if !os(WASI)
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
#endif

#if !os(WASI)
internal func system_pipe(_ fds: UnsafeMutablePointer<Int32>) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fds) }
#endif
  return pipe(fds)
}
#endif

internal func system_ftruncate(_ fd: Int32, _ length: off_t) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, length) }
#endif
  return ftruncate(fd, length)
}

internal func system_mkdir(
    _ path: UnsafePointer<CInterop.PlatformChar>,
    _ mode: CInterop.Mode
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path: path, mode) }
#endif
  return mkdir(path, mode)
}

internal func system_rmdir(
    _ path: UnsafePointer<CInterop.PlatformChar>
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path: path) }
#endif
  return rmdir(path)
}

#if SYSTEM_PACKAGE_DARWIN
internal let SYSTEM_CS_DARWIN_USER_TEMP_DIR = _CS_DARWIN_USER_TEMP_DIR

internal func system_confstr(
  _ name: CInt,
  _ buf: UnsafeMutablePointer<CInterop.PlatformChar>,
  _ len: Int
) -> Int {
  return confstr(name, buf, len)
}
#endif

#if !os(Windows)
internal let SYSTEM_AT_REMOVE_DIR = AT_REMOVEDIR
internal let SYSTEM_DT_DIR = DT_DIR
internal typealias system_dirent = dirent
#if os(Linux) || os(Android) || os(FreeBSD) || os(OpenBSD)
internal typealias system_DIRPtr = OpaquePointer
#else
internal typealias system_DIRPtr = UnsafeMutablePointer<DIR>
#endif

internal func system_unlinkat(
  _ fd: CInt,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ flag: CInt
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, flag) }
#endif
return unlinkat(fd, path, flag)
}

internal func system_fdopendir(
  _ fd: CInt
) -> system_DIRPtr? {
  return fdopendir(fd)
}

internal func system_readdir(
  _ dir: system_DIRPtr
) -> UnsafeMutablePointer<dirent>? {
  return readdir(dir)
}

internal func system_rewinddir(
  _ dir: system_DIRPtr
) {
  return rewinddir(dir)
}

internal func system_closedir(
  _ dir: system_DIRPtr
) -> CInt {
  return closedir(dir)
}

internal func system_openat(
  _ fd: CInt,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ oflag: Int32
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(fd, path, oflag)
  }
#endif
  return openat(fd, path, oflag)
}
#endif

internal func system_umask(
  _ mode: CInterop.Mode
) -> CInterop.Mode {
  return umask(mode)
}

internal func system_getenv(
  _ name: UnsafePointer<CChar>
) -> UnsafeMutablePointer<CChar>? {
  return getenv(name)
}
