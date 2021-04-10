/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
import SystemSockets
#else
import System
#error("No socket support")
#endif

// FIXME: Need collaborative mocking between systempackage and systemsockets
/*
// @available(...)
final class SocketTest: XCTestCase {

  func testSyscalls() {

    let socket = SocketDescriptor(rawValue: 3)
    let rawSocket = socket.rawValue
    let rawBuf = UnsafeMutableRawBufferPointer.allocate(byteCount: 100, alignment: 4)
    defer { rawBuf.deallocate() }
    let bufAddr = rawBuf.baseAddress
    let bufCount = rawBuf.count
    let writeBuf = UnsafeRawBufferPointer(rawBuf)
    let writeBufAddr = writeBuf.baseAddress

    let syscallTestCases: Array<MockTestCase> = [
      MockTestCase(name: "socket", .interruptable, PF_INET6, SOCK_STREAM, 0) {
        retryOnInterrupt in
        _ = try SocketDescriptor.open(.ipv6, .stream, retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(name: "shutdown", .noInterrupt, rawSocket, SHUT_RD) {
        retryOnInterrupt in
        _ = try socket.shutdown(.read)
      },
      MockTestCase(name: "listen", .noInterrupt, rawSocket, 999) {
        retryOnInterrupt in
        _ = try socket.listen(backlog: 999)
      },
      MockTestCase(
        name: "recv", .interruptable, rawSocket, bufAddr, bufCount, MSG_PEEK
      ) {
        retryOnInterrupt in
        _ = try socket.receive(
          into: rawBuf, flags: .peek, retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(
        name: "send", .interruptable, rawSocket, writeBufAddr, bufCount, MSG_DONTROUTE
      ) {
        retryOnInterrupt in
        _ = try socket.send(
          writeBuf, flags: .doNotRoute, retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(
        name: "recvfrom", .interruptable, rawSocket, Wildcard(), Wildcard(), 42, Wildcard(), Wildcard()
      ) { retryOnInterrupt in
        var sender = SocketAddress()
        _ = try socket.receive(into: rawBuf,
                               sender: &sender,
                               flags: .init(rawValue: 42),
                               retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(
        name: "sendto", .interruptable, rawSocket, Wildcard(), Wildcard(), 42, Wildcard(), Wildcard()
      ) { retryOnInterrupt in
        let recipient = SocketAddress(ipv4: .loopback, port: 123)
        _ = try socket.send(UnsafeRawBufferPointer(rawBuf),
                            to: recipient,
                            flags: .init(rawValue: 42),
                            retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(
        name: "recvmsg", .interruptable, rawSocket, Wildcard(), 42
      ) { retryOnInterrupt in
        var sender = SocketAddress()
        var ancillary = SocketDescriptor.AncillaryMessageBuffer()
        _ = try socket.receive(into: rawBuf,
                               sender: &sender,
                               ancillary: &ancillary,
                               flags: .init(rawValue: 42),
                               retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(
        name: "sendmsg", .interruptable, rawSocket, Wildcard(), 42
      ) { retryOnInterrupt in
        let recipient = SocketAddress(ipv4: .loopback, port: 123)
        let ancillary = SocketDescriptor.AncillaryMessageBuffer()
        _ = try socket.send(UnsafeRawBufferPointer(rawBuf),
                            to: recipient,
                            ancillary: ancillary,
                            flags: .init(rawValue: 42),
                            retryOnInterrupt: retryOnInterrupt)
      },
    ]

    syscallTestCases.forEach { $0.runAllTests() }

  }
}
*/
