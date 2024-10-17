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

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
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
      MockTestCase(name: "open", .interruptable, "a path", O_RDWR | O_APPEND) {
        retryOnInterrupt in
        _ = try FileDescriptor.open(
          "a path", .readWrite, options: [.append], retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "open", .interruptable, "a path", O_WRONLY | O_CREAT | O_APPEND, 0o777) {
        retryOnInterrupt in
        _ = try FileDescriptor.open(
          "a path", .writeOnly, options: [.create, .append],
          permissions: [.groupReadWriteExecute, .ownerReadWriteExecute, .otherReadWriteExecute],
          retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "read", .interruptable, rawFD, bufAddr, bufCount) {
        retryOnInterrupt in
        _ = try fd.read(into: rawBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "pread", .interruptable, rawFD, bufAddr, bufCount, 5) {
        retryOnInterrupt in
        _ = try fd.read(fromAbsoluteOffset: 5, into: rawBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "lseek", .noInterrupt, rawFD, -2, SEEK_END) {
        _ in
        _ = try fd.seek(offset: -2, from: .end)
      },

      MockTestCase(name: "write", .interruptable, rawFD, writeBufAddr, bufCount) {
        retryOnInterrupt in
        _ = try fd.write(writeBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "pwrite", .interruptable, rawFD, writeBufAddr, bufCount, 7) {
        retryOnInterrupt in
        _ = try fd.write(toAbsoluteOffset: 7, writeBuf, retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "close", .noInterrupt, rawFD) {
        _ in
        _ = try fd.close()
      },

      MockTestCase(name: "dup", .interruptable, rawFD) { retryOnInterrupt in
        _ = try fd.duplicate(retryOnInterrupt: retryOnInterrupt)
      },

      MockTestCase(name: "dup2", .interruptable, rawFD, 42) { retryOnInterrupt in
        _ = try fd.duplicate(as: FileDescriptor(rawValue: 42),
                             retryOnInterrupt: retryOnInterrupt)
      },
    ]

    for test in syscallTestCases { test.runAllTests() }
  }

  func testWriteFromEmptyBuffer() throws {
    #if os(Windows)
    let fd = try FileDescriptor.open(FilePath("NUL"), .writeOnly)
    #else
    let fd = try FileDescriptor.open(FilePath("/dev/null"), .writeOnly)
    #endif
    let written1 = try fd.write(toAbsoluteOffset: 0, .init(start: nil, count: 0))
    XCTAssertEqual(written1, 0)

    let pointer = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
    defer { pointer.deallocate() }
    let empty = UnsafeRawBufferPointer(start: pointer, count: 0)
    let written2 = try fd.write(toAbsoluteOffset: 0, empty)
    XCTAssertEqual(written2, 0)
  }

  #if os(Windows)
  // Generate a file containing random bytes; this should not be used
  // for cryptography, it's just for testing.
  func generateRandomData(at path: FilePath, count: Int) throws {
    let fd = try FileDescriptor.open(path, .readWrite,
                                     options: [.create, .truncate])
    defer {
      try! fd.close()
    }
    let data = [UInt8](
      sequence(first: 0,
               next: {
                 _ in UInt8.random(in: UInt8.min...UInt8.max)
               }).dropFirst().prefix(count)
    )

    try data.withUnsafeBytes {
      _ = try fd.write($0)
    }
  }
  #endif

  func testReadToEmptyBuffer() throws {
    try withTemporaryFilePath(basename: "testReadToEmptyBuffer") { path in
      #if os(Windows)
      // Windows doesn't have an equivalent to /dev/random, so generate
      // some random bytes and write them to a file for the next step.
      let randomPath = path.appending("random.txt")
      try generateRandomData(at: randomPath, count: 16)
      let fd = try FileDescriptor.open(randomPath, .readOnly)
      #else // !os(Windows)
      let fd = try FileDescriptor.open(FilePath("/dev/random"), .readOnly)
      #endif
      let read1 = try fd.read(fromAbsoluteOffset: 0, into: .init(start: nil, count: 0))
      XCTAssertEqual(read1, 0)

      let pointer = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
      defer { pointer.deallocate() }
      let empty = UnsafeMutableRawBufferPointer(start: pointer, count: 0)
      let read2 = try fd.read(fromAbsoluteOffset: 0, into: empty)
      XCTAssertEqual(read2, 0)
    }
  }

  func testHelpers() {
    // TODO: Test writeAll, writeAll(toAbsoluteOffset), closeAfter
  }

  func testAdHocPipe() throws {
    // Ad-hoc test testing `Pipe` functionality.
    // We cannot test `Pipe` using `MockTestCase` because it calls `pipe` with a pointer to an array local to the `Pipe`, the address of which we do not know prior to invoking `Pipe`.
    let pipe = try FileDescriptor.pipe()
    try pipe.readEnd.closeAfter {
      try pipe.writeEnd.closeAfter {
        var abc = "abc"
        try abc.withUTF8 {
          _ = try pipe.writeEnd.write(UnsafeRawBufferPointer($0))
        }
        let readLen = 3
        let readBytes = try Array<UInt8>(unsafeUninitializedCapacity: readLen) { buf, count in
          count = try pipe.readEnd.read(into: UnsafeMutableRawBufferPointer(buf))
        }
        XCTAssertEqual(readBytes, Array(abc.utf8))
      }
    }
  }

  func testAdHocOpen() {
    // Ad-hoc test touching a file system.
    do {
      // TODO: Test this against a virtual in-memory file system
      try withTemporaryFilePath(basename: "testAdhocOpen") { path in
        let fd = try FileDescriptor.open(path.appending("b.txt"), .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
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
      name: "open", .interruptable, "a path", O_WRONLY | O_CREAT, 0o020
    ) {
      retryOnInterrupt in
      _ = try FileDescriptor.open(
        "a path", .writeOnly, options: [.create],
        permissions: [.groupWrite],
        retryOnInterrupt: retryOnInterrupt)
    }
    issue26.runAllTests()

  }

  func testResizeFile() throws {
    try withTemporaryFilePath(basename: "testResizeFile") { path in 
      let fd = try FileDescriptor.open(path.appending("\(UUID().uuidString).txt"), .readWrite, options: [.create, .truncate], permissions: .ownerReadWrite)
      try fd.closeAfter {
        // File should be empty initially.
        XCTAssertEqual(try fd.fileSize(), 0)
        // Write 3 bytes.
        try fd.writeAll("abc".utf8)
        // File should now be 3 bytes.
        XCTAssertEqual(try fd.fileSize(), 3)
        // Resize to 6 bytes.
        try fd.resize(to: 6)
        // File should now be 6 bytes.
        XCTAssertEqual(try fd.fileSize(), 6)
        // Read in the 6 bytes.
        let readBytes = try Array<UInt8>(unsafeUninitializedCapacity: 6) { (buf, count) in
          try fd.seek(offset: 0, from: .start)
          // Should have read all 6 bytes.
          count = try fd.read(into: UnsafeMutableRawBufferPointer(buf))
          XCTAssertEqual(count, 6)
        }
        // First 3 bytes should be unaffected by resize.
        XCTAssertEqual(Array(readBytes[..<3]), Array("abc".utf8))
        // Extension should be padded with zeros.
        XCTAssertEqual(Array(readBytes[3...]), Array(repeating: 0, count: 3))
        // File should still be 6 bytes.
        XCTAssertEqual(try fd.fileSize(), 6)
        // Resize to 2 bytes.
        try fd.resize(to: 2)
        // File should now be 2 bytes.
        XCTAssertEqual(try fd.fileSize(), 2)
        // Read in file with a buffer big enough for 6 bytes.
        let readBytesAfterTruncation = try Array<UInt8>(unsafeUninitializedCapacity: 6) { (buf, count) in
          try fd.seek(offset: 0, from: .start)
          count = try fd.read(into: UnsafeMutableRawBufferPointer(buf))
          // Should only have read 2 bytes.
          XCTAssertEqual(count, 2)
        }
        // Written content was trunctated.
        XCTAssertEqual(readBytesAfterTruncation, Array("ab".utf8))
      }
    }
  }
}

