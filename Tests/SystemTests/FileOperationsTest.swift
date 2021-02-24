/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import SystemPackage

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class FileOperationsTest: XCTestCase {
  func testSyscalls() {
    let fd = FileDescriptor(rawValue: 1)

    let rawBuf = UnsafeMutableRawBufferPointer.allocate(byteCount: 100, alignment: 4)
    defer { rawBuf.deallocate() }
    let bufAddr = rawBuf.baseAddress
    let rawFD = fd.rawValue
    let bufCount = rawBuf.count
    let writeBuf = UnsafeRawBufferPointer(rawBuf)
    let writeBufAddr = writeBuf.baseAddress

    let syscallTestCases: Array<MockTestCase> = [
      MockTestCase(name: "open", "a path", O_RDWR | O_APPEND, interruptable: true) {
        retryOnInterrupt in
        _ = try FileDescriptor.open(
          "a path", .readWrite, options: [.append], retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "open", "a path", O_WRONLY | O_CREAT | O_APPEND, 0o777, interruptable: true) {
        retryOnInterrupt in
        _ = try FileDescriptor.open(
          "a path", .writeOnly, options: [.create, .append],
          permissions: [.groupReadWriteExecute, .ownerReadWriteExecute, .otherReadWriteExecute],
          retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "read", rawFD, bufAddr, bufCount, interruptable: true) {
        retryOnInterrupt in
        _ = try fd.read(into: rawBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "pread", rawFD, bufAddr, bufCount, 5, interruptable: true) {
        retryOnInterrupt in
        _ = try fd.read(fromAbsoluteOffset: 5, into: rawBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "lseek", rawFD, -2, SEEK_END, interruptable: false) {
        _ in
        _ = try fd.seek(offset: -2, from: .end)
      },

      MockTestCase(name: "write", rawFD, writeBufAddr, bufCount, interruptable: true) {
        retryOnInterrupt in
        _ = try fd.write(writeBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "pwrite", rawFD, writeBufAddr, bufCount, 7, interruptable: true) {
        retryOnInterrupt in
        _ = try fd.write(toAbsoluteOffset: 7, writeBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "close", rawFD, interruptable: false) {
        _ in
        _ = try fd.close()
      },

    ]

    for test in syscallTestCases { test.runAllTests() }
  }

  func testHelpers() {
    // TODO: Test writeAll, writeAll(toAbsoluteOffset), closeAfter
  }

  func testAdHocOpen() {
    // Ad-hoc test touching a file system.
    do {
      // TODO: Test this against a virtual in-memory file system
      let fd = try FileDescriptor.open("/tmp/b.txt", .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
      try fd.closeAfter {
        try fd.writeAll("abc".utf8)
        var def = "def"
        try def.withUTF8 {
          _ = try fd.write(UnsafeRawBufferPointer($0))
        }
        try fd.seek(offset: 1, from: .start)

        let readLen = 3
        let readBytes = try Array<UInt8>(unsafeUninitializedCapacity: readLen) { (buf, count) in
          count = try fd.read(into: UnsafeMutableRawBufferPointer(buf))
        }
        let preadBytes = try Array<UInt8>(unsafeUninitializedCapacity: readLen) { (buf, count) in
          count = try fd.read(fromAbsoluteOffset: 1, into: UnsafeMutableRawBufferPointer(buf))
        }

        XCTAssertEqual(readBytes.first!, "b".utf8.first!)
        XCTAssertEqual(readBytes, preadBytes)

        // TODO: seek
      }
    } catch let err as Errno {
      print("caught \(err))")
      // Should we assert? I'd be interested in knowing if this happened
      XCTAssert(false)
    } catch {
      fatalError("FATAL: `testAdHocOpen`")
    }
  }

  func testGithubIssues() {
    // https://github.com/apple/swift-system/issues/26
    let issue26 = MockTestCase(
      name: "open", "a path", O_WRONLY | O_CREAT, 0o020, interruptable: true
    ) {
      retryOnInterrupt in
      _ = try FileDescriptor.open(
        "a path", .writeOnly, options: [.create],
        permissions: [.groupWrite],
        retryOnInterrupt: retryOnInterrupt)
    }
    issue26.runAllTests()

  }
}

