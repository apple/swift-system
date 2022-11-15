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

extension FileOperationsTest {

  func testFileLocks() throws {
    let path = FilePath("/tmp/\(UUID().uuidString).txt")

    let ofd_1 = try FileDescriptor.open(
      path, .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
    let dup_1 = try ofd_1.duplicate()

    let ofd_2 = try FileDescriptor.open(
      path, .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
    let dup_2 = try ofd_2.duplicate()

    func testOFDs(one: FileDescriptor.FileLock.Kind, two: FileDescriptor.FileLock.Kind) {
      XCTAssertEqual(one, try ofd_1.getConflictingLock())
      XCTAssertEqual(one, try dup_1.getConflictingLock())

      XCTAssertEqual(two, try ofd_2.getConflictingLock())
      XCTAssertEqual(two, try dup_2.getConflictingLock())
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
      try dup_2.lock(.write, nonBlocking: true)
    } catch let e as Errno {
      XCTAssertEqual(.resourceTemporarilyUnavailable, e)
    }
    do {
      try ofd_1.lock(.write, nonBlocking: true)
    } catch let e as Errno {
      XCTAssertEqual(.resourceTemporarilyUnavailable, e)
    }

    try ofd_1.unlock()
    XCTAssertEqual(.read, try ofd_1.getConflictingLock())
    XCTAssertEqual(.read, try dup_1.getConflictingLock())
    XCTAssertEqual(.none, try ofd_2.getConflictingLock())
    XCTAssertEqual(.none, try dup_2.getConflictingLock())

    try dup_2.lock(.write, nonBlocking: true)
    XCTAssertEqual(.write, try ofd_1.getConflictingLock())
    XCTAssertEqual(.write, try dup_1.getConflictingLock())
    XCTAssertEqual(.none, try ofd_2.getConflictingLock())
    XCTAssertEqual(.none, try dup_2.getConflictingLock())
  }

  func testFileLockByteRanges() throws {
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
      byteRange range: Range<Int64>
    ) {
      XCTAssertEqual(one, try ofd_1.getConflictingLock(byteRange: range))
      XCTAssertEqual(one, try dup_1.getConflictingLock(byteRange: range))

      XCTAssertEqual(two, try ofd_2.getConflictingLock(byteRange: range))
      XCTAssertEqual(two, try dup_2.getConflictingLock(byteRange: range))
    }

    // TODO: tests

  }
}
