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

// Coverage for the `_v2` forward-compat side channel on _StdlibFilePath Codable.
// See FilePathConformances.swift for the contract.
//
// Exercises the SE-0529 core directly rather than through the wrapper, so it is
// backing-independent: these expectations hold whichever backing is active.
@available(System 0.0.2, *)
final class FilePathV2CodableTest: XCTestCase {

  // MARK: - Round trip (new -> new)

  func testRoundTripPreservesTrailingSeparator() throws {
    // The whole point: a trailing separator survives encode+decode.
    let paths: [_StdlibFilePath] = [
      "/tmp/foo/",
      "foo/bar/",
      "/a/",
      "./",
    ]
    for path in paths {
      XCTAssertTrue(
        path.hasTrailingSeparator, "test precondition: \(path)")
      let data = try JSONEncoder().encode(path)
      let back = try JSONDecoder().decode(_StdlibFilePath.self, from: data)
      XCTAssertEqual(path, back, "round trip: \(path)")
      XCTAssertTrue(
        back.hasTrailingSeparator, "trailing sep lost: \(path)")
    }
  }

  func testRoundTripWithoutTrailingSeparator() throws {
    let paths: [_StdlibFilePath] = ["/tmp/foo", "foo/bar", "/", "", "a"]
    for path in paths {
      let data = try JSONEncoder().encode(path)
      let back = try JSONDecoder().decode(_StdlibFilePath.self, from: data)
      XCTAssertEqual(path, back, "round trip: \(path)")
    }
  }

  // MARK: - `_storage` stays old-normal (new -> old compatibility)

  func testStorageIsStrippedForOldDecoders() throws {
    // `_storage` must not carry the trailing separator, so an old decoder
    // (which rejects non-normal storage) can still read it. We can't run the
    // old decoder here, but we can assert the encoded `_storage` equals what
    // the stripped path encodes, i.e. no trailing separator in `_storage`.
    let path: _StdlibFilePath = "/tmp/foo/"
    let stripped: _StdlibFilePath = "/tmp/foo"

    let obj = try JSONSerialization.jsonObject(
      with: try JSONEncoder().encode(path)) as! [String: Any]
    let strippedObj = try JSONSerialization.jsonObject(
      with: try JSONEncoder().encode(stripped)) as! [String: Any]

    // `_storage` sub-object is byte-for-byte what the stripped path emits.
    let storageJSON = try JSONSerialization.data(
      withJSONObject: obj["_storage"]!, options: [.sortedKeys])
    let strippedStorageJSON = try JSONSerialization.data(
      withJSONObject: strippedObj["_storage"]!, options: [.sortedKeys])
    XCTAssertEqual(storageJSON, strippedStorageJSON)
  }

  func testV2IsAlwaysEmitted() throws {
    // Even a default (no trailing separator) path carries `_v2`.
    for path in [_StdlibFilePath("/tmp/foo"), _StdlibFilePath("/tmp/foo/")] {
      let obj = try JSONSerialization.jsonObject(
        with: try JSONEncoder().encode(path)) as! [String: Any]
      XCTAssertNotNil(obj["_v2"], "_v2 missing for \(path)")
      let v2 = obj["_v2"] as! [String: Any]
      XCTAssertNotNil(
        v2["hasTrailingSeparator"],
        "hasTrailingSeparator missing for \(path)")
    }
  }

  func testV2FlagMatchesTrailingSeparator() throws {
    let cases: [(_StdlibFilePath, Bool)] = [
      ("/tmp/foo/", true),
      ("/tmp/foo", false),
      ("foo/", true),
      ("foo", false),
      ("/", false),
    ]
    for (path, expected) in cases {
      let obj = try JSONSerialization.jsonObject(
        with: try JSONEncoder().encode(path)) as! [String: Any]
      let v2 = obj["_v2"] as! [String: Any]
      XCTAssertEqual(
        v2["hasTrailingSeparator"] as? Bool, expected,
        "flag wrong for \(path)")
    }
  }

  // MARK: - Decoding old / v1 archives (no `_v2`)

  func testDecodeWithoutV2DefaultsToNoTrailingSeparator() throws {
    // An archive with only `_storage` (old / v1) must decode, defaulting the
    // trailing separator off. `/tmp/foo` in old-normal bytes.
    //
    // / t m p / f o o \0
    let json = #"""
      {"_storage":{"nullTerminatedStorage":[47,116,109,112,47,102,111,111,0]}}
      """#
    let path = try JSONDecoder().decode(
      _StdlibFilePath.self, from: Data(json.utf8))
    XCTAssertEqual(path, "/tmp/foo")
    XCTAssertFalse(path.hasTrailingSeparator)
  }

  func testDecodeWithEmptyV2DefaultsFields() throws {
    // `_v2` present but empty: append-only contract says default every field.
    let json = #"""
      {"_storage":{"nullTerminatedStorage":[47,116,109,112,47,102,111,111,0]},"_v2":{}}
      """#
    let path = try JSONDecoder().decode(
      _StdlibFilePath.self, from: Data(json.utf8))
    XCTAssertEqual(path, "/tmp/foo")
    XCTAssertFalse(path.hasTrailingSeparator)
  }

  func testDecodeWithUnknownV2FieldIsIgnored() throws {
    // A future field this version doesn't know is ignored, not fatal.
    let json = #"""
      {"_storage":{"nullTerminatedStorage":[47,116,109,112,0]},"_v2":{"hasTrailingSeparator":true,"somethingNewer":42}}
      """#
    let path = try JSONDecoder().decode(
      _StdlibFilePath.self, from: Data(json.utf8))
    XCTAssertEqual(path, "/tmp/")
    XCTAssertTrue(path.hasTrailingSeparator)
  }
}
