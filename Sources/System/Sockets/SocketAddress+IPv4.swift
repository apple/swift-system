/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  @frozen
  /// An IPv4 address and port number.
  public struct IPv4: RawRepresentable {
    public var rawValue: CInterop.SockAddrIn

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.SockAddrIn) {
      self.rawValue = rawValue
      self.rawValue.sin_family = Family.ipv4.rawValue
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Create a SocketAddress from an IPv4 address and port number.
  @_alwaysEmitIntoClient
  public init(_ ipv4: IPv4) {
    self = Swift.withUnsafeBytes(of: ipv4.rawValue) { buffer in
      SocketAddress(buffer)
    }
  }

  /// If `self` holds an IPv4 address, extract it, otherwise return `nil`.
  @_alwaysEmitIntoClient
  public var ipv4: IPv4? {
    guard family == .ipv4 else { return nil }
    let value: CInterop.SockAddrIn? = self.withUnsafeBytes { buffer in
      guard buffer.count >= MemoryLayout<CInterop.SockAddrIn>.size else {
        return nil
      }
      return buffer.baseAddress!.load(as: CInterop.SockAddrIn.self)
    }
    guard let value = value else { return nil }
    return IPv4(rawValue: value)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4 {
  /// Create a socket address from a given Internet address and port number.
  @_alwaysEmitIntoClient
  public init(address: Address, port: SocketAddress.Port) {
    rawValue = CInterop.SockAddrIn()
    rawValue.sin_family = CInterop.SAFamily(SocketDescriptor.Domain.ipv4.rawValue);
    rawValue.sin_port = port.rawValue._networkOrder
    rawValue.sin_addr = CInterop.InAddr(s_addr: address.rawValue._networkOrder)
  }

  /// TODO: doc
  @_alwaysEmitIntoClient
  public init?(address: String, port: SocketAddress.Port) {
    guard let address = Address(address) else { return nil }
    self.init(address: address, port: port)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4: Hashable {
  @_alwaysEmitIntoClient
  public static func ==(left: Self, right: Self) -> Bool {
    left.address == right.address && left.port == right.port
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(address)
    hasher.combine(port)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4: CustomStringConvertible {
  public var description: String {
    "\(address):\(port)"
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4 {
  @frozen
  /// A 32-bit IPv4 address.
  public struct Address: RawRepresentable, Hashable {
    /// The raw internet address value, in host byte order.
    public var rawValue: CInterop.InAddrT

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.InAddrT) {
      self.rawValue = rawValue
    }
  }

  /// The 32-bit IPv4 address.
  @_alwaysEmitIntoClient
  public var address: Address {
    get {
      let value = CInterop.InAddrT(_networkOrder: rawValue.sin_addr.s_addr)
      return Address(rawValue: value)
    }
    set {
      rawValue.sin_addr.s_addr = newValue.rawValue._networkOrder
    }
  }

  @_alwaysEmitIntoClient
  public var port: SocketAddress.Port {
    get { SocketAddress.Port(CInterop.InPort(_networkOrder: rawValue.sin_port)) }
    set { rawValue.sin_port = newValue.rawValue._networkOrder }
  }
}

extension SocketAddress.IPv4.Address {
  /// The IPv4 address 0.0.0.0.
  ///
  /// This corresponds to the C constant `INADDR_ANY`.
  @_alwaysEmitIntoClient
  public static var any: Self { Self(rawValue: _INADDR_ANY) }

  /// The IPv4 loopback address 127.0.0.1.
  ///
  /// This corresponds to the C constant `INADDR_LOOPBACK`.
  @_alwaysEmitIntoClient
  public static var loopback: Self { Self(rawValue: _INADDR_LOOPBACK) }

  /// The IPv4 broadcast address 255.255.255.255.
  ///
  /// This corresponds to the C constant `INADDR_BROADCAST`.
  @_alwaysEmitIntoClient
  public static var broadcast: Self { Self(rawValue: _INADDR_BROADCAST) }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4.Address: CustomStringConvertible {
  public var description: String {
    _inet_ntop()
  }

  internal func _inet_ntop() -> String {
    let addr = CInterop.InAddr(s_addr: rawValue._networkOrder)
    return withUnsafeBytes(of: addr) { src in
      String(_unsafeUninitializedCapacity: Int(_INET_ADDRSTRLEN)) { dst in
        dst.baseAddress!.withMemoryRebound(
          to: CChar.self,
          capacity: Int(_INET_ADDRSTRLEN)
        ) { dst in
          let res = system_inet_ntop(
              _PF_INET,
              src.baseAddress!,
              dst,
              CInterop.SockLen(_INET_ADDRSTRLEN))
          if res == -1 {
            let errno = Errno.current
            fatalError("Failed to convert IPv4 address to string: \(errno)")
          }
          let length = system_strlen(dst)
          assert(length <= _INET_ADDRSTRLEN)
          return length
        }
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.IPv4.Address: LosslessStringConvertible {
  public init?(_ description: String) {
    guard let value = Self._inet_pton(description) else { return nil }
    self = value
  }

  internal static func _inet_pton(_ string: String) -> Self? {
    string.withCString { ptr in
      var addr = CInterop.InAddr()
      let res = system_inet_pton(_PF_INET, ptr, &addr)
      guard res == 1 else { return nil }
      return Self(rawValue: CInterop.InAddrT(_networkOrder: addr.s_addr))
    }
  }
}
