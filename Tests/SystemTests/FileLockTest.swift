/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

func _range(_ r: some RangeExpression<Int64>) -> Range<Int64> {
  r.relative(to: Int64.min..<Int64.max)
}

extension FileOperationsTest {
  func testFileLocks() throws {
    let path = FilePath("/tmp/\(UUID().uuidString).txt")

    let ofd_A = try FileDescriptor.open(
      path, .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
    let dup_A = try ofd_A.duplicate()

    let ofd_B = try FileDescriptor.open(
      path, .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
    let dup_B = try ofd_B.duplicate()

    // A(read) -> A(write) -> FAIL: B(read/write)
    XCTAssertTrue(try ofd_A.lock(.read))
    XCTAssertTrue(try ofd_A.lock(.write))
    XCTAssertTrue(try dup_A.lock(.write)) // redundant, but works
    XCTAssertFalse(try ofd_B.lock(.read))
    XCTAssertFalse(try ofd_B.lock(.write))
    XCTAssertFalse(try dup_B.lock(.write))
    try dup_A.unlock()

    // A(read) -> B(read) -> FAIL: A/B(write)
    // -> B(unlock) -> A(write) -> FAIL: B(read/write)
    XCTAssertTrue(try dup_A.lock(.read))
    XCTAssertTrue(try ofd_B.lock(.read))
    XCTAssertFalse(try ofd_A.lock(.write))
    XCTAssertFalse(try dup_A.lock(.write))
    XCTAssertFalse(try ofd_B.lock(.write))
    XCTAssertFalse(try dup_B.lock(.write))
    try dup_B.unlock()
    XCTAssertTrue(try ofd_A.lock(.write))
    XCTAssertFalse(try dup_B.lock(.read))
    XCTAssertFalse(try ofd_B.lock(.write))
    try dup_A.unlock()

    /// Byte ranges

    // A(read, ..<50) -> B(write, 50...)
    // -> A(write, 10..<20) -> B(read, 40..<50)
    // -> FAIL: B(read, 17..<18), A(read 60..<70)
    // -> A(unlock, 11..<12) -> B(read, 11..<12) -> A(read, 11..<12)
    // -> FAIL A/B(write, 11..<12)
    XCTAssertTrue(try ofd_A.lock(.read, byteRange: ..<50))
    XCTAssertTrue(try ofd_B.lock(.write, byteRange: 50...))
    XCTAssertTrue(try ofd_A.lock(.write, byteRange: 10..<20))
    XCTAssertTrue(try ofd_B.lock(.read, byteRange: 40..<50))
    XCTAssertFalse(try ofd_B.lock(.read, byteRange: 17..<18))
    XCTAssertFalse(try ofd_A.lock(.read, byteRange: 60..<70))
    try dup_A.unlock(byteRange: 11..<12)
    XCTAssertTrue(try ofd_B.lock(.read, byteRange: 11..<12))
    XCTAssertTrue(try ofd_A.lock(.read, byteRange: 11..<12))
    XCTAssertFalse(try ofd_B.lock(.write, byteRange: 11..<12))
    XCTAssertFalse(try ofd_A.lock(.write, byteRange: 11..<12))
  }

  func testFileLocksWaiting() {
    // TODO: Test waiting, test waiting until timeouts
  }
}

