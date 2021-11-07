/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

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

      MockTestCase(name: "mmap", .noInterrupt, rawFD, 1, PROT_NONE, MAP_SHARED, 0) { _ in
        _ = try fd.memoryMap(length: 1, pageOffset: 0, kind: .shared, protection: [.none])
      },

      MockTestCase(name: "mmap", .noInterrupt, rawFD, 2, PROT_READ, MAP_PRIVATE, 1) { _ in
        _ = try fd.memoryMap(length: 2, pageOffset: 1, kind: .private, protection: [.read])
      },

      MockTestCase(name: "mmap", .noInterrupt, rawFD, 2, PROT_READ | PROT_WRITE, MAP_PRIVATE, 1) { _ in
        _ = try fd.memoryMap(length: 2, pageOffset: 1, kind: .private, protection: [.read, .write])
      },

      MockTestCase(name: "mmap", .noInterrupt, rawFD, 0, PROT_WRITE, MAP_PRIVATE, 1) { _ in
        _ = try fd.memoryMap(length: 0, pageOffset: 1, kind: .private, protection: [.write])
      },

      MockTestCase(name: "munmap", .noInterrupt, rawBuf.baseAddress!, 42) { _ in
        _ = try fd.memoryUnmap(memoryMap: rawBuf.baseAddress!, length: 42)
      },

      MockTestCase(name: "msync", .noInterrupt, rawBuf.baseAddress!, 42, MS_SYNC) { _ in
        _ = try fd.memorySync(memoryMap: rawBuf.baseAddress!, length: 42, kind: .synchronous)
      },

      MockTestCase(name: "msync", .noInterrupt, rawBuf.baseAddress!, 42, MS_ASYNC) { _ in
        _ = try fd.memorySync(memoryMap: rawBuf.baseAddress!, length: 42, kind: .asynchronous)
      },

      MockTestCase(name: "msync", .noInterrupt, rawBuf.baseAddress!, 42, MS_ASYNC & MS_INVALIDATE) { _ in
        _ = try fd.memorySync(memoryMap: rawBuf.baseAddress!, length: 42, kind: .asynchronous, invalidateOtherMappings: true)
      },

      MockTestCase(name: "msync", .noInterrupt, rawBuf.baseAddress!, 42, MS_SYNC & MS_INVALIDATE) { _ in
        _ = try fd.memorySync(memoryMap: rawBuf.baseAddress!, length: 42, kind: .synchronous, invalidateOtherMappings: true)
      },
    ]

    for test in syscallTestCases { test.runAllTests() }
  }

  func testHelpers() {
    // TODO: Test writeAll, writeAll(toAbsoluteOffset), closeAfter
  }
  
#if !os(Windows)
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
#endif

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

  func testAdHocMmap() throws {
    // Ad-hoc test for memory mapping a file.
    let header = "swift"
    let footer = "system"
    do {
      let fd = try FileDescriptor.open("/tmp/c.txt",
                                       .readWrite,
                                       options: [.create, .truncate],
                                       permissions: .ownerReadWrite)

      try fd.closeAfter {
        // Write two pages of nil bytes to the file
        try fd.writeAll(Data(count: sysconf(_SC_PAGESIZE) * 2))

        // Map the first page with write protections
        let ptr1page1 = try fd.memoryMap(length: header.count, pageOffset: 0, kind: .shared, protection: [.write])
        let page1 = ptr1page1.assumingMemoryBound(to: String.self)
        page1.pointee = header

        // Create another map to page1
        let ptr2page1 = try fd.memoryMap(length: header.count, pageOffset: 0, kind: .shared, protection: [.write])
        XCTAssertEqual(ptr2page1.assumingMemoryBound(to: String.self).pointee, header)

        // Map the second page with write protections
        let ptr1page2 = try fd.memoryMap(length: footer.count, pageOffset: 1, kind: .shared, protection: [.write])
        let page2 = ptr1page2.assumingMemoryBound(to: String.self)
        page2.pointee = footer

        // Create another map to page 2, asserting the data has been shared across the map
        let ptr2page2 = try fd.memoryMap(length: footer.count, pageOffset: 1, kind: .shared, protection: [.write])
        XCTAssertEqual(ptr2page2.assumingMemoryBound(to: String.self).pointee, footer)

        // Create a *private* mapping to page 2
        let ptr2page2private = try fd.memoryMap(length: footer.count,
                                                pageOffset: 1,
                                                kind: .private,
                                                protection: [.write])
        // Write to the private mapping so that the header is in place of the footer
        let page2private = ptr2page2private.assumingMemoryBound(to: String.self)
        page2private.pointee = header

        // Assert that the shared mappings are still correct and unaffected by the private mapping
        XCTAssertEqual(ptr2page1.assumingMemoryBound(to: String.self).pointee, header)
        XCTAssertEqual(ptr2page2.assumingMemoryBound(to: String.self).pointee, footer)

        // Flush changes to the filesystem
        try fd.memorySync(memoryMap: ptr1page1, length: header.count, kind: .synchronous)
        try fd.memorySync(memoryMap: ptr1page2, length: footer.count, kind: .synchronous)

        // Seek to the start of the file, as writing to it will have moved our offset
        try fd.seek(offset: 0, from: .start)
        let readBytes = try Array<CChar>(unsafeUninitializedCapacity: sysconf(_SC_PAGESIZE) * 2) { (buf, count) in
          count = try fd.read(into: UnsafeMutableRawBufferPointer(buf))
        }
        // Assert the header and footer are correctly in place
        XCTAssertEqual(String(validatingPlatformString: readBytes), header)
        let readFooter = [CChar](readBytes[sysconf(_SC_PAGESIZE)..<sysconf(_SC_PAGESIZE) + footer.count + 1])
        XCTAssertEqual(String(validatingPlatformString: readFooter), footer)

        try fd.memoryUnmap(memoryMap: ptr1page1, length: sysconf(_SC_PAGESIZE))
        try fd.memoryUnmap(memoryMap: ptr2page1, length: sysconf(_SC_PAGESIZE))
        try fd.memoryUnmap(memoryMap: ptr1page2, length: sysconf(_SC_PAGESIZE))
        try fd.memoryUnmap(memoryMap: ptr2page2, length: sysconf(_SC_PAGESIZE))
        try fd.memoryUnmap(memoryMap: page2private, length: sysconf(_SC_PAGESIZE))
        // Nothing to check here. accessing the underlying memory will result in a SIGSEGV
      }
    } catch let err as Errno {
      print("caught \(err))")
      XCTAssert(false)
    } catch {
      fatalError("FATAL: `testAdHocMmap`")
    }
  }
}

