/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Public typealiases

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import CSystem
import Glibc
#elseif os(Windows)
import CSystem
import ucrt
#else
#error("Unsupported Platform")
#endif

import SystemPackage

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension CInterop {
  public typealias SockAddr = sockaddr
  public typealias SockLen = socklen_t
  public typealias SAFamily = sa_family_t

  public typealias SockAddrIn = sockaddr_in
  public typealias InAddr = in_addr
  public typealias InAddrT = in_addr_t

  public typealias In6Addr = in6_addr

  public typealias InPort = in_port_t

  public typealias SockAddrIn6 = sockaddr_in6
  public typealias SockAddrUn = sockaddr_un

  public typealias IOVec = iovec
  public typealias MsgHdr = msghdr
  public typealias CMsgHdr = cmsghdr  // Note: c is for "control", not "C"

  public typealias AddrInfo = addrinfo
}

// memset for raw buffers
// FIXME: Do we really not have something like this in the stdlib already?
internal func system_memset(
  _ buffer: UnsafeMutableRawBufferPointer,
  to byte: UInt8
) {
  memset(buffer.baseAddress, CInt(byte), buffer.count)
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
internal var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#elseif os(Windows)
internal var system_errno: CInt {
  get {
    var value: CInt = 0
    // TODO(compnerd) handle the error?
    _ = ucrt._get_errno(&value)
    return value
  }
  set {
    _ = ucrt._set_errno(newValue)
  }
}
#else
internal var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#endif

internal func system_strlen(_ s: UnsafePointer<CChar>) -> Int {
  strlen(s)
}
internal func system_strlen(_ s: UnsafeMutablePointer<CChar>) -> Int {
  strlen(s)
}

