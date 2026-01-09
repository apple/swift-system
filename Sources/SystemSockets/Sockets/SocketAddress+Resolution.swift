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

// MARK: - Address Resolution Error

/// An error returned by address resolution functions.
@frozen
@available(System 99, *)
public struct AddressResolutionError: Error, Hashable, Sendable {
  /// The error code returned by getaddrinfo or getnameinfo.
  public let code: CInt

  @_alwaysEmitIntoClient
  public init(code: CInt) {
    self.code = code
  }

  /// A human-readable error message.
  public var message: String {
    String(cString: system_gai_strerror(code))
  }
}

@available(System 99, *)
extension AddressResolutionError: CustomStringConvertible {
  public var description: String {
    "AddressResolutionError(\(code)): \(message)"
  }
}

// MARK: - Resolution Hints

@available(System 99, *)
extension SocketAddress {
  /// Hints for address resolution.
  public struct ResolutionHints: Sendable {
    /// The protocol family to search for.
    public var family: SocketDescriptor.Domain?

    /// The socket type to search for.
    public var socketType: SocketDescriptor.ConnectionType?

    /// The protocol to search for.
    public var `protocol`: SocketDescriptor.ProtocolID?

    /// Resolution flags.
    public var flags: ResolutionFlags

    /// Creates resolution hints with the given parameters.
    public init(
      family: SocketDescriptor.Domain? = nil,
      socketType: SocketDescriptor.ConnectionType? = nil,
      protocol: SocketDescriptor.ProtocolID? = nil,
      flags: ResolutionFlags = []
    ) {
      self.family = family
      self.socketType = socketType
      self.protocol = `protocol`
      self.flags = flags
    }
  }

  /// Flags for address resolution.
  @frozen
  public struct ResolutionFlags: OptionSet, Sendable {
    public var rawValue: CInt

    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }

    /// Use passive socket for binding.
    ///
    /// The corresponding C constant is `AI_PASSIVE`.
    public static var passive: ResolutionFlags { ResolutionFlags(rawValue: AI_PASSIVE) }

    /// Return canonical name.
    ///
    /// The corresponding C constant is `AI_CANONNAME`.
    public static var canonicalName: ResolutionFlags { ResolutionFlags(rawValue: AI_CANONNAME) }

    /// Address must be numeric.
    ///
    /// The corresponding C constant is `AI_NUMERICHOST`.
    public static var numericHost: ResolutionFlags { ResolutionFlags(rawValue: AI_NUMERICHOST) }

    /// Service must be numeric.
    ///
    /// The corresponding C constant is `AI_NUMERICSERV`.
    public static var numericService: ResolutionFlags { ResolutionFlags(rawValue: AI_NUMERICSERV) }

    /// Return IPv4-mapped IPv6 addresses.
    ///
    /// The corresponding C constant is `AI_V4MAPPED`.
    public static var v4Mapped: ResolutionFlags { ResolutionFlags(rawValue: AI_V4MAPPED) }

    /// Return both IPv4 and IPv6 addresses.
    ///
    /// The corresponding C constant is `AI_ALL`.
    public static var all: ResolutionFlags { ResolutionFlags(rawValue: AI_ALL) }

    /// Return addresses only if configured.
    ///
    /// The corresponding C constant is `AI_ADDRCONFIG`.
    public static var addressConfigured: ResolutionFlags { ResolutionFlags(rawValue: AI_ADDRCONFIG) }
  }
}

// MARK: - Resolution Result

@available(System 99, *)
extension SocketAddress {
  /// A result from address resolution.
  public struct ResolvedAddress: Sendable {
    /// The socket domain.
    public let family: SocketDescriptor.Domain

    /// The socket type.
    public let socketType: SocketDescriptor.ConnectionType

    /// The socket protocol.
    public let `protocol`: SocketDescriptor.ProtocolID

    /// The resolved socket address.
    public let address: SocketAddress

    /// The canonical name, if requested and available.
    public let canonicalName: String?

    internal init(
      family: SocketDescriptor.Domain,
      socketType: SocketDescriptor.ConnectionType,
      protocol: SocketDescriptor.ProtocolID,
      address: SocketAddress,
      canonicalName: String?
    ) {
      self.family = family
      self.socketType = socketType
      self.protocol = `protocol`
      self.address = address
      self.canonicalName = canonicalName
    }
  }
}

// MARK: - Address Resolution

