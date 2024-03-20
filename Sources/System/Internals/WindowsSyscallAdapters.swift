/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Windows)

import ucrt
import WinSDK

@inline(__always)
internal func open(
  _ path: UnsafePointer<CInterop.PlatformChar>, _ oflag: Int32
) -> CInt {
  var fh: CInt = -1
  _ = _wsopen_s(&fh, path, oflag, _SH_DENYNO, _S_IREAD | _S_IWRITE)
  return fh
}

@inline(__always)
internal func open(
  _ path: UnsafePointer<CInterop.PlatformChar>, _ oflag: Int32,
  _ mode: CInterop.Mode
) -> CInt {
  // TODO(compnerd): Apply read/write permissions
  var fh: CInt = -1
  _ = _wsopen_s(&fh, path, oflag, _SH_DENYNO, _S_IREAD | _S_IWRITE)
  return fh
}

@inline(__always)
internal func close(_ fd: Int32) -> Int32 {
  _close(fd)
}

@inline(__always)
internal func lseek(
  _ fd: Int32, _ off: Int64, _ whence: Int32
) -> Int64 {
  _lseeki64(fd, off, whence)
}

@inline(__always)
internal func read(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int
) -> Int {
  Int(_read(fd, buf, numericCast(nbyte)))
}

@inline(__always)
internal func write(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int
) -> Int {
  Int(_write(fd, buf, numericCast(nbyte)))
}

@inline(__always)
internal func lseek(
  _ fd: Int32, _ off: off_t, _ whence: Int32
) -> off_t {
  _lseek(fd, off, whence)
}

@inline(__always)
internal func dup(_ fd: Int32) -> Int32 {
  _dup(fd)
}

@inline(__always)
internal func dup2(_ fd: Int32, _ fd2: Int32) -> Int32 {
  _dup2(fd, fd2)
}

@inline(__always)
internal func pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  let handle: intptr_t = _get_osfhandle(fd)
  if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }

  // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
  let hFile: HANDLE = HANDLE(bitPattern: handle)!

  var ovlOverlapped: OVERLAPPED = OVERLAPPED()
  ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
  ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)

  var nNumberOfBytesRead: DWORD = 0
  if !ReadFile(hFile, buf, DWORD(nbyte), &nNumberOfBytesRead, &ovlOverlapped) {
    ucrt._set_errno(mapWindowsErrorToErrno(GetLastError()))
    return Int(-1)
  }
  return Int(nNumberOfBytesRead)
}

@inline(__always)
internal func pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  let handle: intptr_t = _get_osfhandle(fd)
  if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }

  // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
  let hFile: HANDLE = HANDLE(bitPattern: handle)!

  var ovlOverlapped: OVERLAPPED = OVERLAPPED()
  ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
  ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)

  var nNumberOfBytesWritten: DWORD = 0
  if !WriteFile(hFile, buf, DWORD(nbyte), &nNumberOfBytesWritten,
                &ovlOverlapped) {
    ucrt._set_errno(mapWindowsErrorToErrno(GetLastError()))
    return Int(-1)
  }
  return Int(nNumberOfBytesWritten)
}

@inline(__always)
internal func pipe(_ fds: UnsafeMutablePointer<Int32>) -> CInt {
  return _pipe(fds, 4096, _O_BINARY | _O_NOINHERIT);
}

@inline(__always)
internal func ftruncate(_ fd: Int32, _ length: off_t) -> Int32 {
  let handle: intptr_t = _get_osfhandle(fd)
  if handle == /* INVALID_HANDLE_VALUE */ -1 { ucrt._set_errno(EBADF); return -1 }

  // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
  let hFile: HANDLE = HANDLE(bitPattern: handle)!
  let liDesiredLength = LARGE_INTEGER(QuadPart: LONGLONG(length))
  var liCurrentOffset = LARGE_INTEGER(QuadPart: 0)

  // Save the current position and restore it when we're done
  if !SetFilePointerEx(hFile, liCurrentOffset, &liCurrentOffset,
                       DWORD(FILE_CURRENT)) {
    ucrt._set_errno(mapWindowsErrorToErrno(GetLastError()))
    return -1
  }
  defer {
    _ = SetFilePointerEx(hFile, liCurrentOffset, nil, DWORD(FILE_BEGIN));
  }

  // Truncate (or extend) the file
  if !SetFilePointerEx(hFile, liDesiredLength, nil, DWORD(FILE_BEGIN))
       || !SetEndOfFile(hFile) {
    ucrt._set_errno(mapWindowsErrorToErrno(GetLastError()))
    return -1
  }

  return 0;
}

