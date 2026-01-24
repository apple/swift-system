//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

@Suite("Span-based File I/O")
private struct SpanFileIOTests {

  // MARK: - Basic Functionality

  @available(SystemWithSpan 0.0.1, *)
  @Test func basicReadWriteOperations() async throws {
    try withTemporaryFilePath(basename: "basicReadWriteOperations") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        // Test write(_:)
        let data1: [UInt8] = [0x61, 0x62, 0x63] // "abc"
        let written1 = try data1.withUnsafeBytes { bytes in
          try fd.write(RawSpan(_unsafeBytes: bytes))
        }
        #expect(written1 == 3)

        // Test write(toAbsoluteOffset:_:)
        let data2: [UInt8] = [0x64, 0x65, 0x66] // "def"
        let written2 = try data2.withUnsafeBytes { bytes in
          try fd.write(toAbsoluteOffset: 3, RawSpan(_unsafeBytes: bytes))
        }
        #expect(written2 == 3)

        // Test writeAll(_:)
        try fd.seek(offset: 6, from: .start)
        let data3: [UInt8] = [0x67, 0x68, 0x69] // "ghi"
        let written3 = try data3.withUnsafeBytes { bytes in
          try fd.writeAll(RawSpan(_unsafeBytes: bytes))
        }
        #expect(written3 == 3)

        // Test writeAll(toAbsoluteOffset:_:)
        let data4: [UInt8] = [0x6A, 0x6B, 0x6C] // "jkl"
        let written4 = try data4.withUnsafeBytes { bytes in
          try fd.writeAll(toAbsoluteOffset: 9, RawSpan(_unsafeBytes: bytes))
        }
        #expect(written4 == 3)

        // Test read(into:)
        try fd.seek(offset: 0, from: .start)
        let result1 = try [UInt8](unsafeUninitializedCapacity: 12) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          _ = try fd.read(into: &output)
          count = output.byteCount
        }
        #expect(result1.count <= 12) // May be partial

