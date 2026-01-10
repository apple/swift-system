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

/// A Unix domain socket address.
///
/// Unix domain socket addresses use a filesystem path to identify the socket.
@frozen
@available(System 99, *)
public struct UnixAddress: Sendable, Equatable, Hashable {
  /// The underlying C structure.
  @usableFromInline
  internal var _storage: sockaddr_un

  /// The length of the path (not including null terminator).
  @usableFromInline
  internal var _pathLength: Int

  /// Creates a Unix address from a raw sockaddr_un.
  @_alwaysEmitIntoClient
  public init(_ sockaddr: sockaddr_un) {
    _storage = sockaddr
    // Calculate path length from the stored data
    _pathLength = withUnsafeBytes(of: sockaddr.sun_path) { bytes in
      bytes.prefix(while: { $0 != 0 }).count
    }
  }

  /// Creates a Unix address from a path string.
  ///
  /// - Parameter path: The filesystem path for the socket.
  /// - Returns: `nil` if the path is too long.
  @_alwaysEmitIntoClient
  public init?(_ path: String) {
    var addr = sockaddr_un()
    #if SYSTEM_PACKAGE_DARWIN
    addr.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
    #endif
    addr.sun_family = sa_family_t(AF_UNIX)

    let maxPathLength = MemoryLayout.size(ofValue: addr.sun_path) - 1 // Leave room for null

    let copied = path.withCString { cString in
      let len = system_strlen(cString)
      guard len <= maxPathLength else { return -1 }

      withUnsafeMutableBytes(of: &addr.sun_path) { dest in
        dest.copyMemory(from: UnsafeRawBufferPointer(start: cString, count: len + 1))
      }
      return len
    }

    guard copied >= 0 else { return nil }

    _storage = addr
    _pathLength = copied
  }
}

// MARK: - Properties

@available(System 99, *)
extension UnixAddress {
  /// The path as a string.
  public var path: String {
    withUnsafeBytes(of: _storage.sun_path) { bytes in
      let pathBytes = bytes.prefix(_pathLength)
      return pathBytes.withMemoryRebound(to: CChar.self) { chars in
        String(cString: chars.baseAddress!)
      }
    }
  }
}

// MARK: - Pointer Access

@available(System 99, *)
extension UnixAddress {
  /// Calls the given closure with a pointer to the underlying sockaddr.
  @_alwaysEmitIntoClient
  public func withUnsafePointer<R>(
    _ body: (UnsafePointer<sockaddr>, CInterop.SockLen) throws -> R
  ) rethrows -> R {
    try Swift.withUnsafePointer(to: _storage) { storage in
      try storage.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
        // Length includes sun_family plus the path (including null terminator)
        let length = MemoryLayout<sa_family_t>.size + _pathLength + 1
        #if SYSTEM_PACKAGE_DARWIN
        let actualLength = MemoryLayout<UInt8>.size + length // Include sun_len
        #else
        let actualLength = length
        #endif
        return try body(sockaddr, CInterop.SockLen(actualLength))
      }
    }
  }
}

// MARK: - CustomStringConvertible

@available(System 99, *)
extension UnixAddress: CustomStringConvertible {
  public var description: String {
    path
  }
}

// MARK: - Equatable and Hashable

@available(System 99, *)
extension UnixAddress {
  @_alwaysEmitIntoClient
  public static func == (lhs: UnixAddress, rhs: UnixAddress) -> Bool {
    lhs._pathLength == rhs._pathLength &&
    Swift.withUnsafeBytes(of: lhs._storage.sun_path) { lhsBytes in
      Swift.withUnsafeBytes(of: rhs._storage.sun_path) { rhsBytes in
        lhsBytes.prefix(lhs._pathLength).elementsEqual(rhsBytes.prefix(rhs._pathLength))
      }
    }
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_pathLength)
    Swift.withUnsafeBytes(of: _storage.sun_path) { bytes in
      hasher.combine(bytes: UnsafeRawBufferPointer(rebasing: bytes.prefix(_pathLength)))
    }
  }
}

// MARK: - SocketAddress Integration

@available(System 99, *)
extension SocketAddress {
  /// Creates a socket address from a Unix address.
  @_alwaysEmitIntoClient
  public init(unix: UnixAddress) {
    self.init()
    unix.withUnsafePointer { addr, len in
      withUnsafeMutableBytes(of: &_storage) { dest in
        dest.copyMemory(from: UnsafeRawBufferPointer(start: addr, count: Int(len)))
      }
      _length = len
    }
  }

  /// The address as a Unix address, if applicable.
  @_alwaysEmitIntoClient
  public var unix: UnixAddress? {
    guard family == .local else { return nil }
    return Swift.withUnsafeBytes(of: _storage) { buffer in
      buffer.baseAddress!.withMemoryRebound(to: sockaddr_un.self, capacity: 1) { ptr in
        UnixAddress(ptr.pointee)
      }
    }
  }
}
