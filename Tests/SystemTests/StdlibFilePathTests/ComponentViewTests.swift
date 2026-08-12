/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Assertions go through the `expect*` helpers in TestSupport.swift. A test
// whose subject is one platform's syntax carries that platform's trait
// (`.windowsOnly` / `.darwinOnly`); a platform-independent test asserts
// through `universal(...)`, which spells an expected path in the built
// platform's separator so the test runs unchanged wherever it is built.

extension AllTests.ComponentViewTests {

  // MARK: - Basic collection properties

  @Test
  func emptyPath() {
    let path = _StdlibFilePath("")
    expectTrue(path.components.isEmpty)
    expectEqual(path.components.count, 0)
    expectEqual(path.components.startIndex, path.components.endIndex)
  }

  @Test
  func rootOnlyHasNoComponents() {
    let root = _StdlibFilePath("/")
    expectTrue(root.components.isEmpty)
    expectNotNil(root.anchor)
  }

  @Test(.windowsOnly)
  func rootOnlyHasNoComponentsWindows() {
    let winRoot = _StdlibFilePath(#"C:\"#)
    expectTrue(winRoot.components.isEmpty)
    expectNotNil(winRoot.anchor)
  }

  @Test
  func indexTraversal() {
    let path = _StdlibFilePath("/usr/local/bin")
    let cv = path.components
    expectEqual(cv.count, 3)

    var idx = cv.startIndex
    expectEqual(cv[idx].description, "usr")
    idx = cv.index(after: idx)
    expectEqual(cv[idx].description, "local")
    idx = cv.index(after: idx)
    expectEqual(cv[idx].description, "bin")
    idx = cv.index(after: idx)
    expectEqual(idx, cv.endIndex)

    // Reverse traversal
    idx = cv.index(before: cv.endIndex)
    expectEqual(cv[idx].description, "bin")
    idx = cv.index(before: idx)
    expectEqual(cv[idx].description, "local")
  }

  // MARK: - append

  @Test
  func appendToRelative() {
    var path = _StdlibFilePath("a/b")
    path.components.append("c")

    expectEqual(path.description, universal("a/b/c"))
    expectEqual(path.components.map(\.description), ["a", "b", "c"])
  }

  @Test
  func appendToAbsolute() {
    var path = _StdlibFilePath("/usr")
    path.components.append("local")

    expectEqual(path.description, universal("/usr/local"))
    expectEqual(path.anchor?.description, universal("/"))
  }

  @Test
  func appendToEmpty() {
    var path = _StdlibFilePath("")
    path.components.append("hello")

    expectEqual(path.description, "hello")
  }

  @Test
  func appendToRootOnly() {
    var path = _StdlibFilePath("/")
    path.components.append("usr")

    expectEqual(path.description, universal("/usr"))
    expectEqual(path.anchor?.description, universal("/"))
  }

  @Test
  func appendContentsOf() {
    var path = _StdlibFilePath("/usr")
    path.components.append(contentsOf: ["local", "bin"] as [_StdlibFilePath.Component])

    expectEqual(path.description, universal("/usr/local/bin"))
  }

  // MARK: - insert

  @Test
  func insertAtBeginning() {
    var path = _StdlibFilePath("/local/bin")
    path.components.insert("usr", at: path.components.idx(0))

    expectEqual(path.description, universal("/usr/local/bin"))
  }

  @Test
  func insertInMiddle() {
    var path = _StdlibFilePath("/usr/bin")
    path.components.insert("local", at: path.components.idx(1))

    expectEqual(path.description, universal("/usr/local/bin"))
  }

  @Test
  func insertAtEnd() {
    var path = _StdlibFilePath("/usr/local")
    path.components.insert("bin", at: path.components.endIndex)

    expectEqual(path.description, universal("/usr/local/bin"))
  }

  // MARK: - remove

  @Test
  func removeFirst() {
    var path = _StdlibFilePath("/usr/local/bin")
    path.components.removeFirst()

    expectEqual(path.description, universal("/local/bin"))
    expectEqual(path.anchor?.description, universal("/"))
  }

  @Test
  func removeLast() {
    var path = _StdlibFilePath("/usr/local/bin")
    path.components.removeLast()

    expectEqual(path.description, universal("/usr/local"))
  }

  @Test
  func removeAtIndex() {
    var path = _StdlibFilePath("/usr/local/bin")
    path.components.remove(at: path.components.idx(1))

    expectEqual(path.description, universal("/usr/bin"))
  }

  @Test
  func removeAllComponents() {
    var path = _StdlibFilePath("/usr/local")
    var cv = path.components
    cv.removeAll()
    path.components = cv

    // Anchor is preserved, components are gone
    expectEqual(path.description, universal("/"))
    expectEqual(path.anchor?.description, universal("/"))
    expectTrue(path.components.isEmpty)
  }

  @Test
  func removeAllFromRelative() {
    var path = _StdlibFilePath("a/b/c")
    path.components.removeAll()

    expectEqual(path.description, "")
    expectTrue(path.isEmpty)
  }

  // MARK: - replaceSubrange

  @Test
  func replaceMiddle() {
    var path = _StdlibFilePath("/usr/local/bin")
    path.components.replaceSubrange(
      path.components.range(1..<2),
      with: ["share", "man"] as [_StdlibFilePath.Component])

    expectEqual(path.description, universal("/usr/share/man/bin"))
  }

  @Test
  func replaceAll() {
    var path = _StdlibFilePath("/old/path")
    path.components.replaceSubrange(
      path.components.startIndex..<path.components.endIndex,
      with: ["new", "path"] as [_StdlibFilePath.Component])

    expectEqual(path.description, universal("/new/path"))
    expectEqual(path.anchor?.description, universal("/"))
  }

  @Test
  func replaceWithEmpty() {
    var path = _StdlibFilePath("/usr/local/bin")
    path.components.replaceSubrange(
      path.components.range(1..<3), with: [] as [_StdlibFilePath.Component])

    expectEqual(path.description, universal("/usr"))
  }

  @Test
  func replaceEmptyRange() {
    var path = _StdlibFilePath("/usr/bin")
    path.components.replaceSubrange(
      path.components.range(1..<1),
      with: ["local"] as [_StdlibFilePath.Component])

    expectEqual(path.description, universal("/usr/local/bin"))
  }

  // MARK: - Normalization interactions

  @Test
  func dotComponentInsertion() {
    // Component.init normalizes through _StdlibFilePath, so "." as a
    // single component is `.currentDirectory` kind
    let dot: _StdlibFilePath.Component = "."
    expectEqual(dot.kind, .currentDirectory)

    let dotdot: _StdlibFilePath.Component = ".."
    expectEqual(dotdot.kind, .parentDirectory)
  }

  @Test
  func appendDotDot() {
    var path = _StdlibFilePath("/usr/local")
    var cv = path.components
    cv.append("..")
    path.components = cv

    // ".." is preserved as a component (no lexical collapsing)
    expectEqual(path.components.map(\.description), ["usr", "local", ".."])
    expectEqual(path.description, universal("/usr/local/.."))
  }

  @Test
  func appendDotToRelative() {
    // With the view-on-storage architecture, appending a "." component
    // directly mutates storage without renormalization. The dot persists.
    var path = _StdlibFilePath("a/b")
    path.components.append(".")

    expectEqual(path.components.map(\.description), ["a", "b", "."])
    expectEqual(path.description, universal("a/b/."))
  }

  @Test
  func componentInitNormalizesInput() {
    // Component.init?(_:) goes through _StdlibFilePath, which normalizes.
    // So Component("a//b") is nil (normalizes to multi-component path)
    let str1: String = "a//b"
    let multiComp: _StdlibFilePath.Component? = .init(str1)
    expectNil(multiComp)
    let str2: String = "a/b"
    let withSlash: _StdlibFilePath.Component? = .init(str2)
    expectNil(withSlash)
    let str3: String = "/"
    let rootOnly: _StdlibFilePath.Component? = .init(str3)
    expectNil(rootOnly)
    let str4: String = ""
    let empty: _StdlibFilePath.Component? = .init(str4)
    expectNil(empty)
    let str5: String = "hello"
    let valid: _StdlibFilePath.Component? = .init(str5)
    expectNotNil(valid)
    expectEqual(valid?.description, "hello")
  }

  // MARK: - Windows platform

  @Test(.windowsOnly)
  func windowsAppend() {
    var path = _StdlibFilePath(#"C:\Users"#)
    path.components.append("Admin")

    expectEqual(path.description, #"C:\Users\Admin"#)
    expectEqual(path.anchor?.description, #"C:\"#)
  }

  @Test(.windowsOnly)
  func windowsDriveRelativeAppend() {
    var path = _StdlibFilePath("C:src")
    var cv = path.components
    cv.append("main.swift")
    path.components = cv

    // C: anchor (no backslash): components follow directly
    expectEqual(path.description, #"C:src\main.swift"#)
    expectEqual(path.anchor?.description, "C:")
  }

  @Test(.windowsOnly)
  func windowsRemoveComponent() {
    var path = _StdlibFilePath(#"C:\Users\Admin\file.txt"#)
    path.components.removeLast()

    expectEqual(path.description, #"C:\Users\Admin"#)
  }

  @Test(.windowsOnly)
  func windowsUNCAppend() {
    var path = _StdlibFilePath(#"\\server\share"#)
    path.components.append("folder")

    expectEqual(path.description, #"\\server\share\folder"#)
  }

  @Test(.windowsOnly)
  func windowsReplaceComponents() {
    var path = _StdlibFilePath(#"C:\old\stuff"#)
    path.components.replaceSubrange(
      path.components.startIndex..<path.components.endIndex,
      with: ["new", "things"] as [_StdlibFilePath.Component])

    expectEqual(path.description, #"C:\new\things"#)
  }

  // MARK: - Anchor preservation

  @Test
  func anchorSurvivesMutation() {
    var path = _StdlibFilePath("/usr/local/bin")
    let originalAnchor = path.anchor

    var cv = path.components
    cv.removeAll()
    cv.append("etc")
    path.components = cv

    expectEqual(path.anchor, originalAnchor)
    expectEqual(path.description, universal("/etc"))
  }

  @Test
  func noAnchorSurvivesMutation() {
    var path = _StdlibFilePath("a/b/c")

    var cv = path.components
    cv.replaceSubrange(cv.startIndex..<cv.endIndex, with: ["x", "y"] as [_StdlibFilePath.Component])
    path.components = cv

    expectNil(path.anchor)
    expectEqual(path.description, universal("x/y"))
  }

  @Test(.windowsOnly)
  func windowsAnchorSurvivesMutation() {
    var path = _StdlibFilePath(#"\\server\share\old\path"#)
    let originalAnchor = path.anchor

    var cv = path.components
    cv.removeAll()
    cv.append("new")
    path.components = cv

    expectEqual(path.anchor, originalAnchor)
    expectEqual(path.description, #"\\server\share\new"#)
  }

  // MARK: - Hashable / Equatable

  @Test
  func componentViewEquality() {
    let a = _StdlibFilePath("/usr/local/bin")
    let b = _StdlibFilePath("/usr/local/bin")
    expectEqual(a.components, b.components)

    let c = _StdlibFilePath("/usr/local")
    expectNotEqual(a.components, c.components)
  }

  @Test
  func componentViewOrdering() {
    let a = _StdlibFilePath("a/b").components
    let b = _StdlibFilePath("a/c").components
    let c = _StdlibFilePath("a/b/c").components
    expectTrue(a < b)
    expectTrue(a < c) // prefix is less
  }

  // MARK: - Derived Collection operations

  @Test
  func filter() {
    let path = _StdlibFilePath("a/b/c/d")
    let even = path.components.enumerated()
      .filter { $0.offset % 2 == 0 }
      .map(\.element)
    expectEqual(even.map(\.description), ["a", "c"])
  }

  @Test
  func map() {
    let path = _StdlibFilePath("/usr/local/bin")
    let names = path.components.map(\.description)
    expectEqual(names, ["usr", "local", "bin"])
  }

  @Test
  func reversed() {
    let path = _StdlibFilePath("a/b/c")
    let rev = path.components.reversed().map(\.description)
    expectEqual(rev, ["c", "b", "a"])
  }

  @Test
  func prefix() {
    var path = _StdlibFilePath("/usr/local/bin/tool")
    let first2 = Array(path.components.prefix(2))
    path.components.replaceSubrange(
      path.components.startIndex..<path.components.endIndex, with: first2)

    expectEqual(path.description, universal("/usr/local"))
  }

  @Test
  func dropFirst() {
    var path = _StdlibFilePath("/usr/local/bin")
    let tail = Array(path.components.dropFirst())
    path.components.replaceSubrange(
      path.components.startIndex..<path.components.endIndex, with: tail)

    expectEqual(path.description, universal("/local/bin"))
  }

  // MARK: - Round-trip through ComponentView init()

  @Test
  func buildFromScratch() {
    var cv = _StdlibFilePath.ComponentView()
    cv.append("usr")
    cv.append("local")
    cv.append("bin")

    var path = _StdlibFilePath("/")
    path.components = cv
    expectEqual(path.description, universal("/usr/local/bin"))
  }

  @Test
  func buildRelativeFromScratch() {
    var cv = _StdlibFilePath.ComponentView()
    cv.append("src")
    cv.append("main.swift")

    var path = _StdlibFilePath()
    path.components = cv
    expectEqual(path.description, universal("src/main.swift"))
  }

  @Test(.windowsOnly)
  func windowsBuildFromScratch() {
    var cv = _StdlibFilePath.ComponentView()
    cv.append("Users")
    cv.append("Admin")
    cv.append("Documents")

    var path = _StdlibFilePath(#"C:\"#)
    path.components = cv
    expectEqual(path.description, #"C:\Users\Admin\Documents"#)
  }

  // MARK: - Edge cases

  @Test
  func singleComponentPath() {
    var path = _StdlibFilePath("hello")
    expectEqual(path.components.count, 1)
    expectEqual(path.components.first?.description, "hello")

    path.components.removeLast()
    expectTrue(path.isEmpty)
  }

  @Test
  func multipleAppends() {
    var path = _StdlibFilePath("/")

    for name: String in ["a", "b", "c", "d", "e"] {
      path.components.append(_StdlibFilePath.Component(name)!)
    }

    expectEqual(path.components.count, 5)
    expectEqual(path.description, universal("/a/b/c/d/e"))
  }

  @Test
  func replaceEntireRelativeKeepsAnchor() {
    var path = _StdlibFilePath("/old/path/here")
    let anchor = path.anchor

    path.components.replaceSubrange(
      path.components.startIndex..<path.components.endIndex, with: [
        "completely" as _StdlibFilePath.Component,
        "new" as _StdlibFilePath.Component,
      ])

    expectEqual(path.anchor, anchor)
    expectEqual(path.components.map(\.description), ["completely", "new"])
  }

  // MARK: - Suffix semantics on mutation

  // -- Trailing separator: strip on remove/replace --

  @Test
  func trailingSepStrippedOnRemoveLast() {
    var path = _StdlibFilePath("a/b/c/")
    expectTrue(path.hasTrailingSeparator)

    path.components.removeLast()

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("a/b"))
  }

  @Test
  func trailingSepStrippedOnReplaceLast() {
    var path = _StdlibFilePath("a/b/c/")
    expectTrue(path.hasTrailingSeparator)

    path.components.replaceSubrange(
      path.components.index(before: path.components.endIndex) ..< path.components.endIndex,
      with: ["d" as _StdlibFilePath.Component])

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("a/b/d"))
  }

  @Test
  func trailingSepStrippedOnRemoveAll() {
    var path = _StdlibFilePath("a/b/c/")
    expectTrue(path.hasTrailingSeparator)

    path.components.removeAll()

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, "")
  }

  @Test
  func trailingSepStrippedOnRemoveAllAbsolute() {
    var path = _StdlibFilePath("/a/b/c/")
    expectTrue(path.hasTrailingSeparator)

    path.components.removeAll()

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("/"))
  }

  @Test(.windowsOnly)
  func windowsTrailingSepStrippedOnRemoveLast() {
    var path = _StdlibFilePath(#"C:\Users\Admin\"#)
    expectTrue(path.hasTrailingSeparator)

    path.components.removeLast()

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, #"C:\Users"#)
  }

  // -- Trailing separator: preserve when last unchanged --

  @Test
  func trailingSepPreservedOnInsertFirst() {
    var path = _StdlibFilePath("a/b/c/")
    expectTrue(path.hasTrailingSeparator)

    path.components.insert("z", at: path.components.idx(0))

    expectTrue(path.hasTrailingSeparator)
    expectEqual(path.description, universal("z/a/b/c/"))
  }

  @Test
  func trailingSepPreservedOnReplaceNonLast() {
    var path = _StdlibFilePath("a/b/c/")

    path.components.replaceSubrange(
      path.components.range(0..<1),
      with: ["x" as _StdlibFilePath.Component])

    expectTrue(path.hasTrailingSeparator)
    expectEqual(path.description, universal("x/b/c/"))
  }

  @Test
  func trailingSepPreservedOnRemoveFirst() {
    var path = _StdlibFilePath("a/b/c/")

    path.components.removeFirst()

    expectTrue(path.hasTrailingSeparator)
    expectEqual(path.description, universal("b/c/"))
  }

  @Test
  func trailingSepPreservedOnInsertMiddle() {
    var path = _StdlibFilePath("/a/c/")

    path.components.insert("b", at: path.components.idx(1))

    expectTrue(path.hasTrailingSeparator)
    expectEqual(path.description, universal("/a/b/c/"))
  }

  @Test
  func trailingSepPreservedOnNoChange() {
    var path = _StdlibFilePath("a/b/c/")
    let cv = path.components
    path.components = cv

    expectTrue(path.hasTrailingSeparator)
    expectEqual(path.description, universal("a/b/c/"))
  }

  @Test(.windowsOnly)
  func trailingSepPreservedEmptyToEmpty() {
    // \\server\share\ decomposes with empty components and
    // trailing sep. Setting empty components back preserves it.
    var path = _StdlibFilePath(#"\\server\share\"#)
    expectTrue(path.hasTrailingSeparator)
    expectTrue(path.components.isEmpty)

    let cv = path.components
    path.components = cv

    expectTrue(path.hasTrailingSeparator)
  }

  // -- Trailing separator: strip on append --

  @Test
  func trailingSepOnAppend() {
    var path = _StdlibFilePath("a/b/")
    expectTrue(path.hasTrailingSeparator)

    path.components.append("c")

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("a/b/c"))
  }

  @Test
  func trailingSepOnAppendContentsOf() {
    var path = _StdlibFilePath("/dir/")
    expectTrue(path.hasTrailingSeparator)

    path.components.append(contentsOf: ["sub", "file"] as [_StdlibFilePath.Component])

    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("/dir/sub/file"))
  }

  // -- Resource fork: strip on remove/replace (Darwin) --

  @Test(.darwinOnly)
  func resourceForkStrippedOnRemoveLast() {
    var path = _StdlibFilePath("/dir/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["dir", "file"])

    path.components.removeLast()

    expectFalse(path.isResourceFork)
    expectEqual(path.description, "/dir")
  }

  @Test(.darwinOnly)
  func resourceForkStrippedOnReplaceLast() {
    var path = _StdlibFilePath("/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["file"])

    path.components.replaceSubrange(
      path.components.range(0..<1),
      with: ["other" as _StdlibFilePath.Component])

    expectFalse(path.isResourceFork)
    expectEqual(path.description, "/other")
  }

  @Test(.darwinOnly)
  func resourceForkStrippedOnRemoveAll() {
    var path = _StdlibFilePath("/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)

    path.components.removeAll()

    expectFalse(path.isResourceFork)
    expectEqual(path.description, "/")
  }

  // -- Resource fork: preserve when last unchanged --

  @Test(.darwinOnly)
  func resourceForkPreservedOnInsert() {
    var path = _StdlibFilePath("/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["file"])

    path.components.insert("dir", at: path.components.idx(0))

    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["dir", "file"])
  }

  @Test(.darwinOnly)
  func resourceForkPreservedOnNoChange() {
    var path = _StdlibFilePath("/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)

    let cv = path.components
    path.components = cv

    expectTrue(path.isResourceFork)
  }

  // -- Resource fork: strip on append --

  @Test(.darwinOnly)
  func resourceForkOnAppend() {
    var path = _StdlibFilePath("/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)

    path.components.append("extra")

    expectFalse(path.isResourceFork)
    expectEqual(path.description, "/file/extra")
  }

  // MARK: - Re-decomposition after component mutation
  //
  // When a component mutation produces a string that re-parses to a
  // different decomposition (e.g. inserting `.nofollow` at the front
  // of an absolute Darwin path causes anchor absorption), we honor
  // the new decomposition rather than masking it. The string is what
  // the kernel sees; pretending otherwise would be a lie.

  // MARK: - Structural suffix rule corner cases

  @Test
  func trailingSepStrippedOnRemoveLastEvenWithEqualNeighbor() {
    var path = _StdlibFilePath("/a/b/b/")
    path.components.removeLast()
    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("/a/b"))
  }

  @Test
  func replaceAllDropsSuffixEvenWhenLastByteEqual() {
    var path = _StdlibFilePath("/a/b/c/")
    path.components.replaceSubrange(
      path.components.startIndex..<path.components.endIndex,
      with: ["x", "y", "c"] as [_StdlibFilePath.Component])
    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, universal("/x/y/c"))
  }

  @Test(.windowsOnly)
  func removeAllOnUNCDropsGapSeparator() {
    var path = _StdlibFilePath(#"\\server\share\"#)
    expectTrue(path.hasTrailingSeparator)
    path.components.removeAll()
    expectFalse(path.hasTrailingSeparator)
    expectEqual(path.description, #"\\server\share"#)
  }

  // MARK: - removeAll across all anchor shapes
  //
  // The view region for removeAll extends from anchor-end (before any gap
  // separator) to end-of-storage. These cases exercise the four anchor
  // shapes: anchor-includes-trailing-sep, anchor-ends-with-`:`, anchor-
  // with-gap-sep, and verbatim variants of the same.

  @Test(.windowsOnly)
  func removeAllUNCWithComponentsDropsGapSep() {
    var path = _StdlibFilePath(#"\\server\share\foo\bar"#)
    expectEqual(path.components.map(\.description), ["foo", "bar"])
    path.components.removeAll()
    expectEqual(path.description, #"\\server\share"#)
    expectFalse(path.hasTrailingSeparator)
  }

  @Test(.windowsOnly)
  func removeAllDriveAbsoluteKeepsAnchorSep() {
    var path = _StdlibFilePath(#"C:\foo\bar"#)
    path.components.removeAll()
    expectEqual(path.description, #"C:\"#)
  }

  @Test(.windowsOnly)
  func removeAllDriveRelativeKeepsColon() {
    var path = _StdlibFilePath(#"C:foo\bar"#)
    path.components.removeAll()
    expectEqual(path.description, "C:")
  }

  @Test(.windowsOnly)
  func removeAllVerbatimDriveKeepsAnchor() {
    var path = _StdlibFilePath(#"\\?\C:\foo\bar"#)
    path.components.removeAll()
    expectEqual(path.description, #"\\?\C:\"#)
  }

  @Test(.windowsOnly)
  func removeAllVerbatimUNCDropsGapSep() {
    var path = _StdlibFilePath(#"\\?\UNC\server\share\foo"#)
    path.components.removeAll()
    expectEqual(path.description, #"\\?\UNC\server\share"#)
  }

  @Test(.windowsOnly)
  func removeAllVerbatimDeviceDropsGapSep() {
    var path = _StdlibFilePath(#"\\?\name\foo"#)
    path.components.removeAll()
    expectEqual(path.description, #"\\?\name"#)
  }

  // MARK: - Colon-ending anchors: Windows drive-relative vs Darwin volfs
  //
  // The `:` is the anchor/component boundary only on Windows
  // (drive-relative `C:foo`). On Darwin, `:` is a regular byte that can
  // appear in a volfs FILEID, so an anchor ending in `:` still needs a
  // gap separator before any component bytes.

  @Test(.windowsOnly)
  func windowsDriveRelativeAppendStaysDriveRelative() {
    // Appending to `C:` must yield `C:foo`, not `C:\foo` (which would
    // be drive-absolute, a different anchor shape).
    var path = _StdlibFilePath("C:")
    expectEqual(path.anchor?.description, "C:")
    path.components.append("foo")
    expectEqual(path.description, "C:foo")
    expectEqual(path.anchor?.description, "C:")
    expectEqual(path.components.map(\.description), ["foo"])
  }

  @Test(.windowsOnly)
  func windowsDriveRelativeMultiAppendStaysDriveRelative() {
    var path = _StdlibFilePath("C:")
    path.components.append("foo")
    path.components.append("bar")
    expectEqual(path.description, #"C:foo\bar"#)
    expectEqual(path.anchor?.description, "C:")
  }

  @Test(.windowsOnly)
  func windowsDriveRelativeAssignKeepsAnchor() {
    var path = _StdlibFilePath("C:")
    var cv = _StdlibFilePath.ComponentView()
    cv.append("foo")
    path.components = cv
    expectEqual(path.description, "C:foo")
    expectEqual(path.anchor?.description, "C:")
  }

  @Test(.darwinOnly)
  func darwinVolfsColonInFileIdGetsGapSeparator() {
    // Darwin volfs FILEID is "bytes up to next /". A FILEID ending in
    // `:` is degenerate but legal. Adding a component must add a gap
    // separator. The `:`-skips-gap-sep rule is Windows-specific.
    var path = _StdlibFilePath("/.vol/12345/67890:")
    expectEqual(path.anchor?.description, "/.vol/12345/67890:")
    path.components.append("foo")
    expectEqual(path.description, "/.vol/12345/67890:/foo")
    expectEqual(path.anchor?.description, "/.vol/12345/67890:")
    expectEqual(path.components.map(\.description), ["foo"])
  }

  @Test(.darwinOnly)
  func darwinVolfsColonAssignKeepsAnchor() {
    var path = _StdlibFilePath("/.vol/12345/67890:")
    var cv = _StdlibFilePath.ComponentView()
    cv.append("foo")
    path.components = cv
    expectEqual(path.description, "/.vol/12345/67890:/foo")
    expectEqual(path.anchor?.description, "/.vol/12345/67890:")
  }

  @Test(.windowsOnly)
  func windowsUNCWithColonShareGetsGapSeparator() {
    // The UNC parser allows `:` in share names: `\\server\C:` parses
    // as anchor `\\server\C:` (length 11), not drive-relative. The
    // gap separator must be added on append.
    var path = _StdlibFilePath(#"\\server\C:"#)
    expectEqual(path.anchor?.description, #"\\server\C:"#)
    path.components.append("foo")
    expectEqual(path.description, #"\\server\C:\foo"#)
    expectEqual(path.anchor?.description, #"\\server\C:"#)
  }

  @Test(.windowsOnly)
  func windowsUNCWithColonShareAssignKeepsGap() {
    var path = _StdlibFilePath(#"\\server\C:"#)
    var cv = _StdlibFilePath.ComponentView()
    cv.append("foo")
    path.components = cv
    expectEqual(path.description, #"\\server\C:\foo"#)
  }

  // MARK: - Suffix interactions with splice

  @Test
  func appendAfterTrailingSepAbsorbs() {
    var path = _StdlibFilePath("/foo/")
    expectTrue(path.hasTrailingSeparator)
    path.components.append("bar")
    expectEqual(path.description, universal("/foo/bar"))
    expectFalse(path.hasTrailingSeparator)
  }

  @Test
  func replaceSubrangeLastWithEmptyMatchesRemoveLast() {
    var path = _StdlibFilePath("/a/b/c")
    let last = path.components.index(before: path.components.endIndex)
    path.components.replaceSubrange(last..<path.components.endIndex, with: [])
    expectEqual(path.description, universal("/a/b"))
  }

  @Test(.darwinOnly)
  func insertInteriorPreservesResourceFork() {
    // Insert in the middle of a multi-component path that has a
    // resource fork suffix. Middle insert is not touchesEnd, so the
    // suffix region is untouched.
    var path = _StdlibFilePath("/foo/bar/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["foo", "bar"])
    let afterFoo = path.components.index(after: path.components.startIndex)
    path.components.insert("x", at: afterFoo)
    expectEqual(path.description, "/foo/x/bar/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["foo", "x", "bar"])
  }

  // MARK: - Cross-anchor assignment
  //
  // Property assignment splices newValue's contributed bytes
  // (`[_originalStart, _suffixEnd)`) into self's post-anchor region.
  // Self's anchor stays put; the new contribution becomes the
  // components+suffix.

  @Test(.windowsOnly)
  func assignDifferentAnchorCvKeepsSelfAnchor() {
    // cv from a path with a different anchor. Only cv's components
    // (the bytes after cv's original anchor) get spliced; self's
    // anchor is preserved.
    var path = _StdlibFilePath(#"\foo"#)
    let cv = _StdlibFilePath(#"C:\bar"#).components
    path.components = cv
    expectEqual(path.description, #"\bar"#)
  }

  @Test
  func assignAnchoredCvOntoAnchorlessKeepsAnchorless() {
    // cv has anchor, self doesn't. Splice copies only cv's component
    // bytes; self stays anchorless.
    var path = _StdlibFilePath("a/b")
    let cv = _StdlibFilePath("/foo").components
    path.components = cv
    expectEqual(path.description, "foo")
  }

  @Test(.darwinOnly)
  func absorptionThenAssignMatchesInPlace() {
    // cv mutated to trigger anchor absorption, then assigned back.
    // The splice uses cv's _originalStart (immutable since view
    // creation), so the absorbed bytes are part of the spliced region.
    // Result must match in-place mutation.

    var inPlace = _StdlibFilePath("/foo/bar")
    inPlace.components.insert(".nofollow", at: inPlace.components.startIndex)
    expectEqual(inPlace.description, "/.nofollow/foo/bar")

    var assigned = _StdlibFilePath("/foo/bar")
    var cv = assigned.components
    cv.insert(".nofollow", at: cv.startIndex)
    assigned.components = cv

    expectEqual(assigned.description, inPlace.description)
  }

  // -- Darwin anchor hazards --

  @Test(.darwinOnly)
  func darwinInsertNofollowAtFront() {
    // /foo/bar -> insert ".nofollow" at 0 -> /.nofollow/foo/bar.
    // Darwin anchor parsing absorbs "/.nofollow/" into the anchor,
    // so the post-mutation decomposition reflects the kernel's view
    // rather than the caller's per-component intent.
    var path = _StdlibFilePath("/foo/bar")
    expectEqual(path.anchor?.description, "/")

    var cv = path.components
    cv.insert(".nofollow", at: cv.idx(0))
    path.components = cv

    expectEqual(path.description, "/.nofollow/foo/bar")
    expectEqual(path.anchor?.description, "/.nofollow/")
    expectEqual(path.components.map(\.description), ["foo", "bar"])
  }

  @Test(.darwinOnly)
  func darwinInsertResolveAtFront() {
    // /usr/bin -> insert ".resolve" at 0
    // Then "usr" looks like the resolve flag value: /.resolve/usr/bin
    var path = _StdlibFilePath("/usr/bin")

    var cv = path.components
    cv.insert(".resolve", at: cv.idx(0))
    path.components = cv

    expectEqual(path.description, "/.resolve/usr/bin")

    // Reparse: /.resolve/usr/ is the anchor (flag value = "usr")
    let newAnchor = path.anchor?.description
    let newComps = path.components.map(\.description)
    expectEqual(newAnchor, "/.resolve/usr/")
    expectEqual(newComps, ["bin"])
  }

  @Test(.darwinOnly)
  func darwinInsertVolAtFront() {
    // /1234/5678/file -> insert ".vol" at 0
    // Becomes /.vol/1234/5678/file, with /.vol/1234/5678 absorbed as the anchor
    var path = _StdlibFilePath("/1234/5678/file")

    var cv = path.components
    cv.insert(".vol", at: cv.idx(0))
    path.components = cv

    expectEqual(path.description, "/.vol/1234/5678/file")

    let newAnchor = path.anchor?.description
    let newComps = path.components.map(\.description)
    expectEqual(newAnchor, "/.vol/1234/5678")
    expectEqual(newComps, ["file"])
  }

  @Test(.darwinOnly)
  func darwinAppendsFormCombinedAnchor() {
    // Starting from a `/.nofollow/` anchor, appending `.vol`, FSID, and
    // FILEID one at a time. The first two appends leave them as plain
    // components (the vol parser fails on the incomplete form). The third
    // append completes a parsable `.vol/FSID/FILEID` and triggers absorption:
    // the combined anchor `/.nofollow/.vol/N/M` forms and the components
    // collapse to empty, since a Darwin anchor may include resolve flags
    // and/or a volume identifier.
    var path = _StdlibFilePath("/.nofollow/")
    expectEqual(path.anchor?.description, "/.nofollow/")
    expectEqual(path.components.map(\.description), [])

    path.components.append(".vol")
    expectEqual(path.anchor?.description, "/.nofollow/")
    expectEqual(path.components.map(\.description), [".vol"])

    path.components.append("1234")
    expectEqual(path.anchor?.description, "/.nofollow/")
    expectEqual(path.components.map(\.description), [".vol", "1234"])

    path.components.append("5678")
    // Absorption: components fold into the combined anchor.
    expectEqual(path.anchor?.description, "/.nofollow/.vol/1234/5678")
    expectEqual(path.components.map(\.description), [])
  }

  @Test(.darwinOnly)
  func darwinRemoveLastFromCombinedAnchorStaysWithLeading() {
    // Removing the only component of a combined-anchor path leaves the
    // anchor + gap separator. Same shape as UNC `\\server\share\only` ->
    // `\\server\share\`: the gap separator becomes the trailing separator,
    // anchor stays intact, components empty.
    var path = _StdlibFilePath("/.nofollow/.vol/1234/5678/foo")
    expectEqual(path.anchor?.description, "/.nofollow/.vol/1234/5678")
    expectEqual(path.components.map(\.description), ["foo"])

    path.components.removeLast()

    expectEqual(path.description, "/.nofollow/.vol/1234/5678/")
    expectEqual(path.anchor?.description, "/.nofollow/.vol/1234/5678")
    expectEqual(path.components.map(\.description), [])
    expectTrue(path.hasTrailingSeparator)
  }

  @Test(.darwinOnly)
  func darwinRemoveComponentExposesAnchor() {
    // Reverse direction: remove first component to reveal anchor structure.
    // /prefix/.nofollow/foo -> remove "prefix" -> /.nofollow/foo
    var path = _StdlibFilePath("/prefix/.nofollow/foo")
    expectEqual(path.anchor?.description, "/")
    expectEqual(path.components.map(\.description), ["prefix", ".nofollow", "foo"])

    var cv = path.components
    cv.removeFirst()
    path.components = cv

    expectEqual(path.description, "/.nofollow/foo")

    let newAnchor = path.anchor?.description
    let newComps = path.components.map(\.description)
    expectEqual(newAnchor, "/.nofollow/")
    expectEqual(newComps, ["foo"])
  }

  @Test(.darwinOnly)
  func darwinReplaceFirstExposesVol() {
    // Replace first component to create .vol anchor
    // /old/1234/5678 -> replace "old" with ".vol" -> /.vol/1234/5678
    var path = _StdlibFilePath("/old/1234/5678")
    expectEqual(path.components.count, 3)

    var cv = path.components
    cv.replaceSubrange(cv.range(0..<1), with: [".vol" as _StdlibFilePath.Component])
    path.components = cv

    expectEqual(path.description, "/.vol/1234/5678")

    let newAnchor = path.anchor?.description
    let newComps = path.components.map(\.description)
    expectEqual(newAnchor, "/.vol/1234/5678")
    expectEqual(newComps, [])
  }

  @Test(.darwinOnly)
  func darwinNofollowOnRelativePathIsSafe() {
    // .nofollow only triggers anchor parsing on absolute paths
    var path = _StdlibFilePath("a/b")
    var cv = path.components
    cv.insert(".nofollow", at: cv.idx(0))
    path.components = cv

    // No root, so .nofollow is just a regular component
    expectNil(path.anchor)
    expectEqual(path.components.map(\.description), [".nofollow", "a", "b"])
    expectEqual(path.description, ".nofollow/a/b")
  }

  @Test(.darwinOnly)
  func darwinNofollowNotFirstIsSafe() {
    // .nofollow only triggers when it's the path-initial dot component
    var path = _StdlibFilePath("/usr/bin")
    var cv = path.components
    cv.append(".nofollow")
    path.components = cv

    // .nofollow at end doesn't affect the anchor
    expectEqual(path.anchor?.description, "/")
    expectEqual(path.components.map(\.description), ["usr", "bin", ".nofollow"])
  }

  // -- Darwin resource fork hazards --

  @Test(.darwinOnly)
  func darwinAppendCreatesResourceFork() {
    // Appending "rsrc" after a component named "..namedfork" produces
    // a path whose tail matches the /..namedfork/rsrc suffix pattern.
    var path = _StdlibFilePath("/file/..namedfork")
    expectFalse(path.isResourceFork)

    var cv = path.components
    cv.append("rsrc")
    path.components = cv

    expectEqual(path.description, "/file/..namedfork/rsrc")

    // Reparse sees the resource fork suffix
    expectTrue(path.isResourceFork)
    // The components no longer include ..namedfork and rsrc
    let newComps = path.components.map(\.description)
    expectEqual(newComps, ["file"])
  }

  @Test(.darwinOnly)
  func darwinInsertBeforeRsrcBreaksSuffix() {
    // Inserting between "..namedfork" and "rsrc" breaks the suffix pattern
    var path = _StdlibFilePath("/file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["file"])

    var cv = path.components
    cv.append("oops")
    path.components = cv

    // The setter preserves isResourceFork=false (trailing sep context)
    // but reconstruction from decomposed form doesn't auto-add the suffix.
    // This case is tricky: the original decomposition stripped the suffix,
    // so we only have ["file"] + the new component, no resource fork.
    expectEqual(path.components.map(\.description), ["file", "oops"])
    expectFalse(path.isResourceFork)
  }

  @Test(.darwinOnly)
  func darwinRemoveLastCreatesResourceFork() {
    // /dir/file/..namedfork/rsrc/extra: the suffix doesn't match because
    // of trailing content. Removing "extra" exposes the suffix.
    var path = _StdlibFilePath("/dir/file/..namedfork/rsrc/extra")
    expectFalse(path.isResourceFork)
    expectEqual(path.components.map(\.description), [
      "dir", "file", "..namedfork", "rsrc", "extra",
    ])

    var cv = path.components
    cv.removeLast()
    path.components = cv

    expectEqual(path.description, "/dir/file/..namedfork/rsrc")

    // Reparse now sees the resource fork suffix
    expectTrue(path.isResourceFork)
    let newComps = path.components.map(\.description)
    expectEqual(newComps, ["dir", "file"])
  }

  @Test(.darwinOnly)
  func darwinReplaceCreatesResourceFork() {
    // Replace last component with "rsrc" when penultimate is "..namedfork"
    var path = _StdlibFilePath("/data/..namedfork/icon")
    expectFalse(path.isResourceFork)

    var cv = path.components
    cv.replaceSubrange(cv.index(before: cv.endIndex) ..< cv.endIndex,
                       with: ["rsrc" as _StdlibFilePath.Component])
    path.components = cv

    expectEqual(path.description, "/data/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["data"])
  }

  @Test(.darwinOnly)
  func darwinResourceForkOnRelativeIsSafe() {
    // Resource fork suffix works on relative paths too
    var path = _StdlibFilePath("file/..namedfork")
    var cv = path.components
    cv.append("rsrc")
    path.components = cv

    expectEqual(path.description, "file/..namedfork/rsrc")
    expectTrue(path.isResourceFork)
    expectEqual(path.components.map(\.description), ["file"])
  }

  // -- Windows reparse hazards --

  @Test(.windowsOnly)
  func windowsRemoveExposesRootBackslash() {
    // \\server\share\only -> remove "only" -> \\server\share\
    // The trailing separator now belongs to the UNC anchor.
    var path = _StdlibFilePath(#"\\server\share\only"#)
    expectEqual(path.anchor?.description, #"\\server\share"#)
    expectEqual(path.components.map(\.description), ["only"])

    var cv = path.components
    cv.removeLast()
    path.components = cv

    // With no components, the anchor stands alone
    expectEqual(path.anchor?.description, #"\\server\share"#)
    expectTrue(path.components.isEmpty)
    expectTrue(path.hasTrailingSeparator)
  }

  @Test(.windowsOnly)
  func windowsVerbatimDotPreserved() {
    // In verbatim paths (\\?\), dot and dotdot are regular components.
    // Appending "." to a verbatim path is not treated as currentDirectory.
    var path = _StdlibFilePath(#"\\?\C:\dir"#)
    var cv = path.components
    cv.append(".")
    path.components = cv

    expectEqual(path.description, #"\\?\C:\dir\."#)
    // In verbatim context the "." is a regular component name
    let lastComp = path.components.last!
    expectEqual(lastComp.kind, .regular)
  }

  @Test(.windowsOnly)
  func windowsVerbatimDotDotPreserved() {
    // Similarly, ".." in verbatim paths is just a literal name
    var path = _StdlibFilePath(#"\\?\C:\dir"#)
    var cv = path.components
    cv.append("..")
    path.components = cv

    expectEqual(path.description, #"\\?\C:\dir\.."#)
    let lastComp = path.components.last!
    expectEqual(lastComp.kind, .regular)
  }

  @Test(.windowsOnly)
  func windowsDevicePathAppend() {
    // \\.\device paths: appending to a device-only path
    var path = _StdlibFilePath(#"\\.\COM1"#)
    var cv = path.components
    cv.append("extra")
    path.components = cv

    expectEqual(path.description, #"\\.\COM1\extra"#)
    expectEqual(path.components.map(\.description), ["extra"])
  }
}
