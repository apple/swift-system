/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Information about a resolved address.
  ///
  /// The members of this struct can be passed directly to
  /// `SocketDescriptor.connect()` or `SocketDescriptor.bind().
  ///
  /// This loosely corresponds to the C `struct addrinfo`.
  public struct Info {
    /// Address family.
    public var family: Family { Family(rawValue: CInterop.SAFamily(domain.rawValue)) }

    /// Communications domain.
    public let domain: SocketDescriptor.Domain

    /// Socket type.
    public let type: SocketDescriptor.ConnectionType
    /// Protocol for socket.
    public let `protocol`: SocketDescriptor.ProtocolID
    /// Socket address.
    public let address: SocketAddress
    /// Canonical name for service location.
    public let canonicalName: String?

    internal init(
      domain: SocketDescriptor.Domain,
      type: SocketDescriptor.ConnectionType,
      protocol: SocketDescriptor.ProtocolID,
      address: SocketAddress,
      canonicalName: String? = nil
    ) {
      self.domain = domain
      self.type = type
      self.protocol = `protocol`
      self.address = address
      self.canonicalName = canonicalName
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Address resolution flags.
  @frozen
  public struct ResolverFlags: OptionSet, RawRepresentable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) {
      self.init(rawValue: raw)
    }

    @_alwaysEmitIntoClient
    public init() {
      self.rawValue = 0
    }

    /// Return IPv4 (or IPv6) addresses only if the local system is
    /// configured with an IPv4 (or IPv6) address of its own.
    ///
    /// This corresponds to the C constant `AI_ADDRCONFIG`.
    @_alwaysEmitIntoClient
    public static var configuredAddress: Self { Self(_AI_ADDRCONFIG) }

    /// If `.ipv4Mapped` is also present, then return also return all
    /// matching IPv4 addresses in addition to IPv6 addresses.
    ///
    /// If `.ipv4Mapped` is not present, then this flag is ignored.
    ///
    /// This corresponds to the C constant `AI_ALL`.
    @_alwaysEmitIntoClient
    public static var all: Self { Self(_AI_ALL) }

    /// If this flag is present, then name resolution returns the canonical
    /// name of the specified hostname in the `canonicalName` field of the
    /// first `Info` structure of the returned array.
    ///
    /// This corresponds to the C constant `AI_CANONNAME`.
    @_alwaysEmitIntoClient
    public static var canonicalName: Self { Self(_AI_CANONNAME) }

    /// Indicates that the specified hostname string contains an IPv4 or
    /// IPv6 address in numeric string representation. No name resolution
    /// will be attempted.
    ///
    /// This corresponds to the C constant `AI_NUMERICHOST`.
    @_alwaysEmitIntoClient
    public static var numericHost: Self { Self(_AI_NUMERICHOST) }

    /// Indicates that the specified service string contains a numerical port
    /// value. This prevents having to resolve the port number using a
    /// resolution service.
    ///
    /// This corresponds to the C constant `AI_NUMERICSERV`.
    @_alwaysEmitIntoClient
    public static var numericService: Self { Self(_AI_NUMERICSERV) }

    /// Indicates that the returned address is intended for use in
    /// a call to `SocketDescriptor.bind()`. In this case, a
    /// `nil` hostname resolves to `SocketAddress.IPv4.Address.any` or
    /// `SocketAddress.IPv6.Address.any`.
    ///
    /// If this flag is not present, the returned socket address will be ready
    /// for use as the recipient address in a call to `connect()` or
    /// `sendMessage()`. In this case a `nil` hostname resolves to
    /// `SocketAddress.IPv4.Address.loopback`, or
    /// `SocketAddress.IPv6.Address.loopback`.
    ///
    /// This corresponds to the C constant `AI_PASSIVE`.
    @_alwaysEmitIntoClient
    public static var passive: Self { Self(_AI_PASSIVE) }

    /// This flag indicates that name resolution should return IPv4-mapped
    /// IPv6 addresses if no matching IPv6 addresses are found.
    ///
    /// This flag is ignored unless resolution is performed with the IPv6
    /// family.
    ///
    /// This corresponds to the C constant `AI_V4MAPPED`.
    @_alwaysEmitIntoClient
    public static var ipv4Mapped: Self { Self(_AI_V4MAPPED) }

    /// This behaves the same as `.ipv4Mapped` if the kernel supports
    /// IPv4-mapped IPv6 addresses. Otherwise this flag is ignored.
    ///
    /// This corresponds to the C constant `AI_V4MAPPED_CFG`.
    @_alwaysEmitIntoClient
    public static var ipv4MappedIfSupported: Self { Self(_AI_V4MAPPED_CFG) }

    /// This is the combination of the flags
    /// `.ipv4MappedIfSupported` and `.configuredAddress`,
    /// used by default if no flags are specified.
    ///
    /// This behavior can be overridden by setting the `.unusable` flag.
    ///
    /// This corresponds to the C constant `AI_DEFAULT`.
    @_alwaysEmitIntoClient
    public static var `default`: Self { Self(_AI_DEFAULT) }

    /// Adding this flag suppresses the implicit default setting of
    /// `.ipv4MappedIfSupported` and `.configuredAddress` for an empty `Flags`
    /// value, allowing unusuable addresses to be included in the results.
    ///
    /// This corresponds to the C constant `AI_UNUSABLE`.
    @_alwaysEmitIntoClient
    public static var unusable: Self { Self(_AI_UNUSABLE) }
  }
}

