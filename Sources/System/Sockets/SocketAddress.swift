/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
/// An opaque type holding a socket address and port number in some address family.
///
/// TODO: Show examples of creating an ipv4 and ipv6 address
///
/// The corresponding C type is `sockaddr_t`
public struct SocketAddress {
  internal var _variant: _Variant

  /// Create an address from raw bytes
  public init(
    address: UnsafePointer<CInterop.SockAddr>,
    length: CInterop.SockLen
  ) {
    self.init(UnsafeRawBufferPointer(start: address, count: Int(length)))
  }

  /// Create an address from raw bytes
  public init(_ buffer: UnsafeRawBufferPointer) {
    self.init(unsafeUninitializedCapacity: buffer.count) { target in
      target.baseAddress!.copyMemory(
        from: buffer.baseAddress!,
        byteCount: buffer.count)
      return buffer.count
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Initialize an empty socket address with the specified minimum capacity.
  /// The default capacity makes enough storage space to fit any IPv4/IPv6 address.
  ///
  /// Addresses with storage preallocated this way can be repeatedly passed to
  /// `SocketDescriptor.receiveMessage`, eliminating the need for a potential
  /// allocation each time it is called.
  public init(minimumCapacity: Int = Self.defaultCapacity) {
    self.init(unsafeUninitializedCapacity: minimumCapacity) { buffer in
      system_memset(buffer, to: 0)
      return 0
    }
  }

  /// Reserve storage capacity such that `self` is able to store addresses
  /// of at least `minimumCapacity` bytes without any additional allocation.
  ///
  /// Addresses with storage preallocated this way can be repeatedly passed to
  /// `SocketDescriptor.receiveMessage`, eliminating the need for a potential
  /// allocation each time it is called.
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    guard minimumCapacity > _capacity else { return }
    let length = _length
    var buffer = _RawBuffer(minimumCapacity: minimumCapacity)
    buffer.withUnsafeMutableBytes { target in
      self.withUnsafeBytes { source in
        assert(source.count == length)
        assert(target.count > source.count)
        if source.count > 0 {
          target.baseAddress!.copyMemory(
            from: source.baseAddress!,
            byteCount: source.count)
        }
      }
    }
    self._variant = .large(length: length, bytes: buffer)
  }

  /// Reset this address value to an empty address of unspecified family,
  /// filling the underlying storage with zero bytes.
  public mutating func clear() {
    self._withUnsafeMutableBytes(entireCapacity: true) { buffer in
      system_memset(buffer, to: 0)
    }
    self._length = 0
  }

  /// Creates a socket address with the specified capacity, then calls the
  /// given closure with a buffer covering the socket address's uninitialized
  /// memory.
  public init(
    unsafeUninitializedCapacity capacity: Int,
    initializingWith body: (UnsafeMutableRawBufferPointer) throws -> Int
  ) rethrows {
    if capacity <= MemoryLayout<_InlineStorage>.size {
      var storage = _InlineStorage()
      let length: Int = try withUnsafeMutableBytes(of: &storage) { bytes in
        let buffer = UnsafeMutableRawBufferPointer(rebasing: bytes[..<capacity])
        return try body(buffer)
      }
      precondition(length >= 0 && length <= capacity)
      self._variant = .small(length: UInt8(length), bytes: storage)
    } else {
      var buffer = _RawBuffer(minimumCapacity: capacity)
      let count = try buffer.withUnsafeMutableBytes { target in
        try body(target)
      }
      precondition(count >= 0 && count <= capacity)
      self._variant = .large(length: count, bytes: buffer)
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// A default capacity, with enough storage space to fit any IPv4/IPv6 address.
  public static var defaultCapacity: Int { MemoryLayout<_InlineStorage>.size }

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
    case large(length: Int, bytes: _RawBuffer)
  }

  internal var _length: Int {
    get {
      switch _variant {
      case let .small(length: length, bytes: _):
        return Int(length)
      case let .large(length: length, bytes: _):
        return length
      }
    }
    set {
      assert(newValue <= _capacity)
      switch _variant {
      case let .small(length: _, bytes: bytes):
        self._variant = .small(length: UInt8(newValue), bytes: bytes)
      case let .large(length: _, bytes: bytes):
        self._variant = .large(length: newValue, bytes: bytes)
      }
    }
  }

  internal var _capacity: Int {
    switch _variant {
    case .small(length: _, bytes: _):
      return MemoryLayout<_InlineStorage>.size
    case .large(length: _, bytes: let bytes):
      return bytes.capacity
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Calls `body` with an unsafe raw buffer pointer to the raw bytes of this
  /// address. This is useful when you need to pass an address to a function
  /// that treats socket addresses as untyped raw data.
  public func withUnsafeBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    switch _variant {
    case let .small(length: length, bytes: bytes):
      let length = Int(length)
      assert(length <= MemoryLayout<_InlineStorage>.size)
      return try Swift.withUnsafeBytes(of: bytes) { buffer in
        try body(UnsafeRawBufferPointer(rebasing: buffer[..<length]))
      }
    case let .large(length: length, bytes: bytes):
      return try bytes.withUnsafeBytes { buffer in
        precondition(length <= buffer.count)
        let buffer = UnsafeRawBufferPointer(rebasing: buffer[..<length])
        return try body(buffer)
      }
    }
  }

  /// Calls `body` with an unsafe raw buffer pointer to the
  /// raw bytes of this address. This is useful when you
  /// need to pass an address to a function that takes a
  /// a C `sockaddr` pointer along with a `socklen_t` length value.
  public func withUnsafeCInterop<R>(
    _ body: (UnsafePointer<CInterop.SockAddr>?, CInterop.SockLen) throws -> R
  ) rethrows -> R {
    try withUnsafeBytes { bytes in
      let start = bytes.baseAddress?.assumingMemoryBound(to: CInterop.SockAddr.self)
      let length = CInterop.SockLen(bytes.count)
      if length >= MemoryLayout<CInterop.SockAddr>.size {
        return try body(start, length)
      } else {
        return try body(nil, 0)
      }
    }
  }

  internal mutating func _withUnsafeMutableBytes<R>(
    entireCapacity: Bool,
    _ body: (UnsafeMutableRawBufferPointer) throws -> R
  ) rethrows -> R {
    switch _variant {
    case .small(length: let length, bytes: var bytes):
      assert(length <= MemoryLayout<_InlineStorage>.size)
      defer { self._variant = .small(length: length, bytes: bytes) }
      return try Swift.withUnsafeMutableBytes(of: &bytes) { buffer in
        if entireCapacity {
          return try body(buffer)
        } else {
          return try body(.init(rebasing: buffer[..<Int(length)]))
        }
      }
    case .large(length: let length, bytes: var bytes):
      self._variant = .small(length: 0, bytes: _InlineStorage()) // Prevent CoW copies
      defer { self._variant = .large(length: length, bytes: bytes) }
      return try bytes.withUnsafeMutableBytes { buffer in
        precondition(length <= buffer.count)
        if entireCapacity {
          return try body(buffer)
        } else {
          return try body(.init(rebasing: buffer[..<length]))
        }
      }
    }
  }

  internal mutating func _withMutableCInterop<R>(
    entireCapacity: Bool,
    _ body: (
      UnsafeMutablePointer<CInterop.SockAddr>?,
      inout CInterop.SockLen
    ) throws -> R
  ) rethrows -> R {
    let (result, length): (R, Int) = try _withUnsafeMutableBytes(
      entireCapacity: true
    ) { bytes in
      let start = bytes.baseAddress?.assumingMemoryBound(to: CInterop.SockAddr.self)
      var length = CInterop.SockLen(bytes.count)
      let result = try body(start, &length)
      precondition(length >= 0 && length <= bytes.count, "\(length) \(bytes.count)")
      return (result, Int(length))
    }
    self._length = length
    return result
  }


  /// The address family identifier of this socket address.
  public var family: Family {
    withUnsafeCInterop { addr, length in
      guard let addr = addr else { return .unspecified }
      return Family(rawValue: addr.pointee.sa_family)
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress: CustomStringConvertible {
  public var description: String {
    if let address = self.ipv4 {
      return "SocketAddress(family: \(family), address: \(address))"
    }
    if let address = self.ipv6 {
      return "SocketAddress(family: \(family), address: \(address))"
    }
    if let address = self.local {
      return "SocketAddress(family: \(family), address: \(address))"
    }
    return "SocketAddress(family: \(family), \(self._length) bytes)"
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  @frozen
  /// The port number on which the socket is listening.
  public struct Port: RawRepresentable, ExpressibleByIntegerLiteral, Hashable {
    /// The port number, in host byte order.
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.InPort

    @_alwaysEmitIntoClient
    public init(_ value: CInterop.InPort) {
      self.rawValue = value
    }

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.InPort) {
      self.init(rawValue)
    }

    @_alwaysEmitIntoClient
    public init(integerLiteral value: CInterop.InPort) {
      self.init(value)
    }
  }
}
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.Port: CustomStringConvertible {
  public var description: String {
    rawValue.description
  }
}
