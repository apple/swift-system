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
  /// `SocketDescriptor.open()`, `SocketDescriptor.connect()`
  /// or `SocketDescriptor.bind()` to initiate connections.
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
  /// Name resolution flags.
  @frozen
  public struct NameResolverFlags:
    OptionSet, RawRepresentable, CustomStringConvertible
  {
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

    public var description: String {
      let descriptions: [(Element, StaticString)] = [
        (.configuredAddress, ".configuredAddress"),
        (.all, ".all"),
        (.canonicalName, ".canonicalName"),
        (.numericHost, ".numericHost"),
        (.numericService, ".numericService"),
        (.passive, ".passive"),
        (.ipv4Mapped, ".ipv4Mapped"),
        (.ipv4MappedIfSupported, ".ipv4MappedIfSupported"),
        (.default, ".default"),
        (.unusable, ".unusable"),
      ]
      return _buildDescription(descriptions)
    }

  }

  /// Address resolution flags.
  @frozen
  public struct AddressResolverFlags:
    OptionSet, RawRepresentable, CustomStringConvertible
  {
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

    /// A fully qualified domain name is not required for local hosts.
    ///
    /// This corresponds to the C constant `NI_NOFQDN`.
    @_alwaysEmitIntoClient
    public static var noFullyQualifiedDomain: Self { Self(_NI_NOFQDN) }

    /// Return the address in numeric form, instead of a host name.
    ///
    /// This corresponds to the C constant `NI_NUMERICHOST`.
    @_alwaysEmitIntoClient
    public static var numericHost: Self { Self(_NI_NUMERICHOST) }

    /// Indicates that a name is required; if the host name cannot be found,
    /// an error will be thrown. If this option is not present, then a
    /// numerical address is returned.
    ///
    /// This corresponds to the C constant `NI_NAMEREQD`.
    @_alwaysEmitIntoClient
    public static var nameRequired: Self { Self(_NI_NAMEREQD) }

    /// The service name is returned as a digit string representing the port
    /// number.
    ///
    /// This corresponds to the C constant `NI_NUMERICSERV`.
    @_alwaysEmitIntoClient
    public static var numericService: Self { Self(_NI_NUMERICSERV) }

    /// Specifies that the service being looked up is a datagram service.
    /// This is useful in case a port number is used for different services
    /// over TCP & UDP.
    ///
    /// This corresponds to the C constant `NI_DGRAM`.
    @_alwaysEmitIntoClient
    public static var datagram: Self { Self(_NI_DGRAM) }

    /// Enable IPv6 address notation with scope identifiers.
    ///
    /// This corresponds to the C constant `NI_WITHSCOPEID`.
    @_alwaysEmitIntoClient
    public static var scopeIdentifier: Self { Self(_NI_WITHSCOPEID) }

    public var description: String {
      let descriptions: [(Element, StaticString)] = [
        (.noFullyQualifiedDomain, ".noFullyQualifiedDomain"),
        (.numericHost, ".numericHost"),
        (.nameRequired, ".nameRequired"),
        (.numericService, ".numericService"),
        (.datagram, ".datagram"),
        (.scopeIdentifier, ".scopeIdentifier"),
      ]
      return _buildDescription(descriptions)
    }

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

    /// Address family not supported for the specific hostname.
    ///
    /// The corresponding C constant is `EAI_ADDRFAMILY`.
    @_alwaysEmitIntoClient
    public static var unsupportedAddressFamilyForHost: Self { Self(_EAI_ADDRFAMILY) }

    /// Temporary failure in name resolution.
    ///
    /// The corresponding C constant is `EAI_AGAIN`.
    @_alwaysEmitIntoClient
    public static var temporaryFailure: Self { Self(_EAI_AGAIN) }

    /// Invalid resolver flags.
    ///
    /// The corresponding C constant is `EAI_BADFLAGS`.
    @_alwaysEmitIntoClient
    public static var badFlags: Self { Self(_EAI_BADFLAGS) }

    /// Non-recoverable failure in name resolution.
    ///
    /// The corresponding C constant is `EAI_FAIL`.
    @_alwaysEmitIntoClient
    public static var nonrecoverableFailure: Self { Self(_EAI_FAIL) }

    /// Unsupported address family.
    ///
    /// The corresponding C constant is `EAI_FAMILY`.
    @_alwaysEmitIntoClient
    public static var unsupportedAddressFamily: Self { Self(_EAI_FAMILY) }

    /// Memory allocation failure.
    ///
    /// The corresponding C constant is `EAI_MEMORY`.
    @_alwaysEmitIntoClient
    public static var memoryAllocation: Self { Self(_EAI_MEMORY) }

    /// No data associated with hostname.
    ///
    /// The corresponding C constant is `EAI_NODATA`.
    @_alwaysEmitIntoClient
    public static var noData: Self { Self(_EAI_NODATA) }

    /// Hostname nor service name provided, or not known.
    ///
    /// The corresponding C constant is `EAI_NONAME`.
    @_alwaysEmitIntoClient
    public static var noName: Self { Self(_EAI_NONAME) }

    /// Service name not supported for specified socket type.
    ///
    /// The corresponding C constant is `EAI_SERVICE`.
    @_alwaysEmitIntoClient
    public static var unsupportedServiceForSocketType: Self { Self(_EAI_SERVICE) }

    /// Socket type not supported.
    ///
    /// The corresponding C constant is `EAI_SOCKTYPE`.
    @_alwaysEmitIntoClient
    public static var unsupportedSocketType: Self { Self(_EAI_SOCKTYPE) }

    /// System error.
    ///
    /// The corresponding C constant is `EAI_SYSTEM`.
    @_alwaysEmitIntoClient
    public static var system: Self { Self(_EAI_SYSTEM) }

    /// Invalid hints.
    ///
    /// The corresponding C constant is `EAI_BADHINTS`.
    @_alwaysEmitIntoClient
    public static var badHints: Self { Self(_EAI_BADHINTS) }

    /// Unsupported protocol value.
    ///
    /// The corresponding C constant is `EAI_PROTOCOL`.
    @_alwaysEmitIntoClient
    public static var unsupportedProtocol: Self { Self(_EAI_PROTOCOL) }

    /// Argument buffer overflow.
    ///
    /// The corresponding C constant is `EAI_OVERFLOW`.
    @_alwaysEmitIntoClient
    public static var overflow: Self { Self(_EAI_OVERFLOW) }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Get a list of IP addresses and port numbers for a host and service.
  ///
  /// On failure, this throws either a `ResolverError` or an `Errno`,
  /// depending on the error code returned by the underlying `getaddrinfo`
  /// function.
  ///
  /// The method corresponds to the C function `getaddrinfo`.
  public static func resolveName(
    hostname: String?,
    service: String?,
    flags: NameResolverFlags? = nil,
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
  internal static func _resolve(
    hostname: String?,
    service: String?,
    flags: NameResolverFlags?,
    family: Family?,
    type: SocketDescriptor.ConnectionType?,
    protocol: SocketDescriptor.ProtocolID?
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
    let error = _withOptionalUnsafePointerOrNull(
      to: haveHints ? hints : nil
    ) { hints in
      _getaddrinfo(hostname, service, hints, &entries)
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

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  /// Resolve a socket address to hostname and service name.
  ///
  /// On failure, this throws either a `ResolverError` or an `Errno`,
  /// depending on the error code returned by the underlying `getnameinfo`
  /// function.
  ///
  /// This method corresponds to the C function `getnameinfo`.
  public static func resolveAddress(
    _ address: SocketAddress,
    flags: AddressResolverFlags = []
  ) throws -> (hostname: String, service: String) {
    let (result, error) = _resolveAddress(address, flags)
    if let error = error {
      if let errno = error.1 { throw errno }
      throw error.0
    }
    return result
  }

  internal static func _resolveAddress(
    _ address: SocketAddress,
    _ flags: AddressResolverFlags
  ) -> (results: (hostname: String, service: String), error: (ResolverError, Errno?)?) {
    address.withUnsafeCInterop { adr, adrlen in
      var r: CInt = 0
      var service: String = ""
      let host = String(_unsafeUninitializedCapacity: Int(_NI_MAXHOST)) { host in
        let h = UnsafeMutableRawPointer(host.baseAddress!)
          .assumingMemoryBound(to: CChar.self)
        service = String(_unsafeUninitializedCapacity: Int(_NI_MAXSERV)) { serv in
          let s = UnsafeMutableRawPointer(serv.baseAddress!)
            .assumingMemoryBound(to: CChar.self)
          r = system_getnameinfo(
            adr, adrlen,
            h, CInterop.SockLen(host.count),
            s, CInterop.SockLen(serv.count),
            flags.rawValue)
          if r != 0 { return 0 }
          return system_strlen(s)
        }
        if r != 0 { return 0 }
        return system_strlen(h)
      }
      var error: (ResolverError, Errno?)? = nil
      if r != 0 {
        let err = ResolverError(rawValue: r)
        error = (err, err == .system ? Errno.current : nil)
      }
      return ((host, service), error)
    }
  }
}
