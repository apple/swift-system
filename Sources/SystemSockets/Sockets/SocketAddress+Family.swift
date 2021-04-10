/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

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
    public static var unspecified: Family { Family(CInterop.SAFamily(AF_UNSPEC)) }

    /// Local address family.
    ///
    /// The corresponding C constant is `AF_LOCAL`.
    @_alwaysEmitIntoClient
    public static var local: Family { Family(CInterop.SAFamily(AF_LOCAL)) }

    /// UNIX address family. (Renamed `local`.)
    ///
    /// The corresponding C constant is `AF_UNIX`.
    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "local")
    public static var unix: Family { Family(CInterop.SAFamily(AF_UNIX)) }

    /// IPv4 address family.
    ///
    /// The corresponding C constant is `AF_INET`.
    @_alwaysEmitIntoClient
    public static var ipv4: Family { Family(CInterop.SAFamily(AF_INET)) }

    /// Internal routing address family.
    ///
    /// The corresponding C constant is `AF_ROUTE`.
    @_alwaysEmitIntoClient
    public static var routing: Family { Family(CInterop.SAFamily(AF_ROUTE)) }

    /// IPv6 address family.
    ///
    /// The corresponding C constant is `AF_INET6`.
    @_alwaysEmitIntoClient
    public static var ipv6: Family { Family(CInterop.SAFamily(AF_INET6)) }

    /// System address family.
    ///
    /// The corresponding C constant is `AF_SYSTEM`.
    @_alwaysEmitIntoClient
    public static var system: Family { Family(CInterop.SAFamily(AF_SYSTEM)) }

    /// Raw network device address family.
    ///
    /// The corresponding C constant is `AF_NDRV`
    @_alwaysEmitIntoClient
    public static var networkDevice: Family { Family(CInterop.SAFamily(AF_NDRV)) }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.Family: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unspecified: return "unspecified"
    case .local: return "local"
    //case .unix: return "unix"
    case .ipv4: return "ipv4"
    case .routing: return "routing"
    case .ipv6: return "ipv6"
    case .system: return "system"
    case .networkDevice: return "networkDevice"
    default:
      return rawValue.description
    }
  }
}
