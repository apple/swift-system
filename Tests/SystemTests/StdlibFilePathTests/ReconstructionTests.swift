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

// Reconstruction and the suffix/anchor setters, driven directly with
// caller-built parts rather than as the round-trip tail of a decomposition
// (which is what DecompositionTests.runCase covers). Expectations from
// SE-0529:
//   * "Path reconstruction": `init(anchor:_:hasTrailingSeparator:)` and the
//     Darwin `init(anchor:_:resourceFork:)`. The reconstructed path "parses
//     and normalizes exactly as if the equivalent string literal had been
//     provided."
//   * "Trailing separators": `hasTrailingSeparator` get/set,
//     `withTrailingSeparator()`, `withoutTrailingSeparator()`.
//   * "Resource forks": `isResourceFork` get/set, `withResourceFork()`,
//     `withoutResourceFork()`, and the documented trailing-separator to
//     resource-fork swap.
//   * `anchor` get/set.

extension AllTests.ReconstructionTests {

  // Build component arrays inside the active platform (Component init consults
  // the platform for its separator check).
  private func comps(_ names: String...) -> [_StdlibFilePath.Component] {
    names.map { _StdlibFilePath.Component($0)! }
  }

  // MARK: - init(anchor:_:hasTrailingSeparator:)

  @Test
  func reconstructRelativeNilAnchor() {
    let p = _StdlibFilePath(anchor: nil, comps("foo", "bar"))
    expectEqual(p.description, universal("foo/bar"), "relative reconstruction")
    expectNil(p.anchor, "nil anchor stays relative")
    expectEqual(p.components.map(\.description), ["foo", "bar"])
  }

  @Test
  func reconstructBasicRoot() {
    // The basic-root anchor: `/` on unix, `\` on Windows after slash
    // conversion. Use `universal()` to express the platform-varying spelling.
    let p = _StdlibFilePath(anchor: _StdlibFilePath.Anchor("/"), comps("foo", "bar"))
    expectEqual(p.description, universal("/foo/bar"),
      "basic-root reconstruction")
    expectEqual(p.anchor?.description, universal("/"),
      "anchor is the basic root")
    expectEqual(p.components.map(\.description), ["foo", "bar"])
  }

