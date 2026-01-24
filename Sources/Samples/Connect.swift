/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser
import SystemSockets

struct Connect: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Connect to a TCP server and send/receive messages"
  )

  @Argument(help: "The host to connect to")
  var host: String

  @Argument(help: "The port to connect to")
  var port: UInt16

  @Option(name: .shortAndLong, help: "Message to send")
  var message: String = "Hello from swift-system sockets!"

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  func run() throws {
    print("Resolving \(host)...")

    // Resolve the hostname
    let hints = SocketAddress.ResolutionHints(family: .ipv4, socketType: .stream, protocol: .tcp)
    let addresses = try SocketAddress.resolve(hostname: host, service: "\(port)", hints: hints)

    guard let first = addresses.first else {
      print("No addresses found for \(host)")
      return
    }

    print("Connecting to \(first.address.ipv4?.description ?? "unknown")...")

    // Create socket
    let socket = try SocketDescriptor.open(first.family, first.socketType, protocol: first.protocol)
    defer { try? socket.close() }

    // Connect
    try socket.connect(to: first.address)
    print("Connected!")

    // Send message
    let messageBytes = Array(message.utf8)
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try socket.send(span)
    }
    print("Sent \(sent) bytes: \(message)")

    // Receive response
    var buffer = [UInt8](repeating: 0, count: 4096)
    let received = try buffer.withUnsafeMutableBytes { buf in
      var output = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try socket.receive(into: &output)
    }

    if received > 0 {
      let response = String(decoding: buffer.prefix(received), as: UTF8.self)
      print("Received \(received) bytes: \(response)")
    } else {
      print("Connection closed by server")
    }

    print("Done!")
  }
}
