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

extension AllTests.DecompositionTests {

  func runCase(_ tc: PathTestCase, platform: _Platform) {
    let expected: Expected
    switch platform {
    case .linux: expected = tc.linux
    case .darwin: expected = tc.darwin
    case .windows: expected = tc.windows
    }

    let path = _StdlibFilePath(tc.input)!

    // anchor
    let anchorDesc = path.anchor?.description
    expectEqual(anchorDesc, expected.anchor,
      "[\(platform)] input=\(tc.input.debugDescription) anchor: got \(anchorDesc.debugDescription), expected \(expected.anchor.debugDescription)")

    // components
    let compDescs = path.components.map(\.description)
    expectEqual(compDescs, expected.components,
      "[\(platform)] input=\(tc.input.debugDescription) components: got \(compDescs), expected \(expected.components)")

    // hasTrailingSeparator
    expectEqual(path.hasTrailingSeparator, expected.hasTrailingSeparator,
      "[\(platform)] input=\(tc.input.debugDescription) hasTrailingSep: got \(path.hasTrailingSeparator), expected \(expected.hasTrailingSeparator)")

    // isResourceFork (Darwin)
    if platform == .darwin {
      expectEqual(path.isResourceFork, expected.isResourceFork,
        "[\(platform)] input=\(tc.input.debugDescription) isResourceFork: got \(path.isResourceFork), expected \(expected.isResourceFork)")
    }

    // printed
    expectEqual(path.description, expected.printed,
      "[\(platform)] input=\(tc.input.debugDescription) printed: got \(path.description.debugDescription), expected \(expected.printed.debugDescription)")

    // isAbsolute
    expectEqual(path.isAbsolute, expected.isAbsolute,
      "[\(platform)] input=\(tc.input.debugDescription) isAbsolute: got \(path.isAbsolute), expected \(expected.isAbsolute)")

    // isRooted
    let expectedRooted = expected.isRooted ?? expected.isAbsolute
    let actualRooted = path.anchor?.isRooted ?? false
    expectEqual(actualRooted, expectedRooted,
      "[\(platform)] input=\(tc.input.debugDescription) isRooted: got \(actualRooted), expected \(expectedRooted)")

    // driveLetter
    if let expectedDrive = expected.driveLetter {
      expectTrue(path.anchor?._driveLetter == expectedDrive,
        "[\(platform)] input=\(tc.input.debugDescription) driveLetter: got \(path.anchor?._driveLetter.debugDescription ?? "nil"), expected \(expectedDrive)")
    }

    // kinds
    let actualKinds = path.components.map(\.kind)
    if let expectedKinds = expected.kinds {
      expectEqual(actualKinds, expectedKinds,
        "[\(platform)] input=\(tc.input.debugDescription) kinds: got \(actualKinds), expected \(expectedKinds)")
    } else {
      let allRegular = actualKinds.allSatisfy { $0 == .regular }
      expectTrue(allRegular,
        "[\(platform)] input=\(tc.input.debugDescription) kinds: expected all .regular, got \(actualKinds)")
    }

    // Round-trip: reconstruct from decomposition
    let roundTrip: _StdlibFilePath
    if expected.isResourceFork {
      roundTrip = _StdlibFilePath(
        anchor: path.anchor,
        path.components,
        resourceFork: true)
    } else {
      roundTrip = _StdlibFilePath(
        anchor: path.anchor,
        path.components,
        hasTrailingSeparator: path.hasTrailingSeparator)
    }
    expectEqual(roundTrip, path,
      "[\(platform)] input=\(tc.input.debugDescription) round-trip failed: got \(roundTrip.description.debugDescription), expected \(path.description.debugDescription)")
  }

  @Test(.linuxOnly)
  func allCasesLinux() {
    for tc in pathTestCases {
      runCase(tc, platform: .linux)
    }
  }

  @Test(.darwinOnly)
  func allCasesDarwin() {
    for tc in pathTestCases {
      runCase(tc, platform: .darwin)
    }
  }

  @Test(.windowsOnly)
  func allCasesWindows() {
    for tc in pathTestCases {
      runCase(tc, platform: .windows)
    }
  }
}
