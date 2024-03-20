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

private struct SyntaxTestCase: TestCase {
  // Whether we want the path to be constructed and syntactically
  // manipulated as though it were a Windows path
  let isWindows: Bool

  // We defer forming the path until `runAllTests()` executes,
  // so that we can switch between unix and windows behavior.
  let pathStr: String

  let normalized: String

  let absolute: Bool

  let root: String?
  let relative: String

  let dirname: String
  let basename: String?

  let stem: String?
  let `extension`: String?

  let components: [String]

  let lexicallyNormalized: String

  var file: StaticString
  var line: UInt
}

extension SyntaxTestCase {
  // Convenience constructor which can substitute sensible defaults
  private static func testCase(
    isWindows: Bool,
    _ path: String,

    // Nil `normalized` means use `path`
    normalized: String?,

    // Nil means use the precense of a root
    absolute: Bool?,

    // Nil `root` means no root. Nil `relative` means use `normalized`
    root: String?, relative: String?,

    // Nil `dirname` requires nil `basename` and means use `normalized`
    dirname: String?, basename: String?,

    // `nil` stem means use `basename`
    stem: String?, extension: String?,

    components: [String],

    // Nil `lexicallyNormalized` means use `normalized`
    lexicallyNormalized: String?,

    file: StaticString, line: UInt
  ) -> SyntaxTestCase {
    if dirname == nil {
      assert(basename == nil )
    }

    let normalized = normalized ?? path
    let lexicallyNormalized = lexicallyNormalized ?? normalized
    let absolute = absolute ?? (root != nil)
    let relative = relative ?? normalized
    let dirname = dirname ?? (normalized)
    let stem = stem ?? basename
    return SyntaxTestCase(
      isWindows: isWindows,
      pathStr: path,
      normalized: normalized,
      absolute: absolute,
      root: root, relative: relative,
      dirname: dirname, basename: basename,
      stem: stem, extension: `extension`,
      components: components,
      lexicallyNormalized: lexicallyNormalized,
      file: file, line: line)
  }

  // Conveience constructor for unix path test cases
  static func unix(
    _ path: String,
    normalized: String? = nil,
    root: String? = nil, relative: String? = nil,
    dirname: String? = nil, basename: String? = nil,
    stem: String? = nil, extension: String? = nil,
    components: [String],
    lexicallyNormalized: String? = nil,
    file: StaticString = #file, line: UInt = #line
  ) -> SyntaxTestCase {
    .testCase(
      isWindows: false,
      path,
      normalized: normalized,
      absolute: nil,
      root: root, relative: relative,
      dirname: dirname, basename: basename,
      stem: stem, extension: `extension`,
      components: components,
      lexicallyNormalized: lexicallyNormalized,
      file: file, line: line)
  }

