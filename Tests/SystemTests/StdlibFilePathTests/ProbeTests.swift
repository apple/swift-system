/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Edge-case decomposition checks: each `@Test` pins the decomposition of a
// degenerate / boundary input that the table-driven `pathTestCases` doesn't
// cover (Darwin anchor reparse, bare resolve/vol forms, Windows
// multi-backslash roots, Windows empty-device sigils, prefix near-misses).
// Nested in `AllTests.DecompositionTests` so they share the same
// `@Suite(.serialized)` umbrella as the table-driven cases.

extension AllTests.DecompositionTests {

  /// Pin the four primary decomposition fields for `input` on `platform`.
  /// The default `#_sourceLocation` captures the *caller's* location, so a
  /// failure points at the assertion row rather than this helper.
  ///
  /// The `withPlatform` gate selects rows per platform for the one test here
  /// that asserts on both Linux and Darwin. Single-platform tests carry a
  /// `.darwinOnly` / `.windowsOnly` trait instead, so they report as skipped
  /// rather than passing without asserting.
  private func expectDecomposition(
    _ input: String,
    platform: _Platform,
    anchor: String?,
    components: [String],
    trailingSeparator: Bool = false,
    printed: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    withPlatform(platform) {
      guard let path = _StdlibFilePath(input) else {
        expectNotNil(Optional<Int>.none,
          "[\(platform)] \(input.debugDescription) _StdlibFilePath init returned nil",
          sourceLocation: sourceLocation)
        return
      }
      expectEqual(path.anchor?.description, anchor,
        "[\(platform)] \(input.debugDescription) anchor: got \(path.anchor?.description.debugDescription ?? "nil")",
        sourceLocation: sourceLocation)
      expectEqual(path.components.map(\.description), components,
        "[\(platform)] \(input.debugDescription) components: got \(path.components.map(\.description))",
        sourceLocation: sourceLocation)
      expectEqual(path.hasTrailingSeparator, trailingSeparator,
        "[\(platform)] \(input.debugDescription) trailingSeparator: got \(path.hasTrailingSeparator)",
        sourceLocation: sourceLocation)
      expectEqual(path.description, printed,
        "[\(platform)] \(input.debugDescription) printed: got \(path.description.debugDescription)",
        sourceLocation: sourceLocation)
    }
  }

  // MARK: - Darwin relative-portion re-parse vs combined anchors
  //
  // `_normalizeDarwin` extracts the relative portion into a fresh string and
  // dot-normalizes it; that path re-runs `_parseRoot()` on the slice. This
  // pins which token-shaped sequences after a leading anchor extend the
  // anchor and which fall back to plain components.
  //
  // An anchor may include resolve flags and/or a volume identifier; resolve
  // always precedes vol. So:
  // - `.vol` after a leading vol/nofollow/resolve flag: the only valid
  //   continuation. `/.nofollow/.vol/N/M` is a single combined anchor.
  // - Anything else after a leading anchor (vol after vol, nofollow after
  //   anything, resolve after anything): the leading anchor stands and the
  //   token-named bytes remain plain components.
  @Test(.darwinOnly)
  func darwinRelativeReparse() {
    // .vol token as a relative component under a volfs anchor.
    expectDecomposition("/.vol/1234/5678/.vol/x", platform: .darwin,
      anchor: "/.vol/1234/5678", components: [".vol", "x"],
      printed: "/.vol/1234/5678/.vol/x")
    // .nofollow token as a relative component under a volfs anchor.
    expectDecomposition("/.vol/1234/5678/.nofollow/x", platform: .darwin,
      anchor: "/.vol/1234/5678", components: [".nofollow", "x"],
      printed: "/.vol/1234/5678/.nofollow/x")
    // .resolve/3 tokens as relative components under a volfs anchor.
    expectDecomposition("/.vol/1234/5678/.resolve/3/x", platform: .darwin,
      anchor: "/.vol/1234/5678", components: [".resolve", "3", "x"],
      printed: "/.vol/1234/5678/.resolve/3/x")
    // .vol after .nofollow forms a combined anchor: an anchor may include
    // resolve flags and/or a volume identifier.
    expectDecomposition("/.nofollow/.vol/1234/5678", platform: .darwin,
      anchor: "/.nofollow/.vol/1234/5678", components: [],
      printed: "/.nofollow/.vol/1234/5678")
    // .nofollow token as a relative component under a .nofollow anchor.
    expectDecomposition("/.nofollow/.nofollow/x", platform: .darwin,
      anchor: "/.nofollow/", components: [".nofollow", "x"],
      printed: "/.nofollow/.nofollow/x")
    // Inner `.resolve/1` is not canonicalized: canonicalization is anchor-only,
    // and here `.resolve/1` is in component position under a `.resolve/3/`
    // anchor.
    expectDecomposition("/.resolve/3/.resolve/1/x", platform: .darwin,
      anchor: "/.resolve/3/", components: [".resolve", "1", "x"],
      printed: "/.resolve/3/.resolve/1/x")
  }

