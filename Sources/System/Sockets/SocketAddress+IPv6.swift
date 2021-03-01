/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// An IPv6 address and port number.
  @frozen
  public struct IPv6: RawRepresentable {
    public var rawValue: CInterop.SockAddrIn6

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.SockAddrIn6) {
      self.rawValue = rawValue
      self.rawValue.sin6_family = Family.ipv6.rawValue
    }

    @_alwaysEmitIntoClient
    public init?(_ address: SocketAddress) {
      guard address.family == .ipv6 else { return nil }
      let value: CInterop.SockAddrIn6? = address.withUnsafeBytes { buffer in
        guard buffer.count >= MemoryLayout<CInterop.SockAddrIn6>.size else {
          return nil
        }
        return buffer.baseAddress!.load(as: CInterop.SockAddrIn6.self)
      }
      guard let value = value else { return nil }
      self.rawValue = value
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Create a SocketAddress from an IPv6 address and port number.
  @_alwaysEmitIntoClient
  public init(_ address: IPv6) {
    self = Swift.withUnsafeBytes(of: address.rawValue) { buffer in
      SocketAddress(buffer)
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6 {
  /// Create a socket address from an IPv6 address and port number.
  @_alwaysEmitIntoClient
  public init(address: Address, port: Port) {
    // FIXME: We aren't modeling flowinfo & scope_id yet.
    // If we need to do that, we can add new arguments or define new
    // initializers/accessors later.
    rawValue = CInterop.SockAddrIn6()
    rawValue.sin6_family = SocketAddress.Family.ipv6.rawValue
    rawValue.sin6_port = port.rawValue._networkOrder
    rawValue.sin6_flowinfo = 0
    rawValue.sin6_addr = address.rawValue
    rawValue.sin6_scope_id = 0
  }

  @_alwaysEmitIntoClient
  public init?(address: String, port: Port) {
    guard let address = Address(address) else { return nil }
    self.init(address: address, port: port)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6: Hashable {
  @_alwaysEmitIntoClient
  public static func ==(left: Self, right: Self) -> Bool {
    left.address == right.address
      && left.port == right.port
      && left.rawValue.sin6_flowinfo == right.rawValue.sin6_flowinfo
      && left.rawValue.sin6_scope_id == right.rawValue.sin6_scope_id
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(port)
    hasher.combine(rawValue.sin6_flowinfo)
    hasher.combine(address)
    hasher.combine(rawValue.sin6_scope_id)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6: CustomStringConvertible {
  public var description: String {
    "[\(address)]:\(port)"
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6 {
  public typealias Port = SocketAddress.IPv4.Port

  @_alwaysEmitIntoClient
  public var port: Port {
    get { Port(CInterop.InPort(_networkOrder: rawValue.sin6_port)) }
    set { rawValue.sin6_port = newValue.rawValue._networkOrder }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6 {
  /// A 128-bit IPv6 address.
  @frozen
  public struct Address: RawRepresentable {
    /// The raw internet address value, in host byte order.
    public var rawValue: CInterop.In6Addr

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.In6Addr) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public init(_ value: CInterop.In6Addr) {
      self.rawValue = value
    }
  }

  @_alwaysEmitIntoClient
  public var address: Address {
    get {
      return Address(rawValue: rawValue.sin6_addr)
    }
    set {
      rawValue.sin6_addr = newValue.rawValue
    }
  }
}

extension SocketAddress.IPv6.Address {
  /// The IPv6 address "::" (i.e., all zero).
  ///
  /// This corresponds to the C constant `IN6ADDR_ANY_INIT`.
  @_alwaysEmitIntoClient
  public static var any: Self {
    Self(CInterop.In6Addr())
  }

  /// The IPv4 loopback address "::1".
  ///
  /// This corresponds to the C constant `IN6ADDR_LOOPBACK_INIT`.
  @_alwaysEmitIntoClient
  public static var loopback: Self {
    var addr = CInterop.In6Addr()
    addr.__u6_addr.__u6_addr8.15 = 1
    return Self(addr)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6.Address {
  /// Create a 128-bit IPv6 address from raw bytes in memory.
  @_alwaysEmitIntoClient
  public init(bytes: UnsafeRawBufferPointer) {
    precondition(bytes.count == MemoryLayout<CInterop.In6Addr>.size)
    var addr = CInterop.In6Addr()
    withUnsafeMutableBytes(of: &addr) { target in
      target.baseAddress!.copyMemory(
        from: bytes.baseAddress!,
        byteCount: bytes.count)
    }
    self.rawValue = addr
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6.Address: Hashable {
  @_alwaysEmitIntoClient
  public static func ==(left: Self, right: Self) -> Bool {
    let l = left.rawValue.__u6_addr.__u6_addr32
    let r = right.rawValue.__u6_addr.__u6_addr32
    return l.0 == r.0 && l.1 == r.1 && l.2 == r.2 && l.3 == r.3
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    let t = rawValue.__u6_addr.__u6_addr32
    hasher.combine(t.0)
    hasher.combine(t.1)
    hasher.combine(t.2)
    hasher.combine(t.3)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6.Address: CustomStringConvertible {
  @_alwaysEmitIntoClient
  public var description: String {
    _inet_ntop()
  }

  @usableFromInline
  internal func _inet_ntop() -> String {
    return withUnsafeBytes(of: rawValue) { src in
      String(_unsafeUninitializedCapacity: Int(_INET6_ADDRSTRLEN)) { dst in
        dst.baseAddress!.withMemoryRebound(
          to: CChar.self,
          capacity: Int(_INET6_ADDRSTRLEN)
        ) { dst in
          let res = system_inet_ntop(
              _PF_INET6,
              src.baseAddress!,
              dst,
              CInterop.SockLen(_INET6_ADDRSTRLEN))
          if res == -1 {
            let errno = Errno.current
            fatalError("Failed to convert IPv6 address to string: \(errno)")
          }
          let length = system_strlen(dst)
          assert(length <= _INET6_ADDRSTRLEN)
          return length
        }
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv6.Address: LosslessStringConvertible {
  @_alwaysEmitIntoClient
  public init?(_ description: String) {
    guard let value = Self._inet_pton(description) else { return nil }
    self = value
  }

  @usableFromInline
  internal static func _inet_pton(_ string: String) -> Self? {
    string.withCString { ptr in
      var addr = CInterop.In6Addr()
      let res = system_inet_pton(_PF_INET6, ptr, &addr)
      guard res == 1 else { return nil }
      return Self(rawValue: addr)
    }
  }
}
