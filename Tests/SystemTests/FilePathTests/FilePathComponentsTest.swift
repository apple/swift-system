/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import SystemPackage

@testable
import SystemPackage


// Helper to organize some ad-hoc testing
//
// TODO: Currently a class so we can overwrite file/line, but that can be
// re-evaluated when we have source loc stacks.
private final class AdHocComponentsTest: TestCase {
  // TODO (source-loc stack): Push fil/line from init onto stack

  // Record the top-most file/line info (`expect` overwrites these values)
  //
  // TODO: When we have source loc stacks, push the location from the init,
  // and `expect` will be push/pops
  var file: StaticString
  var line: UInt

  var path: FilePath
  var body: (AdHocComponentsTest) -> ()

  init(
    _ path: FilePath,
    _ file: StaticString = #file,
    _ line: UInt = #line,
    _ body: @escaping (AdHocComponentsTest) -> ()
  ) {
    self.file = file
    self.line = line
    self.path = path
    self.body = body
  }

  func runAllTests() {
    body(self)
  }
}

private func adhocComponentsTest(
  _ path: FilePath,
  _ file: StaticString = #file,
  _ line: UInt = #line,
  _ body: @escaping (AdHocComponentsTest) -> ()
) {
  let test = AdHocComponentsTest(path, file, line, body)
  test.runAllTests()
}

extension AdHocComponentsTest {
  // Temporarily re-bind file/line
  func withSourceLoc(
    _ newFile: StaticString,
    _ newLine: UInt,
    _ body: () -> ()
  ) {
    let (origFile, origLine) = (self.file, self.line)
    (self.file, self.line) = (newFile, newLine)
    defer { (self.file, self.line) = (origFile, origLine) }
    body()
  }

  // Customize error report by adding our path and components to output
  func failureMessage(_ reason: String?) -> String {
    """

    Fail
      path: \(path)
      components: \(Array(path.components))
      \(reason ?? "")
    """
  }

  func expect(
    _ expected: FilePath,
    file: StaticString = #file, line: UInt = #line
  ) {

    withSourceLoc(file, line) {
      expectEqual(expected, path, "expected: \(expected)")
    }
  }

  func expectRelative(
    file: StaticString = #file, line: UInt = #line
  ) {
    withSourceLoc(file, line) {
      expectTrue(path.isRelative, "expected relative")
    }
  }

  func expectAbsolute(
    file: StaticString = #file, line: UInt = #line
  ) {
    withSourceLoc(file, line) {
      expectTrue(path.isAbsolute, "expected absolute")
    }
  }

  // TODO: Do we want to overload others like expectEqual[Sequence]?
}

// @available(9999....)
struct TestPathComponents: TestCase {
  var path: FilePath
  var expectedRoot: FilePath.Root?
  var expectedComponents: [FilePath.Component]

  var pathComponents: Array<FilePath.Component> { Array(path.components) }

  let file: StaticString
  let line: UInt

  func failureMessage(_ reason: String?) -> String {
    """

    Fail \(reason ?? "")
      path: \(path)
      components: \(pathComponents))
      expected: \(expectedComponents)
    """
  }

  init<C: Collection>(
    _ path: FilePath,
    root: FilePath.Root?,
    _ components: C,
    file: StaticString = #file, line: UInt = #line
  ) where C.Element == FilePath.Component {
    self.path = path
    self.expectedRoot = root
    self.expectedComponents = Array(components)
    self.file = file
    self.line = line
  }

  func testComponents() {
    expectEqual(expectedRoot, path.root)
    expectEqualSequence(
      expectedComponents, Array(path.components), "testComponents()")
  }

  func testBidi() {


  }

  func testRRC() {
    // TODO: Convert tests into mutation tests
//    // What generalized tests can we do, given how initial "/" is special?
//    // E.g. absolute path inserted into itself can have only one root
//
//    do {
//      var path = self.path
//      if path.isAbsolute {
//        path.components.removeFirst()
//      }
//      expectTrue(path.isRelative)
//
//      let componentsArray = Array(path.components)
//      path.components.append(contentsOf: componentsArray)
//      expectEqualSequence(componentsArray + componentsArray, path.components)
//
//      // TODO: Other generalized tests which work on relative paths
//    }
  }

  func runAllTests() {
    testComponents()
    testBidi()
    testRRC()
  }
}

