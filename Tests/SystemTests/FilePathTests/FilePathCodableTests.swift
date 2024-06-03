/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

private struct EncodingTestCase: TestCase {
  // The JSON source to decode
  let source: String

  // The expected FilePath value. nil if the decoding is expected to fail.
  let expected: FilePath?

  var file: StaticString
  var line: UInt
}

extension EncodingTestCase {
  static func valid(
    _ source: String, _ expected: FilePath,
    file: StaticString = #file, line: UInt = #line
  ) -> EncodingTestCase {
    EncodingTestCase(source: source, expected: expected, file: file, line: line)
  }

  static func invalid(
    _ source: String,
    file: StaticString = #file, line: UInt = #line
  ) -> EncodingTestCase {
    EncodingTestCase(source: source, expected: nil, file: file, line: line)
  }
}

extension EncodingTestCase {
  private struct Content: Codable {
    var path: FilePath
  }

  func runAllTests() {
    let data = Data(source.utf8)
    do {
      let decoded = try JSONDecoder().decode(Content.self, from: data)
      guard let expected else {
        self.fail("expected error, but successfully decoded: \(decoded.path)")
        return
      }
      expectEqual(expected, decoded.path)

      // Encoding should round-trip
      let reencoded = try JSONEncoder().encode(decoded)
      let redecoded = try JSONDecoder().decode(Content.self, from: reencoded)
      expectEqual(expected, redecoded.path)
    } catch {
      if expected != nil {
        self.fail("unexpected error: \(error)")
      }
    }
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
final class FilePathCodableTest: XCTestCase {
  func testEncoding() {
    let testCases: [EncodingTestCase] = [
      .valid(#"{ "path": "/" }"#, "/"),
      .valid(#"{ "path": "\/" }"#, "/"),
      .valid(#"{ "path": "\/foo" }"#, "/foo"),
      .valid(#"{ "path": [47, 102, 111, 111, 0] }"#, "/foo"),
      // Decode up to null terminator
      .valid(#"{ "path": [47, 102, 111, 111, 0, 47] }"#, "/foo/"),
      // Non-null-terminated input
      .invalid(#"{ "path": [47, 102, 111, 111] }"#),
      // Coding format used in older versions of swift-system, synthesized by the compiler
      .invalid(#"{ "path": { "_storage": { "nullTerminatedStorage": [47, 0] } } }"#),
    ]

    for testCase in testCases {
      testCase.runAllTests()
    }
  }
}
