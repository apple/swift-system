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

struct ReverseResolve: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "reverse",
    abstract: "Resolve a numerical IP address and port number into a hostname/service string"
  )

  @Argument(help: "The IP address to resolve")
  var address: String?

  @Argument(help: "The port number to resolve")
  var port: String?

  @Flag(help: "No fully qualified domain for local addresses")
  var nofqdn: Bool = false

  @Flag(help: "Disable hostname resolution; hostname must be numeric address")
  var numericHost: Bool = false

  @Flag(help: "Disable service resolution; service name must be numeric")
  var numericService: Bool = false

  @Flag(help: "Look up a datagram service")
  var datagram: Bool = false

  @Flag(help: "Allow IPv6 scope identifiers")
  var scopeid: Bool = false

  func run() throws {
    // First, we need to get a sockaddr, so things start with forward resolution.
    let infos = try SocketAddress.resolveName(
      hostname: address,
      service: port,
      flags: [.numericHost, .numericService])

    var results: Set<String> = []
    for info in infos {
      // Now try a reverse lookup.
      var flags: SocketAddress.AddressResolverFlags = []
      if nofqdn {
        flags.insert(.noFullyQualifiedDomain)
      }
      if numericHost {
        flags.insert(.numericHost)
      }
      if numericService {
        flags.insert(.numericService)
      }
      if datagram {
        flags.insert(.datagram)
      }
      if scopeid {
        flags.insert(.scopeIdentifier)
      }
      let (hostname, service) = try SocketAddress.resolveAddress(info.address, flags: flags)
      results.insert("\(hostname) \(service)")
    }
    for r in results.sorted() {
      print(r)
    }
  }
}
