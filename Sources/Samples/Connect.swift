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

struct Connect: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "connect",
    abstract: "Open a connection and send lines from stdin over it."
  )

  @Argument(help: "The hostname to connect to.")
  var hostname: String

  @Argument(help: "The port number (or service name) to connect to.")
  var service: String

  @Flag(help: "Use IPv4")
  var ipv4: Bool = false

  @Flag(help: "Use IPv6")
  var ipv6: Bool = false

  @Flag(help: "Use UDP")
  var udp: Bool = false

  @Flag(help: "Send data out-of-band")
  var outOfBand: Bool = false

  func connect(
    to addresses: [SocketAddress.Info]
  ) throws -> (SocketDescriptor, SocketAddress)? {
    for addressinfo in addresses {
      do {
        let socket = try SocketDescriptor.open(
          addressinfo.domain,
          addressinfo.type,
          addressinfo.protocol)
        do {
          try socket.connect(to: addressinfo.address)
          return (socket, addressinfo.address)
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

  func run() throws {
    let addresses = try SocketAddress.resolve(
      hostname: nil,
      service: service,
      family: ipv6 ? .ipv6 : .ipv4,
      type: udp ? .datagram : .stream)

    guard let (socket, address) = try connect(to: addresses) else {
      complain("Can't connect to \(hostname)")
      throw ExitCode.failure
    }
    complain("Connected to \(address.niceDescription)")

    let flags: SocketDescriptor.MessageFlags = outOfBand ? .outOfBand : .none
    try socket.closeAfter {
      while var line = readLine(strippingNewline: false) {
        try line.withUTF8 { buffer in
          var buffer = UnsafeRawBufferPointer(buffer)
          while !buffer.isEmpty {
            let c = try socket.send(buffer, flags: flags)
            buffer = .init(rebasing: buffer[c...])
          }
        }
      }
    }
  }
}
