/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode,
  _ flag: Int32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, mode, flag) }
#endif
  return fchmodat(fd, path, mode, flag)
}

internal func system_chown(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ userID: CInterop.UserID,
  _ groupID: CInterop.GroupID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, userID, groupID) }
#endif
  return chown(path, userID, groupID)
}

internal func system_lchown(
  _ path: UnsafePointer<CInterop.PlatformChar>,
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
  _ path: UnsafePointer<CInterop.PlatformChar>,
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
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ flag: UInt32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, flag) }
#endif
  return chflags(path, flag)
}

internal func system_lchflags(
  _ path: UnsafePointer<CInterop.PlatformChar>,
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

internal func system_umask(
    _ cmask: CInterop.Mode
) -> CInterop.Mode {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockModeT(cmask) }
#endif
  return umask(cmask)
}

internal func system_mkfifo(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return mkfifo(path, mode)
}

@available(macOS 13.0, *)
internal func system_mkfifoat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return mkfifoat(fd, path, mode)
}

internal func system_mknod(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode,
  _ deviceID: CInterop.DeviceID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode, deviceID) }
#endif
  return mknod(path, mode, deviceID)
}

@available(macOS 13.0, *)
internal func system_mknodat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode,
  _ deviceID: CInterop.DeviceID
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode, deviceID) }
#endif
  return mknodat(fd, path, mode, deviceID)
}

internal func system_mkdir(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, mode) }
#endif
  return mkdir(path, mode)
}

internal func system_mkdirat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, mode) }
#endif
  return mkdirat(fd, path, mode)
}

#if os(FreeBSD)
internal func system_utimens(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ times: UnsafePointer<timespec>?
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, times) }
#endif
  return utimens(path, times)
}
#endif

#if os(FreeBSD)
internal func system_lutimens(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ times: UnsafePointer<timespec>?
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(path, times) }
#endif
  return lutimens(path, times)
}
#endif

internal func system_utimensat(
  _ fd: Int32,
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ times: UnsafePointer<timespec>?,
  _ flag: Int32
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, path, times, flag) }
#endif
  return utimensat(fd, path, times, flag)
}

internal func system_futimens(
  _ fd: Int32,
  _ times: UnsafePointer<timespec>?
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd, times) }
#endif
  return futimens(fd, times)
}
#endif
