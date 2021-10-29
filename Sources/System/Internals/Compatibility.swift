/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

internal extension String {
    
    @usableFromInline
    init(
    _unsafeUninitializedCapacity capacity: Int,
    initializingUTF8With body: (UnsafeMutableBufferPointer<UInt8>) throws -> Int
    ) rethrows {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    if #available(macOS 11, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
      self = try String(
        unsafeUninitializedCapacity: capacity,
        initializingUTF8With: body)
      return
    } else {
        self = try Self.withUnsafeUninitialized(capacity: capacity, initializing: body)
    }
#elseif swift(>=5.5)
        self = try String(
          unsafeUninitializedCapacity: capacity,
          initializingUTF8With: body
        )
#else // older Swift
        self = try Self.withUnsafeUninitialized(capacity: capacity, initializing: body)
#endif
  }
    
    static func withUnsafeUninitialized(
        capacity: Int,
        initializing body: (UnsafeMutableBufferPointer<UInt8>) throws -> Int
    ) rethrows -> String {
        let array = try Array<UInt8>(
          unsafeUninitializedCapacity: capacity
        ) { buffer, count in
          count = try body(buffer)
        }
        return String(decoding: array, as: UTF8.self)
    }
}

