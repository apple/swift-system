/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser
#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

struct Listen: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "listen",
    abstract: "Listen for an incoming connection and print received text to stdout."
  )

  @Argument(help: "The port number (or service name) to listen on.")
  var service: String

  @Flag(help: "Use IPv4")
  var ipv4: Bool = false

  @Flag(help: "Use IPv6")
  var ipv6: Bool = false

  @Flag(help: "Use UDP")
  var udp: Bool = false

  func startServer(
    on addresses: [SocketAddress.Info]
  ) throws -> (SocketDescriptor, SocketAddress.Info)? {
    for info in addresses {
      do {
        let socket = try SocketDescriptor.open(
          info.domain,
          info.type,
          info.protocol)
        do {
          try socket.bind(to: info.address)
          if !info.type.isConnectionless {
            try socket.listen(backlog: 10)
          }
          return (socket, info)
        }
        catch {
          try? socket.close()
          throw error
        }
      }
      catch {
        continue
      }
    }
    return nil
  }

  func prefix(
    client: SocketAddress,
    flags: SocketDescriptor.MessageFlags
  ) -> String {
    var prefix: [String] = []
    if client.family != .unspecified {
      prefix.append("client: \(client.niceDescription)")
    }
    if flags != .none {
      prefix.append("flags: \(flags)")
    }
    guard !prefix.isEmpty else { return "" }
    return "<\(prefix.joined(separator: ", "))> "
  }

  func run() throws {
    let addresses = try SocketAddress.resolveName(
      hostname: nil,
      service: service,
      flags: .canonicalName,
      family: ipv6 ? .ipv6 : .ipv4,
      type: udp ? .datagram : .stream)


    guard let (socket, address) = try startServer(on: addresses) else {
      complain("Can't listen on \(service)")
      throw ExitCode.failure
    }
    complain("Listening on \(address.address.niceDescription)")

    var client = SocketAddress()
    let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1024, alignment: 1)
    defer { buffer.deallocate() }

    var ancillary = SocketDescriptor.AncillaryMessageBuffer()
    try socket.closeAfter {
      if udp {
        while true {
          let (count, flags) =
            try socket.receive(into: buffer, sender: &client, ancillary: &ancillary)
          print(prefix(client: client, flags: flags), terminator: "")
          try FileDescriptor.standardOutput.writeAll(buffer[..<count])
        }
      } else {
        let conn = try socket.accept(client: &client)
        complain("Connection from \(client.niceDescription)")
        try conn.closeAfter {
          while true {
            let (count, flags) =
            try conn.receive(into: buffer, sender: &client, ancillary: &ancillary)
            guard count > 0 else { break }
            print(prefix(client: client, flags: flags), terminator: "")
            try FileDescriptor.standardOutput.writeAll(buffer[..<count])
          }
        }
      }
    }
  }
}

