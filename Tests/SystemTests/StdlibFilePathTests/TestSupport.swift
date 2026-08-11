/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
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

// TestSupport is the seam between the test bodies and (a) the test framework,
// (b) the platform this target was built for. Test bodies go through it: they
// call the `expect*` helpers rather than `#expect` directly, and they name a
// platform with the traits and gates below rather than reading
// `_builtPlatform`. Keeping the seam this narrow is what lets the suite change
// test frameworks by rewriting one file.
//
// One assertion has no seam helper. `withCodeUnitsThrowsTypedError` in
// ValidationTests calls `#expect(throws:)` directly, because throwing
// assertions have no common spelling across frameworks.

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

// `T` is unconstrained: comparing `Optional<T>` against nil does not
// require `Equatable`.
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

/// Test traits that skip a test whose subject does not exist on the built
/// platform. A whole-platform test carries the trait, so an off-platform run
/// reports it as skipped; a test that asserts on several platforms carries no
/// trait and gates its per-platform sections with `withPlatform` below.
///
/// Prefer the trait. A gate that spans a whole test body makes the test pass
/// while asserting nothing, which reads as coverage that isn't there.
extension Trait where Self == ConditionTrait {
  static var windowsOnly: Self {
    .enabled(if: _builtPlatform == .windows, "Windows-only path syntax")
  }
  static var darwinOnly: Self {
    .enabled(if: _builtPlatform == .darwin, "Darwin-only path syntax")
  }
  static var linuxOnly: Self {
    .enabled(if: _builtPlatform == .linux, "Linux-only path syntax")
  }
  static var unixOnly: Self {
    .enabled(if: _builtPlatform != .windows, "unix-only path syntax")
  }
}

/// Runs `body` only when `p` is the built platform, for one section of a test
/// that also asserts on other platforms. Off-platform calls are inert, so a
/// gate wrapping an entire test body would make it pass vacuously: use the
/// `.windowsOnly` / `.darwinOnly` / `.linuxOnly` traits for that instead.
func withPlatform(
  _ p: _Platform,
  _ body: () throws -> Void
) rethrows {
  guard p == _builtPlatform else { return }
  try body()
}

/// Runs `body` when the built platform is one of `ps`, for one section of a
/// mixed-platform test. Canonical case: `withPlatforms(.linux, .darwin)` for
/// "any unix". Tests valid on every platform should carry no gate at all.
func withPlatforms(
  _ ps: _Platform...,
  body: () throws -> Void
) rethrows {
  guard ps.contains(_builtPlatform) else { return }
  try body()
}

// MARK: - Universal path literals

/// Translates a `/`-form path string into the build's separator spelling, so
/// platform-independent tests can share expected strings:
///
///     expectEqual(path.description, universal("/usr/local/bin"))
///
/// Valid only for paths universal modulo the separator byte: relative paths
/// and plain-root paths. Not for platform-specific anchors (`C:`, UNC, `\\?\…`,
/// `/.vol/…`, `/.nofollow/…`, `/.resolve/…`), which need a platform-specific
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
// per the proposal. These shims expose them on every build (the real value on
// Windows, a benign default elsewhere) so that Windows-only test bodies still
// type-check on a non-Windows build.

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