  // Conveience constructor for unix path test cases
  static func windows(
    _ path: String,
    normalized: String? = nil,
    absolute: Bool,
    root: String? = nil, relative: String? = nil,
    dirname: String? = nil, basename: String? = nil,
    stem: String? = nil, extension: String? = nil,
    components: [String],
    lexicallyNormalized: String? = nil,
    file: StaticString = #file, line: UInt = #line
  ) -> SyntaxTestCase {
    .testCase(
      isWindows: true,
      path,
      normalized: normalized,
      absolute: absolute,
      root: root, relative: relative,
      dirname: dirname, basename: basename,
      stem: stem, extension: `extension`,
      components: components,
      lexicallyNormalized: lexicallyNormalized,
      file: file, line: line)
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension SyntaxTestCase {
  func testComponents(_ path: FilePath, expected: [String]) {
    let expectedComponents = expected.map { FilePath.Component($0)! }

    expectEqualSequence(expectedComponents, Array(path.components),
                        "expected components")
    expectEqualSequence(expectedComponents, Array(path.removingRoot().components),
                        "expected components")

    expectEqualSequence(expectedComponents, path.components)
    expectEqual(expectedComponents.first, path.components.first)
    expectEqual(expectedComponents.last, path.components.last)

   expectEqual(path, FilePath(root: path.root, expectedComponents), "init<C>(root:components)")
   expectEqual(path, FilePath(root: path.root, path.components), "init<C>(root:components)")
    expectEqual(path, FilePath(
                  root: path.root, path.components[...]),
                "init(_ components: Slice)")

    let reversedPathComponents = path.components.reversed()
    expectEqual(expectedComponents.count, reversedPathComponents.count)
    expectEqualSequence(expectedComponents.reversed(), reversedPathComponents, "reversed")

    expectEqualSequence(
      expectedComponents, reversedPathComponents.reversed(), "doubly reversed")

    expectEqualSequence(path.removingRoot().components, path.components,
      "relativeComponents")

    let doublyReversed = FilePath(
      root: nil, path.removingRoot().components.reversed()
    ).components.reversed()
    expectEqualSequence(path.removingRoot().components, doublyReversed,
     "relative path doubly reversed")

    expectTrue(path.starts(with: path.removingLastComponent()),
               "starts(with: dirname)")
    expectEqual(path.removingLastComponent(), FilePath(
                  root: path.root, path.components.dropLast()),
                "ComponentView.dirname")

    var prefixComps = expectedComponents
    var prefixBasenamePath = path
    var prefixPopLastPath = path
    var compView = path.components[...]
    var prefixDirname = path.removingLastComponent()
    while !prefixComps.isEmpty {
      expectTrue(path.starts(with: FilePath(root: path.root, prefixComps)), "startswith")
      expectTrue(path.starts(with: prefixBasenamePath), "startswith")
      expectTrue(path.starts(with: prefixPopLastPath), "startswith")
      expectEqual(prefixBasenamePath, prefixPopLastPath, "popLast/basename")
      expectEqual(prefixBasenamePath, FilePath(root: path.root, compView),
                  "popLast/basename")
      prefixComps.removeLast()
      prefixBasenamePath = prefixBasenamePath.removingLastComponent()
      prefixPopLastPath.removeLastComponent()
      compView = compView.dropLast()

      expectEqual(prefixBasenamePath, prefixDirname, "prefix dirname")
      prefixDirname = prefixDirname.removingLastComponent()
    }
    var suffixComps = expectedComponents
    compView = path.components[...]
    while !suffixComps.isEmpty {
      expectTrue(path.ends(with: FilePath(root: nil, suffixComps)), "endswith")
      expectEqual(FilePath(root: nil, compView), FilePath(root: nil, suffixComps))
      suffixComps.removeFirst()
      compView = compView.dropFirst()
    }

    // FIXME: If we add operator `/` back, uncomment this
    #if false
    let slashPath = _path.components.reduce("", /)
    let pushPath: FilePath = _path.components.reduce(
      into: "", { $0.pushLast($1) })

    expectEqual(_path, slashPath, "`/`")
    expectEqual(_path, pushPath, "pushLast")
    #endif
  }


  func runAllTests() {
    // Assert we were set up correctly if non-nil
    func assertNonEmpty<C: Collection>(_ c: C?) {
      assert(c == nil || !c!.isEmpty)
    }
    assertNonEmpty(root)
    assertNonEmpty(basename)
    assertNonEmpty(stem)

    withWindowsPaths(enabled: isWindows) {
      let path = FilePath(pathStr)

      expectTrue((path == "") == path.isEmpty, "isEmpty")

      expectEqual(normalized, path.description, "normalized")

      var copy = path
      copy.lexicallyNormalize()
      expectEqual(copy == path, path.isLexicallyNormal, "isLexicallyNormal")
      expectEqual(lexicallyNormalized, copy.description, "lexically normalized")
      expectEqual(copy, path.lexicallyNormalized(), "lexicallyNormal")

      expectEqual(absolute, path.isAbsolute, "absolute")
      expectEqual(!absolute, path.isRelative, "!absolute")

      expectEqual(root, path.root?.description, "root")
      expectEqual(relative, path.removingRoot().description, "relative")

      if path.isRelative {
        if path.root == nil {
          expectEqual(path, path.removingRoot(), "relative idempotent")
        } else {
          expectTrue(isWindows)
          expectFalse(path == path.removingRoot())
          var relPathCopy = path.removingRoot()
          relPathCopy.root = path.root
          expectEqual(path, relPathCopy)

          // TODO: Windows root analysis tests
        }
      } else {
        var pathCopy = path
        pathCopy.root = nil
        expectEqual(pathCopy, path.removingRoot(), "set nil root")
        expectEqual(relative, path.removingRoot().description, "set root to nil")
        pathCopy.root = path.root
        expectTrue(pathCopy.isAbsolute)
        expectEqual(path, pathCopy)
        expectTrue(path.root != nil)
      }

      if let root = path.root {
        var pathCopy = path
        pathCopy.components.removeAll()
        expectEqual(FilePath(root: root), pathCopy, "set empty relative")
      } else {
        var pathCopy = path
        pathCopy.components.removeAll()
        expectTrue(pathCopy.isEmpty, "set empty relative")
      }

      expectEqual(dirname, path.removingLastComponent().description, "dirname")
      expectEqual(basename, path.lastComponent?.description, "basename")

      do {
        var path = path
        var pathCopy = path
        while !path.removingRoot().isEmpty {
          pathCopy = pathCopy.removingLastComponent()
          path.removeLastComponent()
          expectEqual(path, pathCopy)
        }
      }

      expectEqual(stem, path.stem, "stem")
      expectEqual(`extension`, path.extension, "extension")

      if let base = path.lastComponent {
        expectEqual(path.stem, base.stem)
        expectEqual(path.extension, base.extension)
      }

      var pathCopy = path
      while pathCopy.extension != nil {
        var name = pathCopy.lastComponent!.description
        name.removeSubrange(name.lastIndex(of: ".")!...)
        pathCopy.extension = nil
        expectEqual(name, pathCopy.lastComponent!.description, "set nil extension (2)")
      }
      expectTrue(pathCopy.extension == nil, "set nil extension")

      pathCopy = path
      pathCopy.removeAll(keepingCapacity: true)
      expectTrue(pathCopy.isEmpty)

      testComponents(path, expected: self.components)
    }
  }
}

private struct WindowsRootTestCase: TestCase {
  // We defer forming the path until `runAllTests()` executes,
  // so that we can switch between unix and windows behavior.
  let rootStr: String

  let expected: String

  let absolute: Bool

  var file: StaticString
  var line: UInt
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension WindowsRootTestCase {
  func runAllTests() {
    withWindowsPaths(enabled: true) {
      let path = FilePath(rootStr)
      expectEqual(expected, path.string)
      expectNotNil(path.root)
      expectEqual(path, FilePath(root: path.root ?? ""))
      expectTrue(path.components.isEmpty)
      expectTrue(path.removingRoot().isEmpty)
      expectTrue(path.isLexicallyNormal)
    }
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
final class FilePathSyntaxTest: XCTestCase {
  func testPathSyntax() {
    let unixPaths: Array<SyntaxTestCase> = [
      .unix("", components: []),

      .unix(
        "/",
        root: "/", relative: "",
        components: []
      ),

      .unix(
        "/..",
        root: "/", relative: "..",
        dirname: "/", basename: "..",
        components: [".."],
        lexicallyNormalized: "/"
      ),

      .unix(
        "/.",
        root: "/", relative: ".",
        dirname: "/", basename: ".",
        components: ["."],
        lexicallyNormalized: "/"
      ),

      .unix(
        "/../.",
        root: "/", relative: "../.",
        dirname: "/..", basename: ".",
        components: ["..", "."],
        lexicallyNormalized: "/"
      ),

      .unix(
        ".",
        dirname: "", basename: ".",
        components: ["."],
        lexicallyNormalized: ""
      ),

      .unix(
        "..",
        dirname: "", basename: "..",
        components: [".."],
        lexicallyNormalized: ".."
      ),

      .unix(
        "./..",
        dirname: ".", basename: "..",
        components: [".", ".."],
        lexicallyNormalized: ".."
      ),

      .unix(
        "../.",
        dirname: "..", basename: ".",
        components: ["..", "."],
        lexicallyNormalized: ".."
      ),

      .unix(
        "../..",
        dirname: "..", basename: "..",
        components: ["..", ".."],
        lexicallyNormalized: "../.."
      ),

      .unix(
        "a/../..",
        dirname: "a/..", basename: "..",
        components: ["a", "..", ".."],
        lexicallyNormalized: ".."
      ),

      .unix(
        "a/.././.././../b",
        dirname: "a/.././.././..", basename: "b",
        components: ["a", "..", ".", "..", ".", "..", "b"],
        lexicallyNormalized: "../../b"
      ),

      .unix(
        "/a/.././.././../b",
        root: "/", relative: "a/.././.././../b",
        dirname: "/a/.././.././..", basename: "b",
        components: ["a", "..", ".", "..", ".", "..", "b"],
        lexicallyNormalized: "/b"
      ),

      .unix(
        "./.",
        dirname: ".", basename: ".",
        components: [".", "."],
        lexicallyNormalized: ""
      ),

      .unix(
        "foo.txt",
        dirname: "", basename: "foo.txt",
        stem: "foo", extension: "txt",
        components: ["foo.txt"]
      ),

      .unix(
        "a/foo/bar/../..",
        dirname: "a/foo/bar/..", basename: "..",
        components: ["a", "foo", "bar", "..", ".."],
        lexicallyNormalized: "a"
      ),

      .unix(
        "a/./foo/bar/.././../.",
        dirname: "a/./foo/bar/.././..", basename: ".",
        components: ["a", ".", "foo", "bar", "..", ".", "..", "."],
        lexicallyNormalized: "a"
      ),

      .unix(
        "a/../b",
        dirname: "a/..", basename: "b",
        components: ["a", "..", "b"],
        lexicallyNormalized: "b"
      ),

      .unix(
        "/a/../b/../c/../../d",
        root: "/", relative: "a/../b/../c/../../d",
        dirname: "/a/../b/../c/../..", basename: "d",
        components: ["a", "..", "b", "..", "c", "..", "..", "d"],
        lexicallyNormalized: "/d"
      ),

      .unix(
        "/usr/bin/ls",
        root: "/", relative: "usr/bin/ls",
        dirname: "/usr/bin", basename: "ls",
        components: ["usr", "bin", "ls"]
      ),

      .unix(
        "bin/ls",
        dirname: "bin", basename: "ls",
        components: ["bin", "ls"]
      ),

      .unix(
        "~/bar.app",
        dirname: "~", basename: "bar.app",
        stem: "bar", extension: "app",
        components: ["~", "bar.app"]
      ),

      .unix(
        "~/bar.app.bak/",
        normalized: "~/bar.app.bak",
        dirname: "~", basename: "bar.app.bak",
        stem: "bar.app", extension: "bak",
        components: ["~", "bar.app.bak"]
      ),

      .unix(
        "/tmp/.",
        root: "/", relative: "tmp/.",
        dirname: "/tmp", basename: ".",
        components: ["tmp", "."],
        lexicallyNormalized: "/tmp"
      ),

      .unix(
        "/tmp/..",
        root: "/", relative: "tmp/..",
        dirname: "/tmp", basename: "..",
        components: ["tmp", ".."],
        lexicallyNormalized: "/"
      ),

      .unix(
        "/tmp/../",
        normalized: "/tmp/..",
        root: "/", relative: "tmp/..",
        dirname: "/tmp", basename: "..",
        components: ["tmp", ".."],
        lexicallyNormalized: "/"
      ),

      .unix(
        "/tmp/./a/../b",
        root: "/", relative: "tmp/./a/../b",
        dirname: "/tmp/./a/..", basename: "b",
        components: ["tmp", ".", "a", "..", "b"],
        lexicallyNormalized: "/tmp/b"
      ),

      .unix(
        "/tmp/.hidden",
        root: "/", relative: "tmp/.hidden",
        dirname: "/tmp", basename: ".hidden",
        components: ["tmp", ".hidden"]
      ),

      .unix(
        "/tmp/.hidden.",
        root: "/", relative: "tmp/.hidden.",
        dirname: "/tmp", basename: ".hidden.",
        stem: ".hidden", extension: "",
        components: ["tmp", ".hidden."]
      ),

      .unix(
        "/tmp/.hidden.o",
        root: "/", relative: "tmp/.hidden.o",
        dirname: "/tmp", basename: ".hidden.o",
        stem: ".hidden", extension: "o",
        components: ["tmp", ".hidden.o"]
      ),

      .unix(
        "/tmp/.hidden.o.",
        root: "/", relative: "tmp/.hidden.o.",
        dirname: "/tmp", basename: ".hidden.o.",
        stem: ".hidden.o", extension: "",
        components: ["tmp", ".hidden.o."]
      ),

      // Backslash is not a separator, nor a root
      .unix(
        #"\bin\.\ls"#,
        dirname: "", basename: #"\bin\.\ls"#,
        stem: #"\bin\"#, extension: #"\ls"#,
        components: [#"\bin\.\ls"#]
      ),
    ]

    let windowsPaths: Array<SyntaxTestCase> = [
      .windows(#""#, absolute: false,  components: []),

      .windows(
        #"C"#,
        absolute: false,
        dirname: "", basename: "C",
        components: ["C"]
      ),

      .windows(
        #"C:"#,
        absolute: false,
        root: #"C:"#, relative: #""#,
        components: []
      ),

      .windows(
        #"C:\"#,
        absolute: true,
        root: #"C:\"#, relative: #""#,
        components: []
      ),

      .windows(
        #"C:\foo\bar.exe"#,
        absolute: true,
        root: #"C:\"#, relative: #"foo\bar.exe"#,
        dirname: #"C:\foo"#, basename: "bar.exe",
        stem: "bar", extension: "exe",
        components: ["foo", "bar.exe"]
      ),

      .windows(
        #"C:foo\bar"#,
        absolute: false,
        root: #"C:"#, relative: #"foo\bar"#,
        dirname: #"C:foo"#, basename: "bar",
        components: ["foo", "bar"]
      ),

      .windows(
        #"C:foo\bar\..\.."#,
        absolute: false,
        root: #"C:"#, relative: #"foo\bar\..\.."#,
        dirname: #"C:foo\bar\.."#, basename: "..",
        components: ["foo", "bar", "..", ".."],
        lexicallyNormalized: "C:"
      ),

      .windows(
        #"C:foo\bar\..\..\.."#,
        absolute: false,
        root: #"C:"#, relative: #"foo\bar\..\..\.."#,
        dirname: #"C:foo\bar\..\.."#, basename: "..",
        components: ["foo", "bar", "..", "..", ".."],
        lexicallyNormalized: "C:"
      ),

      .windows(
        #"\foo\bar.exe"#,
        absolute: false,
        root: #"\"#, relative: #"foo\bar.exe"#,
        dirname: #"\foo"#, basename: "bar.exe",
        stem: "bar", extension: "exe",
        components: ["foo", "bar.exe"]
      ),

      .windows(
        #"foo\bar.exe"#,
        absolute: false,
        dirname: #"foo"#, basename: "bar.exe",
        stem: "bar", extension: "exe",
        components: ["foo", "bar.exe"]
      ),

      .windows(
        #"\\?\device\"#,
        absolute: true,
        root: #"\\?\device\"#, relative: "",
        components: []
      ),

      .windows(
        #"\\?\device\folder\file.exe"#,
        absolute: true,
        root: #"\\?\device\"#, relative: #"folder\file.exe"#,
        dirname: #"\\?\device\folder"#, basename: "file.exe",
        stem: "file", extension: "exe",
        components: ["folder", "file.exe"]
      ),

      .windows(
        #"\\?\UNC\server\share\"#,
        absolute: true,
        root: #"\\?\UNC\server\share\"#, relative: #""#,
        components: []
      ),

      .windows(
        #"\\?\UNC\server\share\folder\file.txt"#,
        absolute: true,
        root: #"\\?\UNC\server\share\"#, relative: #"folder\file.txt"#,
        dirname: #"\\?\UNC\server\share\folder"#, basename: "file.txt",
        stem: "file", extension: "txt",
        components: ["folder", "file.txt"]
      ),

      .windows(
        #"\\server\share\"#,
        absolute: true,
        root: #"\\server\share\"#, relative: "",
        components: []
      ),

      .windows(
        #"\\server\share\folder\file.txt"#,
        absolute: true,
        root: #"\\server\share\"#, relative: #"folder\file.txt"#,
        dirname: #"\\server\share\folder"#, basename: "file.txt",
        stem: "file", extension: "txt",
        components: ["folder", "file.txt"]
      ),

      .windows(
        #"\\server\share\folder\file.txt\.."#,
        absolute: true,
        root: #"\\server\share\"#, relative: #"folder\file.txt\.."#,
        dirname: #"\\server\share\folder\file.txt"#, basename: "..",
        components: ["folder", "file.txt", ".."],
        lexicallyNormalized: #"\\server\share\folder"#
      ),

      .windows(
        #"\\server\share\folder\file.txt\..\.."#,
        absolute: true,
        root: #"\\server\share\"#, relative: #"folder\file.txt\..\.."#,
        dirname: #"\\server\share\folder\file.txt\.."#, basename: "..",
        components: ["folder", "file.txt", "..", ".."],
        lexicallyNormalized: #"\\server\share\"#
      ),

      .windows(
        #"\\server\share\folder\file.txt\..\..\..\.."#,
        absolute: true,
        root: #"\\server\share\"#, relative: #"folder\file.txt\..\..\..\.."#,
        dirname: #"\\server\share\folder\file.txt\..\..\.."#, basename: "..",
        components: ["folder", "file.txt", "..", "..", "..", ".."],
        lexicallyNormalized: #"\\server\share\"#
      ),

      // Actually a rooted relative path
      .windows(
        #"\server\share\folder\file.txt\..\..\.."#,
        absolute: false,
        root: #"\"#, relative: #"server\share\folder\file.txt\..\..\.."#,
        dirname: #"\server\share\folder\file.txt\..\.."#, basename: "..",
        components: ["server", "share", "folder", "file.txt", "..", "..", ".."],
        lexicallyNormalized: #"\server"#
      ),

      .windows(
        #"\\?\Volume{12345678-abcd-1111-2222-123445789abc}\folder\file"#,
        absolute: true,
        root: #"\\?\Volume{12345678-abcd-1111-2222-123445789abc}\"#,
        relative: #"folder\file"#,
        dirname: #"\\?\Volume{12345678-abcd-1111-2222-123445789abc}\folder"#,
        basename: "file",
        components: ["folder", "file"]
      )

      // TODO: partially-formed Windows roots, we should fully form them...
    ]

    for test in unixPaths {
      test.runAllTests()
    }
    for test in windowsPaths {
      test.runAllTests()
    }
  }


  func testPrefixSuffix() {
    let startswith: Array<(String, String)> = [
      ("/usr/bin/ls", "/"),
      ("/usr/bin/ls", "/usr"),
      ("/usr/bin/ls", "/usr/bin"),
      ("/usr/bin/ls", "/usr/bin/ls"),
      ("/usr/bin/ls", "/usr/bin/ls//"),
      ("/usr/bin/ls", ""),
    ]

    let noStartswith: Array<(String, String)> = [
      ("/usr/bin/ls", "/u"),
      ("/usr/bin/ls", "/us"),
      ("/usr/bin/ls", "/usr/bi"),
      ("/usr/bin/ls", "usr/bin/ls"),
      ("/usr/bin/ls", "usr/"),
      ("/usr/bin/ls", "ls"),
    ]

    for (path, pre) in startswith {
      XCTAssert(FilePath(path).starts(with: FilePath(pre)))
    }
    for (path, pre) in noStartswith {
      XCTAssertFalse(FilePath(path).starts(with: FilePath(pre)))
    }

    let endswith: Array<(String, String)> = [
      ("/usr/bin/ls", "ls"),
      ("/usr/bin/ls", "bin/ls"),
      ("/usr/bin/ls", "usr/bin/ls"),
      ("/usr/bin/ls", "/usr/bin/ls"),
      ("/usr/bin/ls", "/usr/bin/ls///"),
      ("/usr/bin/ls", ""),
    ]

    let noEndswith: Array<(String, String)> = [
      ("/usr/bin/ls", "/ls"),
      ("/usr/bin/ls", "/bin/ls"),
      ("/usr/bin/ls", "/usr/bin"),
      ("/usr/bin/ls", "foo"),
    ]

    for (path, suf) in endswith {
      XCTAssert(FilePath(path).ends(with: FilePath(suf)))
    }
    for (path, suf) in noEndswith {
      XCTAssertFalse(FilePath(path).ends(with: FilePath(suf)))
    }
  }

  func testLexicallyRelative() {
    let path: FilePath = "/usr/local/bin"
    XCTAssert(path.lexicallyRelative(toBase: "/usr/local") == "bin")
    XCTAssert(path.lexicallyRelative(toBase: "/usr/local/bin/ls") == "..")
    XCTAssert(path.lexicallyRelative(toBase: "/tmp/foo.txt") == "../../usr/local/bin")
    XCTAssert(path.lexicallyRelative(toBase: "local/bin") == nil)

    let rel = FilePath(root: nil, path.components)
    XCTAssert(rel.lexicallyRelative(toBase: "/usr/local") == nil)
    XCTAssert(rel.lexicallyRelative(toBase: "usr/local") == "bin")
    XCTAssert(rel.lexicallyRelative(toBase: "usr/local/bin/ls") == "..")
    XCTAssert(rel.lexicallyRelative(toBase: "tmp/foo.txt") == "../../usr/local/bin")
    XCTAssert(rel.lexicallyRelative(toBase: "local/bin") == "../../usr/local/bin")

    // TODO: Test Windows path with root pushed
  }

  func testAdHocMutations() {
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

    restoreAfter {
      path.root = nil
      expect("usr/local/bin")
      path.components = FilePath("ls").components
      expect("ls")
    }

    restoreAfter {
      path.components = FilePath("/bin/ls").components
      expect("/bin/ls")
      path.components.removeAll()
      expect("/")
    }

    restoreAfter {
      path = path.removingLastComponent().appending("lib")
      expect("/usr/local/lib")
      path = path.removingLastComponent()
      expect("/usr/local")
      path = path.removingLastComponent().appending("bin")
      expect("/usr/bin")
    }

    restoreAfter {
      path = FilePath("~").appending(path.lastComponent!)
      expect("~/bin")
      path = FilePath("").appending(path.lastComponent!)
      expect("bin")
      path = FilePath("").appending(path.lastComponent!)
      expect("bin")
      path = FilePath("/usr/local").appending(path.lastComponent!)
      expect("/usr/local/bin")
    }

    restoreAfter {
      path.removeLastComponent()
      expect("/usr/local")
      path.removeLastComponent()
      expect("/usr")
      path.removeLastComponent()
      expect("/")
      path.removeLastComponent()
      expect("/")

      path.removeAll()
      expect("")

      path.append("tmp")
      expect("tmp")
      path.append("cat")
      expect("tmp/cat")
      path.push("/")
      expect("/")

      path.append(".")
      expect("/.")
      XCTAssert(path.components.last!.kind == .currentDirectory)
      path.lexicallyNormalize()
      expect("/")

      path.append("..")
      expect("/..")
      XCTAssert(path.components.last!.kind == .parentDirectory)
      path.lexicallyNormalize()
      expect("/")

      path.append("foo")
      path.append("..")
      expect("/foo/..")
      path.lexicallyNormalize()
      expect("/")
    }

    restoreAfter {
      path.append("ls")
      expect("/usr/local/bin/ls")
      path.extension = "exe"
      expect("/usr/local/bin/ls.exe")
      path.extension = "txt"
      expect("/usr/local/bin/ls.txt")

      path.extension = nil
      expect("/usr/local/bin/ls")

      path.extension = ""
      expect("/usr/local/bin/ls.")
      XCTAssert(path.extension == "")
      path.extension = "txt"
      expect("/usr/local/bin/ls.txt")
    }

    restoreAfter {
      path.append("..")
      expect("/usr/local/bin/..")
      XCTAssert(path.components.last!.kind == .parentDirectory)
      path.extension = "txt"
      expect("/usr/local/bin/..")
      XCTAssert(path.components.last!.kind == .parentDirectory)
      path.removeAll()
      expect("")
      path.extension = "txt"
      expect("")
      path.append("/")
      expect("/")
      path.extension = "txt"
      expect("/")
    }

    restoreAfter {
      XCTAssert(!path.removePrefix("/usr/bin"))
      expect("/usr/local/bin")

      XCTAssert(!path.removePrefix("/us"))
      expect("/usr/local/bin")

      XCTAssert(path.removePrefix("/usr/local"))
      expect("bin")

      XCTAssert(path.removePrefix("bin"))
      expect("")
    }

    restoreAfter {
      path.append("utils/widget/")
      expect("/usr/local/bin/utils/widget")
      path.append("/bin///ls")
      expect("/usr/local/bin/utils/widget/bin/ls")
      path.push("/bin/ls")
      expect("/bin/ls")
      path.append("/")
      expect("/bin/ls")
      path.push("/")
      expect("/")

      path.append("tmp")
      expect("/tmp")
      path.append("foo/bar")
      expect("/tmp/foo/bar")
      XCTAssert(!path.isEmpty)

      path.append(FilePath.Component("baz"))
      expect("/tmp/foo/bar/baz")
      path.append("/")
      expect("/tmp/foo/bar/baz")
      path.removeAll()
      expect("")
      XCTAssert(path.isEmpty)
      path.append("")
      expect("")

      path.append("/bar/baz")
      expect("/bar/baz")
      path.removeAll()
      expect("")
      path.append(FilePath.Component("usr"))
      expect("usr")
      path.push("/bin/ls")
      expect("/bin/ls")
      path.removeAll()
      expect("")

      path.append("bar/baz")
      expect("bar/baz")

      path.append(["a", "b", "c"])
      expect("bar/baz/a/b/c")

      path.removeAll()
      expect("")
      path.append(["a", "b", "c"])
      expect("a/b/c")
    }

    restoreAfter {
      expect("/usr/local/bin")
      path.push("bar/baz")
      expect("/usr/local/bin/bar/baz")
      path.push("/")
      expect("/")
      path.push("tmp")
      expect("/tmp")
      path.push("/dev/null")
      expect("/dev/null")
    }

    restoreAfter {
      let same = path.string
      path.reserveCapacity(0)
      expect(same)
      path.reserveCapacity(1000)
      expect(same)
    }

    restoreAfter {
      XCTAssert(path.lexicallyContains("usr"))
      XCTAssert(path.lexicallyContains("/usr"))
      XCTAssert(path.lexicallyContains("local/bin"))
#if !os(Windows)
      // On Windows, this is a relative path and is still contained
      XCTAssert(!path.lexicallyContains("/local/bin"))
#endif
      path.append("..")
      XCTAssert(!path.lexicallyContains("local/bin"))
      XCTAssert(path.lexicallyContains("local/bin/.."))
      expect("/usr/local/bin/..")
      XCTAssert(path.lexicallyContains("usr/local"))
      XCTAssert(path.lexicallyContains("usr/local/."))
    }

    restoreAfter {
      XCTAssert(path.lexicallyResolving("ls") == "/usr/local/bin/ls")
      XCTAssert(path.lexicallyResolving("/ls") == "/usr/local/bin/ls")
      XCTAssert(path.lexicallyResolving("../bin/ls") == nil)
      XCTAssert(path.lexicallyResolving("/../bin/ls") == nil)

      XCTAssert(path.lexicallyResolving("/../bin/../lib/target") == nil)
      XCTAssert(path.lexicallyResolving("./ls/../../lib/target") == nil)

      let staticContent: FilePath = "/var/www/my-website/static"
      let links: [FilePath] =
        ["index.html", "/assets/main.css", "../../../../etc/passwd"]
      let paths = links.map { staticContent.lexicallyResolving($0) }
      XCTAssert(paths == [
        "/var/www/my-website/static/index.html",
        "/var/www/my-website/static/assets/main.css",
        nil])

    }

    restoreAfter {
      path = "/tmp"
      let sub: FilePath = "foo/./bar/../baz/."
      for comp in sub.components.filter({ $0.kind != .currentDirectory }) {
        path.append(comp)
      }
      expect("/tmp/foo/bar/../baz")
    }

    restoreAfter {
      path = "/usr/bin"
      let binIdx = path.components.firstIndex(of: "bin")!
      path.components.insert("local", at: binIdx)
      expect("/usr/local/bin")
    }

    restoreAfter {
      path = "/./home/./username/scripts/./tree"
      let scriptIdx = path.components.lastIndex(of: "scripts")!
      path.components.insert("bin", at: scriptIdx)
      expect("/./home/./username/bin/scripts/./tree")

      path.components.removeAll { $0.kind == .currentDirectory }
      expect("/home/username/bin/scripts/tree")
    }

    restoreAfter {
      path = "/usr/bin"
      XCTAssert(path.removeLastComponent())
      expect("/usr")
      XCTAssert(path.removeLastComponent())
      expect("/")
      XCTAssertFalse(path.removeLastComponent())
      expect("/")
    }

    restoreAfter {
      path = ""
      path.append("/var/www/website")
      expect("/var/www/website")
      path.append("static/assets")
      expect("/var/www/website/static/assets")
      path.append("/main.css")
      expect("/var/www/website/static/assets/main.css")

    }
  }

  func testFailableStringInitializers() {
    let invalidComps: Array<String> = [
      "", "/", "a/b",
    ]
    let invalidRoots: Array<String> = [
      "", "a", "a/b",
    ]
    for c in invalidComps {
      XCTAssertNil(FilePath.Component(c))
    }
    for c in invalidRoots {
      XCTAssertNil(FilePath.Root(c))
    }

    // Due to SE-0213, this is how you call he failable init explicitly,
    // otherwise it will be considered a literal `as` cast.
    XCTAssertNil(FilePath.Component.init("/"))
  }

  func testPartialWindowsRoots() {
    func partial(
      _ str: String,
      _ full: String,
      absolute: Bool = true,
      file: StaticString = #file, line: UInt = #line
    ) -> WindowsRootTestCase {
      WindowsRootTestCase(
        rootStr: str, expected: full, absolute: absolute,
        file: file, line: line)
    }
    func full(
      _ str: String, absolute: Bool = true,
      file: StaticString = #file, line: UInt = #line
    ) -> WindowsRootTestCase {
      partial(str, str, absolute: absolute,
              file: file, line: line)
    }

    // TODO: Some of these are kinda funky (like `\\` -> `\\\\`), but
    // I'm not aware of a sane fixup behavior here, so we go
    // with a lesser of insanes.
    let partialRootTestCases: [WindowsRootTestCase] = [
      // Full roots
      full(#"\"#, absolute: false),
      full(#"C:"#, absolute: false),
      full(#"C:\"#),

      // Full UNCs (with omitted fields)
      full(#"\\server\share\"#),
      full(#"\\server\\"#),
      full(#"\\\share\"#),
      full(#"\\\\"#),

      // Full device UNCs (with omitted fields)
      full(#"\\.\UNC\server\share\"#),
      full(#"\\.\UNC\server\\"#),
      full(#"\\.\UNC\\share\"#),
      full(#"\\.\UNC\\\"#),

      // Full device (with omitted fields)
      full(#"\\.\volume\"#),
      full(#"\\.\\"#),

      // Partial UNCs
      partial(#"\\server\share"#, #"\\server\share\"#),
      partial(#"\\server\"#, #"\\server\\"#),
      partial(#"\\server"#, #"\\server\\"#),
      partial(#"\\\\"#, #"\\\\"#),
      partial(#"\\\"#, #"\\\\"#),
      partial(#"\\"#, #"\\\\"#),

      // Partial device UNCs
      partial(#"\\.\UNC\server\share"#, #"\\.\UNC\server\share\"#),
      partial(#"\\.\UNC\server\"#, #"\\.\UNC\server\\"#),
      partial(#"\\.\UNC\server"#, #"\\.\UNC\server\\"#),
      partial(#"\\.\UNC\\\"#, #"\\.\UNC\\\"#),
      partial(#"\\.\UNC\\"#, #"\\.\UNC\\\"#),
      partial(#"\\.\UNC\"#, #"\\.\UNC\\\"#),
      partial(#"\\.\UNC"#, #"\\.\UNC\\\"#),

      // Partial device
      partial(#"\\.\volume"#, #"\\.\volume\"#),
      partial(#"\\.\"#, #"\\.\\"#),
      partial(#"\\."#, #"\\.\\"#),
    ]

    for partialRootTest in partialRootTestCases {
      partialRootTest.runAllTests()
    }


  }

}
