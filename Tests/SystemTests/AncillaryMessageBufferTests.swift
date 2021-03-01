/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// @available(...)
final class AncillaryMessageBufferTest: XCTestCase {
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
      XCTAssertEqual(Int(message.level.rawValue), 100 * i)
      XCTAssertEqual(Int(message.type.rawValue), 1000 * i)
      message.withUnsafeBytes { buffer in
        XCTAssertEqual(buffer.count, i)
        for idx in buffer.indices {
          XCTAssertEqual(buffer[idx], UInt8(i), "byte #\(idx)")
        }
      }
      i += 1
    }
    XCTAssertEqual(i, 100, "Too many messages in buffer")
  }
}
