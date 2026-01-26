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

@Suite("Socket Descriptor")
private struct SocketDescriptorTests {

  // MARK: - Type Tests

  @available(System 99, *)
  @Test func domainValues() {
    #expect(SocketDescriptor.Domain.ipv4.rawValue == AF_INET)
    #expect(SocketDescriptor.Domain.ipv6.rawValue == AF_INET6)
    #expect(SocketDescriptor.Domain.local.rawValue == AF_UNIX)
  }

  @available(System 99, *)
  @Test func connectionTypeValues() {
    #expect(SocketDescriptor.ConnectionType.stream.rawValue == SOCK_STREAM)
    #expect(SocketDescriptor.ConnectionType.datagram.rawValue == SOCK_DGRAM)
  }

  @available(System 99, *)
  @Test func protocolValues() {
    #expect(SocketDescriptor.ProtocolID.tcp.rawValue == CInt(IPPROTO_TCP))
    #expect(SocketDescriptor.ProtocolID.udp.rawValue == CInt(IPPROTO_UDP))
  }

  // MARK: - Socket Creation Tests

  @available(System 99, *)
  @Test func createTCPSocket() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    #expect(socket.rawValue >= 0)
    try socket.close()
  }

  @available(System 99, *)
  @Test func createUDPSocket() throws {
    let socket = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    #expect(socket.rawValue >= 0)
    try socket.close()
  }

  @available(System 99, *)
  @Test func createIPv6TCPSocket() throws {
    let socket = try SocketDescriptor.open(.ipv6, .stream, protocol: .tcp)
    #expect(socket.rawValue >= 0)
    try socket.close()
  }

  @available(System 99, *)
  @Test func createUnixSocket() throws {
    let socket = try SocketDescriptor.open(.local, .stream)
    #expect(socket.rawValue >= 0)
    try socket.close()
  }

  // MARK: - Shutdown Tests

  @available(System 99, *)
  @Test func shutdownKindValues() {
    #expect(SocketDescriptor.ShutdownKind.read.rawValue == SHUT_RD)
    #expect(SocketDescriptor.ShutdownKind.write.rawValue == SHUT_WR)
    #expect(SocketDescriptor.ShutdownKind.readWrite.rawValue == SHUT_RDWR)
  }
}

#endif
