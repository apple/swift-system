/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
import SystemPackage
@testable import SystemSockets

@Suite("Ancillary Message Buffer")
struct AncillaryMessageBufferTests {

  @available(System 99, *)
  @Test("Append and iterate messages")
  func testAppend() {
    // Create a buffer of 100 messages, with varying payload lengths.
    var buffer = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 0)
    for i in 0 ..< 100 {
      let bytes = UnsafeMutableRawBufferPointer.allocate(byteCount: i, alignment: 1)
      defer { bytes.deallocate() }
      system_memset(bytes, to: UInt8(i))
      buffer.appendMessage(level: .init(rawValue: CInt(100 * i)),
                           type: .init(rawValue: CInt(1000 * i)),
                           bytes: UnsafeRawBufferPointer(bytes))
    }
    // Check that we can access appended messages.
    var i = 0
    for message in buffer {
      #expect(Int(message.level.rawValue) == 100 * i)
      #expect(Int(message.type.rawValue) == 1000 * i)
      message.withUnsafeBytes { buffer in
        #expect(buffer.count == i)
        for idx in buffer.indices {
          #expect(buffer[idx] == UInt8(i), "byte #\(idx)")
        }
      }
      i += 1
    }
    #expect(i == 100, "Too many messages in buffer")
  }
}