  // MARK: - Bare resolve/vol anchors without trailing content
  //
  // The parser treats volfs anchors and resolve/nofollow anchors
  // asymmetrically:
  //   * `_parseVol` recognizes `/.vol/F/I` without a trailing slash; the
  //     `2`->`@` canonicalization also fires without one.
  //   * `_parseResolve`/`_parseNofollow` require the trailing slash; bare
  //     `/.resolve/N` and `/.nofollow` fall through to a plain `/` root with
  //     the bytes as regular components, and `_canonicalizeDarwinAnchor` does
  //     not fire on `/.resolve/1` (it matches the literal `/.resolve/1/`).
  //
  // The asymmetry is principled per XNU: a volfs anchor is a complete inode
  // reference, while resolve/nofollow are prefixes that modify a following
  // path.
  //
  // Already pinned in PathTestCases.swift (not re-asserted): `/.nofollow`,
  // `/.resolve/0`, `/.vol/1234/5678`, `/.vol/1234/2`.
  @Test(.unixOnly)
  func bareResolveVolAnchors() {
    // Bare `/.resolve/1` is not a resolve anchor, since `_parseResolve` requires
    // the trailing slash, so this falls through to a plain `/` root.
    expectDecomposition("/.resolve/1", platform: .darwin,
      anchor: "/", components: [".resolve", "1"],
      printed: "/.resolve/1")
    // `/.resolve/1/` canonicalizes to `/.nofollow/`. Here with no following
    // path -> anchor only, no components.
    expectDecomposition("/.resolve/1/", platform: .darwin,
      anchor: "/.nofollow/", components: [],
      printed: "/.nofollow/")
    // Bare `/.resolve/3` (non-canonicalizing flag): same fall-through.
    expectDecomposition("/.resolve/3", platform: .darwin,
      anchor: "/", components: [".resolve", "3"],
      printed: "/.resolve/3")
    // `/.vol/1234/2/`: the `2`->`@` canonicalization fires, and the trailing
    // slash is a separator (the volfs anchor itself is not slash-terminated).
    expectDecomposition("/.vol/1234/2/", platform: .darwin,
      anchor: "/.vol/1234/@", components: [], trailingSeparator: true,
      printed: "/.vol/1234/@/")
    // Linux contrast for the same bytes: no Darwin anchor magic at all.
    expectDecomposition("/.resolve/1", platform: .linux,
      anchor: "/", components: [".resolve", "1"],
      printed: "/.resolve/1")
  }

