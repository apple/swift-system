/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import Foundation

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Component and Root Codable. The wire format is the historical synthesized
// shape over their old stored properties:
//
//   Component: { "_path": <FilePath>, "_range": [lower, upper] }
//   Root:      { "_path": <FilePath>, "_rootEnd": N }
//
// The nested `_path` follows the ACTIVE backing, so under the SE-0529 backing it
// additionally carries the `_v2` side channel. See FilePathConformances.swift for
// why decoding must slice `_path`'s raw storage before normalizing, and why
// decode needs no era switch while encode does.
@available(System 0.0.2, *)
final class FilePathSliceCodableTest: XCTestCase {

  // MARK: - Wire shape

  func testComponentWireShape() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let c: FilePath.Component = "foo"
    // ERA: the nested `_path` is whichever backing is active (see
    // FilePathConformances.swift `_SlicePathPayload`). The historical backing
    // emits `_storage` alone; `_StdlibFilePath` also emits the `_v2`
    // forward-compat side channel carrying the now-significant trailing
    // separator.
    let expected = usingStdlibFilePath
      ? #"{"_path":{"_storage":{"nullTerminatedStorage":[102,111,111,0]},"_v2":{"hasTrailingSeparator":false}},"_range":[0,3]}"#
      : #"{"_path":{"_storage":{"nullTerminatedStorage":[102,111,111,0]}},"_range":[0,3]}"#
    XCTAssertEqual(
      String(decoding: try encoder.encode(c), as: UTF8.self),
      expected
    )
  }

#if !os(Windows)
  func testRootWireShape() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let r: FilePath.Root = "/"
    // ERA: `Root` is a thin wrapper over whichever backing is active, so its
    // `_path` sub-object is that backing's own Codable output. The historical
    // backing emits `_storage` alone; `_StdlibFilePath` always also emits the
    // `_v2` forward-compat side channel (see FilePathConformances.swift), which
    // is what carries the now-significant trailing separator.
    let expected = usingStdlibFilePath
      ? #"{"_path":{"_storage":{"nullTerminatedStorage":[47,0]},"_v2":{"hasTrailingSeparator":false}},"_rootEnd":1}"#
      : #"{"_path":{"_storage":{"nullTerminatedStorage":[47,0]}},"_rootEnd":1}"#
    XCTAssertEqual(
      String(decoding: try encoder.encode(r), as: UTF8.self),
      expected
    )
  }
#endif

  // MARK: - Round trip

  func testComponentRoundTrip() throws {
    let components: [FilePath.Component] = [
      "foo", "foo.txt", "foo.tar.gz", ".hidden", "a", ".", "..", "...",
      "..bar", "\u{3042}",
    ]
    for c in components {
      let data = try JSONEncoder().encode(c)
      let back = try JSONDecoder().decode(FilePath.Component.self, from: data)
      XCTAssertEqual(c, back)
    }
  }

  func testRootRoundTrip() throws {
    let r: FilePath.Root = "/"
    let data = try JSONEncoder().encode(r)
    let back = try JSONDecoder().decode(FilePath.Root.self, from: data)
    XCTAssertEqual(r, back)
  }

  // MARK: - Decoding the old format

  func testComponentDecodeOffsetsIntoUnnormalizedPath() throws {
    // THE trap. Old swift-system's normalization touched separators only,
    // never dots, so it stored "/./foo" verbatim and gave the "foo"
    // component a _range of 3..<6. The copy normalizes "/./foo" to "/foo",
    // where 3..<6 is out of bounds. Decoding _path as a FilePath and slicing
    // after would read the wrong bytes; the raw storage has to be sliced
    // first.
    //
    // / . / f o o \0
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[47,46,47,102,111,111,0]}},"_range":[3,6]}
      """#
    let c = try JSONDecoder().decode(
      FilePath.Component.self, from: Data(json.utf8))
    XCTAssertEqual(c, "foo")
  }

  func testComponentDecodeSlicesFromLongerPath() throws {
    // Old always encoded the whole originating path, not just the component:
    // "/usr/bin" with _range 5..<8 is the component "bin".
    //
    // / u s r / b i n \0
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[47,117,115,114,47,98,105,110,0]}},"_range":[5,8]}
      """#
    let c = try JSONDecoder().decode(
      FilePath.Component.self, from: Data(json.utf8))
    XCTAssertEqual(c, "bin")
  }

#if !os(Windows)
  func testRootDecodeSlicesFromLongerPath() throws {
    // "/usr/bin" with _rootEnd 1 is the root "/".
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[47,117,115,114,47,98,105,110,0]}},"_rootEnd":1}
      """#
    let r = try JSONDecoder().decode(FilePath.Root.self, from: Data(json.utf8))
    XCTAssertEqual(r, "/")
  }
#endif

  // MARK: - Rejections

  func testComponentDecodeRejectsRangeSpanningSeparator() {
    // "/usr/bin"[1..<8] is "usr/bin": two components, not one.
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[47,117,115,114,47,98,105,110,0]}},"_range":[1,8]}
      """#
    XCTAssertThrowsError(try JSONDecoder().decode(
      FilePath.Component.self, from: Data(json.utf8)))
  }

  func testComponentDecodeRejectsOutOfBoundsRange() {
    // endIndex excludes the null terminator, so 3 is the end of "foo".
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[102,111,111,0]}},"_range":[0,4]}
      """#
    XCTAssertThrowsError(try JSONDecoder().decode(
      FilePath.Component.self, from: Data(json.utf8)))
  }

  func testComponentDecodeRejectsEmptyRange() {
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[102,111,111,0]}},"_range":[1,1]}
      """#
    XCTAssertThrowsError(try JSONDecoder().decode(
      FilePath.Component.self, from: Data(json.utf8)))
  }

  // Root decode validation is SE-0529-only, so the next two tests are guarded
  // rather than made backing-aware. swift-system got `Root`'s Codable
  // synthesized off its stored `_path` / `_rootEnd` via the internal
  // `_StrSlice: Codable` conformance (swift-system 8ac955b: no `init(from:)`
  // anywhere in FilePathComponents.swift), so it validated nothing beyond what
  // `_path` itself checked. Neither test existed pre-port. Under the
  // swiftSystem backing these archives decode into `Root`s that violate the
  // old type's own invariants, faithfully reproducing history, but there is
  // no historical expectation to assert, so there is nothing to pin.

  func testRootDecodeRejectsZeroRootEnd() throws {
    try XCTSkipUnless(
      usingStdlibFilePath,
      "Root decode validation is SE-0529-only")
    // Mirrors the old Root invariant `_rootEnd > _path._storage.startIndex`.
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[47,0]}},"_rootEnd":0}
      """#
    XCTAssertThrowsError(try JSONDecoder().decode(
      FilePath.Root.self, from: Data(json.utf8)))
  }

  func testRootDecodeRejectsNonRoot() throws {
    try XCTSkipUnless(
      usingStdlibFilePath,
      "Root decode validation is SE-0529-only")
    // "foo"[0..<3] is a component, not a root.
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[102,111,111,0]}},"_rootEnd":3}
      """#
    XCTAssertThrowsError(try JSONDecoder().decode(
      FilePath.Root.self, from: Data(json.utf8)))
  }

  func testSliceDecodeRejectsCorruptSystemString() {
    // SystemString's own decoder still validates: interior NUL.
    let json = #"""
      {"_path":{"_storage":{"nullTerminatedStorage":[102,0,111,0]}},"_range":[0,1]}
      """#
    XCTAssertThrowsError(try JSONDecoder().decode(
      FilePath.Component.self, from: Data(json.utf8)))
  }
}
