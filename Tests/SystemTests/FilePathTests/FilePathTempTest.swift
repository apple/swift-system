/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class TemporaryPathTest: XCTestCase {
  func testUnique() throws {
    try withTemporaryPath(basename: "test") { path in
      let strPath = String(decoding: path)
      XCTAssert(strPath.contains("test"))
      try withTemporaryPath(basename: "test") { path2 in
        let strPath2 = String(decoding: path2)
        XCTAssertNotEqual(strPath, strPath2)
      }
    }
  }

  func testCleanup() throws {
    var thePath: FilePath? = nil

    try withTemporaryPath(basename: "test") { path in
      thePath = path.appending("foo.txt")
      let fd = try FileDescriptor.open(thePath!, .readWrite,
                                       options: [.create, .truncate],
                                       permissions: .ownerReadWrite)
      _ = try fd.closeAfter {
        try fd.writeAll("Hello World".utf8)
      }
    }

    XCTAssertThrowsError(try FileDescriptor.open(thePath!, .readOnly)) {
      error in

      XCTAssertEqual(error as! Errno, Errno.noSuchFileOrDirectory)
    }
  }
}
