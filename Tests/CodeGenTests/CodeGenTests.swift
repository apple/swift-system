/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

import XCTest
import SystemPackage
import CodeGen

final class CodeGenTests: XCTestCase {
  func testPlatformConstants() throws {

    let dir = FilePath(#filePath).removingLastComponent()
    let outCostants = dir.appending("output/constants")
    let outTests = dir.appending("output/tests")
    try populatePlatformConstants(
      constantsPath: outCostants, testsPath: outTests)

    let refConstants = try String(contentsOfFile: platformConstantsPath.string)
    let refTests = try String(contentsOfFile: platformTestsPath.string)

    XCTAssertEqual(refConstants, try String(contentsOfFile: outCostants.string))
    XCTAssertEqual(refTests, try String(contentsOfFile: outTests.string))

  }
}