extension SocketAddress {
  /// An address resolution failure.
  ///
  /// This corresponds to the error returned by the C function `getaddrinfo`.
  @frozen
  public struct ResolverError
  : Error, RawRepresentable, Hashable, CustomStringConvertible
  {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) {
      self.init(rawValue: raw)
    }

    // Use "hidden" entry points for `NSError` bridging
    @_alwaysEmitIntoClient
    public var _code: Int { Int(rawValue) }

    @_alwaysEmitIntoClient
    public var _domain: String {
      // FIXME: See if there is an existing domain for these.
      "System.SocketAddress.ResolverError"
    }

    public var description: String {
      String(cString: system_gai_strerror(rawValue))
    }

    @_alwaysEmitIntoClient
    public static func ~=(_ lhs: ResolverError, _ rhs: Error) -> Bool {
      guard let value = rhs as? ResolverError else { return false }
      return lhs == value
    }

    /// Address family not supported for the specific hostname (`EAI_ADDRFAMILY`).
    @_alwaysEmitIntoClient
    public static var unsupportedAddressFamilyForHost: Self { Self(_EAI_ADDRFAMILY) }

    /// Temporary failure in name resolution (`EAI_AGAIN`).
    @_alwaysEmitIntoClient
    public static var temporaryFailure: Self { Self(_EAI_AGAIN) }

    /// Invalid resolver flags (`EAI_BADFLAGS`).
    @_alwaysEmitIntoClient
    public static var badFlags: Self { Self(_EAI_BADFLAGS) }

    /// Non-recoverable failure in name resolution (`EAI_FAIL`).
    @_alwaysEmitIntoClient
    public static var nonrecoverableFailure: Self { Self(_EAI_FAIL) }

    /// Unsupported address family (`EAI_FAMILY`).
    @_alwaysEmitIntoClient
    public static var unsupportedAddressFamily: Self { Self(_EAI_FAMILY) }

    /// Memory allocation failure (`EAI_MEMORY`).
    @_alwaysEmitIntoClient
    public static var memoryAllocation: Self { Self(_EAI_MEMORY) }

    /// No data associated with hostname (`EAI_NODATA`).
    @_alwaysEmitIntoClient
    public static var noData: Self { Self(_EAI_NODATA) }

    /// Hostname nor service name provided, or not known (`EAI_NONAME`).
    @_alwaysEmitIntoClient
    public static var noName: Self { Self(_EAI_NONAME) }

    /// Service name not supported for specified socket type (`EAI_SERVICE`).
    @_alwaysEmitIntoClient
    public static var unsupportedServiceForSocketType: Self { Self(_EAI_SERVICE) }

    /// Socket type not supported (`EAI_SOCKTYPE`).
    @_alwaysEmitIntoClient
    public static var unsupportedSocketType: Self { Self(_EAI_SOCKTYPE) }

    /// System error (`EAI_SYSTEM`).
    @_alwaysEmitIntoClient
    public static var system: Self { Self(_EAI_SYSTEM) }

