/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import CSystem
#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// Throwing wrapper around the `io_uring_enter2` shim.
///
/// On success returns the syscall's non-negative result (the number of SQEs
/// consumed by the kernel). On failure, reads `errno` and throws the matching
/// `Errno`. `EINTR` is retried automatically.
@usableFromInline
internal func _ioUringEnter2(
  ringDescriptor: Int32,
  toSubmit: UInt32,
  minComplete: UInt32,
  flags: UInt32,
  args: UnsafeMutablePointer<swift_io_uring_getevents_arg>?,
  argsSize: Int
) throws(Errno) -> Int32 {
  let result = valueOrErrno(retryOnInterrupt: true) {
    io_uring_enter2(
      ringDescriptor, toSubmit, minComplete, flags, args, argsSize
    )
  }
  return try result.get()
}

/// Throwing wrapper around the `io_uring_enter` shim.
///
/// On success returns the syscall's non-negative result (the number of SQEs
/// consumed by the kernel). On failure, reads `errno` and throws the matching
/// `Errno`. `EINTR` is retried automatically.
@usableFromInline
internal func _ioUringEnter(
  ringDescriptor: Int32,
  toSubmit: UInt32,
  minComplete: UInt32,
  flags: UInt32,
  sig: UnsafeMutablePointer<sigset_t>?
) throws(Errno) -> Int32 {
  let result = valueOrErrno(retryOnInterrupt: true) {
    io_uring_enter(ringDescriptor, toSubmit, minComplete, flags, sig)
  }
  return try result.get()
}

#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
