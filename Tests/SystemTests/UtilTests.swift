/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

class UtilTests: XCTestCase {
  func testStackBuffer() {
    // Exercises _withStackBuffer a bit, in hopes any bugs will
    // show up as ASan failures.
    for size in stride(from: 0, to: 1000, by: 5) {
      var called = false
      _withStackBuffer(capacity: size) { buffer in
        XCTAssertFalse(called)
        called = true

        buffer.initializeMemory(as: UInt8.self, repeating: 42)
      }
      XCTAssertTrue(called)
    }
  }

  func testCStringArray() {
    func check(
      _ array: [String],
      file: StaticString = #file,
      line: UInt = #line
    ) {
      array._withCStringArray { carray in
        let actual = carray.map { $0.map { String(cString: $0) } ?? "<NULL>" }
        XCTAssertEqual(actual, array, file: file, line: line)
        // Verify that there is a null pointer following the last item in
        // carray. (Note: this is intentionally addressing beyond the
        // end of the buffer, as the function promises that is going to be okay.)
        XCTAssertNil((carray.baseAddress! + carray.count).pointee)
      }
    }

    check([])
    check([""])
    check(["", ""])
    check(["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""])
    // String literals of various sizes and counts
    check(["hello"])
    check(["hello", "world"])
    check(["This is a rather large string literal"])
    check([
      "This is a rather large string literal",
      "This is small",
      "This one is not that small -- it's even longer than the first",
    ])
    check([
      "This is a rather large string literal",
      "This one is not that small -- it's even longer than the first",
      "And this is the largest of them all. I wonder if it even fits on a line"
    ])
    check(Array(repeating: "", count: 100))
    check(Array(repeating: "Hiii", count: 100))
    check(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m"])
    check(["", "b", "", "d", "", "f", "", "h", "", "j", "", "👨‍👨‍👧‍👦👩‍❤️‍💋‍👨", "m"])

    var girls = ["Dörothy", "Róse", "Blánche", "Sőphia"]
    check(girls) // Small strings
    for i in girls.indices {
      // Convert to native
      girls[i] = "\(girls[i]) \(girls[i]) \(girls[i])"
    }
    check(girls) // Native large strings
    for i in girls.indices {
      let data = girls[i].data(using: .utf16)!
      girls[i] = NSString(
        data: data,
        encoding: String.Encoding.utf16.rawValue
      )! as String
    }
    check(girls) // UTF-16 Cocoa strings
  }
}
