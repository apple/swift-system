/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
@_implementationOnly import CSystem
import Glibc
#elseif canImport(Musl)
@_implementationOnly import CSystem
import Musl
#elseif canImport(Android)
@_implementationOnly import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

import SystemPackage

@available(System 99, *)
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

    #if SYSTEM_PACKAGE_DARWIN
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
    #endif
  }
}

@available(System 99, *)
extension SocketAddress.Family: CustomStringConvertible {
  public var description: String {
    switch self {
    case .unspecified: return "unspecified"
    case .local: return "local"
    case .ipv4: return "ipv4"
    case .routing: return "routing"
    case .ipv6: return "ipv6"
    #if SYSTEM_PACKAGE_DARWIN
    case .system: return "system"
    case .networkDevice: return "networkDevice"
    #endif
    default:
      return rawValue.description
    }
  }
}