@inline(__always)
internal func mkdir(
  _ path: UnsafePointer<CInterop.PlatformChar>,
  _ mode: CInterop.Mode
) -> CInt {
  // TODO: Read/write permissions (these need mapping to a SECURITY_DESCRIPTOR).
  if !CreateDirectoryW(path, nil) {
    ucrt._set_errno(mapWindowsErrorToErrno(GetLastError()))
    return -1
  }

  return 0;
}

@inline(__always)
internal func rmdir(
  _ path: UnsafePointer<CInterop.PlatformChar>
) -> CInt {
  if !RemoveDirectoryW(path) {
    ucrt._set_errno(mapWindowsErrorToErrno(GetLastError()))
    return -1
  }

  return 0;
}

@usableFromInline
internal func mapWindowsErrorToErrno(_ errorCode: DWORD) -> CInt {
  switch Int32(errorCode) {
  case ERROR_SUCCESS:
    return 0
  case ERROR_INVALID_FUNCTION,
       ERROR_INVALID_ACCESS,
       ERROR_INVALID_DATA,
       ERROR_INVALID_PARAMETER,
       ERROR_NEGATIVE_SEEK:
    return EINVAL
  case ERROR_FILE_NOT_FOUND,
       ERROR_PATH_NOT_FOUND,
       ERROR_INVALID_DRIVE,
       ERROR_NO_MORE_FILES,
       ERROR_BAD_NETPATH,
       ERROR_BAD_NET_NAME,
       ERROR_BAD_PATHNAME,
       ERROR_FILENAME_EXCED_RANGE:
    return ENOENT
  case ERROR_TOO_MANY_OPEN_FILES:
    return EMFILE
  case ERROR_ACCESS_DENIED,
       ERROR_CURRENT_DIRECTORY,
       ERROR_LOCK_VIOLATION,
       ERROR_NETWORK_ACCESS_DENIED,
       ERROR_CANNOT_MAKE,
       ERROR_FAIL_I24,
       ERROR_DRIVE_LOCKED,
       ERROR_SEEK_ON_DEVICE,
       ERROR_NOT_LOCKED,
       ERROR_LOCK_FAILED,
       ERROR_WRITE_PROTECT...ERROR_SHARING_BUFFER_EXCEEDED:
    return EACCES
  case ERROR_INVALID_HANDLE,
       ERROR_INVALID_TARGET_HANDLE,
       ERROR_DIRECT_ACCESS_HANDLE:
    return EBADF
  case ERROR_ARENA_TRASHED,
       ERROR_NOT_ENOUGH_MEMORY,
       ERROR_INVALID_BLOCK,
       ERROR_NOT_ENOUGH_QUOTA:
    return ENOMEM
  case ERROR_BAD_ENVIRONMENT:
    return E2BIG
  case ERROR_BAD_FORMAT,
       ERROR_INVALID_STARTING_CODESEG...ERROR_INFLOOP_IN_RELOC_CHAIN:
    return ENOEXEC
  case ERROR_NOT_SAME_DEVICE:
    return EXDEV
  case ERROR_FILE_EXISTS,
       ERROR_ALREADY_EXISTS:
    return EEXIST
  case ERROR_NO_PROC_SLOTS,
       ERROR_MAX_THRDS_REACHED,
       ERROR_NESTING_NOT_ALLOWED:
    return EAGAIN
  case ERROR_BROKEN_PIPE:
    return EPIPE
  case ERROR_DISK_FULL:
    return ENOSPC
  case ERROR_WAIT_NO_CHILDREN,
       ERROR_CHILD_NOT_COMPLETE:
    return ECHILD
  case ERROR_DIR_NOT_EMPTY:
    return ENOTEMPTY
  case ERROR_NO_UNICODE_TRANSLATION:
    return EILSEQ
  default:
    return EINVAL
  }
}

#endif
