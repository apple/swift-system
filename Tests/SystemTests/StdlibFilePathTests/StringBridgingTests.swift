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

// String bridging, including ill-formed Unicode. Expectations from SE-0529
// ("Paths and strings", and the `description` documentation for each type):
//   * `String(decoding:)`: UTF-8 (Linux/Darwin) or UTF-16 (Windows) decode,
//     replacing ill-formed sequences with U+FFFD. Never fails.
//   * `String(validating:)`: `nil` when the content is not well-formed.
//   * `description` equals `String(decoding:)` for the same value.
//
// `_StdlibFilePath.CodeUnit` and the decode encoding are fixed at compile time:
// `CChar`/UTF-8 off Windows, `UInt16`/UTF-16 on Windows. So on a non-Windows
// build the ill-formed cases use lone UTF-8 bytes (0x80 / 0xFF). The Windows
// analogue is an unpaired UTF-16 surrogate, which this build cannot express in
// `[CChar]`, so it is not faked here.

extension AllTests.StringBridgingTests {

  // MARK: - codeUnits init path (mirrors ValidationTests)

  private func filePath(fromCodeUnits units: [_StdlibFilePath.CodeUnit]) -> _StdlibFilePath? {
    _StdlibFilePath(codeUnits: units.span)
  }

  private func component(
    fromCodeUnits units: [_StdlibFilePath.CodeUnit]
  ) -> _StdlibFilePath.Component? {
    _StdlibFilePath.Component(codeUnits: units.span)
  }

  // MARK: - Well-formed round-trips

  // For well-formed content, both `String(decoding:)` and `String(validating:)`
  // recover the original text exactly.
  @Test(.unixOnly)
  func wellFormedRoundTripFilePath() {
    // Inputs use `/`-form paths whose stored bytes (and decoded String)
    // differ on Windows; restrict to unix.
    for s in ["/foo/bar", "foo/bar", "/usr/local/bin", "/café/naïve", "a/b/c"] {
      let p = _StdlibFilePath(s)!
      expectEqual(String(decoding: p), s,
        "decoding recovers \(s.debugDescription)")
      // String(validating:) is String?; compare against the non-optional
      // (Swift promotes the rhs). A nil here would also fail this assertion.
      expectTrue(String(validating: p) == s,
        "validating recovers \(s.debugDescription)")
    }
}

  @Test
  func wellFormedRoundTripAnchor() {
    withPlatforms(.linux, .darwin) {
      let a = _StdlibFilePath.Anchor("/")
      expectEqual(String(decoding: a), "/", "decoding anchor /")
      expectTrue(String(validating: a) == "/", "validating anchor /")
    }
    withPlatform(.windows) {
      let a = _StdlibFilePath.Anchor(#"C:\"#)
      expectEqual(String(decoding: a), #"C:\"#, "decoding anchor C:\\")
      expectTrue(String(validating: a) == #"C:\"#, "validating anchor C:\\")
    }
    withPlatform(.darwin) {
      let a = _StdlibFilePath.Anchor("/.nofollow/")
      expectEqual(String(decoding: a), "/.nofollow/", "decoding anchor /.nofollow/")
      expectTrue(String(validating: a) == "/.nofollow/",
        "validating anchor /.nofollow/")
    }
  }

  @Test
  func wellFormedRoundTripComponent() {
    // Component names have no separator; round-trips are universal.
    for name in ["foo", "file.txt", "café", ".."] {
      let c = _StdlibFilePath.Component(name)!
      expectEqual(String(decoding: c), name,
        "decoding component \(name.debugDescription)")
      expectTrue(String(validating: c) == name,
        "validating component \(name.debugDescription)")
    }
  }

  // MARK: - description == String(decoding:)

  // The proposal specifies `description` as `String(decoding:)` of the same
  // value (lossy, U+FFFD-correcting). Pin that identity on all three types;
  // it holds whatever the platform-specific stored bytes look like.
  @Test
  func descriptionEqualsDecoding() {
    let p = _StdlibFilePath("/foo/bar")
    expectEqual(p.description, String(decoding: p), "_StdlibFilePath description")

    let a = _StdlibFilePath.Anchor("/")
    expectEqual(a.description, String(decoding: a), "Anchor description")

    let c = _StdlibFilePath.Component("foo")
    expectEqual(c.description, String(decoding: c), "Component description")
  }

#if !os(Windows)
  // MARK: - Ill-formed Unicode (UTF-8 / CChar build only)
  //
  // Lone 0x80 is a UTF-8 continuation byte with no leader; 0xFF never appears
  // in valid UTF-8. We append them to "foo" and drive construction through the
  // public codeUnits init (the path ValidationTests uses).
  //
  // Not exercised here: on a `UInt16`/UTF-16 build the analogous ill-formed
  // input is an unpaired surrogate (a lone 0xD800, say). A lone surrogate is
  // not representable in `[CChar]`, so rather than fake one, this section is
  // `#if !os(Windows)`.

  private func illFormedUTF8Bytes() -> [_StdlibFilePath.CodeUnit] {
    let prefix = "foo".utf8.map { _StdlibFilePath.CodeUnit(bitPattern: $0) }
    let bad: [_StdlibFilePath.CodeUnit] = [
      _StdlibFilePath.CodeUnit(bitPattern: 0x80),
      _StdlibFilePath.CodeUnit(bitPattern: 0xFF),
    ]
    return prefix + bad
  }

  @Test
  func illFormedFilePath() {
    let p = filePath(fromCodeUnits: illFormedUTF8Bytes())!
    // validating: ill-formed => nil
    expectNil(String(validating: p),
      "String(validating:) is nil for ill-formed _StdlibFilePath")
    // decoding: lossy => contains U+FFFD, never fails
    expectTrue(String(decoding: p).unicodeScalars.contains("\u{FFFD}"),
      "String(decoding:) yields U+FFFD for ill-formed _StdlibFilePath")
    // description tracks decoding even when ill-formed
    expectEqual(p.description, String(decoding: p),
      "description == decoding (ill-formed)")
  }

  @Test
  func illFormedComponent() {
    let c = component(fromCodeUnits: illFormedUTF8Bytes())!

    // decoding: lossy => U+FFFD. This matches the proposal and the impl.
    expectTrue(String(decoding: c).unicodeScalars.contains("\u{FFFD}"),
      "String(decoding:) yields U+FFFD for ill-formed Component")

    // Per SE-0529, `String?(validating: component)` returns nil when the
    // content is not well-formed Unicode, so FilePathStringBridging.swift
    // implements it as a decode/re-encode/compare round-trip (matching the
    // `_StdlibFilePath` overload) rather than off the lossy U+FFFD description.
    //
    // The Anchor overload works the same way but is not directly reachable
    // from a test: Anchor has no public codeUnits initializer, so there is no
    // way to smuggle ill-formed bytes into its (otherwise structural, ASCII)
    // region.
    expectNil(String(validating: c),
      "String(validating:) should be nil for ill-formed Component")
  }
#endif
}
