/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension SocketAddress {
  @frozen
  public struct IPv6: RawRepresentable {
    public var rawValue: CInterop.SockAddrIn6

    public init(rawValue: CInterop.SockAddrIn6) {
      self.rawValue = rawValue
      self.rawValue.sin6_family = CInterop.SAFamily(Family.ipv6.rawValue)
    }

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

extension SocketAddress {
  public init(_ address: IPv6) {
    self = Swift.withUnsafeBytes(of: address.rawValue) { buffer in
      SocketAddress(buffer)
    }
  }
}

extension SocketAddress.IPv6 {
  public init(address: Address, port: Port) {
    // FIXME: We aren't modeling flowinfo & scope_id yet.
    // If we need to do that, we can define new initializers/accessors later.
    rawValue = CInterop.SockAddrIn6()
    rawValue.sin6_family = CInterop.SAFamily(SocketAddress.Family.ipv6.rawValue)
    rawValue.sin6_port = port.rawValue._networkOrder
    rawValue.sin6_flowinfo = 0
    rawValue.sin6_addr = address.rawValue
    rawValue.sin6_scope_id = 0
  }

  public init?(address: String, port: Port) {
    guard let address = Address(address) else { return nil }
    self.init(address: address, port: port)
  }
}

extension SocketAddress.IPv6: Hashable {
  public static func ==(left: Self, right: Self) -> Bool {
    left.address == right.address
      && left.port == right.port
      && left.rawValue.sin6_flowinfo == right.rawValue.sin6_flowinfo
      && left.rawValue.sin6_scope_id == right.rawValue.sin6_scope_id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(port)
    hasher.combine(rawValue.sin6_flowinfo)
    hasher.combine(address)
    hasher.combine(rawValue.sin6_scope_id)
  }
}

extension SocketAddress.IPv6: CustomStringConvertible {
  public var description: String {
    "[\(address)]:\(port)"
  }
}

extension SocketAddress.IPv6 {
  public typealias Port = SocketAddress.IPv4.Port

  public var port: Port {
    get { Port(CInterop.InPort(_networkOrder: rawValue.sin6_port)) }
    set { rawValue.sin6_port = newValue.rawValue._networkOrder }
  }
}

extension SocketAddress.IPv6 {
  @frozen
  public struct Address: RawRepresentable {
    /// The raw internet address value, in host byte order.
    public var rawValue: CInterop.In6Addr

    public init(rawValue: CInterop.In6Addr) {
      self.rawValue = rawValue
    }
  }

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

extension SocketAddress.IPv6.Address: Hashable {
  public static func ==(left: Self, right: Self) -> Bool {
    let l = left.rawValue.__u6_addr.__u6_addr32
    let r = right.rawValue.__u6_addr.__u6_addr32
    return l.0 == r.0 && l.1 == r.1 && l.2 == r.2 && l.3 == r.3
  }

  public func hash(into hasher: inout Hasher) {
    let t = rawValue.__u6_addr.__u6_addr32
    hasher.combine(t.0)
    hasher.combine(t.1)
    hasher.combine(t.2)
    hasher.combine(t.3)
  }
}

extension SocketAddress.IPv6.Address: CustomStringConvertible {
  public var description: String {
    _inet_ntop()
  }

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

extension SocketAddress.IPv6.Address: LosslessStringConvertible {
  public init?(_ description: String) {
    guard let value = Self._inet_pton(description) else { return nil }
    self = value
  }

  internal static func _inet_pton(_ string: String) -> Self? {
    string.withCString { ptr in
      var addr = CInterop.In6Addr()
      let res = system_inet_pton(_PF_INET6, ptr, &addr)
      guard res == 1 else { return nil }
      return Self(rawValue: addr)
    }
  }
}
