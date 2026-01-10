/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import SystemPackage
import SystemSockets

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

/// Turn off libc's input/output buffering.
internal func disableBuffering() {
  setbuf(stdin, nil)
  setbuf(stdout, nil)
  setbuf(stderr, nil)
}

internal func complain(_ message: String) {
  var message = message + "\n"
  message.withUTF8 { buffer in
    _ = try? FileDescriptor.standardError.writeAll(buffer)
  }
}

extension SocketAddress.ResolvedAddress {
  var niceDescription: String {
    var proto = ""
    switch self.protocol {
    case .udp: proto = "udp"
    case .tcp: proto = "tcp"
    default: proto = "\(self.protocol)"
    }
    return "\(address.niceDescription) (\(proto))"
  }
}

extension SocketAddress {
  var niceDescription: String {
    if let ipv4 = self.ipv4 { return ipv4.description }
    if let ipv6 = self.ipv6 { return ipv6.description }
    if let unix = self.unix { return unix.description }
    return self.description
  }
}

extension SocketDescriptor.ConnectionType {
  var isConnectionless: Bool {
    self == .datagram || self == .reliablyDeliveredMessage
  }
}
