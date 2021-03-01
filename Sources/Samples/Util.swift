/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import CSystem
import Glibc
#elseif os(Windows)
import CSystem
import ucrt
#else
#error("Unsupported Platform")
#endif

/// Turn off libc's input/output buffering.
internal func disableBuffering() {
  // FIXME: We should probably be able to do this from System.
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

extension SocketAddress {
  var niceDescription: String {
    switch family {
    case .ipv4:
      if let ipv4 = IPv4(self) { return ipv4.description }
      return self.description
    case .ipv6:
      if let ipv6 = IPv6(self) { return ipv6.description }
      return self.description
    case .local:
      if let local = Local(self) { return local.description }
      return self.description
    default:
      return self.description
    }
  }
}

extension SocketDescriptor.ConnectionType {
  var isConnectionLess: Bool {
    self == .datagram || self == .reliablyDeliveredMessage
  }
}
