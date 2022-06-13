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
      XCTAssertTrue(char.isLetter)
    }

    // non printable
    for value in 0..<(UInt8(ascii: " ")) {
      XCTAssertFalse(SystemChar(codeUnit: CInterop.PlatformUnicodeEncoding.CodeUnit(value)).isLetter)
    }
    XCTAssertFalse(SystemChar(codeUnit: 0x7F).isLetter) // DEL

    // misc other
    let invalid = SystemString(
      ##" !"#$%&'()*+,-./0123456789:;<=>?@[\]^_`{|}~"##)
    for char in invalid {
      XCTAssertFalse(char.isLetter)
    }
  }
}
