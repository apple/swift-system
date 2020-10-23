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
internal func open(_ path: UnsafePointer<CChar>, _ oflag: Int32) -> CInt {
  var fh: CInt = -1
  _ = _sopen_s(&fh, path, oflag, _SH_DENYNO, _S_IREAD | _S_IWRITE)
  return fh
}

@inline(__always)
internal func open(
  _ path: UnsafePointer<CChar>, _ oflag: Int32, _ mode: CModeT
) -> CInt {
  // TODO(compnerd): Apply read/write permissions
  var fh: CInt = -1
  _ = _sopen_s(&fh, path, oflag, _SH_DENYNO, _S_IREAD | _S_IWRITE)
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
internal func pread(
  _ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  let handle: intptr_t = _get_osfhandle(fd)
  if handle == /* INVALID_HANDLE_VALUE */ -1 { return Int(EBADF) }

  // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
  let hFile: HANDLE = HANDLE(bitPattern: handle)!

  var ovlOverlapped: OVERLAPPED = OVERLAPPED()
  ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
  ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)

  var nNumberOfBytesRead: DWORD = 0
  if !ReadFile(hFile, buf, DWORD(nbyte), &nNumberOfBytesRead, &ovlOverlapped) {
    let _ = GetLastError()
    // TODO(compnerd) map windows error to errno
    return Int(-1)
  }
  return Int(nNumberOfBytesRead)
}

@inline(__always)
internal func pwrite(
  _ fd: Int32, _ buf: UnsafeRawPointer!, _ nbyte: Int, _ offset: off_t
) -> Int {
  let handle: intptr_t = _get_osfhandle(fd)
  if handle == /* INVALID_HANDLE_VALUE */ -1 { return Int(EBADF) }

  // NOTE: this is a non-owning handle, do *not* call CloseHandle on it
  let hFile: HANDLE = HANDLE(bitPattern: handle)!

  var ovlOverlapped: OVERLAPPED = OVERLAPPED()
  ovlOverlapped.OffsetHigh = DWORD(UInt32(offset >> 32) & 0xffffffff)
  ovlOverlapped.Offset = DWORD(UInt32(offset >> 0) & 0xffffffff)

  var nNumberOfBytesWritten: DWORD = 0
  if !WriteFile(hFile, buf, DWORD(nbyte), &nNumberOfBytesWritten,
                &ovlOverlapped) {
    let _ = GetLastError()
    // TODO(compnerd) map windows error to errno
    return Int(-1)
  }
  return Int(nNumberOfBytesWritten)
}

#endif
