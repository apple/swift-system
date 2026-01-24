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

@Suite("Socket Operations")
private struct SocketOperationsTests {

  // MARK: - Bind Tests

  @available(System 99, *)
  @Test func bindToAnyPort() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    let address = SocketAddress(ipv4: IPv4Address.any(port: 0))
    try socket.bind(to: address)

    // Verify we can get the local address after binding
    var localAddr = SocketAddress()
    try socket.getLocalAddress(into: &localAddr)
    #expect(localAddr.family == SocketDescriptor.Domain.ipv4)
    #expect(localAddr.ipv4?.port != 0) // Port should be assigned
  }

  @available(System 99, *)
  @Test func bindToLoopback() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    let address = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try socket.bind(to: address)

    var localAddr = SocketAddress()
    try socket.getLocalAddress(into: &localAddr)
    #expect(localAddr.ipv4?.addressString == "127.0.0.1")
  }

  // MARK: - Listen Tests

  @available(System 99, *)
  @Test func listenWithDefaultBacklog() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    let address = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try socket.bind(to: address)
    try socket.listen(backlog: 5)
  }

  // MARK: - Connect and Accept Tests

  @available(System 99, *)
  @Test func tcpConnectAndAccept() throws {
    // Create server socket
    let server = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? server.close() }

    let serverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try server.bind(to: serverAddr)
    try server.listen(backlog: 1)

    // Get the actual port
    var boundAddr = SocketAddress()
    try server.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    // Create client socket and connect
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }

    let connectAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    try client.connect(to: connectAddr)

    // Accept connection
    var peerAddr = SocketAddress()
    let acceptedSocket = try server.accept(client: &peerAddr)
    defer { try? acceptedSocket.close() }

    #expect(peerAddr.family == SocketDescriptor.Domain.ipv4)
    #expect(peerAddr.ipv4?.addressString == "127.0.0.1")
  }

  // MARK: - Send and Receive Tests

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func tcpSendReceive() throws {
    // Create server socket
    let server = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? server.close() }

    let serverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try server.bind(to: serverAddr)
    try server.listen(backlog: 1)

    var boundAddr = SocketAddress()
    try server.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    // Create client socket and connect
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }

    let connectAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    try client.connect(to: connectAddr)

    // Accept connection
    let acceptedSocket = try server.accept()
    defer { try? acceptedSocket.close() }

    // Send data from client using Span
    let message = "Hello, World!"
    let messageBytes = Array(message.utf8)
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try client.send(span)
    }
    #expect(sent == messageBytes.count)

    // Receive data on server using OutputRawSpan
    var buffer = [UInt8](repeating: 0, count: 1024)
    let received = try buffer.withUnsafeMutableBytes { buf in
      var output = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try acceptedSocket.receive(into: &output)
    }
    #expect(received == messageBytes.count)

    let receivedMessage = String(decoding: buffer.prefix(received), as: UTF8.self)
    #expect(receivedMessage == message)
  }

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func tcpSendReceiveSpan() throws {
    // Create server socket
    let server = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? server.close() }

    let serverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try server.bind(to: serverAddr)
    try server.listen(backlog: 1)

    var boundAddr = SocketAddress()
    try server.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    // Create client socket and connect
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }

    let connectAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    try client.connect(to: connectAddr)

    // Accept connection
    let acceptedSocket = try server.accept()
    defer { try? acceptedSocket.close() }

    // Send data from client using Span
    let message = "Hello, Span World!"
    let messageBytes = Array(message.utf8)
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try client.send(span)
    }
    #expect(sent == messageBytes.count)

    // Receive data on server using OutputRawSpan
    var buffer = [UInt8](repeating: 0, count: 1024)
    let received = try buffer.withUnsafeMutableBytes { buf in
      var output = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try acceptedSocket.receive(into: &output)
    }
    #expect(received == messageBytes.count)

    let receivedMessage = String(decoding: buffer.prefix(received), as: UTF8.self)
    #expect(receivedMessage == message)
  }

  // MARK: - UDP Tests

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func udpSendReceive() throws {
    // Create receiver socket
    let receiver = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    defer { try? receiver.close() }

    let receiverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try receiver.bind(to: receiverAddr)

    var boundAddr = SocketAddress()
    try receiver.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    // Create sender socket
    let sender = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    defer { try? sender.close() }

    // Send datagram using Span
    let message = "UDP Message"
    let messageBytes = Array(message.utf8)
    let targetAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try sender.send(span, to: targetAddr)
    }
    #expect(sent == messageBytes.count)

    // Receive datagram using OutputRawSpan
    var buffer = [UInt8](repeating: 0, count: 1024)
    var fromAddr = SocketAddress()
    let received = try buffer.withUnsafeMutableBytes { buf in
      var output = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try receiver.receive(into: &output, sender: &fromAddr)
    }
    #expect(received == messageBytes.count)
    #expect(fromAddr.family == SocketDescriptor.Domain.ipv4)

    let receivedMessage = String(decoding: buffer.prefix(received), as: UTF8.self)
    #expect(receivedMessage == message)
  }

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func udpSendReceiveSpan() throws {
    // Create receiver socket
    let receiver = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    defer { try? receiver.close() }

    let receiverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try receiver.bind(to: receiverAddr)

    var boundAddr = SocketAddress()
    try receiver.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    // Create sender socket
    let sender = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    defer { try? sender.close() }

    // Send datagram using Span
    let message = "UDP Span Message"
    let messageBytes = Array(message.utf8)
    let targetAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try sender.send(span, to: targetAddr)
    }
    #expect(sent == messageBytes.count)

    // Receive datagram using OutputRawSpan
    var buffer = [UInt8](repeating: 0, count: 1024)
    var fromAddr = SocketAddress()
    let received = try buffer.withUnsafeMutableBytes { buf in
      var output = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try receiver.receive(into: &output, sender: &fromAddr)
    }
    #expect(received == messageBytes.count)
    #expect(fromAddr.family == SocketDescriptor.Domain.ipv4)

    let receivedMessage = String(decoding: buffer.prefix(received), as: UTF8.self)
    #expect(receivedMessage == message)
  }

  // MARK: - Socket Options Tests

  @available(System 99, *)
  @Test func setReuseAddress() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    try socket.setReuseAddress(true)
    let value = try socket.getSocketOption(SocketDescriptor.SocketOption.reuseAddress)
    #expect(value != 0)
  }

  @available(System 99, *)
  @Test func getSendBufferSize() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    let size = try socket.getSocketOption(SocketDescriptor.SocketOption.sendBufferSize)
    #expect(size > 0)
  }

  @available(System 99, *)
  @Test func getReceiveBufferSize() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    let size = try socket.getSocketOption(SocketDescriptor.SocketOption.receiveBufferSize)
    #expect(size > 0)
  }
}

#endif
