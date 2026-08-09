/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import Foundation

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Direct coverage for `lexicallyNormalize()` / `_normalizeSpecialDirectories`.
//
// The existing table in FilePathSyntaxTest.testPathSyntax has a
// `lexicallyNormalized` column, but that whole file is behind
// `#if ENABLE_MOCKING` (it drives `withWindowsPaths`), which is off in the
// default test run, so none of it exercises `_normalizeSpecialDirectories`.
// These POSIX cases run unconditionally. Expectations are taken from that
// table's unix rows, plus underflow / leading-`..`-run edges that pin the
// rooted-vs-rootless behavior.
@available(System 0.0.2, *)
final class FilePathLexicalNormalizeTest: XCTestCase {
  func testLexicallyNormalized() {
    let cases: [(String, String)] = [
      // From FilePathSyntaxTest.testPathSyntax unix rows:
      ("/..", "/"),
      ("/.", "/"),
      ("/../.", "/"),
      (".", ""),
      ("..", ".."),
      ("./..", ".."),
      ("../.", ".."),
      ("../..", "../.."),
      ("a/../..", ".."),
      ("a/.././.././../b", "../../b"),
      ("/a/.././.././../b", "/b"),
      ("./.", ""),
      ("a/foo/bar/../..", "a"),
      ("a/./foo/bar/.././../.", "a"),
      ("a/../b", "b"),
      ("/a/../b/../c/../../d", "/d"),
      ("/tmp/.", "/tmp"),
      ("/tmp/..", "/"),
      ("/tmp/../", "/"),
      ("/tmp/./a/../b", "/tmp/b"),

      // Edges pinning the rooted/rootless `..` rule: rooted underflow keeps
      // swallowing `..`; rootless underflow preserves it.
      ("/../../..", "/"),
      ("../../..", "../../.."),
      ("a/../../..", "../.."),
      ("/a/b/c/../../..", "/"),
      ("/a/b/c/../../../..", "/"),
      ("foo/..", ""),
      ("foo/bar/../..", ""),
      ("./foo/../..", ".."),

      // Already-normal inputs are unchanged (fast path).
      ("/usr/local/bin", "/usr/local/bin"),
      ("../local/bin", "../local/bin"),
      ("", ""),
      ("/", "/"),
    ]

    for (input, expected) in cases {
      let path = FilePath(input)

      var mutated = path
      mutated.lexicallyNormalize()
      XCTAssertEqual(
        FilePath(expected), mutated,
        "lexicallyNormalize(): \(input) -> \(mutated) (expected \(expected))")

      XCTAssertEqual(
        FilePath(expected), path.lexicallyNormalized(),
        "lexicallyNormalized(): \(input)")

      XCTAssertTrue(
        mutated.isLexicallyNormal,
        "result not lexically normal: \(input) -> \(mutated)")
      XCTAssertEqual(
        mutated, mutated.lexicallyNormalized(),
        "not idempotent: \(input)")

      XCTAssertEqual(
        path.isLexicallyNormal, (path == mutated),
        "isLexicallyNormal disagrees with normalization for \(input)")
    }
  }
}
