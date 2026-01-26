/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser
import SystemSockets

struct Resolve: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Resolve a hostname to IP addresses using getaddrinfo"
  )

  @Argument(help: "The hostname to resolve")
  var hostname: String

  @Option(name: .shortAndLong, help: "Service name or port number")
  var service: String?

  @Flag(name: .long, help: "Show only IPv4 addresses")
  var ipv4Only: Bool = false

  @Flag(name: .long, help: "Show only IPv6 addresses")
  var ipv6Only: Bool = false

  @available(System 99, *)
  func run() throws {
    let family: SocketDescriptor.Domain?
    if ipv4Only {
      family = .ipv4
    } else if ipv6Only {
      family = .ipv6
    } else {
      family = nil
    }

    let hints = SocketAddress.ResolutionHints(family: family)

    print("Resolving \(hostname)...")

    let addresses = try SocketAddress.resolve(
      hostname: hostname,
      service: service,
      hints: hints
    )

    if addresses.isEmpty {
      print("No addresses found")
      return
    }

    print("Found \(addresses.count) address(es):\n")

    for (index, info) in addresses.enumerated() {
      print("[\(index + 1)] Family: \(familyName(info.family))")
      print("    Type: \(typeName(info.socketType))")
      print("    Protocol: \(protocolName(info.protocol))")

      if let ipv4 = info.address.ipv4 {
        print("    Address: \(ipv4.addressString):\(ipv4.port)")
      } else if let ipv6 = info.address.ipv6 {
        print("    Address: [\(ipv6.addressString)]:\(ipv6.port)")
      }

      if let canonName = info.canonicalName {
        print("    Canonical: \(canonName)")
      }

      print()
    }
  }

  @available(System 99, *)
  private func familyName(_ domain: SocketDescriptor.Domain) -> String {
    switch domain {
    case .ipv4: return "IPv4"
    case .ipv6: return "IPv6"
    case .local: return "Unix"
    default: return "Unknown (\(domain.rawValue))"
    }
  }

  @available(System 99, *)
  private func typeName(_ type: SocketDescriptor.ConnectionType) -> String {
    switch type {
    case .stream: return "Stream (TCP)"
    case .datagram: return "Datagram (UDP)"
    case .raw: return "Raw"
    default: return "Unknown (\(type.rawValue))"
    }
  }

  @available(System 99, *)
  private func protocolName(_ proto: SocketDescriptor.ProtocolID) -> String {
    switch proto {
    case .tcp: return "TCP"
    case .udp: return "UDP"
    case .ip: return "IP"
    default: return "Unknown (\(proto.rawValue))"
    }
  }
}
