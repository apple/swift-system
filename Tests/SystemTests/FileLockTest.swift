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

    let ofd_1 = try FileDescriptor.open(
      path, .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
    let dup_1 = try ofd_1.duplicate()

    let ofd_2 = try FileDescriptor.open(
      path, .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
    let dup_2 = try ofd_2.duplicate()

    func testOFDs(
      one: FileDescriptor.FileLock.Kind,
      two: FileDescriptor.FileLock.Kind,
      byteRange: Range<Int64>? = nil
    ) {
      if let br = byteRange {
        XCTAssertEqual(one, try ofd_1.getConflictingLock(byteRange: br))
        XCTAssertEqual(one, try dup_1.getConflictingLock(byteRange: br))

        XCTAssertEqual(two, try ofd_2.getConflictingLock(byteRange: br))
        XCTAssertEqual(two, try dup_2.getConflictingLock(byteRange: br))
      } else {
        XCTAssertEqual(one, try ofd_1.getConflictingLock())
        XCTAssertEqual(one, try dup_1.getConflictingLock())

        XCTAssertEqual(two, try ofd_2.getConflictingLock())
        XCTAssertEqual(two, try dup_2.getConflictingLock())
      }
    }

    testOFDs(one: .none, two: .none)

    try ofd_1.lock()
    testOFDs(one: .none, two: .read)

    try ofd_1.lock(.write)
    testOFDs(one: .none, two: .write)

    try dup_1.unlock()
    testOFDs(one: .none, two: .none)

    try dup_2.lock()
    testOFDs(one: .read, two: .none)

    try dup_1.lock()
    testOFDs(one: .read, two: .read)

    do {
      try dup_2.lock(.write)
    } catch let e as Errno {
      XCTAssertEqual(.resourceTemporarilyUnavailable, e)
    }
    do {
      try ofd_1.lock(.write)
    } catch let e as Errno {
      XCTAssertEqual(.resourceTemporarilyUnavailable, e)
    }

    try ofd_1.unlock()
    try ofd_2.unlock()
    testOFDs(one: .none, two: .none)

    /// Byte ranges

    try dup_1.lock(byteRange: ..<50)
    testOFDs(one: .none, two: .read)
    testOFDs(one: .none, two: .none, byteRange: _range(51...))
    testOFDs(one: .none, two: .read, byteRange: _range(1..<2))

    try dup_1.lock(.write, byteRange: 100..<150)
    testOFDs(one: .none, two: .write)
    testOFDs(one: .none, two: .read, byteRange: 49..<50)
    testOFDs(one: .none, two: .none, byteRange: 98..<99)
    testOFDs(one: .none, two: .write, byteRange: _range(100...))

    try dup_1.unlock(byteRange: ..<49)
    testOFDs(one: .none, two: .read, byteRange: 49..<50)

    try dup_1.unlock(byteRange: ..<149)
    testOFDs(one: .none, two: .write)
    testOFDs(one: .none, two: .none, byteRange: _range(..<149))
    testOFDs(one: .none, two: .write, byteRange: 149..<150)

    try dup_1.unlock(byteRange: 149..<150)
    testOFDs(one: .none, two: .none)
  }
}

