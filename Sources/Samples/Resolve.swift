/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import ArgumentParser
#if SYSTEM_PACKAGE
import SystemPackage
import SystemSockets
#else
import System
#error("No socket support")
#endif

struct Resolve: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "resolve",
    abstract: "Resolve a pair of hostname/servicename strings to a list of socket addresses."
  )

  @Argument(help: "The hostname to resolve")
  var hostname: String?

  @Argument(help: "The service name to resolve")
  var service: String?

  @Flag(help: "Return the canonical hostname")
  var canonicalName: Bool = false

  @Flag(help: "Resolve for binding")
  var passive: Bool = false

  @Flag(help: "Disable hostname resolution; hostname must be numeric address")
  var numericHost: Bool = false

  @Flag(help: "Disable service resolution; service name must be numeric")
  var numericService: Bool = false

  @Flag(help: "Resolve IPv4 addresses")
  var ipv4: Bool = false

  @Flag(help: "Resolve IPv6 addresses")
  var ipv6: Bool = false

  @Flag(help: "Print the raw SocketAddress structures")
  var raw: Bool = false

  func run() throws {
    var flags: SocketAddress.NameResolverFlags = [.default, .all]
    if canonicalName { flags.insert(.canonicalName) }
    if passive { flags.insert(.passive) }
    if numericHost { flags.insert(.numericHost) }
    if numericService { flags.insert(.numericService) }

    var family: SocketAddress.Family? = nil
    if ipv4 { family = .ipv4 }
    if ipv6 { family = .ipv6 }

    let results = try SocketAddress.resolveName(
      hostname: hostname, service: service,
      flags: flags,
      family: family
    )
    if results.isEmpty {
      print("No results found")
    } else {
      for entry in results {
        if raw {
          print(entry)
        } else {
          print(entry.niceDescription)
        }
      }
    }
  }
}
