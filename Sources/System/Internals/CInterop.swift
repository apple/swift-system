/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Public typealiases

/// The C `mode_t` type.
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(*, deprecated, renamed: "CInterop.Mode")
public typealias CModeT =  CInterop.Mode

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

/// A namespace for C and platform types
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public enum CInterop {
  /// The C `char` type
  public typealias Char = CChar

  #if os(Windows)
  /// The platform's preferred character type. On Unix, this is an 8-bit C
  /// `char` (which may be signed or unsigned, depending on platform). On
  /// Windows, this is `UInt16` (a "wide" character).
  public typealias PlatformChar = UInt16
  #else
  /// The platform's preferred character type. On Unix, this is an 8-bit C
  /// `char` (which may be signed or unsigned, depending on platform). On
  /// Windows, this is `UInt16` (a "wide" character).
  public typealias PlatformChar = CInterop.Char
  #endif

  #if os(Windows)
  /// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
  /// Windows it is UTF-16. Native strings may contain invalid Unicode,
  /// which will be handled by either error-correction or failing, depending
  /// on API.
  public typealias PlatformUnicodeEncoding = UTF16
  #else
  /// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
  /// Windows it is UTF-16. Native strings may contain invalid Unicode,
  /// which will be handled by either error-correction or failing, depending
  /// on API.
  public typealias PlatformUnicodeEncoding = UTF8
  #endif

  public typealias Mode = mode_t

  public typealias SockAddr = sockaddr
  public typealias SockLen = socklen_t
  public typealias SAFamily = sa_family_t

  public typealias SockAddrIn = sockaddr_in
  public typealias InAddr = in_addr
  public typealias InAddrT = in_addr_t

  public typealias In6Addr = in6_addr

  public typealias InPort = in_port_t

  public typealias SockAddrIn6 = sockaddr_in6
  public typealias SockAddrUn = sockaddr_un
}
