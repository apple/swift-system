/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

final class InternalUnitTests: XCTestCase {


  func testFileOffsets() {
    func test(
      _ br: (some RangeExpression<Int64>)?,
      _ expected: (start: Int64, length: Int64)
    ) {
      let (start, len) = _mapByteRangeToByteOffsets(br)
      XCTAssertEqual(start, expected.start)
      XCTAssertEqual(len, expected.length)
    }

    test(2..<5, (start: 2, length: 3))
    test(2...5, (start: 2, length: 4))

    test(..<5, (start: 0, length: 5))
    test(...5, (start: 0, length: 6))
    test(5..., (start: 5, length: 0))

    // E.g. for use in specifying n bytes behind SEEK_CUR
    //
    // FIXME: are these ok? the API is for absolute
    // offsets...
    test((-3)..., (start: -3, length: 0))
    test((-3)..<0, (start: -3, length: 3))

    // Non-sensical: up to the caller
    test(..<(-5), (start: 0, length: -5))

  }


  
}
