/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public struct SocketAddress {
  // FIXME Figure out if we need to model this with a standalone struct
  public typealias Family = SocketDescriptor.Domain

  internal var _variant: _Variant

  public init(
    address: UnsafePointer<CInterop.SockAddr>,
    length: CInterop.SockLen
  ) {
    self.init(UnsafeRawBufferPointer(start: address, count: Int(length)))
  }

  public init(_ buffer: UnsafeRawBufferPointer) {
    precondition(buffer.count >= MemoryLayout<CInterop.SockAddr>.size)
    if buffer.count <= MemoryLayout<_InlineStorage>.size {
      var storage = _InlineStorage()
      withUnsafeMutableBytes(of: &storage) { bytes in
        bytes.baseAddress!.copyMemory(
          from: buffer.baseAddress!,
          byteCount: buffer.count)
      }
      self._variant = .small(length: UInt8(buffer.count), bytes: storage)
    } else {
      let wordSize = MemoryLayout<_ManagedStorage.Element>.stride
      let wordCount = (buffer.count + wordSize - 1) / wordSize
      let storage = _ManagedStorage.create(
        minimumCapacity: wordCount,
        makingHeaderWith: { _ in buffer.count }) as! _ManagedStorage
      storage.withUnsafeMutablePointerToElements { start in
        let raw = UnsafeMutableRawPointer(start)
        raw.copyMemory(from: buffer.baseAddress!, byteCount: buffer.count)
      }
      self._variant = .large(storage)
    }
  }
}

extension SocketAddress {
  internal class _ManagedStorage: ManagedBuffer<Int, UInt64> {
    internal typealias Header = Int // Number of bytes stored
    internal typealias Element = UInt64 // not UInt8 to get 8-byte alignment
  }

  @_alignment(8) // This must be large enough to cover any sockaddr variant
  internal struct _InlineStorage {
    /// A chunk of 28 bytes worth of integers, treated as inline storage for
    /// short `sockaddr` values.
    ///
    /// Note: 28 bytes is just enough to cover socketaddr_in6 on Darwin.
    /// The length of this struct may need to be adjusted on other platforms.
    internal let bytes: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)

    internal init() {
      bytes = (0, 0, 0, 0, 0, 0, 0)
    }
  }
}

extension SocketAddress {
  internal enum _Variant {
    case small(length: UInt8, bytes: _InlineStorage)
    case large(_ManagedStorage)

    internal var length: Int {
      switch self {
      case let .small(length: length, bytes: _):
        return Int(length)
      case let .large(storage):
        return storage.header
      }
    }

    internal func withUnsafeBytes<R>(
      _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R {
      switch self {
      case let .small(length: length, bytes: bytes):
        let length = Int(length)
        assert(length <= MemoryLayout<_InlineStorage>.size)
        return try Swift.withUnsafeBytes(of: bytes) { buffer in
          try body(UnsafeRawBufferPointer(rebasing: buffer[..<length]))
        }
      case let .large(storage):
        return try storage.withUnsafeMutablePointers { length, start in
          try body(UnsafeRawBufferPointer(start: start, count: length.pointee))
        }
      }
    }
  }
}


extension SocketAddress {
  /// Calls `body` with an unsafe raw buffer pointer to the raw bytes of this
  /// address. This is useful when you need to pass an address to a function
  /// that treats socket addresses as untyped raw data.
  public func withUnsafeBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    try _variant.withUnsafeBytes(body)
  }

  /// Calls `body` with an unsafe raw buffer pointer to the
  /// raw bytes of this address. This is useful when you
  /// need to pass an address to a function that takes a
  /// a C `sockaddr` pointer along with a `socklen_t` length value.
  public func withRawAddress<R>(
    _ body: (UnsafePointer<CInterop.SockAddr>, CInterop.SockLen) throws -> R
  ) rethrows -> R {
    try _variant.withUnsafeBytes { bytes in
      let start = bytes.baseAddress!.assumingMemoryBound(to: CInterop.SockAddr.self)
      let length = CInterop.SockLen(bytes.count)
      return try body(start, length)
    }
  }

  public var family: Family {
    withRawAddress { addr, length in
      .init(rawValue: CInt(addr.pointee.sa_family))
    }
  }
}

extension SocketAddress: CustomStringConvertible {
  public var description: String {
    switch family {
    case .ipv4:
      let address = IPv4(self)!
      return "SocketAddress(family: \(family.rawValue)) \(address)"
    case .ipv6:
      let address = IPv6(self)!
      return "SocketAddress(family: \(family.rawValue)) \(address)"
    default:
      return "SocketAddress(family: \(family.rawValue))"
    }
  }
}
