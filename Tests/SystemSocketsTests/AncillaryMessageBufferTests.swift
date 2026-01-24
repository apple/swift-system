/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

import SystemPackage
@testable import SystemSockets

@Suite("Ancillary Message Buffer")
struct AncillaryMessageBufferTests {
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test("Append and iterate messages")
  func testAppend() {
    // Create a buffer of 100 messages with varying payload lengths (0-99 bytes).
    // Use a realistic level/type combination for all messages.
    let level = SocketDescriptor.ProtocolID(rawValue: SOL_SOCKET)
    let type = SocketDescriptor.Option(rawValue: CInt(SCM_RIGHTS))

    var buffer = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 0)
    for i in 0 ..< 100 {
      let bytes = UnsafeMutableRawBufferPointer.allocate(byteCount: i, alignment: 1)
      defer { bytes.deallocate() }
      system_memset(bytes, to: UInt8(i))
      let span = RawSpan(_unsafeBytes: UnsafeRawBufferPointer(bytes))
      buffer.appendMessage(level: level, type: type, bytes: span)
    }

    // Check that we can access appended messages.
    for (i, message) in buffer.enumerated() {
      #expect(message.level == level)
      #expect(message.type == type)
      message.withUnsafeBytes { bytes in
        #expect(bytes.count == i)
        #expect(bytes.allSatisfy { $0 == UInt8(i) })
      }
    }
    #expect(buffer.count == 100)
  }

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test("Append messages using Span")
  func testAppendSpan() {
    struct TestMessage {
      let level: SocketDescriptor.ProtocolID
      let type: SocketDescriptor.Option
      let fillByte: UInt8
      let size: Int
    }

    let testMessages = [
      TestMessage(level: .init(rawValue: 1), type: .init(rawValue: 100), fillByte: 42, size: 8),
      TestMessage(level: .init(rawValue: 2), type: .init(rawValue: 200), fillByte: 99, size: 16),
      TestMessage(level: .init(rawValue: 3), type: .init(rawValue: 300), fillByte: 123, size: 4),
    ]

    var buffer = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 0)

    // Append all messages using RawSpan API
    for testMsg in testMessages {
      let testData = [UInt8](repeating: testMsg.fillByte, count: testMsg.size)
      testData.withUnsafeBytes { bytes in
        let span = RawSpan(_unsafeBytes: bytes)
        buffer.appendMessage(level: testMsg.level, type: testMsg.type, bytes: span)
      }
    }

    // Verify all messages were appended correctly
    #expect(buffer.count == testMessages.count)
    for (message, expected) in zip(buffer, testMessages) {
      #expect(message.level == expected.level)
      #expect(message.type == expected.type)
      message.withUnsafeBytes { bytes in
        #expect(bytes.count == expected.size)
        #expect(bytes.allSatisfy { $0 == expected.fillByte })
      }
    }
  }
}
