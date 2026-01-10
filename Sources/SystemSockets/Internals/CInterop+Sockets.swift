/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// C interoperability types for socket operations

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
@_implementationOnly import CSystem
import Glibc
#elseif canImport(Musl)
@_implementationOnly import CSystem
import Musl
#elseif canImport(Android)
@_implementationOnly import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

import SystemPackage

@available(System 99, *)
extension CInterop {
  /// Socket address structure.
  ///
  /// The corresponding C type is `sockaddr`.
  public typealias SockAddr = sockaddr

  /// Socket address length type.
  ///
  /// The corresponding C type is `socklen_t`.
  public typealias SockLen = socklen_t

  /// Socket address family type.
  ///
  /// The corresponding C type is `sa_family_t`.
  public typealias SAFamily = sa_family_t

  /// IPv4 socket address structure.
  ///
  /// The corresponding C type is `sockaddr_in`.
  public typealias SockAddrIn = sockaddr_in

  /// IPv4 address structure.
  ///
  /// The corresponding C type is `in_addr`.
  public typealias InAddr = in_addr

  /// IPv4 address type.
  ///
  /// The corresponding C type is `in_addr_t`.
  public typealias InAddrT = in_addr_t

  /// IPv6 address structure.
  ///
  /// The corresponding C type is `in6_addr`.
  public typealias In6Addr = in6_addr

  /// Port number type.
  ///
  /// The corresponding C type is `in_port_t`.
  public typealias InPort = in_port_t

  /// IPv6 socket address structure.
  ///
  /// The corresponding C type is `sockaddr_in6`.
  public typealias SockAddrIn6 = sockaddr_in6

  /// Unix domain socket address structure.
  ///
  /// The corresponding C type is `sockaddr_un`.
  public typealias SockAddrUn = sockaddr_un

  /// I/O vector structure for scatter/gather I/O.
  ///
  /// The corresponding C type is `iovec`.
  public typealias IOVec = iovec

  /// Message header structure for sendmsg/recvmsg.
  ///
  /// The corresponding C type is `msghdr`.
  public typealias MsgHdr = msghdr

  /// Control message header structure.
  ///
  /// The corresponding C type is `cmsghdr`.
  public typealias CMsgHdr = cmsghdr

  /// Address info structure for getaddrinfo.
  ///
  /// The corresponding C type is `addrinfo`.
  public typealias AddrInfo = addrinfo
}
