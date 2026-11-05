/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser
import SystemSockets

struct ReverseResolve: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Reverse resolve an IP address to a hostname using getnameinfo"
  )

  @Argument(help: "The IP address to resolve (IPv4 or IPv6)")
  var address: String

  @Option(name: .shortAndLong, help: "Port number")
  var port: UInt16 = 0

  @Flag(name: .long, help: "Request numeric host (don't resolve)")
  var numericHost: Bool = false

  @Flag(name: .long, help: "Request numeric service (don't resolve)")
  var numericService: Bool = false

  func run() throws {
    // Try to parse as IPv4
    if let ipv4 = IPv4Address(address, port: port) {
      let sockAddr = SocketAddress(ipv4: ipv4)
      try resolve(sockAddr)
      return
    }

    // Try to parse as IPv6
    if let ipv6 = IPv6Address(address, port: port) {
      let sockAddr = SocketAddress(ipv6: ipv6)
      try resolve(sockAddr)
      return
    }

    print("Error: '\(address)' is not a valid IPv4 or IPv6 address")
  }

  private func resolve(_ address: SocketAddress) throws {
    var flags: SocketAddress.ReverseResolutionFlags = []
    if numericHost {
      flags.insert(.numericHost)
    }
    if numericService {
      flags.insert(.numericService)
    }

    print("Resolving \(addressDescription(address))...")

    let info = try address.reverseLookup(flags: flags)

    print()
    if let host = info.hostname {
      print("Host: \(host)")
    } else {
      print("Host: (not resolved)")
    }

    if let service = info.service {
      print("Service: \(service)")
    } else {
      print("Service: (not resolved)")
    }
  }

  private func addressDescription(_ address: SocketAddress) -> String {
    if let ipv4 = address.ipv4 {
      return "\(ipv4.addressString):\(ipv4.port)"
    } else if let ipv6 = address.ipv6 {
      return "[\(ipv6.addressString)]:\(ipv6.port)"
    } else {
      return "(unknown address)"
    }
  }
}
