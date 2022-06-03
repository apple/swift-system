/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
func filePathFromUnterminatedBytes<S: Sequence>(_ bytes: S) -> FilePath where S.Element == UInt8 {
  var array = Array(bytes)
  assert(array.last != 0, "already null terminated")
  array += [0]

  return array.withUnsafeBufferPointer {
    $0.withMemoryRebound(to: CChar.self) {
      FilePath(platformString: $0.baseAddress!)
    }
  }
}
let invalidBytes: [UInt8] = [0x2F, 0x61, 0x2F, 0x62, 0x2F, 0x83]

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
final class FilePathTest: XCTestCase {
  struct TestPath {
    let filePath: FilePath
    let string: String
    let validUTF8: Bool
  }

  let testPaths: [TestPath] = [
    // empty
    TestPath(filePath: FilePath(), string: String(), validUTF8: true),

    // valid ascii
    TestPath(filePath: "/a/b/c", string: "/a/b/c", validUTF8: true),

    // valid utf8
    TestPath(filePath: "/あ/🧟‍♀️", string: "/あ/🧟‍♀️", validUTF8: true),

    // invalid utf8
    TestPath(filePath: filePathFromUnterminatedBytes(invalidBytes), string: String(decoding: invalidBytes, as: UTF8.self), validUTF8: false),
  ]

  func testFilePath() {

    XCTAssertEqual(0, FilePath().length)

    for testPath in testPaths {

      XCTAssertEqual(testPath.string, String(decoding: testPath.filePath))

      // TODO: test component UTF8 validation
      if testPath.validUTF8 {
        XCTAssertEqual(testPath.filePath, FilePath(testPath.string))
        XCTAssertEqual(testPath.string, String(validating: testPath.filePath))
      } else {
        XCTAssertNotEqual(testPath.filePath, FilePath(testPath.string))
        XCTAssertNil(String(validating: testPath.filePath))
      }

      testPath.filePath.withPlatformString {
        XCTAssertEqual(testPath.string, String(cString: $0))
        XCTAssertEqual(testPath.filePath, FilePath(platformString: $0))
      }
    }
  }
}

