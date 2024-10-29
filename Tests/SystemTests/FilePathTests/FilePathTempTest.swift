/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

final class TemporaryPathTest: XCTestCase {
  #if SYSTEM_PACKAGE_DARWIN
  func testNotInSlashTmp() throws {
    try withTemporaryFilePath(basename: "NotInSlashTmp") { path in
      // We shouldn't be using "/tmp" on Darwin
      XCTAssertNotEqual(path.components.first!, "tmp")
    }
  }
  #endif

  func testUnique() throws {
    try withTemporaryFilePath(basename: "test") { path in
      let strPath = String(decoding: path)
      XCTAssert(strPath.contains("test"))
      try withTemporaryFilePath(basename: "test") { path2 in
        let strPath2 = String(decoding: path2)
        XCTAssertNotEqual(strPath, strPath2)
      }
    }
  }

  func testCleanup() throws {
    var thePath: FilePath? = nil

    try withTemporaryFilePath(basename: "test") { path in
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
