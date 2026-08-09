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

// `_StdlibFilePath.resolve()` is a filesystem-touching API: tests need a real OS,
// real syscalls, and real fixtures. The Darwin implementation uses
// `getattrlistat(ATTR_CMN_FULLPATH, FSOPT_ATTR_CMN_EXTENDED |
// FSOPT_RETURN_REALDEV)` — *no* `realpath`, *no* `FSOPT_AUTOFIRMLINKPATH`
// (the firmlink-aware private flag is unavailable from public SDKs and the
// no-flag default already returns the firmlinked path for everything we
// care about — pinned by `firmlinkedHomeRealPath` below). All tests run only
// on the Darwin build via `withPlatform(.darwin)`; on other builds the
// bodies are inert.
//
// Top-level suite (separate from `AllTests`) so we don't have to add a
// nested struct to AllTests.swift. Mirrors the `SystemStringTests` pattern.

@Suite
struct ResolveTests {

  // MARK: - Helpers

  /// Make a fresh, unique temp directory under the system temp dir.
  /// Caller is responsible for cleanup via `defer` + `_cleanup`.
  private func _makeTempDir() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("filepath-resolve-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(
      at: url, withIntermediateDirectories: true)
    return url
  }

  private func _cleanup(_ url: URL) {
    _ = try? FileManager.default.removeItem(at: url)
  }

  /// Asserts `body` throws a `_FilePathResolveError`. Equivalent to
  /// `#expect(throws: _FilePathResolveError.self)` but expressed without the
  /// throwing-assertion seam (which the TestSupport layer doesn't yet vend
  /// — see `withCodeUnitsThrowsTypedError` for the established exception
  /// pattern). Keeps the type check rather than a bare did-it-throw bool, so
  /// a future unexpected-error-type regression fails loudly.
  private func _expectThrowsResolveError(
    _ body: () throws -> Void,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    do {
      try body()
      expectTrue(false, "expected resolve() to throw",
        sourceLocation: sourceLocation)
    } catch is _FilePathResolveError {
      // Expected.
    } catch {
      expectTrue(false,
        "expected _FilePathResolveError, got \(type(of: error)): \(error)",
        sourceLocation: sourceLocation)
    }
  }

  // MARK: - Real existing file resolves to absolute, symlink-free path

  @Test
  func realFileResolvesToAbsoluteSymlinkFreePath() throws {
    try withPlatform(.darwin) {
      let dir = try _makeTempDir()
      defer { _cleanup(dir) }

      let fileURL = dir.appendingPathComponent("hello.txt")
      let created = FileManager.default.createFile(
        atPath: fileURL.path, contents: Data())
      expectTrue(created, "could not create fixture \(fileURL.path)")

      // _StdlibFilePath.init? on a Foundation URL path can only fail on NUL,
      // which these paths cannot contain — hence the bare `!`.
      let resolved = try _StdlibFilePath(fileURL.path)!.resolve()
      expectTrue(resolved.isAbsolute,
        "resolve() should return an absolute path, got "
        + String(decoding: resolved))

      // Symlink-free check: macOS exposes `/var` as a symlink to
      // `/private/var`, and `FileManager.default.temporaryDirectory` lives
      // under `/var/folders/...`. A correct `resolve()` follows that
      // symlink and returns a `/private/var/...` path; a `/var/...` prefix
      // means the symlink was not followed.
      let s = String(decoding: resolved)
      expectFalse(s.hasPrefix("/var/"),
        "resolve() did not follow /var symlink: \(s)")
    }
  }

  // MARK: - Resolving through a symlink yields the link target

  @Test
  func resolvingThroughSymlinkYieldsTarget() throws {
    try withPlatform(.darwin) {
      let dir = try _makeTempDir()
      defer { _cleanup(dir) }

      let target = dir.appendingPathComponent("target.txt")
      let link = dir.appendingPathComponent("link.txt")
      _ = FileManager.default.createFile(
        atPath: target.path, contents: Data())
      try FileManager.default.createSymbolicLink(
        at: link, withDestinationURL: target)

      let resolvedLink = try _StdlibFilePath(link.path)!.resolve()
      let resolvedTarget = try _StdlibFilePath(target.path)!.resolve()

      expectEqual(resolvedLink, resolvedTarget,
        "link should resolve to the same path as the target — "
        + "got link → \(String(decoding: resolvedLink)) "
        + "and target → \(String(decoding: resolvedTarget))")
    }
  }

  // MARK: - Nonexistent path throws

  @Test
  func nonexistentPathThrows() {
    withPlatform(.darwin) {
      // Unique suffix to ensure we don't accidentally hit a real file.
      let p = _StdlibFilePath(
        "/this/path/does/not/exist/anywhere/\(UUID().uuidString)")!
      _expectThrowsResolveError { _ = try p.resolve() }
    }
  }

  // MARK: - Firmlink check (go/no-go for the no-FSOPT approach)
  //
  // On macOS Big Sur+, `/Users` lives on the data volume and is exposed via
  // a firmlink. The kernel's *default* behavior for `ATTR_CMN_FULLPATH`
  // returns the firmlinked path (e.g. `/Users/foo`). The non-firmlinked
  // underlay is `/System/Volumes/Data/Users/foo`; if `resolve()` returned
  // that prefix, our no-FSOPT_AUTOFIRMLINKPATH approach would be invalid
  // and the implementation would need the private SPI flag.

  @Test
  func firmlinkedHomeRealPath() throws {
    try withPlatform(.darwin) {
      let home = FileManager.default.homeDirectoryForCurrentUser.path
      let resolved = try _StdlibFilePath(home)!.resolve()
      let s = String(decoding: resolved)
      expectFalse(s.hasPrefix("/System/Volumes/Data/"),
        "resolve(\(home)) returned the non-firmlinked underlay: \(s) "
        + "— the no-FSOPT default does not produce firmlinked paths on "
        + "this build, so the no-SPI approach is invalid")
    }
  }
}
