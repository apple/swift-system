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

private struct ParsingTestCase: TestCase {
  // Whether we want the path to be constructed and syntactically
  // manipulated as though it were a Windows path
  let isWindows: Bool

  // We defer forming the path until `runAllTests()` executes,
  // so that we can switch between unix and windows behavior.
  var pathStr: String

  // The expected path post separator normalization
  var normalized: String

  var file: StaticString
  var line: UInt
}

extension ParsingTestCase {
  static func unix(
    _ path: String, normalized: String,
    file: StaticString = #file, line: UInt = #line
  ) -> ParsingTestCase {
    ParsingTestCase(
      isWindows: false,
      pathStr: path, normalized: normalized,
      file: file, line: line)
  }

  static func windows(
    _ path: String, normalized: String,
    file: StaticString = #file, line: UInt = #line
  ) -> ParsingTestCase {
    ParsingTestCase(
      isWindows: true,
      pathStr: path, normalized: normalized,
      file: file, line: line)
  }
}

extension ParsingTestCase {
  func runAllTests() {
    withWindowsPaths(enabled: isWindows) {
      let path = FilePath(pathStr)
      expectEqual(normalized, path.description)
    }
  }
}

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
final class FilePathParsingTest: XCTestCase {
  func testNormalization() {
    let unixPaths: Array<ParsingTestCase> = [
      .unix("/", normalized: "/"),
      .unix("", normalized: ""),
      .unix("//", normalized: "/"),
      .unix("///", normalized: "/"),
      .unix("/foo/bar/", normalized: "/foo/bar"),
      .unix("foo//bar", normalized: "foo/bar"),
      .unix("//foo/bar//baz/", normalized: "/foo/bar/baz"),
      .unix("/foo/bar/baz//", normalized: "/foo/bar/baz"),
      .unix("/foo/bar/baz///", normalized: "/foo/bar/baz"),
    ]

    let windowsPaths: Array<ParsingTestCase> = [
      .windows(#"C:\\folder\file\"#, normalized: #"C:\folder\file"#),
      .windows(#"C:folder\\\file\\\"#, normalized: #"C:folder\file"#),
      .windows(#"C:/foo//bar/"#, normalized: #"C:\foo\bar"#),

      .windows(#"\\server\share\"#, normalized: #"\\server\share\"#),
      .windows(#"//server/share/"#, normalized: #"\\server\share\"#),
      .windows(#"\\?\UNC/server\share\"#, normalized: #"\\?\UNC\server\share\"#),

      .windows(#"\\.\C:\"#, normalized: #"\\.\C:\"#),
      .windows(#"C:\"#, normalized: #"C:\"#),
      .windows(#"\"#, normalized: #"\"#),
    ]

    for test in unixPaths {
      test.runAllTests()
    }
    for test in windowsPaths {
      test.runAllTests()
    }
  }
}
