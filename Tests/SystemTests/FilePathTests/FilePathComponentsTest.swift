/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
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
    expectEqualSequence(
      expectedComponents.reversed(), path.components.reversed(), "reversed()")
    expectEqualSequence(
      path.components, path.components.reversed().reversed(),
      "reversed().reversed()")
    for i in 0 ..< path.components.count {
      expectEqualSequence(
        expectedComponents.dropLast(i), path.components.dropLast(i), "dropLast")
      expectEqualSequence(
        expectedComponents.suffix(i), path.components.suffix(i), "suffix")
    }
  }

  func testRRC() {
    // TODO: programmatic tests showing parity with Array<Component>
  }

  func testModify() {
    if path.root == nil {
      let rootedPath = FilePath(root: "/", path.components)
      expectNotEqual(rootedPath, path)
      var pathCopy = path
      expectEqual(path, pathCopy)
      pathCopy.components = rootedPath.components
      expectNil(pathCopy.root, "components.set doesn't assign root")
      expectEqual(path, pathCopy)
    } else {
      let rootlessPath = FilePath(root: nil, path.components)
      var pathCopy = path
      expectEqual(path, pathCopy)
      pathCopy.components = rootlessPath.components
      expectNotNil(pathCopy.root, "components.set preserves root")
      expectEqual(path, pathCopy)
    }
  }

  func runAllTests() {
    testComponents()
    testBidi()
    testRRC()
    testModify()
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
final class FilePathComponentsTest: XCTestCase {
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

  func testCases() {
    var testPaths: Array<TestPathComponents> = [
      TestPathComponents("", root: nil, []),
      TestPathComponents("/", root: "/", []),
      TestPathComponents("foo", root: nil, ["foo"]),
      TestPathComponents("foo/", root: nil, ["foo"]),
      TestPathComponents("/foo", root: "/", ["foo"]),
      TestPathComponents("foo/bar", root: nil, ["foo", "bar"]),
      TestPathComponents("foo/bar/", root: nil, ["foo", "bar"]),
      TestPathComponents("/foo/bar", root: "/", ["foo", "bar"]),
      TestPathComponents("/foo///bar", root: "/", ["foo", "bar"]),
      TestPathComponents("foo/bar/", root: nil, ["foo", "bar"]),
      TestPathComponents("foo///bar/baz/", root: nil, ["foo", "bar", "baz"]),
      TestPathComponents("./", root: nil, ["."]),
      TestPathComponents("./..", root: nil, [".", ".."]),
      TestPathComponents("/./..//", root: "/", [".", ".."]),
    ]
#if !os(Windows)
    testPaths.append(contentsOf:[
        TestPathComponents("///foo//", root: "/", ["foo"]),
        TestPathComponents("//foo///bar/baz/", root: "/", ["foo", "bar", "baz"])
    ])
#else
    // On Windows, these are UNC paths
    testPaths.append(contentsOf:[
        TestPathComponents("///foo//", root: "///foo//", []),
        TestPathComponents("//foo///bar/baz/", root: "//foo//", ["bar", "baz"])
    ])
#endif
    testPaths.forEach {
        $0.runAllTests()
    }
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
