/*
 This source file is part of the SE-0529 reference implementation

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

extension AllTests.ValidationTests {

  // MARK: - Helpers

  func codeUnits(_ s: String) -> [_StdlibFilePath.CodeUnit] {
    Array(s.utf8).map { CChar(bitPattern: $0) }
  }

  func filePathFromCodeUnits(
    _ units: [_StdlibFilePath.CodeUnit]
  ) -> _StdlibFilePath? {
    _StdlibFilePath(codeUnits: units.span)
  }

  func componentFromCodeUnits(
    _ units: [_StdlibFilePath.CodeUnit]
  ) -> _StdlibFilePath.Component? {
    _StdlibFilePath.Component(codeUnits: units.span)
  }

  // MARK: - _StdlibFilePath.init?(_: String) NUL rejection

  @Test
  func filePathInitRejectsNUL() {
    // Platform-independent: NUL is rejected before normalization.
    let good: String = "hello"
    expectNotNil(_StdlibFilePath(good))

    let empty: String = ""
    expectNotNil(_StdlibFilePath(empty))

    let abs: String = "/foo/bar"
    expectNotNil(_StdlibFilePath(abs))

    let nulMiddle: String = "hello\0world"
    expectNil(_StdlibFilePath(nulMiddle))

    let justNul: String = "\0"
    expectNil(_StdlibFilePath(justNul))

    let nulEnd: String = "foo\0"
    expectNil(_StdlibFilePath(nulEnd))

    let nulStart: String = "\0foo"
    expectNil(_StdlibFilePath(nulStart))
  }

  @Test
  func filePathStringLiteralWorks() {
    let p: _StdlibFilePath = "/usr/local/bin"
    expectEqual(p.description, universal("/usr/local/bin"))

    let empty: _StdlibFilePath = ""
    expectTrue(empty.isEmpty)
  }

  // MARK: - _StdlibFilePath.init?(codeUnits:) and round-trip via withCodeUnits

  @Test
  func filePathCodeUnitsRejectsNUL() {
    // The `codeUnits(_:)` helper produces `[CChar]` (_StdlibFilePath.CodeUnit only on
    // non-Windows builds), so this body is unix-only.
    withPlatforms(.linux, .darwin) {
      expectTrue(filePathFromCodeUnits(codeUnits("/foo"))?.description == "/foo")
      expectNil(filePathFromCodeUnits(codeUnits("f\0o")))
      expectNil(filePathFromCodeUnits(codeUnits("\0")))
      expectNil(filePathFromCodeUnits(codeUnits("foo\0")))
    }
  }

  @Test
  func filePathCodeUnitsEmpty() {
    let emptyPath = filePathFromCodeUnits([])
    expectNotNil(emptyPath)
    expectTrue(emptyPath?.isEmpty == true)
  }

  @Test
  func filePathCodeUnitRoundTrip() {
    for input in ["/foo/bar", "", ".", "foo/bar", "/usr/local/bin", "hello"] {
      let s: String = input
      let path = _StdlibFilePath(s)!
      let extracted = path.withCodeUnits { ptr, count in
        Array(UnsafeBufferPointer(start: ptr, count: count))
      }
      let roundTripped = filePathFromCodeUnits(extracted)
      expectTrue(roundTripped == path,
        "Code unit round-trip failed for \(input.debugDescription)")
    }
  }

  @Test
  func filePathCodeUnitRoundTripNonASCII() {
    for input in ["/café/naïve", "/あ/🧟‍♀️", "Ångström"] {
      let s: String = input
      let path = _StdlibFilePath(s)!
      let extracted = path.withCodeUnits { ptr, count in
        Array(UnsafeBufferPointer(start: ptr, count: count))
      }
      let roundTripped = filePathFromCodeUnits(extracted)
      expectTrue(roundTripped == path,
        "Non-ASCII code unit round-trip failed for \(input.debugDescription)")
    }
  }

  // MARK: - Component.init?(_: String)

  @Test
  func componentInitRejectsNUL() {
    // Platform-independent.
    let good: String = "hello"
    expectNotNil(_StdlibFilePath.Component(good))

    let nul: String = "hello\0world"
    expectNil(_StdlibFilePath.Component(nul))

    let justNul: String = "\0"
    expectNil(_StdlibFilePath.Component(justNul))
  }

  @Test
  func componentInitRejectsSeparator() {
    withPlatforms(.linux, .darwin) {
      let fwdSlash: String = "foo/bar"
      expectNil(_StdlibFilePath.Component(fwdSlash))
      let justSlash: String = "/"
      expectNil(_StdlibFilePath.Component(justSlash))
      let trailingSlash: String = "a/"
      expectNil(_StdlibFilePath.Component(trailingSlash))

      // Backslash is legal in filenames on unix.
      let bsOnUnix: String = #"foo\bar"#
      let bs = _StdlibFilePath.Component(bsOnUnix)
      expectNotNil(bs)
      expectTrue(bs?.description == #"foo\bar"#)
    }

    withPlatform(.windows) {
      let backslash: String = #"foo\bar"#
      expectNil(_StdlibFilePath.Component(backslash))
      let justBack: String = #"\"#
      expectNil(_StdlibFilePath.Component(justBack))
      let fwdOnWin: String = "foo/bar"
      expectNil(_StdlibFilePath.Component(fwdOnWin))
    }
  }

  @Test
  func componentInitRejectsEmpty() {
    let empty: String = ""
    expectNil(_StdlibFilePath.Component(empty))
  }

  @Test
  func componentInitAcceptsValid() {
    let hello: String = "hello"
    let c = _StdlibFilePath.Component(hello)
    expectNotNil(c)
    expectTrue(c?.description == "hello")

    let dotStr: String = "."
    let dot = _StdlibFilePath.Component(dotStr)
    expectNotNil(dot)
    expectTrue(dot?.kind == .currentDirectory)

    let dotdotStr: String = ".."
    let dotdot = _StdlibFilePath.Component(dotdotStr)
    expectNotNil(dotdot)
    expectTrue(dotdot?.kind == .parentDirectory)
  }

  // MARK: - Component.init?(codeUnits:)

  @Test
  func componentCodeUnitsRejectsNUL() {
    // Platform-independent.
    expectNotNil(componentFromCodeUnits(codeUnits("foo")))
    expectNil(componentFromCodeUnits(codeUnits("f\0o")))
    expectNil(componentFromCodeUnits(codeUnits("\0")))
  }

  @Test
  func componentCodeUnitsRejectsEmpty() {
    expectNil(componentFromCodeUnits([]))
  }

  @Test
  func componentCodeUnitsRejectsSeparator() {
    // The `codeUnits(_:)` helper produces `[CChar]`, so this body is unix-only.
    withPlatforms(.linux, .darwin) {
      expectNil(componentFromCodeUnits(codeUnits("foo/bar")))
      // Backslash is legal in filenames on unix.
      expectNotNil(componentFromCodeUnits(codeUnits(#"foo\bar"#)))
    }

    withPlatform(.windows) {
      expectNil(componentFromCodeUnits(codeUnits(#"foo\bar"#)))
      expectNil(componentFromCodeUnits(codeUnits("foo/bar")))
    }
  }

  @Test
  func componentCodeUnitRoundTrip() {
    for name in ["hello", ".", "..", "file.txt", "café", "🧟‍♀️"] {
      let s: String = name
      let comp = _StdlibFilePath.Component(s)!
      let span = comp.codeUnits
      var extracted = [_StdlibFilePath.CodeUnit]()
      extracted.reserveCapacity(span.count)
      for i in span.indices { extracted.append(span[i]) }
      let roundTripped = componentFromCodeUnits(extracted)
      expectTrue(roundTripped == comp,
        "Component code unit round-trip failed for \(name.debugDescription)")
    }
  }

  // MARK: - Span code-unit accessors

  /// Copies a span of code units into an array (`Span` is not a `Sequence`).
  private func _array(
    _ span: Span<_StdlibFilePath.CodeUnit>
  ) -> [_StdlibFilePath.CodeUnit] {
    var out = [_StdlibFilePath.CodeUnit]()
    out.reserveCapacity(span.count)
    for i in span.indices { out.append(span[i]) }
    return out
  }

  @Test
  func spanCodeUnitsAccessors() {
    func bytes(_ s: String) -> [_StdlibFilePath.CodeUnit] {
      Array(s.utf8).map { CChar(bitPattern: $0) }
    }
    // The local `bytes(_:)` helper produces `[CChar]`, unix-only.
    withPlatforms(.linux, .darwin) {
      // Bind to `String` locals so the failable `init?(_:)` is selected
      // (a bare string literal binds the non-failable
      // `ExpressibleByStringLiteral` init, which is not optional).
      let input: String = "/usr/local"
      let path = _StdlibFilePath(input)!

      // _StdlibFilePath.codeUnits excludes the null terminator;
      // nullTerminatedCodeUnits includes it as the final element.
      let cu = _array(path.codeUnits)
      expectEqual(cu, bytes("/usr/local"))
      expectFalse(cu.contains(0))

      let ntcu = _array(path.nullTerminatedCodeUnits)
      expectEqual(ntcu, bytes("/usr/local") + [0])
      expectEqual(ntcu.count, cu.count + 1)
      expectTrue(ntcu.last == 0)

      // Bind each owner to a local before borrowing its span: a span
      // borrowed from a force-unwrapped (`!`) temporary would outlive that
      // temporary ("lifetime-dependent value escapes its scope").
      let anchor = path.anchor!
      expectEqual(_array(anchor.codeUnits), bytes("/"))

      // ComponentView.codeUnits is the relative portion (anchor excluded).
      let cv = path.components
      expectEqual(_array(cv.codeUnits), bytes("usr/local"))

      // Component.codeUnits is a single component's bytes.
      let firstComp = cv.first!
      let lastComp = cv.last!
      expectEqual(_array(firstComp.codeUnits), bytes("usr"))
      expectEqual(_array(lastComp.codeUnits), bytes("local"))

      // ComponentView strips a trailing separator (suffix, not a component).
      let trailingInput: String = "/usr/local/"
      let trailing = _StdlibFilePath(trailingInput)!
      expectTrue(trailing.hasTrailingSeparator)
      let trailingCV = trailing.components
      expectEqual(_array(trailingCV.codeUnits), bytes("usr/local"))

      // Empty relative portion -> empty span.
      let rootInput: String = "/"
      let rootOnly = _StdlibFilePath(rootInput)!
      let rootCV = rootOnly.components
      expectEqual(_array(rootCV.codeUnits), [])
      let rootAnchor = rootOnly.anchor!
      expectEqual(_array(rootAnchor.codeUnits), bytes("/"))
    }
  }

  // MARK: - Anchor.init?(_: String) NUL rejection

  @Test
  func anchorInitRejectsNULOnBasicRoot() {
    // Basic-root NUL handling. Universal modulo separator: on Windows
    // the slash-form input still parses (slash is converted), and NUL
    // is rejected before normalization regardless.
    let good: String = "/"
    expectNotNil(_StdlibFilePath.Anchor(good))

    let nul1: String = "/\0"
    expectNil(_StdlibFilePath.Anchor(nul1))

    let nul2: String = "\0/"
    expectNil(_StdlibFilePath.Anchor(nul2))
  }

  @Test
  func anchorInitRejectsNULDarwin() {
    withPlatform(.darwin) {
      let root: String = "/"
      expectNotNil(_StdlibFilePath.Anchor(root))

      let nofollow: String = "/.nofollow/"
      expectNotNil(_StdlibFilePath.Anchor(nofollow))

      let nul: String = "/.nofollow\0/"
      expectNil(_StdlibFilePath.Anchor(nul))

      let vol: String = "/.vol/1234/5678"
      expectNotNil(_StdlibFilePath.Anchor(vol))

      let volNul: String = "/.vol/1234\0/5678"
      expectNil(_StdlibFilePath.Anchor(volNul))
    }
  }

  // Per proposal line 111: a Darwin anchor may include resolve flags AND/OR
  // a volume identifier. The combined form `[/.nofollow/ | /.resolve/N/]
  // .vol/FSID/FILEID` is one anchor, and `Anchor.init?` accepts it iff the
  // combined form is complete (no missing FSID/FILEID).
  @Test
  func anchorInitDarwinAcceptsCombinedForms() {
    withPlatform(.darwin) {
      // String literals dispatch to the trapping `init(stringLiteral:)`;
      // route through let-bindings so the failable `init?(_:)` is selected.
      let nofollowVol: String = "/.nofollow/.vol/1234/5678"
      expectNotNil(_StdlibFilePath.Anchor(nofollowVol),
        "/.nofollow/.vol/1234/5678 is a valid combined anchor")
      let resolveVol: String = "/.resolve/3/.vol/1234/5678"
      expectNotNil(_StdlibFilePath.Anchor(resolveVol),
        "/.resolve/3/.vol/1234/5678 is a valid combined anchor")
      // Combined with FILEID canonicalization (`2` -> `@`): still valid.
      let nofollowVol2: String = "/.nofollow/.vol/1234/2"
      expectNotNil(_StdlibFilePath.Anchor(nofollowVol2),
        "/.nofollow/.vol/1234/2 canonicalizes and is accepted")
      // Combined with both canonicalizations.
      let resolveOneVol2: String = "/.resolve/1/.vol/1234/2"
      expectNotNil(_StdlibFilePath.Anchor(resolveOneVol2),
        "/.resolve/1/.vol/1234/2 canonicalizes and is accepted")
    }
  }

  // Incomplete combined forms (missing FSID or FILEID) fall back to the
  // leading flag as the anchor with the partial vol bytes as components.
  // `Anchor.init?` then rejects them because components are non-empty.
  @Test
  func anchorInitDarwinRejectsIncompleteCombinedForms() {
    withPlatform(.darwin) {
      let nofollowVolEmpty: String = "/.nofollow/.vol/"
      expectNil(_StdlibFilePath.Anchor(nofollowVolEmpty),
        "/.nofollow/.vol/ has no FSID — falls back to /.nofollow/ + [.vol]")
      let nofollowVolNoFileid: String = "/.nofollow/.vol/1234/"
      expectNil(_StdlibFilePath.Anchor(nofollowVolNoFileid),
        "/.nofollow/.vol/1234/ has no FILEID")
      let resolveVolEmpty: String = "/.resolve/3/.vol/"
      expectNil(_StdlibFilePath.Anchor(resolveVolEmpty),
        "/.resolve/3/.vol/ has no FSID")
      let resolveVolNoFileid: String = "/.resolve/3/.vol/1234/"
      expectNil(_StdlibFilePath.Anchor(resolveVolNoFileid),
        "/.resolve/3/.vol/1234/ has no FILEID")
    }
  }

  @Test
  func anchorInitRejectsNULWindows() {
    withPlatform(.windows) {
      let drive: String = #"C:\"#
      expectNotNil(_StdlibFilePath.Anchor(drive))

      let driveNul: String = "C:\\\0"
      expectNil(_StdlibFilePath.Anchor(driveNul))

      let unc: String = #"\\server\share"#
      expectNotNil(_StdlibFilePath.Anchor(unc))

      let uncNul: String = "\\\\\0server\\share"
      expectNil(_StdlibFilePath.Anchor(uncNul))
    }
  }

  @Test
  func anchorInitRejectsInvalid() {
    // Universal modulo separator: empty input has no anchor; "foo" is
    // a relative component-only path (no anchor); "/foo" parses to an
    // anchored path with components, which `Anchor.init?` rejects
    // (anchor only, no components allowed).
    let empty: String = ""
    expectNil(_StdlibFilePath.Anchor(empty))

    let noAnchor: String = "foo"
    expectNil(_StdlibFilePath.Anchor(noAnchor))

    let hasComponents: String = "/foo"
    expectNil(_StdlibFilePath.Anchor(hasComponents))
  }

  // MARK: - Anchor.init? strictness vs _StdlibFilePath.init? totality (Windows)
  //
  // `_StdlibFilePath.Anchor.init?` is STRICT: a named anchor form must carry its
  // name. It rejects incomplete UNC (no server / no share), empty device
  // (`\\.\`), and empty verbatim (`\\?\`). `_StdlibFilePath.init?` by contrast is
  // total and coalesces these same inputs into a degraded anchor. These two
  // tests pin both halves and the resulting divergence.

  @Test
  func anchorInitStrictRejectsIncompleteWindowsForms() {
    withPlatform(.windows) {
      // Named forms missing their name -> nil.
      let incomplete: [String] = [
        #"\\"#,         // incomplete UNC: no server, no share
        #"\\server"#,   // incomplete UNC: server but no share
        #"\\\server"#,  // 3+ backslashes -> `\` root + `server` component
        #"\\."#,        // empty device: no device name
        #"\\.\"#,       // empty device: no device name
        #"\\?"#,        // empty verbatim: no component
        #"\\?\"#,       // empty verbatim: no component
      ]
      for input in incomplete {
        expectNil(_StdlibFilePath.Anchor(input),
          "Anchor.init? should reject \(input.debugDescription)")
      }

      // Populated named forms still construct and round-trip to themselves.
      let named: [(input: String, printed: String)] = [
        (#"\\server\share"#, #"\\server\share"#),
        (#"\\.\pipe"#,       #"\\.\pipe"#),
        (#"\\?\C:\"#,        #"\\?\C:\"#),
        (#"\\?\pictures"#,   #"\\?\pictures"#),
      ]
      for (input, printed) in named {
        let anchor = _StdlibFilePath.Anchor(input)
        expectNotNil(anchor,
          "Anchor.init? should accept \(input.debugDescription)")
        expectEqual(anchor?.description, printed,
          "Anchor \(input.debugDescription) printed form")
      }
    }
  }

  @Test
  func filePathStillCoalescesAnchorRejectedForms() {
    withPlatform(.windows) {
      // The inputs `Anchor.init?` rejects remain TOTAL under `_StdlibFilePath.init?`,
      // which coalesces each into its degraded shape. This is the deliberate
      // divergence: _StdlibFilePath stays total, Anchor is strict.

      // Headline case: `\\\server\share` coalesces to a current-drive root
      // with `server` and `share` as ordinary components, yet the strict
      // Anchor initializer rejects the same string.
      let triple: String = #"\\\server\share"#
      expectNil(_StdlibFilePath.Anchor(triple),
        #"Anchor.init? rejects \\\server\share"#)
      let p = _StdlibFilePath(triple)
      expectNotNil(p, #"_StdlibFilePath.init? accepts \\\server\share"#)
      expectEqual(p?.anchor?.description, #"\"#,
        #"\\\server\share coalesces to anchor \"#)
      expectEqual(p?.components.map(\.description) ?? [], ["server", "share"],
        #"\\\server\share components"#)

      // Every rejected anchor input still constructs a _StdlibFilePath whose anchor
      // is the coalesced/degraded form, with no relative components — while
      // `Anchor.init?` rejects that very input.
      let coalesced: [(input: String, anchor: String)] = [
        (#"\\"#,       #"\\\"#),       // -> degraded 3-backslash root
        (#"\\server"#, #"\\server\"#), // -> server with empty share
        (#"\\."#,      #"\\.\"#),      // -> empty device
        (#"\\.\"#,     #"\\.\"#),      // -> empty device
        (#"\\?"#,      #"\\?\"#),      // -> empty verbatim
        (#"\\?\"#,     #"\\?\"#),      // -> empty verbatim
      ]
      for (input, anchor) in coalesced {
        let fp = _StdlibFilePath(input)
        expectNotNil(fp,
          "_StdlibFilePath.init? should accept \(input.debugDescription)")
        expectEqual(fp?.anchor?.description, anchor,
          "_StdlibFilePath \(input.debugDescription) coalesced anchor")
        expectTrue(fp?.components.isEmpty ?? false,
          "_StdlibFilePath \(input.debugDescription) should have no components")
        expectNil(_StdlibFilePath.Anchor(input),
          "Anchor.init? should reject \(input.debugDescription)")
      }
    }
  }

  // MARK: - Verbatim-UNC trailing separator is not synthesized (Windows)

  @Test
  func verbatimUNCTrailingSeparatorNotSynthesized() {
    withPlatform(.windows) {
      // A verbatim-UNC root with NO trailing separator must not have one
      // synthesized: `\\?\UNC\s\h` stores verbatim with hasTrailingSeparator
      // false, while `\\?\UNC\s\h\` has a genuine trailing separator. The
      // trailing separator is significant, so the two are not equal.
      let noSep: String = #"\\?\UNC\s\h"#
      let withSep: String = #"\\?\UNC\s\h\"#

      let a = _StdlibFilePath(noSep)!
      expectEqual(a.anchor?.description, #"\\?\UNC\s\h"#)
      expectTrue(a.components.isEmpty)
      expectFalse(a.hasTrailingSeparator,
        #"\\?\UNC\s\h should have no trailing separator"#)
      expectEqual(a.description, #"\\?\UNC\s\h"#,
        #"\\?\UNC\s\h must be stored without an added backslash"#)

      let b = _StdlibFilePath(withSep)!
      expectEqual(b.anchor?.description, #"\\?\UNC\s\h"#)
      expectTrue(b.components.isEmpty)
      expectTrue(b.hasTrailingSeparator,
        #"\\?\UNC\s\h\ should have a trailing separator"#)

      expectNotEqual(a, b,
        #"\\?\UNC\s\h must not equal \\?\UNC\s\h\"#)

      // A populated verbatim-UNC path is unaffected by the fix.
      let fooInput: String = #"\\?\UNC\server\share\foo"#
      let c = _StdlibFilePath(fooInput)!
      expectEqual(c.anchor?.description, #"\\?\UNC\server\share"#)
      expectEqual(c.components.map(\.description), ["foo"])
    }
  }

  // MARK: - isAbsolute (isRelative removed)

  @Test
  func isAbsoluteExists() {
    // On Windows `\foo` (the converted form of `/foo`) is the current-drive
    // root — rooted but not fully qualified, so isAbsolute is false. The
    // unix-side expectation is "absolute"; restrict to those.
    withPlatforms(.linux, .darwin) {
      let abs: _StdlibFilePath = "/foo"
      expectTrue(abs.isAbsolute)

      let rel: _StdlibFilePath = "foo"
      expectFalse(rel.isAbsolute)
    }
  }

  // MARK: - withCodeUnits

  @Test
  func withCodeUnitsProvidesPointerAndCount() {
    // Asserts CChar-typed values; unix-only.
    withPlatforms(.linux, .darwin) {
      let path: _StdlibFilePath = "/foo/bar"
      path.withCodeUnits { ptr, count in
        expectEqual(count, 8)
        expectEqual(ptr[0], CChar(UInt8(ascii: "/")))
        expectEqual(ptr[1], CChar(UInt8(ascii: "f")))
        expectEqual(ptr[4], CChar(UInt8(ascii: "/")))
        // The count excludes the null terminator, which sits at [count].
        expectEqual(ptr[count], 0)
      }
    }
  }

  @Test
  func withCodeUnitsEmpty() {
    let path: _StdlibFilePath = ""
    path.withCodeUnits { ptr, count in
      expectEqual(count, 0)
      expectEqual(ptr[0], 0)
    }
  }

  @Test
  func withCodeUnitsNonASCII() {
    // Asserts CChar-typed values and a UTF-8 byte (0xA9); unix-only.
    withPlatforms(.linux, .darwin) {
      let path: _StdlibFilePath = "/café"
      path.withCodeUnits { ptr, count in
        // "/café" is 6 UTF-8 bytes: / c a f 0xC3 0xA9
        expectEqual(count, 6)
        expectEqual(ptr[0], CChar(UInt8(ascii: "/")))
        expectEqual(ptr[5], CChar(bitPattern: 0xA9))
        expectEqual(ptr[count], 0)
      }
    }
  }

  @Test
  func withCodeUnitsReturnsValue() {
    let path: _StdlibFilePath = "/foo"
    let len = path.withCodeUnits { (ptr, _) -> Int in
      var i = 0
      while ptr[i] != 0 { i += 1 }
      return i
    }
    expectEqual(len, 4)
  }

  @Test
  func withCodeUnitsThrowsTypedError() {
    struct TestError: Error {}
    let path: _StdlibFilePath = "/foo"
    // SEAM EXCEPTION: no throwing-assertion helper in the seam (analogues
    // differ sharply across StdlibUnittest / XCTest).
    #expect(throws: TestError.self) {
      try path.withCodeUnits {
        (_: UnsafePointer<_StdlibFilePath.CodeUnit>, _: Int) throws(TestError) -> Int in
        throw TestError()
      }
    }
  }

  // MARK: - String literal inits

  @Test
  func componentStringLiteralValid() {
    let c: _StdlibFilePath.Component = "hello"
    expectEqual(c.description, "hello")
  }

  @Test
  func anchorStringLiteralValid() {
    let a: _StdlibFilePath.Anchor = "/"
    expectEqual(a.description, universal("/"))
  }
}
