/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

final class SystemCharTest: XCTestCase {
  func testIsLetter() {
    let valid = SystemString(
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    for char in valid {
      XCTAssertTrue(char.isASCIILetter)
    }

    // non printable
    for value in 0..<(UInt8(ascii: " ")) {
      XCTAssertFalse(SystemChar(CInterop.PlatformUnicodeEncoding.CodeUnit(value)).isASCIILetter)
    }
    XCTAssertFalse(SystemChar(0x7F).isASCIILetter) // DEL

    // misc other
    let invalid = SystemString(
      ##" !"#$%&'()*+,-./0123456789:;<=>?@[\]^_`{|}~"##)
    for char in invalid {
      XCTAssertFalse(char.isASCIILetter)
    }
  }
}