@available(System 99, *)
extension SocketAddress {
  /// Resolves a hostname and service to a list of socket addresses.
  ///
  /// - Parameters:
  ///   - hostname: The hostname to resolve, or `nil` for the local host.
  ///   - service: The service name or port number, or `nil`.
  ///   - hints: Hints to narrow the search.
  /// - Returns: An array of resolved addresses.
  /// - Throws: `AddressResolutionError` if resolution fails.
  ///
  /// The corresponding C function is `getaddrinfo`.
  public static func resolve(
    hostname: String? = nil,
    service: String? = nil,
    hints: ResolutionHints = ResolutionHints()
  ) throws -> [ResolvedAddress] {
    var hintsStruct = addrinfo()
    hintsStruct.ai_flags = hints.flags.rawValue
    if let family = hints.family {
      hintsStruct.ai_family = family.rawValue
    }
    if let socketType = hints.socketType {
      hintsStruct.ai_socktype = socketType.rawValue
    }
    if let proto = hints.protocol {
      hintsStruct.ai_protocol = proto.rawValue
    }

    var result: UnsafeMutablePointer<addrinfo>?

    let errorCode: CInt = hostname._withOptionalCString { hostnamePtr in
      service._withOptionalCString { servicePtr in
        system_getaddrinfo(hostnamePtr, servicePtr, &hintsStruct, &result)
      }
    }

    guard errorCode == 0 else {
      throw AddressResolutionError(code: errorCode)
    }

    defer { system_freeaddrinfo(result) }

    var addresses: [ResolvedAddress] = []
    var current = result

    while let info = current {
      let family = SocketDescriptor.Domain(rawValue: info.pointee.ai_family)
      let socketType = SocketDescriptor.ConnectionType(rawValue: info.pointee.ai_socktype)
      let proto = SocketDescriptor.ProtocolID(rawValue: info.pointee.ai_protocol)

      let address: SocketAddress
      if let addr = info.pointee.ai_addr {
        address = SocketAddress(
          address: addr,
          length: info.pointee.ai_addrlen
        )
      } else {
        address = SocketAddress()
      }

      let canonicalName: String?
      if let name = info.pointee.ai_canonname {
        canonicalName = String(cString: name)
      } else {
        canonicalName = nil
      }

      addresses.append(ResolvedAddress(
        family: family,
        socketType: socketType,
        protocol: proto,
        address: address,
        canonicalName: canonicalName
      ))

      current = info.pointee.ai_next
    }

    return addresses
  }
}

// MARK: - Reverse Resolution

@available(System 99, *)
extension SocketAddress {
  /// Flags for reverse resolution.
  @frozen
  public struct ReverseResolutionFlags: OptionSet, Sendable {
    public var rawValue: CInt

    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }

    /// Return numeric host.
    ///
    /// The corresponding C constant is `NI_NUMERICHOST`.
    public static var numericHost: ReverseResolutionFlags { ReverseResolutionFlags(rawValue: NI_NUMERICHOST) }

    /// Return numeric service.
    ///
    /// The corresponding C constant is `NI_NUMERICSERV`.
    public static var numericService: ReverseResolutionFlags { ReverseResolutionFlags(rawValue: NI_NUMERICSERV) }

    /// Look up datagram service.
    ///
    /// The corresponding C constant is `NI_DGRAM`.
    public static var datagram: ReverseResolutionFlags { ReverseResolutionFlags(rawValue: NI_DGRAM) }

    /// Return only the hostname part of FQDN.
    ///
    /// The corresponding C constant is `NI_NOFQDN`.
    public static var noFullyQualified: ReverseResolutionFlags { ReverseResolutionFlags(rawValue: NI_NOFQDN) }

    /// Fail if name cannot be determined.
    ///
    /// The corresponding C constant is `NI_NAMEREQD`.
    public static var nameRequired: ReverseResolutionFlags { ReverseResolutionFlags(rawValue: NI_NAMEREQD) }
  }

  /// A result from reverse resolution.
  public struct ReverseLookupResult: Sendable {
    /// The hostname.
    public let hostname: String?

    /// The service name.
    public let service: String?
  }

  /// Resolves this address to a hostname and service.
  ///
  /// - Parameter flags: Flags controlling the resolution.
  /// - Returns: The hostname and service.
  /// - Throws: `AddressResolutionError` if resolution fails.
  ///
  /// The corresponding C function is `getnameinfo`.
  public func reverseLookup(
    flags: ReverseResolutionFlags = []
  ) throws -> ReverseLookupResult {
    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    var service = [CChar](repeating: 0, count: Int(NI_MAXSERV))

    let errorCode = withUnsafePointer { addr, len in
      system_getnameinfo(
        addr,
        len,
        &hostname,
        socklen_t(hostname.count),
        &service,
        socklen_t(service.count),
        flags.rawValue
      )
    }

    guard errorCode == 0 else {
      throw AddressResolutionError(code: errorCode)
    }

    let hostnameStr = hostname[0] != 0 ? String(cString: hostname) : nil
    let serviceStr = service[0] != 0 ? String(cString: service) : nil

    return ReverseLookupResult(hostname: hostnameStr, service: serviceStr)
  }
}

// MARK: - Helpers

extension Optional where Wrapped == String {
  func _withOptionalCString<R>(_ body: (UnsafePointer<CChar>?) throws -> R) rethrows -> R {
    switch self {
    case .none:
      return try body(nil)
    case .some(let string):
      return try string.withCString(body)
    }
  }
}
