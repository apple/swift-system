/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import SystemPackage

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

/// An IPv4 socket address.
///
/// An IPv4 address consists of a 32-bit IP address and a 16-bit port number.
@frozen
@available(System 99, *)
public struct IPv4Address: Sendable, Equatable, Hashable {
  /// The underlying C structure.
  @usableFromInline
  internal var _storage: sockaddr_in

  /// Creates an IPv4 address from a raw sockaddr_in.
  @_alwaysEmitIntoClient
  public init(_ sockaddr: sockaddr_in) {
    _storage = sockaddr
  }

  /// Creates an IPv4 address from an address string and port.
  ///
  /// - Parameters:
  ///   - address: The IPv4 address string (e.g., "127.0.0.1").
  ///   - port: The port number in host byte order.
  /// - Returns: `nil` if the address string is invalid.
  @_alwaysEmitIntoClient
  public init?(_ address: String, port: UInt16) {
    var addr = sockaddr_in()
    #if SYSTEM_PACKAGE_DARWIN
    addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    #endif
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = port.bigEndian

    let result = address.withCString { cString in
      system_inet_pton(AF_INET, cString, &addr.sin_addr)
    }

    guard result == 1 else { return nil }
    _storage = addr
  }

  /// Creates an IPv4 address representing any address (0.0.0.0).
  ///
  /// - Parameter port: The port number in host byte order.
  @_alwaysEmitIntoClient
  public static func any(port: UInt16) -> IPv4Address {
    var addr = sockaddr_in()
    #if SYSTEM_PACKAGE_DARWIN
    addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    #endif
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = port.bigEndian
    addr.sin_addr.s_addr = INADDR_ANY.bigEndian
    return IPv4Address(addr)
  }

  /// Creates an IPv4 address representing the loopback address (127.0.0.1).
  ///
  /// - Parameter port: The port number in host byte order.
  @_alwaysEmitIntoClient
  public static func loopback(port: UInt16) -> IPv4Address {
    var addr = sockaddr_in()
    #if SYSTEM_PACKAGE_DARWIN
    addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    #endif
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = port.bigEndian
    addr.sin_addr.s_addr = INADDR_LOOPBACK.bigEndian
    return IPv4Address(addr)
  }
}

// MARK: - Properties

@available(System 99, *)
extension IPv4Address {
  /// The port number in host byte order.
  @_alwaysEmitIntoClient
  public var port: UInt16 {
    UInt16(bigEndian: _storage.sin_port)
  }

  /// The IP address as a string.
  public var addressString: String {
    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
    var addr = _storage.sin_addr
    _ = Swift.withUnsafePointer(to: &addr) { ptr in
      system_inet_ntop(AF_INET, ptr, &buffer, socklen_t(buffer.count))
    }
    return String(cString: buffer)
  }
}

// MARK: - Pointer Access

@available(System 99, *)
extension IPv4Address {
  /// Calls the given closure with a pointer to the underlying sockaddr.
  @_alwaysEmitIntoClient
  public func withUnsafePointer<R>(
    _ body: (UnsafePointer<sockaddr>, CInterop.SockLen) throws -> R
  ) rethrows -> R {
    try Swift.withUnsafePointer(to: _storage) { storage in
      try storage.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
        try body(sockaddr, CInterop.SockLen(MemoryLayout<sockaddr_in>.size))
      }
    }
  }
}

// MARK: - CustomStringConvertible

@available(System 99, *)
extension IPv4Address: CustomStringConvertible {
  public var description: String {
    "\(addressString):\(port)"
  }
}

// MARK: - ExpressibleByStringLiteral

@available(System 99, *)
extension IPv4Address: ExpressibleByStringLiteral {
  /// Creates an IPv4 address from a string literal.
  ///
  /// The format is "address:port" (e.g., "127.0.0.1:8080").
  /// If no port is specified, port 0 is used.
  public init(stringLiteral value: String) {
    let parts = value.split(separator: ":", maxSplits: 1)
    let address = String(parts[0])
    let port: UInt16 = parts.count > 1 ? UInt16(parts[1]) ?? 0 : 0

    guard let addr = IPv4Address(address, port: port) else {
      fatalError("Invalid IPv4 address literal: \(value)")
    }
    self = addr
  }
}

// MARK: - Equatable and Hashable

@available(System 99, *)
extension IPv4Address {
  @_alwaysEmitIntoClient
  public static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
    lhs._storage.sin_family == rhs._storage.sin_family &&
    lhs._storage.sin_port == rhs._storage.sin_port &&
    lhs._storage.sin_addr.s_addr == rhs._storage.sin_addr.s_addr
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_storage.sin_family)
    hasher.combine(_storage.sin_port)
    hasher.combine(_storage.sin_addr.s_addr)
  }
}

// MARK: - SocketAddress Integration

@available(System 99, *)
extension SocketAddress {
  /// Creates a socket address from an IPv4 address.
  @_alwaysEmitIntoClient
  public init(ipv4: IPv4Address) {
    self.init()
    ipv4.withUnsafePointer { addr, len in
      withUnsafeMutableBytes(of: &_storage) { dest in
        dest.copyMemory(from: UnsafeRawBufferPointer(start: addr, count: Int(len)))
      }
      _length = len
    }
  }

  /// The address as an IPv4 address, if applicable.
  @_alwaysEmitIntoClient
  public var ipv4: IPv4Address? {
    guard family == .ipv4 else { return nil }
    return Swift.withUnsafeBytes(of: _storage) { buffer in
      buffer.baseAddress!.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { ptr in
        IPv4Address(ptr.pointee)
      }
    }
  }
}
