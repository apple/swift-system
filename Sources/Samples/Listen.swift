/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser
import SystemSockets

struct Listen: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Run a simple TCP echo server"
  )

  @Option(name: .shortAndLong, help: "The port to listen on")
  var port: UInt16 = 8080

  @Option(name: .shortAndLong, help: "Maximum number of connections to accept (0 for unlimited)")
  var maxConnections: Int = 0

  @available(System 99, *)
  func run() throws {
    // Create socket
    let server = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? server.close() }

    // Set reuse address
    try server.setReuseAddress(true)

    // Bind
    let address = SocketAddress(ipv4: IPv4Address.any(port: port))
    try server.bind(to: address)

    // Listen
    try server.listen(backlog: 5)

    var localAddr = SocketAddress()
    try server.getLocalAddress(into: &localAddr)
    print("Listening on \(localAddr.ipv4?.description ?? "unknown")...")

    var connectionCount = 0
    while maxConnections == 0 || connectionCount < maxConnections {
      print("Waiting for connection...")

      var peerAddr = SocketAddress()
      let client = try server.accept(client: &peerAddr)
      connectionCount += 1

      print("[\(connectionCount)] Connection from \(peerAddr.ipv4?.description ?? "unknown")")

      // Handle client in a simple blocking manner
      defer { try? client.close() }

      var buffer = [UInt8](repeating: 0, count: 4096)

      while true {
        let received = try buffer.withUnsafeMutableBytes { buffer in
          try client.receive(into: buffer)
        }
        if received == 0 {
          print("[\(connectionCount)] Client disconnected")
          break
        }

        let message = String(decoding: buffer.prefix(received), as: UTF8.self)
        print("[\(connectionCount)] Received \(received) bytes: \(message)")

        // Echo back
        let sent = try buffer.prefix(received).withUnsafeBytes { buffer in
          try client.send(UnsafeRawBufferPointer(buffer))
        }
        print("[\(connectionCount)] Echoed \(sent) bytes")
      }
    }

    print("Server shutting down after \(connectionCount) connections")
  }
}