  @Test(.windowsOnly)
  func reconstructWindowsDriveAbsolute() {
    let p = _StdlibFilePath(anchor: _StdlibFilePath.Anchor(#"C:\"#), comps("foo", "bar"))
    // Anchor ends in a separator, so no gap separator is inserted.
    expectEqual(p.description, #"C:\foo\bar"#, "C:\\ reconstruction")
    expectTrue(p.anchor?.description == #"C:\"#, "anchor is C:\\")
  }

  @Test(.windowsOnly)
  func reconstructWindowsDriveRelative() {
    let p = _StdlibFilePath(anchor: _StdlibFilePath.Anchor("C:"), comps("foo", "bar"))
    // Drive-relative `C:`: the colon is the boundary, so no gap separator,
    // `C:foo\bar`, not `C:\foo\bar` (which is a different anchor).
    expectEqual(p.description, #"C:foo\bar"#, "C: (drive-relative) reconstruction")
    expectTrue(p.anchor?.description == "C:", "anchor is C:")
    expectFalse(p.isAbsolute, "C:foo\\bar is relative")
  }

  @Test(.darwinOnly)
  func reconstructDarwinNofollow() {
    let p = _StdlibFilePath(anchor: _StdlibFilePath.Anchor("/.nofollow/"), comps("foo", "bar"))
    expectEqual(p.description, "/.nofollow/foo/bar", "/.nofollow/ reconstruction")
    expectTrue(p.anchor?.description == "/.nofollow/", "anchor is /.nofollow/")
    expectEqual(p.components.map(\.description), ["foo", "bar"])
  }

  @Test
  func reconstructTrailingSeparatorFlag() {
    let withSep = _StdlibFilePath(
      anchor: _StdlibFilePath.Anchor("/"), comps("foo"), hasTrailingSeparator: true)
    expectEqual(withSep.description, universal("/foo/"),
      "hasTrailingSeparator: true")
    expectTrue(withSep.hasTrailingSeparator, "trailing separator present")

    let noSep = _StdlibFilePath(
      anchor: _StdlibFilePath.Anchor("/"), comps("foo"), hasTrailingSeparator: false)
    expectEqual(noSep.description, universal("/foo"),
      "hasTrailingSeparator: false")
    expectFalse(noSep.hasTrailingSeparator, "no trailing separator")
  }

  @Test
  func reconstructEmptyComponentsWithAnchor() {
    let root = _StdlibFilePath(anchor: _StdlibFilePath.Anchor("/"), [] as [_StdlibFilePath.Component])
    expectEqual(root.description, universal("/"), "anchor-only basic root")
    expectTrue(root.components.isEmpty, "no components")

    withPlatform(.windows) {
      let drive = _StdlibFilePath(anchor: _StdlibFilePath.Anchor(#"C:\"#), [] as [_StdlibFilePath.Component])
      expectEqual(drive.description, #"C:\"#, "anchor-only C:\\")
      expectTrue(drive.components.isEmpty, "no components")

      // Trailing separator on an anchor that doesn't already end in one:
      // \\server\share is a complete root, so the appended `\` is a trailing
      // separator.
      let unc = _StdlibFilePath(
        anchor: _StdlibFilePath.Anchor(#"\\server\share"#),
        [] as [_StdlibFilePath.Component],
        hasTrailingSeparator: true)
      expectEqual(unc.description, #"\\server\share\"#, "UNC + trailing separator")
      expectTrue(unc.hasTrailingSeparator, "UNC trailing separator present")
    }
  }

  // MARK: - Darwin init(anchor:_:resourceFork:)

  @Test(.darwinOnly)
  func reconstructDarwinResourceFork() {
    let p = _StdlibFilePath(
      anchor: _StdlibFilePath.Anchor("/"), comps("foo", "bar"), resourceFork: true)
    expectEqual(p.description, "/foo/bar/..namedfork/rsrc",
      "resource-fork reconstruction")
    expectTrue(p.isResourceFork, "isResourceFork is true")
    // Mutual exclusivity with a trailing separator.
    expectFalse(p.hasTrailingSeparator,
      "resource fork excludes trailing separator")
    // The suffix is not presented as components.
    expectEqual(p.components.map(\.description), ["foo", "bar"],
      "suffix is not a component")
  }

  // MARK: - Emergent semantics under reconstruction

  // The reconstructed path normalizes as if the equivalent string literal were
  // provided. Building `/` + [".nofollow", "foo"] yields the bytes
  // `/.nofollow/foo`, which re-decompose so the `.nofollow` is absorbed into
  // the anchor, exactly as _StdlibFilePath("/.nofollow/foo") would.
  @Test(.darwinOnly)
  func reconstructDarwinAnchorAbsorption() {
    let p = _StdlibFilePath(anchor: _StdlibFilePath.Anchor("/"), comps(".nofollow", "foo"))
    // Proposal-derived expectation (not read from the implementation first):
    expectEqual(p.description, "/.nofollow/foo", "absorbed printed form")
    expectTrue(p.anchor?.description == "/.nofollow/",
      ".nofollow absorbed into anchor")
    expectEqual(p.components.map(\.description), ["foo"],
      "only foo remains a component")
    // Equivalent to constructing from the string literal.
    expectEqual(p, _StdlibFilePath("/.nofollow/foo"),
      "reconstruction == equivalent string literal")
  }

  // MARK: - hasTrailingSeparator setter + with/without

  @Test
  func trailingSeparatorSetter() {
    var p = _StdlibFilePath("/foo")
    expectFalse(p.hasTrailingSeparator, "starts without")

    p.hasTrailingSeparator = true
    expectEqual(p.description, universal("/foo/"), "set true adds separator")

    p.hasTrailingSeparator = true  // no-op
    expectEqual(p.description, universal("/foo/"), "set true again is a no-op")

    p.hasTrailingSeparator = false
    expectEqual(p.description, universal("/foo"), "set false removes separator")

    p.hasTrailingSeparator = false  // no-op
    expectEqual(p.description, universal("/foo"), "set false again is a no-op")
  }

  @Test
  func withTrailingSeparatorMethods() {
    expectEqual(_StdlibFilePath("/foo").withTrailingSeparator().description,
      universal("/foo/"), "adds separator")
    expectEqual(_StdlibFilePath("/foo/").withTrailingSeparator().description,
      universal("/foo/"), "no-op when already present")
    expectEqual(_StdlibFilePath("/foo/").withoutTrailingSeparator().description,
      universal("/foo"), "removes separator")
    expectEqual(_StdlibFilePath("/foo").withoutTrailingSeparator().description,
      universal("/foo"), "no-op when absent")
  }

  @Test
  func trailingSeparatorAnchorOnly() {
    // The basic root's separator is structural (part of the anchor), so it is
    // not a trailing separator and cannot be "added".
    let root = _StdlibFilePath("/")
    expectFalse(root.hasTrailingSeparator,
      "basic root has no trailing separator")
    expectEqual(root.withTrailingSeparator().description, universal("/"),
      "withTrailingSeparator on basic root is a no-op")

    withPlatform(.windows) {
      // \\server\share is a complete root; adding a separator yields a real
      // trailing separator.
      let unc = _StdlibFilePath(#"\\server\share"#)
      expectFalse(unc.hasTrailingSeparator, "bare UNC has no trailing separator")
      let withSep = unc.withTrailingSeparator()
      expectEqual(withSep.description, #"\\server\share\"#, "UNC + separator")
      expectTrue(withSep.hasTrailingSeparator, "now has trailing separator")
    }
  }

  // MARK: - Darwin isResourceFork setter + with/without + suffix swap

  @Test(.darwinOnly)
  func resourceForkSetter() {
    let base = _StdlibFilePath("/foo")
    expectFalse(base.isResourceFork, "plain path is not a resource fork")

    let forked = base.withResourceFork()
    expectEqual(forked.description, "/foo/..namedfork/rsrc", "adds suffix")
    expectTrue(forked.isResourceFork, "isResourceFork true")

    let unforked = forked.withoutResourceFork()
    expectEqual(unforked.description, "/foo", "removes suffix")
    expectFalse(unforked.isResourceFork, "isResourceFork false")
    // withoutResourceFork on a plain path is a no-op.
    expectEqual(base.withoutResourceFork().description, "/foo", "no-op")
  }

  @Test(.darwinOnly)
  func suffixSwapTrailingToResourceFork() {
    // Setting isResourceFork on a path with a trailing separator replaces the
    // separator with the resource-fork suffix.
    var p = _StdlibFilePath("/foo/")
    expectTrue(p.hasTrailingSeparator, "starts with trailing separator")
    p.isResourceFork = true
    expectEqual(p.description, "/foo/..namedfork/rsrc", "separator -> resource fork")
    expectTrue(p.isResourceFork, "now a resource fork")
    expectFalse(p.hasTrailingSeparator, "no longer a trailing separator")
  }

  @Test(.darwinOnly)
  func suffixSwapResourceForkToTrailing() {
    // Setting hasTrailingSeparator on a resource-fork path replaces the suffix
    // with a trailing separator.
    var p = _StdlibFilePath("/foo/..namedfork/rsrc")
    expectTrue(p.isResourceFork, "starts as resource fork")
    p.hasTrailingSeparator = true
    expectEqual(p.description, "/foo/", "resource fork -> separator")
    expectTrue(p.hasTrailingSeparator, "now a trailing separator")
    expectFalse(p.isResourceFork, "no longer a resource fork")
  }

  // MARK: - anchor get/set

  @Test(.windowsOnly)
  func anchorTransplantToVerbatim() {
    // Example from SE-0529.
    var p = _StdlibFilePath(#"C:\Users\dev\project"#)
    expectTrue(p.anchor?.description == #"C:\"#, "starts as C:\\")
    expectTrue(p.anchor?._isVerbatimComponent == false, "not verbatim initially")

    p.anchor = _StdlibFilePath.Anchor(#"\\?\C:\"#)
    expectEqual(p.description, #"\\?\C:\Users\dev\project"#, "transplanted to verbatim")
    expectTrue(p.anchor?._isVerbatimComponent == true, "now verbatim")
    expectTrue(p.anchor?._driveLetter == "C", "drive letter preserved")
  }

  @Test(.darwinOnly)
  func anchorStripDarwinToRoot() {
    // Example from SE-0529.
    var p = _StdlibFilePath("/.nofollow/etc/passwd")
    expectTrue(p.anchor?.description == "/.nofollow/", "starts as /.nofollow/")
    p.anchor = _StdlibFilePath.Anchor("/")
    expectEqual(p.description, "/etc/passwd", "stripped to /")
    expectTrue(p.anchor?.description == "/", "anchor now /")
  }

  @Test
  func anchorSetToNil() {
    var p = _StdlibFilePath("/foo/bar")
    p.anchor = nil
    expectEqual(p.description, universal("foo/bar"),
      "anchor removed -> relative")
    expectNil(p.anchor, "anchor is nil")
    expectFalse(p.isAbsolute, "now relative")
  }

  @Test
  func anchorSetOntoRelative() {
    var p = _StdlibFilePath("foo/bar")
    expectNil(p.anchor, "starts relative")
    p.anchor = _StdlibFilePath.Anchor("/")
    expectEqual(p.description, universal("/foo/bar"), "anchor added")
    // The basic root is fully qualified on unix but is the current-drive root
    // (not absolute) on Windows. Pin only the unix half here; the Windows
    // drive-relative case is covered below.
    withPlatforms(.linux, .darwin) {
      expectTrue(p.isAbsolute, "now absolute")
    }
    withPlatform(.windows) {
      // Drive-relative anchor onto a relative path: no gap separator inserted.
      var q = _StdlibFilePath(#"foo\bar"#)
      expectNil(q.anchor, "starts relative")
      q.anchor = _StdlibFilePath.Anchor("C:")
      expectEqual(q.description, #"C:foo\bar"#, "C: prepended without a gap separator")
      expectFalse(q.isAbsolute, "drive-relative is not absolute")
    }
  }
}
