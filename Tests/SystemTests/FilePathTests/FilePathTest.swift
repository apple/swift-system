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

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
func filePathFromInvalidCodePointSequence<S: Sequence>(_ bytes: S) -> FilePath where S.Element == CInterop.PlatformUnicodeEncoding.CodeUnit {
  var array = Array(bytes)
  assert(array.last != 0, "already null terminated")
  array += [0]

  return array.withUnsafeBufferPointer {
    $0.withMemoryRebound(to: CInterop.PlatformChar.self) {
      FilePath(platformString: $0.baseAddress!)
    }
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
final class FilePathTest: XCTestCase {
  struct TestPath {
    let filePath: FilePath
    let string: String
    let validString: Bool

    init(filePath: FilePath, string: String, validString: Bool) {
        self.filePath = filePath
        #if os(Windows)
        self.string = string.replacingOccurrences(of: "/", with: "\\")
        #else
        self.string = string
        #endif
        self.validString = validString
    }
  }

#if os(Windows)
    static let invalidSequence: [UTF16.CodeUnit] = [0xd800, 0x0020]
    static let invalidSequenceTest =
        TestPath(filePath: filePathFromInvalidCodePointSequence(invalidSequence),
                 string: String(decoding: invalidSequence, as: UTF16.self),
                 validString: false)
#else
    static let invalidSequence: [UTF8.CodeUnit] = [0x2F, 0x61, 0x2F, 0x62, 0x2F, 0x83]
    static let invalidSequenceTest =
        TestPath(filePath: filePathFromInvalidCodePointSequence(invalidSequence),
                 string: String(decoding: invalidSequence, as: UTF8.self),
                 validString: false)
#endif

  var testPaths: [TestPath] = [
    // empty
    TestPath(filePath: FilePath(), string: String(), validString: true),

    // valid ascii
    TestPath(filePath: "/a/b/c", string: "/a/b/c", validString: true),

    // valid utf8
    TestPath(filePath: "/あ/🧟‍♀️", string: "/あ/🧟‍♀️", validString: true),

    // invalid sequence
    invalidSequenceTest,
  ]

  func testFilePath() {

    XCTAssertEqual(0, FilePath().length)

    for testPath in testPaths {

      XCTAssertEqual(testPath.string, String(decoding: testPath.filePath))

      // TODO: test component CodeUnit representation validation
      if testPath.validString {
        XCTAssertEqual(testPath.filePath, FilePath(testPath.string))
        XCTAssertEqual(testPath.string, String(validating: testPath.filePath))
      } else {
        XCTAssertNotEqual(testPath.filePath, FilePath(testPath.string))
        XCTAssertNil(String(validating: testPath.filePath))
      }

      testPath.filePath.withPlatformString {
#if os(Windows)
        XCTAssertEqual(testPath.string, String(decodingCString: $0, as: UTF16.self))
#else
        XCTAssertEqual(testPath.string, String(cString: $0))
#endif
        XCTAssertEqual(testPath.filePath, FilePath(platformString: $0))
      }
    }
  }
}