// TODO: Note that double-reversal will drop root if FilePath is constructed in between ...

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class FilePathComponentsTest: XCTestCase {

  let testPaths: Array<TestPathComponents> = [
    TestPathComponents("", root: nil, []),
    TestPathComponents("/", root: "/", []),
    TestPathComponents("foo", root: nil, ["foo"]),
    TestPathComponents("foo/", root: nil, ["foo"]),
    TestPathComponents("/foo", root: "/", ["foo"]),
    TestPathComponents("foo/bar", root: nil, ["foo", "bar"]),
    TestPathComponents("foo/bar/", root: nil, ["foo", "bar"]),
    TestPathComponents("/foo/bar", root: "/", ["foo", "bar"]),
    TestPathComponents("///foo//", root: "/", ["foo"]),
    TestPathComponents("/foo///bar", root: "/", ["foo", "bar"]),
    TestPathComponents("foo/bar/", root: nil, ["foo", "bar"]),
    TestPathComponents("foo///bar/baz/", root: nil, ["foo", "bar", "baz"]),
    TestPathComponents("//foo///bar/baz/", root: "/", ["foo", "bar", "baz"]),
    TestPathComponents("./", root: nil, ["."]),
    TestPathComponents("./..", root: nil, [".", ".."]),
    TestPathComponents("/./..//", root: "/", [".", ".."]),
  ]

  // TODO: generalize to a driver protocol that will inherit from XCTest, expose allTestCases
  // based on an associated type, and provide the testCasees func, assuming XCTest supports
  // that.
  func testCases() {
    testPaths.forEach { $0.runAllTests() }
  }

  // TODO: Convert these kinds of test cases into mutation API test cases.
  func testAdHocRRC() {
    var path: FilePath = "/usr/local/bin"

    func expect(
      _ s: String,
      _ file: StaticString = #file,
      _ line: UInt = #line
    ) {
      if path == FilePath(s) { return }

      defer { print("expected: \(s), actual: \(path)") }
      XCTAssert(false, file: file, line: line)
    }

    // Run `body`, restoring `path` afterwards
    func restoreAfter(
      body: () -> ()
    ) {
      let copy = path
      defer { path = copy }
      body()
    }

    // Interior removal keeps path prefix intact, if there is one
    restoreAfter {
      path = "prefix//middle1/middle2////suffix"
      let suffix = path.components.indices.last!
      path.components.removeSubrange(..<suffix)
      expect("suffix")
    }

    restoreAfter {
      path = "prefix//middle1/middle2////suffix"
      let firstMiddle = path.components.index(
        path.components.startIndex, offsetBy: 1)
      let suffix = path.components.indices.last!
      path.components.removeSubrange(firstMiddle ..< suffix)
      expect("prefix/suffix")
    }

    restoreAfter {
      path.components.removeFirst()
      expect("/local/bin")
      path.components.removeFirst()
      expect("/bin")
    }

    restoreAfter {
      path.components.insert(
        contentsOf: ["bar", "baz"], at: path.components.startIndex)
      expect("/bar/baz/usr/local/bin")
    }

    restoreAfter {
      path.components.insert("start", at: path.components.startIndex)
      expect("/start/usr/local/bin")
      path.components.insert("prefix", at: path.components.startIndex)
      expect("/prefix/start/usr/local/bin")
      path.components.removeSubrange(
        ..<path.components.index(path.components.startIndex, offsetBy: 4))
      expect("/bin")
      path.components.removeFirst()
      expect("/")
      path.components.append(contentsOf: ["usr", "local", "bin"])
      expect("/usr/local/bin")
      path.components.removeLast(2)
      expect("/usr")
    }

    restoreAfter {
      path.root = nil
      expect("usr/local/bin")
      path.components.removeAll()
      expect("")
      path.components.insert("foo", at: path.components.startIndex)
      expect("foo")

      path.components.removeAll()
      path.components.insert(
        contentsOf: ["bar", "baz"], at: path.components.startIndex)
      expect("bar/baz")
    }

    restoreAfter {
      path.components.append("tail")
      expect("/usr/local/bin/tail")
      path.components.append(contentsOf: ["tail2", "tail3", "tail4"])
      expect("/usr/local/bin/tail/tail2/tail3/tail4")
    }

    // Insertion into the middle adds trailing separator
    restoreAfter {
      path.components.remove(
        at: path.components.index(after: path.components.startIndex))
      expect("/usr/bin")
      path.components.insert("middle", at: path.components.indices.last!)
      expect("/usr/middle/bin")
      path.components.insert(
        contentsOf: ["middle2", "middle3"], at: path.components.indices.last!)
      expect("/usr/middle/middle2/middle3/bin")

      let slice = path.components.dropFirst().dropLast()
      let range = slice.startIndex ..< slice.endIndex
      path.components.replaceSubrange(
        range, with: ["newMiddle", "newMiddle2", "newMiddle3", "newMiddle4/"])
      expect("/usr/newMiddle/newMiddle2/newMiddle3/newMiddle4/bin")
    }

    restoreAfter {
      path.components.removeLast(3)
      expect("/")
      path.components.append(contentsOf: ["bar", "baz"])
      expect("/bar/baz")
    }

    // Empty insertions / removals
    restoreAfter {
      path.components.replaceSubrange(..<path.components.startIndex, with: [])
      expect("/usr/local/bin")
      path.components.replaceSubrange(path.components.endIndex..., with: [])
      expect("/usr/local/bin")
      path.components.insert(contentsOf: [], at: path.components.startIndex)
      expect("/usr/local/bin")
      path.components.insert(contentsOf: [], at: path.components.indices.last!)
      expect("/usr/local/bin")
    }
  }

  func testConcatenation() {
    // TODO: convert tests into mutation tests

//    for lhsTest in testPaths {
//      let lhs = lhsTest.path
//      for rhsTest in testPaths {
//        let rhs = rhsTest.path
//        adhocComponentsTest(lhs + rhs) { concatpath in
//          // (lhs + rhs).components == (lhs.components + rhs.compontents)
//          concatpath.expectEqualSequence(lhs.components + rhs.components, concatpath.components)
//
//          // TODO: More tests around non-normalized separators
//        }
//      }
//    }
  }

  func testSeparatorNormalization() {
    var paths: Array<FilePath> = [
      "/a/b",
      "/a/b/",
      "/a//b/",
      "/a/b//",
      "/a/b////",
      "/a////b/",
    ]
  #if !os(Windows)
    paths.append("//a/b")
    paths.append("///a/b")
    paths.append("///a////b")
    paths.append("///a////b///")
  #endif

    for path in paths {
      var path = path
      path._normalizeSeparators()
      XCTAssertEqual(path, "/a/b")
    }
  }
}

// TODO: Test hashValue and equatable for equal components, i.e. make
// sure indices are not part of the hash.
