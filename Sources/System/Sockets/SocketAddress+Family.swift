/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  @frozen
  /// The address family identifier
  public struct Family: RawRepresentable, Hashable {
    public let rawValue: CInterop.SAFamily

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.SAFamily) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ rawValue: CInterop.SAFamily) { self.init(rawValue: rawValue) }

    /// Unspecified address family.
    ///
    /// The corresponding C constant is `AF_UNSPEC`.
    @_alwaysEmitIntoClient
    public static var unspecified: Family { Family(_AF_UNSPEC) }

    /// Local address family.
    ///
    /// The corresponding C constant is `AF_LOCAL`.
    @_alwaysEmitIntoClient
    public static var local: Family { Family(_AF_LOCAL) }

    /// UNIX address family. (Renamed `local`.)
    ///
    /// The corresponding C constant is `AF_UNIX`.
    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "local")
    public static var unix: Family { Family(_AF_UNIX) }

    /// IPv4 address family.
    ///
    /// The corresponding C constant is `AF_INET`.
    @_alwaysEmitIntoClient
    public static var ipv4: Family { Family(_AF_INET) }

    /// Internal routing address family.
    ///
    /// The corresponding C constant is `AF_ROUTE`.
    @_alwaysEmitIntoClient
    public static var routing: Family { Family(_AF_ROUTE) }

    /// IPv6 address family.
    ///
    /// The corresponding C constant is `AF_INET6`.
    @_alwaysEmitIntoClient
    public static var ipv6: Family { Family(_AF_INET6) }

    /// System address family.
    ///
    /// The corresponding C constant is `AF_SYSTEM`.
    @_alwaysEmitIntoClient
    public static var system: Family { Family(_AF_SYSTEM) }

    /// Raw network device address family.
    ///
    /// The corresponding C constant is `AF_NDRV`
    @_alwaysEmitIntoClient
    public static var networkDevice: Family { Family(_AF_NDRV) }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.Family: CustomStringConvertible {
  public var description: String {
    switch rawValue {
    case _AF_UNSPEC: return "unspecified"
    case _AF_LOCAL: return "local"
    case _AF_UNIX: return "unix"
    case _AF_INET: return "ipv4"
    case _AF_ROUTE: return "routing"
    case _AF_INET6: return "ipv6"
    case _AF_SYSTEM: return "system"
    case _AF_NDRV: return "networkDevice"
    default:
      return rawValue.description
    }
  }
}
