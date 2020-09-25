/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import SystemPackage

// Helper to organize some ad-hoc testing
//
// TODO: Currently a class so we can overwrite file/line, but that can be
// re-evaluated when we have source loc stacks.
fileprivate final class AdHocComponentsTest: TestCase {
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

  var components: FilePath.ComponentView {
    get { path.components }
    set { path.components = newValue }
  }
}

private func adhocComponentsTest(    _ path: FilePath,
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
    _ components: C,
    file: StaticString = #file, line: UInt = #line
  ) where C.Element == FilePath.Component {
    self.path = path
    self.expectedComponents = Array(components)
    self.file = file
    self.line = line
  }

  func testComponents() {
    expectEqualSequence(Array(path.components), expectedComponents, "testComponents()")
  }

  func testBidi() {
    expectEqualSequence(pathComponents, expectedComponents, "testBidi()")
    expectEqual(pathComponents.first, expectedComponents.first, "testBidi()")
    expectEqual(pathComponents.last, expectedComponents.last, "testBidi()")

    let reversedPathComponents = path.components.reversed()
    expectEqualSequence(reversedPathComponents, expectedComponents.reversed(), "testBidi() reversed")

    expectEqualSequence(
      reversedPathComponents.reversed(), expectedComponents, "testBidi() doubly reversed")

    // Constructing an intermediary FilePath will drop trailing / component (if there's a prefix)
    let doublyReversed = FilePath(reversedPathComponents).components.reversed()
    if path.isRelative || path.components.count <= 1 {
      expectEqualSequence(doublyReversed, expectedComponents, "testBidi() doubly reversed 2")
    } else {
      expectEqualSequence(["/"] + doublyReversed, expectedComponents, "testBidi() doubly reversed 2")
    }

  }

  func testRRC() {
    // What generalized tests can we do, given how initial "/" is special?
    // E.g. absolute path inserted into itself can have only one root

    do {
      var path = self.path
      if path.isAbsolute {
        path.components.removeFirst()
      }
      expectTrue(path.isRelative)

      let componentsArray = Array(path.components)
      path.components.append(contentsOf: componentsArray)
      expectEqualSequence(path.components, componentsArray + componentsArray)

      // TODO: Other generalized tests which work on relative paths
    }

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
    TestPathComponents("", []),
    TestPathComponents("/", ["/"]),
    TestPathComponents("foo", ["foo"]),
    TestPathComponents("foo/", ["foo"]),
    TestPathComponents("/foo", ["/", "foo"]),
    TestPathComponents("foo/bar", ["foo", "bar"]),
    TestPathComponents("foo/bar/", ["foo", "bar"]),
    TestPathComponents("/foo/bar", ["/", "foo", "bar"]),
    TestPathComponents("///foo//", ["/", "foo"]),
    TestPathComponents("/foo///bar", ["/", "foo", "bar"]),
    TestPathComponents("foo/bar/", ["foo", "bar"]),
    TestPathComponents("foo///bar/baz/", ["foo", "bar", "baz"]),
    TestPathComponents("//foo///bar/baz/", ["/", "foo", "bar", "baz"]),
    TestPathComponents("./", ["."]),
    TestPathComponents("./..", [".", ".."]),
    TestPathComponents("/./..//", ["/", ".", ".."]),
  ]

  // TODO: generalize to a driver protocol that will inherit from XCTest, expose allTestCases
  // based on an associated type, and provide the testCasees func, assuming XCTest supports
  // that.
  func testCases() {
    testPaths.forEach { $0.runAllTests() }
  }

  // TODO: generalize portions out and apply to suite of test cases...
  func testAdHocRRC() {
    // Interior removal keeps path prefix intact, if there is one
    adhocComponentsTest("prefix//middle1/middle2////suffix") { path in
      let suffix = path.components.indices.last!
      path.components.removeSubrange(..<suffix)
      path.expect("suffix")
    }

    adhocComponentsTest("prefix//middle1/middle2////suffix") { path in
      let firstMiddle = path.components.index(path.components.startIndex, offsetBy: 1)
      let suffix = path.components.indices.last!
      path.components.removeSubrange(firstMiddle ..< suffix)
      path.expect("prefix//suffix")
    }

    let originalPath: FilePath = "/foo/bar/baz"

    // Removing a root will make a path relative, adding one will make it absolute
    adhocComponentsTest(originalPath) { path in
      path.components.removeFirst()
      path.expect("foo/bar/baz")
      path.expectRelative()
      path.components.insert("/", at: path.components.startIndex)
      path.expectAbsolute()
      path.expect(originalPath)

      path.components.removeFirst()
      path.expect("foo/bar/baz")
      path.expectRelative()
      path.components.insert("/////", at: path.components.startIndex)
      path.expectAbsolute()
      path.expect(originalPath)
    }

    // Adding a redundant root is a nop
    adhocComponentsTest(originalPath) { path in
      path.components.insert("/", at: path.components.startIndex)
      path.components.insert(contentsOf: ["/", "/", "/"], at: path.components.startIndex)
      path.expectAbsolute()
      path.expect(originalPath)
    }

    // Adding a non-root start will make a path relative
    // Removing a (root or non-root) start will make a path relative
    adhocComponentsTest(originalPath) { path in
      path.components.insert("start", at: path.components.startIndex)
      path.expect("start/foo/bar/baz")
      path.expectRelative()
      path.components.insert("prefix", at: path.components.startIndex)
      path.expect("prefix/start/foo/bar/baz")
      path.expectRelative()
      path.components.insert(contentsOf: ["/", "a", "b", "c"], at: path.components.startIndex)
      path.expect("/a/b/c/prefix/start/foo/bar/baz")
      path.expectAbsolute()

      path.components.removeSubrange(
        ..<path.components.index(path.components.startIndex, offsetBy: 6))
      path.expect("foo/bar/baz")
      path.expectRelative()
      path.components.removeFirst()
      path.expect("bar/baz")
      path.expectRelative()
      path.components.insert(contentsOf: ["/", "foo"], at: path.components.startIndex)
      path.expectAbsolute()
      path.expect(originalPath)
    }

    adhocComponentsTest(originalPath) { path in
      path.components.removeAll()
      path.components.insert("foo", at: path.components.startIndex)
      path.expect("foo")

      path.components.removeAll()
      path.components.insert("/", at: path.components.startIndex)
      path.expect("/")

      path.components.removeAll()
      path.components.insert(contentsOf: ["/", "foo/"], at: path.components.startIndex)
      path.expect("/foo")
    }

    // Appending a root does nothing unless empty
    adhocComponentsTest("") { path in
      path.components.insert("/", at: path.components.startIndex)
      path.expect("/")
    }

    adhocComponentsTest(originalPath) { path in
      path.components.append("/")
      path.expect(originalPath)
    }

    // Non-start insertion skips roots
    adhocComponentsTest(originalPath) { path in
      path.components.append(contentsOf: ["/", "tail"])
      path.expect("/foo/bar/baz/tail")
      path.components.append(contentsOf: ["/", "tail2", "tail3", "/", "tail4", "/"])
      path.expect("/foo/bar/baz/tail/tail2/tail3/tail4")
    }

    // Insertion into the middle adds trailing separator
    adhocComponentsTest("start/middle1/end/") { path in
      path.components.insert("middle2", at: path.components.indices.last!)
      path.expect("start/middle1/middle2/end/")

      let slice = path.components.dropFirst().dropLast()
      let range = slice.startIndex ..< slice.endIndex
      // TODO: FileSubPath and maybe genrics?
      adhocComponentsTest(FilePath(path.components[range])) { $0.expect("middle1/middle2") }
      path.components.replaceSubrange(
        range, with: ["newMiddle1/", "newMiddle2", "newMiddle3", "/", "newMiddle4/"])
      path.expect("start/newMiddle1/newMiddle2/newMiddle3/newMiddle4/end/")
    }

    adhocComponentsTest(originalPath) { path in
      path.components.removeLast()
      path.expect("/foo/bar/")
      path.components.removeLast()
      path.expect("/foo/")
      path.components.append(contentsOf: ["bar", "baz"])
      path.expect(originalPath)
    }

    // Test trailing slash behavior
    adhocComponentsTest(originalPath) { path in
      path.components.removeLast()
      path.expect("/foo/bar/")
      path.components.append("baz/")
      path.expect("/foo/bar/baz")
      path.components.removeLast()
      path.components.append("baz")
      path.expect(originalPath)
    }

    // Empty insertions / removals
    adhocComponentsTest(originalPath) { path in
      path.components.replaceSubrange(..<path.components.startIndex, with: [])
      path.expect(originalPath)
      path.components.replaceSubrange(path.components.endIndex..., with: [])
      path.expect(originalPath)
      path.components.insert(contentsOf: [], at: path.components.startIndex)
      path.expect(originalPath)
    }
  }

  func testConcatenation() {
    for lhsTest in testPaths {
      let lhs = lhsTest.path
      for rhsTest in testPaths {
        let rhs = rhsTest.path
        adhocComponentsTest(lhs + rhs) { concatpath in
          // (lhs + rhs).components == (lhs.components + rhs.compontents)
          concatpath.expectEqualSequence(concatpath.components, lhs.components + rhs.components)

          // TODO: More tests around non-normalized separators
        }
      }
    }
  }
}
