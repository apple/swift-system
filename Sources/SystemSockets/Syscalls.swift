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

internal func system_socket(_ domain: CInt, type: CInt, protocol: CInt) -> CInt {
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

internal func system_listen(_ socket: CInt, _ backlog: CInt) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, backlog) }
  #endif
  return listen(socket, backlog)
}

internal func system_send(
  _ socket: Int32, _ buffer: UnsafeRawPointer?, _ len: Int, _ flags: Int32
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, buffer, len, flags) }
  #endif
  return send(socket, buffer, len, flags)
}

internal func system_recv(
  _ socket: Int32,
  _ buffer: UnsafeMutableRawPointer?,
  _ len: Int,
  _ flags: Int32
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
  _ dest_addr: UnsafePointer<CInterop.SockAddr>?,
  _ dest_len: CInterop.SockLen
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
  _ address: UnsafeMutablePointer<CInterop.SockAddr>?,
  _ addres_len: UnsafeMutablePointer<CInterop.SockLen>?
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled {
    return _mockInt(socket, buffer, length, flags, address, addres_len)
  }
  #endif
  return recvfrom(socket, buffer, length, flags, address, addres_len)
}

internal func system_sendmsg(
  _ socket: CInt,
  _ message: UnsafePointer<CInterop.MsgHdr>?,
  _ flags: CInt
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, message, flags) }
  #endif
  return sendmsg(socket, message, flags)
}

internal func system_recvmsg(
  _ socket: CInt,
  _ message: UnsafeMutablePointer<CInterop.MsgHdr>?,
  _ flags: CInt
) -> Int {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mockInt(socket, message, flags) }
  #endif
  return recvmsg(socket, message, flags)
}

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

internal func system_inet_ntop(
  _ af: CInt,
  _ src: UnsafeRawPointer,
  _ dst: UnsafeMutablePointer<CChar>,
  _ size: CInterop.SockLen
) -> CInt { // Note: returns 0 on success, -1 on failure, unlike the original
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(af, src, dst, size) }
  #endif
  let res = inet_ntop(af, src, dst, size)
  if Int(bitPattern: res) == 0 { return -1 }
  assert(Int(bitPattern: res) == Int(bitPattern: dst))
  return 0
}

internal func system_inet_pton(
  _ af: CInt, _ src: UnsafePointer<CChar>, _ dst: UnsafeMutableRawPointer
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(af, src, dst) }
  #endif
  return inet_pton(af, src, dst)
}

internal func system_bind(
  _ socket: CInt, _ addr: UnsafePointer<sockaddr>?, _ len: socklen_t
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
  #endif
  return bind(socket, addr, len)
}

internal func system_connect(
  _ socket: CInt, _ addr: UnsafePointer<sockaddr>?, _ len: socklen_t
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled { return _mock(socket, addr, len) }
  #endif
  return connect(socket, addr, len)
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

internal func system_getaddrinfo(
  _ hostname: UnsafePointer<CChar>?,
  _ servname: UnsafePointer<CChar>?,
  _ hints: UnsafePointer<CInterop.AddrInfo>?,
  _ res: UnsafeMutablePointer<UnsafeMutablePointer<CInterop.AddrInfo>?>?
) -> CInt {
  #if ENABLE_MOCKING
  if mockingEnabled {
    return _mock(hostname.map { String(cString: $0) },
                 servname.map { String(cString: $0) },
                 hints, res)
  }
  #endif
  return getaddrinfo(hostname, servname, hints, res)
}

internal func system_getnameinfo(
  _ sa: UnsafePointer<CInterop.SockAddr>?,
  _ salen: CInterop.SockLen,
  _ host: UnsafeMutablePointer<CChar>?,
  _ hostlen: CInterop.SockLen,
  _ serv: UnsafeMutablePointer<CChar>?,
  _ servlen: CInterop.SockLen,
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
  _ addrinfo: UnsafeMutablePointer<CInterop.AddrInfo>?
) {
  #if ENABLE_MOCKING
  if mockingEnabled {
    _ = _mock(addrinfo)
    return
  }
  #endif
  return freeaddrinfo(addrinfo)
}

internal func system_gai_strerror(_ error: CInt) -> UnsafePointer<CChar> {
  #if ENABLE_MOCKING
  // FIXME
  #endif
  return gai_strerror(error)
}