    /// Invalid hints (`EAI_BADHINTS`).
    @_alwaysEmitIntoClient
    public static var badHints: Self { Self(_EAI_BADHINTS) }

    /// Unsupported protocol value (`EAI_PROTOCOL`).
    @_alwaysEmitIntoClient
    public static var unsupportedProtocol: Self { Self(_EAI_PROTOCOL) }

    /// Argument buffer overflow (`EAI_OVERFLOW`).
    @_alwaysEmitIntoClient
    public static var overflow: Self { Self(_EAI_OVERFLOW) }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Get a list of IP addresses and port numbers for a host and service.
  ///
  /// TODO: communicate that on failure, this throws a `ResolverError`.
  ///
  /// The method corresponds to the C function `getaddrinfo`.
  @_alwaysEmitIntoClient
  public static func resolve(
    hostname: String?,
    service: String?,
    flags: ResolverFlags? = nil,
    family: Family? = nil,
    type: SocketDescriptor.ConnectionType? = nil,
    protocol: SocketDescriptor.ProtocolID? = nil
  ) throws -> [Info] {
    // Note: I'm assuming getaddrinfo will never fail with EINTR.
    // It it turns out it can, we should add a `retryIfInterrupted` argument.
    let result = _resolve(
      hostname: hostname,
      service: service,
      flags: flags,
      family: family,
      type: type,
      protocol: `protocol`)
    if let error = result.error {
      if let errno = error.1 { throw errno}
      throw error.0
    }
    return result.results
  }

  /// The method corresponds to the C function `getaddrinfo`.
  @usableFromInline
  internal static func _resolve(
    hostname: String?,
    service: String?,
    flags: ResolverFlags? = nil,
    family: Family? = nil,
    type: SocketDescriptor.ConnectionType? = nil,
    protocol: SocketDescriptor.ProtocolID? = nil
  ) -> (results: [Info], error: (Error, Errno?)?) {
    var hints: CInterop.AddrInfo = CInterop.AddrInfo()
    var haveHints = false
    if let flags = flags {
      hints.ai_flags = flags.rawValue
      haveHints = true
    }
    if let family = family {
      hints.ai_family = CInt(family.rawValue)
      haveHints = true
    }
    if let type = type {
      hints.ai_socktype = type.rawValue
      haveHints = true
    }
    if let proto = `protocol` {
      hints.ai_protocol = proto.rawValue
      haveHints = true
    }

    var entries: UnsafeMutablePointer<CInterop.AddrInfo>? = nil
    let error = _withOptionalUnsafePointer(
      to: haveHints ? hints : nil
    ) { hints in
      _getaddrinfo(
        hostname,
        service,
        hints,
        &entries
      )
    }

    // Handle errors.
    if let error = error {
      return ([], error)
    }

    // Count number of entries.
    var count = 0
    var p: UnsafeMutablePointer<CInterop.AddrInfo>? = entries
    while let entry = p {
      count += 1
      p = entry.pointee.ai_next
    }

    // Convert entries to `Info`.
    var result: [Info] = []
    result.reserveCapacity(count)
    p = entries
    while let entry = p {
      let info = Info(
        domain: SocketDescriptor.Domain(entry.pointee.ai_family),
        type: SocketDescriptor.ConnectionType(entry.pointee.ai_socktype),
        protocol: SocketDescriptor.ProtocolID(entry.pointee.ai_protocol),
        address: SocketAddress(address: entry.pointee.ai_addr,
                               length: entry.pointee.ai_addrlen),
        canonicalName: entry.pointee.ai_canonname.map { String(cString: $0) })
      result.append(info)
      p = entry.pointee.ai_next
    }

    // Release resources.
    system_freeaddrinfo(entries)

    return (result, nil)
  }

  internal static func _getaddrinfo(
    _ hostname: UnsafePointer<CChar>?,
    _ servname: UnsafePointer<CChar>?,
    _ hints: UnsafePointer<CInterop.AddrInfo>?,
    _ res: inout UnsafeMutablePointer<CInterop.AddrInfo>?
  ) -> (ResolverError, Errno?)? {
    let r = system_getaddrinfo(hostname, servname, hints, &res)
    if r == 0 { return nil }
    let error = ResolverError(rawValue: r)
    if error == .system {
      return (error, Errno.current)
    }
    return (error, nil)
  }
}

