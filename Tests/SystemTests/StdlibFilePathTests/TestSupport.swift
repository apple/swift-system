/*
 This source file is part of the SE-0529 reference implementation

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
import Foundation
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// TestSupport — the indirection seam between test bodies and (a) the test
// framework, and (b) compile-time platform selection. At port time only this
// file is rewritten: the `expect*` helpers forward to StdlibUnittest / XCTest
// natives, and the platform helpers evaporate (the stdlib build is naturally
// platform-fixed).
//
// Test bodies MUST go through the seam: no direct `#expect` /
// `Testing.withKnownIssue`, no direct read of `_builtPlatform`. The one
// in-tree exception is `withCodeUnitsThrowsTypedError` in ValidationTests —
// the seam has no throwing-assertion helper because the analogues differ
// sharply across destination frameworks.

// MARK: - Assertion seam

/// Empty messages → nil (otherwise swift-testing renders an empty comment).
private func _msg(_ s: String) -> Comment? {
  s.isEmpty ? nil : "\(s)"
}

func expectEqual<T: Equatable>(
  _ lhs: T, _ rhs: T,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(lhs == rhs, _msg(message()), sourceLocation: sourceLocation)
}

func expectNotEqual<T: Equatable>(
  _ lhs: T, _ rhs: T,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(lhs != rhs, _msg(message()), sourceLocation: sourceLocation)
}

func expectTrue(
  _ condition: Bool,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(condition, _msg(message()), sourceLocation: sourceLocation)
}

func expectFalse(
  _ condition: Bool,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(!condition, _msg(message()), sourceLocation: sourceLocation)
}

// `T` is unconstrained: nil-comparison on `Optional<T>` doesn't require
// `Equatable`, and dropping the constraint keeps the signature expressible
// in every destination framework.
func expectNil<T>(
  _ value: T?,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(value == nil, _msg(message()), sourceLocation: sourceLocation)
}

func expectNotNil<T>(
  _ value: T?,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(value != nil, _msg(message()), sourceLocation: sourceLocation)
}

/// Records issues thrown inside `body` as *known* issues rather than failures.
func expectKnownIssue(
  _ message: String? = nil,
  sourceLocation: SourceLocation = #_sourceLocation,
  _ body: () throws -> Void
) {
  Testing.withKnownIssue(
    message.map { "\($0)" }, sourceLocation: sourceLocation
  ) {
    try body()
  }
}

// MARK: - Platform-runner seam

/// Platform tag for gating tests. Internal so test files can name the
/// platforms (`.linux` / `.darwin` / `.windows`); the library itself uses
/// compile-time predicates and doesn't carry a type.
enum _Platform: Sendable { case linux, darwin, windows }

/// The single platform this target was built for, selected at compile time.
let _builtPlatform: _Platform = {
  #if os(Windows)
  .windows
  #elseif canImport(Darwin)
  .darwin
  #else
  .linux
  #endif
}()

/// Runs `body` only when `p` is the built platform. Other-platform calls are
/// inert — the test still runs and passes, it just makes no assertions.
func withPlatform(
  _ p: _Platform,
  _ body: () throws -> Void
) rethrows {
  guard p == _builtPlatform else { return }
  try body()
}

/// Runs `body` when the built platform is one of `ps`. Canonical case:
/// `withPlatforms(.linux, .darwin)` for "any unix". Tests valid on every
/// platform should carry no gate at all.
func withPlatforms(
  _ ps: _Platform...,
  body: () throws -> Void
) rethrows {
  guard ps.contains(_builtPlatform) else { return }
  try body()
}

// MARK: - Universal path literals

/// Translates a `/`-form path string into the build's separator spelling, so
/// platform-INDEPENDENT tests can share expected strings:
///
///     expectEqual(path.description, universal("/usr/local/bin"))
///
/// Valid only for paths universal modulo the separator byte: relative paths
/// and plain-root paths. Not for platform-specific anchors (`C:`, UNC, `\\?\…`,
/// `/.vol/…`, `/.nofollow/…`, `/.resolve/…`) — those need a platform-specific
/// test. Traps on backslashes in the input or non-plain-root anchors.
func universal(_ canonicalSlashForm: String) -> String {
  precondition(
    !canonicalSlashForm.contains("\\"),
    "universal(): literal contains a backslash; write it with '/' as the "
    + "canonical separator, or use an exact string in a platform-specific "
    + "test: \(canonicalSlashForm)")
  let parsed = _StdlibFilePath(canonicalSlashForm)
  if let anchor = parsed?.anchor {
    let basicRoot: String = _isWindows ? "\\" : "/"
    precondition(
      anchor.description == basicRoot,
      "universal(): literal has a platform-specific anchor "
      + "(\(anchor.description)); use an exact string in a platform-specific "
      + "test: \(canonicalSlashForm)")
  }
  return _isWindows
    ? canonicalSlashForm.replacingOccurrences(of: "/", with: "\\")
    : canonicalSlashForm
}

// MARK: - Windows-only API shims
//
// `driveLetter` and `isVerbatimComponent` are gated under `#if os(Windows)`
// per the proposal. These shims expose them on every build (real value on
// Windows, benign default elsewhere) so test bodies inside
// `withPlatform(.windows)` blocks type-check on non-Windows builds.

extension _StdlibFilePath.Anchor {
  var _driveLetter: Unicode.Scalar? {
    #if os(Windows)
    return self.driveLetter
    #else
    return nil
    #endif
  }

  var _isVerbatimComponent: Bool {
    #if os(Windows)
    return self.isVerbatimComponent
    #else
    return false
    #endif
  }
}
