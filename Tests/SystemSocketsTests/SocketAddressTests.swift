/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if !os(Windows)

import Testing

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

@testable import SystemSockets
import SystemPackage

@Suite("Socket Addresses")
private struct SocketAddressTests {

  // MARK: - IPv4 Address Tests

  @available(System 99, *)
  @Test func ipv4BasicCreation() throws {
    let addr = try #require(IPv4Address("127.0.0.1", port: 8080))
    #expect(addr.port == 8080)
    #expect(addr.addressString == "127.0.0.1")
  }

  @available(System 99, *)
  @Test func ipv4InvalidAddress() {
    let addr = IPv4Address("not.an.ip.address", port: 8080)
    #expect(addr == nil)
  }

  @available(System 99, *)
  @Test func ipv4Any() {
    let addr = IPv4Address.any(port: 0)
    #expect(addr.port == 0)
    #expect(addr.addressString == "0.0.0.0")
  }

  @available(System 99, *)
  @Test func ipv4Loopback() {
    let addr = IPv4Address.loopback(port: 80)
    #expect(addr.port == 80)
    #expect(addr.addressString == "127.0.0.1")
  }

  @available(System 99, *)
  @Test func ipv4StringLiteral() {
    let addr: IPv4Address = "192.168.1.1:443"
    #expect(addr.port == 443)
    #expect(addr.addressString == "192.168.1.1")
  }

  @available(System 99, *)
  @Test func ipv4Equality() {
    let addr1 = IPv4Address("10.0.0.1", port: 8080)!
    let addr2 = IPv4Address("10.0.0.1", port: 8080)!
    let addr3 = IPv4Address("10.0.0.2", port: 8080)!
    let addr4 = IPv4Address("10.0.0.1", port: 9090)!

    #expect(addr1 == addr2)
    #expect(addr1 != addr3)
    #expect(addr1 != addr4)
  }

  @available(System 99, *)
  @Test func ipv4Description() {
    let addr = IPv4Address("8.8.8.8", port: 53)!
    #expect(addr.description == "8.8.8.8:53")
  }

  // MARK: - IPv6 Address Tests

  @available(System 99, *)
  @Test func ipv6BasicCreation() throws {
    let addr = try #require(IPv6Address("::1", port: 8080))
    #expect(addr.port == 8080)
    #expect(addr.addressString == "::1")
  }

  @available(System 99, *)
  @Test func ipv6InvalidAddress() {
    let addr = IPv6Address("not:an:ipv6:address", port: 8080)
    #expect(addr == nil)
  }

  @available(System 99, *)
  @Test func ipv6Any() {
    let addr = IPv6Address.any(port: 0)
    #expect(addr.port == 0)
    #expect(addr.addressString == "::")
  }

  @available(System 99, *)
  @Test func ipv6Loopback() {
    let addr = IPv6Address.loopback(port: 80)
    #expect(addr.port == 80)
    #expect(addr.addressString == "::1")
  }

  @available(System 99, *)
  @Test func ipv6Description() {
    let addr = IPv6Address("2001:db8::1", port: 443)!
    #expect(addr.description == "[2001:db8::1]:443")
  }

  @available(System 99, *)
  @Test func ipv6StringLiteral() {
    let addr: IPv6Address = "[::1]:8080"
    #expect(addr.port == 8080)
    #expect(addr.addressString == "::1")
  }

  // MARK: - Unix Address Tests

  @available(System 99, *)
  @Test func unixBasicCreation() throws {
    let addr = try #require(UnixAddress("/tmp/test.sock"))
    #expect(addr.path == "/tmp/test.sock")
  }

  @available(System 99, *)
  @Test func unixDescription() {
    let addr = UnixAddress("/var/run/daemon.sock")!
    #expect(addr.description == "/var/run/daemon.sock")
  }

  @available(System 99, *)
  @Test func unixEquality() {
    let addr1 = UnixAddress("/tmp/a.sock")!
    let addr2 = UnixAddress("/tmp/a.sock")!
    let addr3 = UnixAddress("/tmp/b.sock")!

    #expect(addr1 == addr2)
    #expect(addr1 != addr3)
  }

  // MARK: - SocketAddress Container Tests

  @available(System 99, *)
  @Test func socketAddressFromIPv4() throws {
    let ipv4 = IPv4Address.loopback(port: 8080)
    let sockAddr = SocketAddress(ipv4: ipv4)

    #expect(sockAddr.family == SocketDescriptor.Domain.ipv4)
    let sockIPv4 = try #require(sockAddr.ipv4)
    #expect(sockIPv4.port == 8080)
    #expect(sockAddr.ipv6 == nil)
    #expect(sockAddr.unix == nil)
  }

  @available(System 99, *)
  @Test func socketAddressFromIPv6() throws {
    let ipv6 = IPv6Address.loopback(port: 443)
    let sockAddr = SocketAddress(ipv6: ipv6)

    #expect(sockAddr.family == SocketDescriptor.Domain.ipv6)
    let sockIPv6 = try #require(sockAddr.ipv6)
    #expect(sockIPv6.port == 443)
    #expect(sockAddr.ipv4 == nil)
    #expect(sockAddr.unix == nil)
  }

  @available(System 99, *)
  @Test func socketAddressFromUnix() throws {
    let unix = UnixAddress("/tmp/test.sock")!
    let sockAddr = SocketAddress(unix: unix)

    #expect(sockAddr.family == SocketDescriptor.Domain.local)
    let sockUnix = try #require(sockAddr.unix)
    #expect(sockUnix.path == "/tmp/test.sock")
    #expect(sockAddr.ipv4 == nil)
    #expect(sockAddr.ipv6 == nil)
  }
}

#endif