        // Test read(filling:)
        try fd.seek(offset: 0, from: .start)
        let result2 = try [UInt8](unsafeUninitializedCapacity: 12) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(filling: &output)
        }
        #expect(result2 == data1 + data2 + data3 + data4)

        // Test read(fromAbsoluteOffset:into:)
        let result3 = try [UInt8](unsafeUninitializedCapacity: 3) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          _ = try fd.read(fromAbsoluteOffset: 3, into: &output)
          count = output.byteCount
        }
        #expect(result3.count <= 3) // May be partial

        // Test read(fromAbsoluteOffset:filling:)
        let result4 = try [UInt8](unsafeUninitializedCapacity: 3) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(fromAbsoluteOffset: 6, filling: &output)
        }
        #expect(result4 == data3)
      }
    }
  }

  @available(SystemWithSpan 0.0.1, *)
  @Test func writeOperations() async throws {
    try withTemporaryFilePath(basename: "writeOperations") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        // Small write
        let small: [UInt8] = [0x61, 0x62, 0x63]
        _ = try small.withUnsafeBytes { bytes in
          try fd.writeAll(RawSpan(_unsafeBytes: bytes))
        }

        // Large write
        let large: [UInt8] = Array((0..<1024).map { UInt8($0 % 256) })
        _ = try large.withUnsafeBytes { bytes in
          try fd.writeAll(RawSpan(_unsafeBytes: bytes))
        }

        // Verify size
        let size = try fd.seek(offset: 0, from: .end)
        #expect(size == 3 + 1024)

        // Verify content
        try fd.seek(offset: 0, from: .start)
        let readBack = try [UInt8](unsafeUninitializedCapacity: 3 + 1024) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(filling: &output)
        }
        #expect(readBack == small + large)
      }
    }
  }

  @available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1, *)
  @Test func readOperations() async throws {
    try withTemporaryFilePath(basename: "readOperations") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        let data: [UInt8] = Array((0..<1024).map { UInt8($0 % 256) })
        try fd.writeAll(data)
        try fd.seek(offset: 0, from: .start)

        // Small read
        let small = try [UInt8](unsafeUninitializedCapacity: 10) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(filling: &output)
        }
        #expect(small == Array(0..<10))

        // Large read
        try fd.seek(offset: 0, from: .start)
        let large = try [UInt8](unsafeUninitializedCapacity: 1024) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(filling: &output)
        }
        #expect(large == data)
      }
    }
  }

  @available(SystemWithSpan 0.0.1, *)
  @Test func absoluteOffsetOperations() async throws {
    try withTemporaryFilePath(basename: "absoluteOffsetOperations") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        let data: [UInt8] = Array(0..<100)
        try fd.writeAll(data)

        // Write at absolute offset should not change file position
        let initialOffset = try fd.seek(offset: 0, from: .current)
        let patchData: [UInt8] = [0xFF, 0xFE]
        _ = try patchData.withUnsafeBytes { bytes in
          try fd.writeAll(toAbsoluteOffset: 50, RawSpan(_unsafeBytes: bytes))
        }
        let afterWriteOffset = try fd.seek(offset: 0, from: .current)
        #expect(initialOffset == afterWriteOffset)

        // Read at absolute offset should not change file position
        try fd.seek(offset: 10, from: .start)
        let readAtOffset = try [UInt8](unsafeUninitializedCapacity: 2) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(fromAbsoluteOffset: 50, filling: &output)
        }
        #expect(readAtOffset == patchData)
        let afterReadOffset = try fd.seek(offset: 0, from: .current)
        #expect(afterReadOffset == 10) // Should still be at 10
      }
    }
  }

  // MARK: - Semantic Behavior

  @available(SystemWithSpan 0.0.1, *)
  @Test func partialReadBehavior() async throws {
    try withTemporaryFilePath(basename: "partialReadBehavior") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        let data: [UInt8] = Array(0..<100)
        try fd.writeAll(data)
        try fd.seek(offset: 0, from: .start)

        // read(into:) may return partial data - this is valid behavior
        let output = UnsafeMutableRawBufferPointer.allocate(byteCount: 100, alignment: 1)
        defer { output.deallocate() }
        var span = OutputRawSpan(buffer: output, initializedCount: 0)

        var totalRead = 0
        while span.freeCapacity > 0 {
          let bytesRead = try fd.read(into: &span)
          if bytesRead == 0 { break } // EOF
          totalRead += bytesRead
          #expect(bytesRead > 0)
          #expect(bytesRead <= span.freeCapacity + bytesRead) // Can't read more than capacity
        }

        // Should eventually get all data with multiple reads
        #expect(totalRead == 100)
        #expect(span.byteCount == 100)
      }
    }
  }

  @available(SystemWithSpan 0.0.1, *)
  @Test func readFillingBehavior() async throws {
    try withTemporaryFilePath(basename: "readFillingBehavior") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        // Test 1: read(filling:) fills buffer completely when data available
        let fullData: [UInt8] = Array(0..<100)
        try fd.writeAll(fullData)
        try fd.seek(offset: 0, from: .start)

        let result1 = try [UInt8](unsafeUninitializedCapacity: 100) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          let bytesRead = try fd.read(filling: &output)
          #expect(bytesRead == 100)
          #expect(output.freeCapacity == 0) // Should be completely full
          count = output.byteCount
        }
        #expect(result1 == fullData)

        // Test 2: read(filling:) stops at EOF even if buffer not full
        try fd.seek(offset: 0, from: .start)
        let result2 = try [UInt8](unsafeUninitializedCapacity: 200) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          let bytesRead = try fd.read(filling: &output)
          #expect(bytesRead == 100) // Only 100 bytes available
          #expect(output.freeCapacity == 100) // 100 bytes unfilled
          count = output.byteCount
        }
        #expect(result2 == fullData)
      }
    }
  }

  // MARK: - Edge Cases

  @available(SystemWithSpan 0.0.1, *)
  @Test func emptyIO() async throws {
    try withTemporaryFilePath(basename: "emptyIO") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        // Empty write
        let empty: [UInt8] = []
        let written = try empty.withUnsafeBytes { bytes in
          try fd.writeAll(RawSpan(_unsafeBytes: bytes))
        }
        #expect(written == 0)

        // Empty read (from empty file)
        let result1 = try [UInt8](unsafeUninitializedCapacity: 10) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(into: &output)
        }
        #expect(result1.isEmpty)

        // Zero-capacity buffer
        let data: [UInt8] = [0x61, 0x62, 0x63]
        try fd.writeAll(data)
        try fd.seek(offset: 0, from: .start)

        let result2 = try [UInt8](unsafeUninitializedCapacity: 0) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(into: &output)
        }
        #expect(result2.isEmpty)
      }
    }
  }

  @available(SystemWithSpan 0.0.1, *)
  @Test func eofBehavior() async throws {
    try withTemporaryFilePath(basename: "eofBehavior") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        let data: [UInt8] = [0x61, 0x62, 0x63]
        try fd.writeAll(data)
        try fd.seek(offset: 0, from: .start)

        // Read all data
        let result1 = try [UInt8](unsafeUninitializedCapacity: 3) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(filling: &output)
        }
        #expect(result1 == data)

        // Read at EOF returns 0
        let result2 = try [UInt8](unsafeUninitializedCapacity: 10) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(into: &output)
        }
        #expect(result2.isEmpty)

        // read(filling:) with buffer larger than file stops at EOF
        try fd.seek(offset: 0, from: .start)
        let result3 = try [UInt8](unsafeUninitializedCapacity: 10) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          let bytesRead = try fd.read(filling: &output)
          #expect(bytesRead == 3) // Only 3 bytes available
          count = bytesRead
        }
        #expect(result3 == data)
      }
    }
  }

  @available(SystemWithSpan 0.0.1, *)
  @Test func preInitializedSpan() async throws {
    try withTemporaryFilePath(basename: "preInitializedSpan") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        let fileData: [UInt8] = [0x61, 0x62, 0x63] // "abc"
        try fd.writeAll(fileData)
        try fd.seek(offset: 0, from: .start)

        // Create buffer with pre-existing initialized data
        let result = try [UInt8](unsafeUninitializedCapacity: 10) { buffer, count in
          // Pre-initialize first 2 bytes
          buffer[0] = 0xFF
          buffer[1] = 0xFE

          // Create OutputRawSpan that knows about pre-initialized portion
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 2)

          // Read more data - should append after pre-initialized data
          let bytesRead = try fd.read(filling: &output)
          #expect(bytesRead == 3) // Read "abc"
          #expect(output.byteCount == 5) // 2 pre-initialized + 3 read = 5 total

          count = output.byteCount
        }

        // Verify: first 2 bytes are pre-initialized, next 3 are from file
        #expect(result == [0xFF, 0xFE, 0x61, 0x62, 0x63])
      }
    }
  }

  @available(SystemWithSpan 0.0.1, *)
  @Test func errorHandling() throws {
    // Test 1: Reading from closed FD
    let fd1 = try FileDescriptor.open(FilePath("/dev/null"), .readOnly)
    try fd1.close()

    #expect(throws: Errno.badFileDescriptor) {
      let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 10, alignment: 1)
      defer { buffer.deallocate() }
      var output = OutputRawSpan(buffer: buffer, initializedCount: 0)
      _ = try fd1.read(into: &output)
    }

    // Test 2: Writing to closed FD
    let fd2 = try FileDescriptor.open(FilePath("/dev/null"), .writeOnly)
    try fd2.close()

    let data: [UInt8] = [0x61, 0x62, 0x63]
    #expect(throws: Errno.badFileDescriptor) {
      try data.withUnsafeBytes { bytes in
        try fd2.write(RawSpan(_unsafeBytes: bytes))
      }
    }

    // Test 3: Writing to read-only FD
    try withTemporaryFilePath(basename: "errorHandling") { path in
      // Create file first
      let fdWrite = try FileDescriptor.open(
        path.appending("test.txt"), .writeOnly,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      _ = try fdWrite.closeAfter {
        try fdWrite.writeAll(data)
      }

      // Open read-only and try to write
      let fdRead = try FileDescriptor.open(
        path.appending("test.txt"), .readOnly
      )
      _ = try fdRead.closeAfter {
        #expect(throws: Errno.badFileDescriptor) {
          try data.withUnsafeBytes { bytes in
            try fdRead.write(RawSpan(_unsafeBytes: bytes))
          }
        }
      }
    }
  }

  // MARK: - Regression/Examples

  @available(SystemWithSpan 0.0.1, *)
  @Test func proposalExample() async throws {
    // Example from the proposal
    try withTemporaryFilePath(basename: "proposalExample") { path in
      let fd = try FileDescriptor.open(
        path.appending("test.txt"), .readWrite,
        options: [.create, .truncate],
        permissions: .ownerReadWrite
      )
      try fd.closeAfter {
        let writeData: [UInt8] = Array(repeating: 42, count: 4096)
        try fd.writeAll(writeData)
        try fd.seek(offset: 0, from: .start)

        let chunk = try [UInt8](unsafeUninitializedCapacity: 4096) { buffer, count in
          var output = OutputRawSpan(buffer: UnsafeMutableRawBufferPointer(buffer), initializedCount: 0)
          count = try fd.read(filling: &output, retryOnInterrupt: true)
        }

        #expect(chunk.count == 4096)
        #expect(chunk == writeData)
      }
    }
  }
}
