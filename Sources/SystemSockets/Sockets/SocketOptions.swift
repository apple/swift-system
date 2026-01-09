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

// MARK: - Option Level

@available(System 99, *)
extension SocketDescriptor {
  /// Socket option levels.
  @frozen
  public struct OptionLevel: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Socket-level options.
    ///
    /// The corresponding C constant is `SOL_SOCKET`.
    @_alwaysEmitIntoClient
    public static var socket: OptionLevel { OptionLevel(rawValue: SOL_SOCKET) }

    /// IPv4 protocol options.
    ///
    /// The corresponding C constant is `IPPROTO_IP`.
    @_alwaysEmitIntoClient
    public static var ip: OptionLevel { OptionLevel(rawValue: IPPROTO_IP) }

    /// IPv6 protocol options.
    ///
    /// The corresponding C constant is `IPPROTO_IPV6`.
    @_alwaysEmitIntoClient
    public static var ipv6: OptionLevel { OptionLevel(rawValue: IPPROTO_IPV6) }

    /// TCP protocol options.
    ///
    /// The corresponding C constant is `IPPROTO_TCP`.
    @_alwaysEmitIntoClient
    public static var tcp: OptionLevel { OptionLevel(rawValue: IPPROTO_TCP) }

    /// UDP protocol options.
    ///
    /// The corresponding C constant is `IPPROTO_UDP`.
    @_alwaysEmitIntoClient
    public static var udp: OptionLevel { OptionLevel(rawValue: IPPROTO_UDP) }
  }
}

// MARK: - Socket-Level Options

@available(System 99, *)
extension SocketDescriptor {
  /// Socket-level options for use with `getOption` and `setOption`.
  @frozen
  public struct SocketOption: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Enable debugging.
    ///
    /// The corresponding C constant is `SO_DEBUG`.
    @_alwaysEmitIntoClient
    public static var debug: SocketOption { SocketOption(rawValue: SO_DEBUG) }

    /// Allow local address reuse.
    ///
    /// The corresponding C constant is `SO_REUSEADDR`.
    @_alwaysEmitIntoClient
    public static var reuseAddress: SocketOption { SocketOption(rawValue: SO_REUSEADDR) }

    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(Linux)
    /// Allow local port reuse.
    ///
    /// The corresponding C constant is `SO_REUSEPORT`.
    @_alwaysEmitIntoClient
    public static var reusePort: SocketOption { SocketOption(rawValue: SO_REUSEPORT) }
    #endif

    /// Keep connections alive.
    ///
    /// The corresponding C constant is `SO_KEEPALIVE`.
    @_alwaysEmitIntoClient
    public static var keepAlive: SocketOption { SocketOption(rawValue: SO_KEEPALIVE) }

    /// Don't route, use direct interface.
    ///
    /// The corresponding C constant is `SO_DONTROUTE`.
    @_alwaysEmitIntoClient
    public static var dontRoute: SocketOption { SocketOption(rawValue: SO_DONTROUTE) }

    /// Linger on close if data present.
    ///
    /// The corresponding C constant is `SO_LINGER`.
    @_alwaysEmitIntoClient
    public static var linger: SocketOption { SocketOption(rawValue: SO_LINGER) }

    /// Permit sending of broadcast messages.
    ///
    /// The corresponding C constant is `SO_BROADCAST`.
    @_alwaysEmitIntoClient
    public static var broadcast: SocketOption { SocketOption(rawValue: SO_BROADCAST) }

    /// Send buffer size.
    ///
    /// The corresponding C constant is `SO_SNDBUF`.
    @_alwaysEmitIntoClient
    public static var sendBufferSize: SocketOption { SocketOption(rawValue: SO_SNDBUF) }

    /// Receive buffer size.
    ///
    /// The corresponding C constant is `SO_RCVBUF`.
    @_alwaysEmitIntoClient
    public static var receiveBufferSize: SocketOption { SocketOption(rawValue: SO_RCVBUF) }

    /// Send low water mark.
    ///
    /// The corresponding C constant is `SO_SNDLOWAT`.
    @_alwaysEmitIntoClient
    public static var sendLowWaterMark: SocketOption { SocketOption(rawValue: SO_SNDLOWAT) }

    /// Receive low water mark.
    ///
    /// The corresponding C constant is `SO_RCVLOWAT`.
    @_alwaysEmitIntoClient
    public static var receiveLowWaterMark: SocketOption { SocketOption(rawValue: SO_RCVLOWAT) }

    /// Get socket error.
    ///
    /// The corresponding C constant is `SO_ERROR`.
    @_alwaysEmitIntoClient
    public static var error: SocketOption { SocketOption(rawValue: SO_ERROR) }

    /// Get socket type.
    ///
    /// The corresponding C constant is `SO_TYPE`.
    @_alwaysEmitIntoClient
    public static var type: SocketOption { SocketOption(rawValue: SO_TYPE) }

    #if SYSTEM_PACKAGE_DARWIN
    /// Don't generate SIGPIPE on broken pipe.
    ///
    /// The corresponding C constant is `SO_NOSIGPIPE`.
    @_alwaysEmitIntoClient
    public static var noSigPipe: SocketOption { SocketOption(rawValue: SO_NOSIGPIPE) }
    #endif
  }
}

// MARK: - TCP Options

