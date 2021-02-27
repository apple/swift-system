/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

// @available(...)
final class SocketTest: XCTestCase {

  func testSyscalls() {

    let socket = SocketDescriptor(rawValue: 3)
    let rawSocket = socket.rawValue

    let syscallTestCases: Array<MockTestCase> = [
      MockTestCase(name: "socket", PF_INET6, SOCK_STREAM, 0, interruptable: true) {
        retryOnInterrupt in
        _ = try SocketDescriptor.open(.ipv6, .stream, retryOnInterrupt: retryOnInterrupt)
      },
      MockTestCase(name: "shutdown", rawSocket, SHUT_RD, interruptable: false) {
        retryOnInterrupt in
        _ = try socket.shutdown(.read)
      },
      MockTestCase(name: "listen", rawSocket, 999, interruptable: false) {
        retryOnInterrupt in
      _ = try socket.listen(backlog: 999)
      },
    ]

    syscallTestCases.forEach { $0.runAllTests() }

  }
}
