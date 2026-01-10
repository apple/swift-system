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

/// An opaque type representing a socket address.
///
/// `SocketAddress` is a type-erased container that can hold any socket address,
/// including IPv4, IPv6, and Unix domain addresses. It provides a unified
/// interface for socket operations that work with different address families.
///
/// To create a socket address for a specific family, use one of the convenience
/// initializers:
///
/// ```swift
/// // IPv4 address
/// let ipv4 = SocketAddress(ipv4: IPv4Address("127.0.0.1", port: 8080)!)
///
/// // IPv6 address
/// let ipv6 = SocketAddress(ipv6: IPv6Address.loopback(port: 80))
///
/// // Unix domain socket
/// let local = SocketAddress(unix: UnixAddress("/tmp/socket.sock")!)
/// ```
///
/// `SocketAddress` uses `sockaddr_storage` internally, which is large enough
/// to hold any socket address type.
@frozen
@available(System 99, *)
public struct SocketAddress: Sendable {
  /// The underlying storage using sockaddr_storage.
  @usableFromInline
  internal var _storage: sockaddr_storage

  /// The actual length of the address data.
  @usableFromInline
  internal var _length: CInterop.SockLen

  /// Creates an empty socket address with unspecified family.
  @_alwaysEmitIntoClient
  public init() {
    _storage = sockaddr_storage()
    _length = 0
  }

  /// Creates a socket address from raw bytes.
  ///
  /// - Parameters:
  ///   - address: Pointer to the socket address.
  ///   - length: The length of the address.
  @_alwaysEmitIntoClient
  public init(
    address: UnsafePointer<CInterop.SockAddr>,
    length: CInterop.SockLen
  ) {
    _storage = sockaddr_storage()
    _length = min(length, CInterop.SockLen(MemoryLayout<sockaddr_storage>.size))
    withUnsafeMutableBytes(of: &_storage) { dest in
      dest.copyMemory(from: UnsafeRawBufferPointer(start: address, count: Int(_length)))
    }
  }

  /// Creates a socket address from a raw buffer.
  @_alwaysEmitIntoClient
  public init(_ buffer: UnsafeRawBufferPointer) {
    _storage = sockaddr_storage()
    _length = CInterop.SockLen(min(buffer.count, MemoryLayout<sockaddr_storage>.size))
    if buffer.count > 0 {
      withUnsafeMutableBytes(of: &_storage) { dest in
        dest.copyMemory(from: UnsafeRawBufferPointer(rebasing: buffer.prefix(Int(_length))))
      }
    }
  }
}

// MARK: - Properties

@available(System 99, *)
extension SocketAddress {
  /// The address family of this socket address.
  @_alwaysEmitIntoClient
  public var family: SocketDescriptor.Domain {
    Swift.withUnsafeBytes(of: _storage) { buffer in
      let sockaddr = buffer.baseAddress!.assumingMemoryBound(to: sockaddr.self)
      return SocketDescriptor.Domain(rawValue: CInt(sockaddr.pointee.sa_family))
    }
  }

  /// The length of this socket address in bytes.
  @_alwaysEmitIntoClient
  public var length: Int {
    Int(_length)
  }

  /// Whether this address is empty (length is 0).
  @_alwaysEmitIntoClient
  public var isEmpty: Bool {
    _length == 0
  }
}

// MARK: - Accessing Raw Bytes

@available(System 99, *)
extension SocketAddress {
  /// Calls the given closure with a pointer to the underlying socket address.
  @_alwaysEmitIntoClient
  public func withUnsafePointer<R>(
    _ body: (UnsafePointer<sockaddr>, CInterop.SockLen) throws -> R
  ) rethrows -> R {
    try Swift.withUnsafePointer(to: _storage) { storage in
      try storage.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
        try body(sockaddr, _length)
      }
    }
  }

  /// Calls the given closure with a mutable pointer to the underlying storage.
  @_alwaysEmitIntoClient
  public mutating func _withUnsafeMutablePointer<R>(
    _ body: (UnsafeMutablePointer<sockaddr>, inout CInterop.SockLen) throws -> R
  ) rethrows -> R {
    var len = CInterop.SockLen(MemoryLayout<sockaddr_storage>.size)
    let result = try Swift.withUnsafeMutablePointer(to: &_storage) { storage in
      try storage.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
        try body(sockaddr, &len)
      }
    }
    _length = len
    return result
  }

  /// Accesses the raw bytes of the socket address.
  @_alwaysEmitIntoClient
  public func withUnsafeBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    try Swift.withUnsafeBytes(of: _storage) { buffer in
      try body(UnsafeRawBufferPointer(rebasing: buffer.prefix(Int(_length))))
    }
  }

  /// Resets this address to an empty state.
  @_alwaysEmitIntoClient
  public mutating func clear() {
    _storage = sockaddr_storage()
    _length = 0
  }
}

// MARK: - Equatable and Hashable

@available(System 99, *)
extension SocketAddress: Equatable {
  @_alwaysEmitIntoClient
  public static func == (lhs: SocketAddress, rhs: SocketAddress) -> Bool {
    guard lhs._length == rhs._length else { return false }
    return lhs.withUnsafeBytes { lhsBytes in
      rhs.withUnsafeBytes { rhsBytes in
        lhsBytes.elementsEqual(rhsBytes)
      }
    }
  }
}

@available(System 99, *)
extension SocketAddress: Hashable {
  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_length)
    withUnsafeBytes { buffer in
      hasher.combine(bytes: buffer)
    }
  }
}

// MARK: - CustomStringConvertible

@available(System 99, *)
extension SocketAddress: CustomStringConvertible {
  public var description: String {
    if isEmpty {
      return "SocketAddress(empty)"
    }

    switch family {
    case .ipv4:
      if let ipv4 = self.ipv4 {
        return "SocketAddress(\(ipv4))"
      }
    case .ipv6:
      if let ipv6 = self.ipv6 {
        return "SocketAddress(\(ipv6))"
      }
    case .local:
      if let unix = self.unix {
        return "SocketAddress(\(unix))"
      }
    default:
      break
    }

    return "SocketAddress(family: \(family), length: \(_length))"
  }
}