@available(System 99, *)
extension SocketDescriptor {
  /// TCP-level options for use with `getOption` and `setOption`.
  @frozen
  public struct TCPOption: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Disable Nagle algorithm.
    ///
    /// The corresponding C constant is `TCP_NODELAY`.
    @_alwaysEmitIntoClient
    public static var noDelay: TCPOption { TCPOption(rawValue: TCP_NODELAY) }

    /// Maximum segment size.
    ///
    /// The corresponding C constant is `TCP_MAXSEG`.
    @_alwaysEmitIntoClient
    public static var maxSegmentSize: TCPOption { TCPOption(rawValue: TCP_MAXSEG) }

    #if SYSTEM_PACKAGE_DARWIN || os(Linux)
    /// Keep alive idle time.
    ///
    /// The corresponding C constant is `TCP_KEEPIDLE` on Linux
    /// or `TCP_KEEPALIVE` on Darwin.
    @_alwaysEmitIntoClient
    public static var keepAliveIdle: TCPOption {
      #if SYSTEM_PACKAGE_DARWIN
      TCPOption(rawValue: TCP_KEEPALIVE)
      #else
      TCPOption(rawValue: TCP_KEEPIDLE)
      #endif
    }
    #endif

    #if os(Linux)
    /// Keep alive interval.
    ///
    /// The corresponding C constant is `TCP_KEEPINTVL`.
    @_alwaysEmitIntoClient
    public static var keepAliveInterval: TCPOption { TCPOption(rawValue: TCP_KEEPINTVL) }

    /// Keep alive probe count.
    ///
    /// The corresponding C constant is `TCP_KEEPCNT`.
    @_alwaysEmitIntoClient
    public static var keepAliveCount: TCPOption { TCPOption(rawValue: TCP_KEEPCNT) }
    #endif
  }
}

// MARK: - Get and Set Options

@available(System 99, *)
extension SocketDescriptor {
  /// Gets a socket option value.
  ///
  /// - Parameters:
  ///   - level: The protocol level.
  ///   - option: The option to get.
  /// - Returns: The option value.
  ///
  /// The corresponding C function is `getsockopt`.
  @_alwaysEmitIntoClient
  public func getOption<T>(
    _ level: OptionLevel,
    _ option: CInt
  ) throws -> T {
    try _getOption(level, option).get()
  }

  @usableFromInline
  internal func _getOption<T>(
    _ level: OptionLevel,
    _ option: CInt
  ) -> Result<T, Errno> {
    // Allocate zeroed storage for the option value
    var storage = [UInt8](repeating: 0, count: MemoryLayout<T>.size)
    var length = socklen_t(MemoryLayout<T>.size)

    let result = storage.withUnsafeMutableBytes { buffer in
      nothingOrErrno(retryOnInterrupt: false) {
        system_getsockopt(
          self.rawValue,
          level.rawValue,
          option,
          buffer.baseAddress,
          &length
        )
      }
    }

    return result.map {
      storage.withUnsafeBytes { buffer in
        buffer.load(as: T.self)
      }
    }
  }

  /// Sets a socket option value.
  ///
  /// - Parameters:
  ///   - level: The protocol level.
  ///   - option: The option to set.
  ///   - value: The value to set.
  ///
  /// The corresponding C function is `setsockopt`.
  @_alwaysEmitIntoClient
  public func setOption<T>(
    _ level: OptionLevel,
    _ option: CInt,
    to value: T
  ) throws {
    try _setOption(level, option, to: value).get()
  }

  @usableFromInline
  internal func _setOption<T>(
    _ level: OptionLevel,
    _ option: CInt,
    to value: T
  ) -> Result<(), Errno> {
    withUnsafePointer(to: value) { valuePtr in
      nothingOrErrno(retryOnInterrupt: false) {
        system_setsockopt(
          self.rawValue,
          level.rawValue,
          option,
          valuePtr,
          socklen_t(MemoryLayout<T>.size)
        )
      }
    }
  }
}

// MARK: - Convenience Methods

@available(System 99, *)
extension SocketDescriptor {
  /// Gets a socket-level option as an integer.
  @_alwaysEmitIntoClient
  public func getSocketOption(_ option: SocketOption) throws -> CInt {
    try getOption(.socket, option.rawValue)
  }

  /// Sets a socket-level option as an integer.
  @_alwaysEmitIntoClient
  public func setSocketOption(_ option: SocketOption, to value: CInt) throws {
    try setOption(.socket, option.rawValue, to: value)
  }

  /// Gets a TCP-level option as an integer.
  @_alwaysEmitIntoClient
  public func getTCPOption(_ option: TCPOption) throws -> CInt {
    try getOption(.tcp, option.rawValue)
  }

  /// Sets a TCP-level option as an integer.
  @_alwaysEmitIntoClient
  public func setTCPOption(_ option: TCPOption, to value: CInt) throws {
    try setOption(.tcp, option.rawValue, to: value)
  }

  /// Enables reuse of local addresses.
  @_alwaysEmitIntoClient
  public func setReuseAddress(_ enabled: Bool = true) throws {
    try setSocketOption(.reuseAddress, to: enabled ? 1 : 0)
  }

  /// Disables the Nagle algorithm.
  @_alwaysEmitIntoClient
  public func setNoDelay(_ enabled: Bool = true) throws {
    try setTCPOption(.noDelay, to: enabled ? 1 : 0)
  }
}
