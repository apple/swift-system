/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class SystemConfigTest: XCTestCase {
  func testSystemConfig() {
    let fd = FileDescriptor(rawValue: 1)
    let tests: Array<MockTestCase> = [
      MockTestCase(name: "sysconf", _SC_CHILD_MAX, interruptable: false) {
        _ in
        _ = try SystemConfig.get(.maxUserProcesses)
      },
      MockTestCase(name: "pathconf", "a_path", _PC_NAME_MAX, interruptable: false) {
        _ in
      _ = try SystemConfig.get(.maxFileNameBytes, for: "a_path")
      },
      MockTestCase(name: "fpathconf", 1, _PC_NAME_MAX, interruptable: false) {
        _ in
      _ = try SystemConfig.get(.maxFileNameBytes, for: fd)
      },
    ]
    tests.forEach { $0.runAllTests() }
  }

}
