/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// System call wrappers for socket operations

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

// MARK: - Socket creation and management

internal func system_socket(_ domain: CInt, _ type: CInt, _ protocol: CInt) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(domain, type, `protocol`) }
#endif
  return socket(domain, type, `protocol`)
}

internal func system_shutdown(_ socket: CInt, _ how: CInt) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, how) }
#endif
  return shutdown(socket, how)
}

internal func system_close(_ fd: CInt) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(fd) }
#endif
  return close(fd)
}

// MARK: - Connection operations

internal func system_bind(
  _ socket: CInt,
  _ addr: UnsafePointer<sockaddr>?,
  _ len: socklen_t
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
#endif
  return bind(socket, addr, len)
}

internal func system_listen(_ socket: CInt, _ backlog: CInt) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, backlog) }
#endif
  return listen(socket, backlog)
}

internal func system_accept(
  _ socket: CInt,
  _ addr: UnsafeMutablePointer<sockaddr>?,
  _ len: UnsafeMutablePointer<socklen_t>?
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
#endif
  return accept(socket, addr, len)
}

internal func system_connect(
  _ socket: CInt,
  _ addr: UnsafePointer<sockaddr>?,
  _ len: socklen_t
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
#endif
  return connect(socket, addr, len)
}

// MARK: - Data transfer

internal func system_send(
  _ socket: CInt,
  _ buffer: UnsafeRawPointer?,
  _ len: Int,
  _ flags: CInt
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, buffer, len, flags) }
#endif
  return send(socket, buffer, len, flags)
}

internal func system_recv(
  _ socket: CInt,
  _ buffer: UnsafeMutableRawPointer?,
  _ len: Int,
  _ flags: CInt
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, buffer, len, flags) }
#endif
  return recv(socket, buffer, len, flags)
}

internal func system_sendto(
  _ socket: CInt,
  _ buffer: UnsafeRawPointer?,
  _ length: Int,
  _ flags: CInt,
  _ dest_addr: UnsafePointer<sockaddr>?,
  _ dest_len: socklen_t
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mockInt(socket, buffer, length, flags, dest_addr, dest_len)
  }
#endif
  return sendto(socket, buffer, length, flags, dest_addr, dest_len)
}

internal func system_recvfrom(
  _ socket: CInt,
  _ buffer: UnsafeMutableRawPointer?,
  _ length: Int,
  _ flags: CInt,
  _ address: UnsafeMutablePointer<sockaddr>?,
  _ address_len: UnsafeMutablePointer<socklen_t>?
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mockInt(socket, buffer, length, flags, address, address_len)
  }
#endif
  return recvfrom(socket, buffer, length, flags, address, address_len)
}

internal func system_sendmsg(
  _ socket: CInt,
  _ message: UnsafePointer<msghdr>?,
  _ flags: CInt
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, message, flags) }
#endif
  return sendmsg(socket, message, flags)
}

internal func system_recvmsg(
  _ socket: CInt,
  _ message: UnsafeMutablePointer<msghdr>?,
  _ flags: CInt
) -> Int {
#if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, message, flags) }
#endif
  return recvmsg(socket, message, flags)
}

// MARK: - Socket options

internal func system_getsockopt(
  _ socket: CInt,
  _ level: CInt,
  _ option: CInt,
  _ value: UnsafeMutableRawPointer?,
  _ length: UnsafeMutablePointer<socklen_t>?
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, level, option, value, length) }
#endif
  return getsockopt(socket, level, option, value, length)
}

internal func system_setsockopt(
  _ socket: CInt,
  _ level: CInt,
  _ option: CInt,
  _ value: UnsafeRawPointer?,
  _ length: socklen_t
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, level, option, value, length) }
#endif
  return setsockopt(socket, level, option, value, length)
}

internal func system_getsockname(
  _ socket: CInt,
  _ addr: UnsafeMutablePointer<sockaddr>?,
  _ len: UnsafeMutablePointer<socklen_t>?
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
#endif
  return getsockname(socket, addr, len)
}

internal func system_getpeername(
  _ socket: CInt,
  _ addr: UnsafeMutablePointer<sockaddr>?,
  _ len: UnsafeMutablePointer<socklen_t>?
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
#endif
  return getpeername(socket, addr, len)
}

// MARK: - Address conversion

@usableFromInline
internal func system_inet_ntop(
  _ af: CInt,
  _ src: UnsafeRawPointer,
  _ dst: UnsafeMutablePointer<CChar>,
  _ size: socklen_t
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(af, src, dst, size) }
#endif
  let res = inet_ntop(af, src, dst, size)
  if Int(bitPattern: res) == 0 { return -1 }
  return 0
}

@usableFromInline
internal func system_inet_pton(
  _ af: CInt,
  _ src: UnsafePointer<CChar>,
  _ dst: UnsafeMutableRawPointer
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(af, src, dst) }
#endif
  return inet_pton(af, src, dst)
}

// MARK: - Name resolution

internal func system_getaddrinfo(
  _ hostname: UnsafePointer<CChar>?,
  _ servname: UnsafePointer<CChar>?,
  _ hints: UnsafePointer<addrinfo>?,
  _ res: UnsafeMutablePointer<UnsafeMutablePointer<addrinfo>?>?
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(
      hostname.map { String(cString: $0) },
      servname.map { String(cString: $0) },
      hints,
      res
    )
  }
#endif
  return getaddrinfo(hostname, servname, hints, res)
}

internal func system_getnameinfo(
  _ sa: UnsafePointer<sockaddr>?,
  _ salen: socklen_t,
  _ host: UnsafeMutablePointer<CChar>?,
  _ hostlen: socklen_t,
  _ serv: UnsafeMutablePointer<CChar>?,
  _ servlen: socklen_t,
  _ flags: CInt
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(sa, salen, host, hostlen, serv, servlen, flags)
  }
#endif
  return getnameinfo(sa, salen, host, hostlen, serv, servlen, flags)
}

internal func system_freeaddrinfo(
  _ addrinfo: UnsafeMutablePointer<addrinfo>?
) {
#if ENABLE_MOCKING
  if mockingEnabled {
    _ = _mock(addrinfo)
    return
  }
#endif
  freeaddrinfo(addrinfo)
}

internal func system_gai_strerror(_ error: CInt) -> UnsafePointer<CChar> {
  gai_strerror(error)
}