  // MARK: - Windows three-or-more leading backslashes
  //
  // `_prenormalizeWindowsRoots` returns after the first backslash for 3+
  // leading backslashes ("NOT a UNC/device path"), and separator coalescing
  // collapses the rest. Result: a single `\` current-drive root with the
  // remainder as components.
  @Test(.windowsOnly)
  func windowsThreePlusBackslashes() {
    expectDecomposition(#"\\\server\share"#, platform: .windows,
      anchor: #"\"#, components: ["server", "share"],
      printed: #"\server\share"#)
    expectDecomposition(#"\\\\server"#, platform: .windows,
      anchor: #"\"#, components: ["server"],
      printed: #"\server"#)
    expectDecomposition(#"\\\"#, platform: .windows,
      anchor: #"\"#, components: [],
      printed: #"\"#)
  }

  // MARK: - Windows degenerate device/sigil forms
  //
  // A `\\.` or `\\?` with no trailing backslash and no device name gets a
  // backslash synthesized by `_prenormalizeWindowsRoots` (`expectBackslash`
  // inserts one), yielding the empty-device anchors `\\.\` / `\\?\`. Both
  // are absolute; `\\?` becomes verbatim-component. (The trailing-backslash
  // variants `\\.\` and `\\?\` already have rows in PathTestCases.swift and
  // are not re-asserted.)
  @Test(.windowsOnly)
  func windowsDegenerateDeviceSigil() {
    expectDecomposition(#"\\."#, platform: .windows,
      anchor: #"\\.\"#, components: [],
      printed: #"\\.\"#)
    expectDecomposition(#"\\?"#, platform: .windows,
      anchor: #"\\?\"#, components: [],
      printed: #"\\?\"#)

    // Same inputs, additional structural assertions.
    // Route through String-typed locals so the failable `init?(_:)` is
    // selected (a bare string literal would bind the non-failable
    // ExpressibleByStringLiteral `init`, which is not optional).
    let dotInput: String = #"\\."#
    let dot = _StdlibFilePath(dotInput)!
    expectTrue(dot.isAbsolute, #"\\. is absolute"#)
    expectFalse(dot.anchor?._isVerbatimComponent ?? true,
      #"\\. is device-namespace, not verbatim"#)

    let qInput: String = #"\\?"#
    let q = _StdlibFilePath(qInput)!
    expectTrue(q.isAbsolute, #"\\? is absolute"#)
    expectTrue(q.anchor?._isVerbatimComponent ?? false,
      #"\\? is verbatim-component"#)
  }

  // MARK: - _matches* prefix pre-filter near-misses
  //
  // `_matchesNofollow`/`_matchesResolve`/`_matchesVol` are prefix
  // pre-filters; the real validation (the required trailing `/` after the
  // keyword, the FSID/FILEID slashes) lives in `_parseNofollow`/
  // `_parseResolve`/`_parseVol`. A near-miss whose keyword is only a prefix
  // of the component (`/.nofollowing`, `/.resolved`, `/.volume`,
  // `/.resolvex`) therefore fails the parser and falls through to a plain
  // `/` root with the bytes as regular components.
  //
  // Analogous rows for inputs without prefix overlap (e.g. `/.hidden/foo`,
  // `/.Resolve/0/foo`) live in PathTestCases.swift; the prefix-overlap
  // near-misses are pinned here.
  @Test(.darwinOnly)
  func matchesPrefixNearMisses() {
    expectDecomposition("/.nofollowing/bar", platform: .darwin,
      anchor: "/", components: [".nofollowing", "bar"],
      printed: "/.nofollowing/bar")
    expectDecomposition("/.resolved/x", platform: .darwin,
      anchor: "/", components: [".resolved", "x"],
      printed: "/.resolved/x")
    expectDecomposition("/.volume/x", platform: .darwin,
      anchor: "/", components: [".volume", "x"],
      printed: "/.volume/x")
    expectDecomposition("/.resolvex/1/y", platform: .darwin,
      anchor: "/", components: [".resolvex", "1", "y"],
      printed: "/.resolvex/1/y")
    // Keyword present but missing the structural slashes:
    // `.vol` with no FSID/FILEID, and FSID but no FILEID.
    expectDecomposition("/.vol", platform: .darwin,
      anchor: "/", components: [".vol"],
      printed: "/.vol")
    expectDecomposition("/.vol/1234", platform: .darwin,
      anchor: "/", components: [".vol", "1234"],
      printed: "/.vol/1234")
  }
}
