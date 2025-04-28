/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// A copy-on-write fixed-size buffer of raw memory.
internal struct _RawBuffer {
  internal var _storage: Storage?

  internal init() {
    self._storage = nil
  }

  internal init(minimumCapacity: Int) {
    if minimumCapacity > 0 {
      self._storage = Storage.create(minimumCapacity: minimumCapacity)
    } else {
      self._storage = nil
    }
  }
}

extension _RawBuffer {
  internal var capacity: Int {
    _storage?.header ?? 0 // Note: not capacity!
  }

  internal mutating func ensureUnique() {
    guard _storage != nil else { return }
    let unique = isKnownUniquelyReferenced(&_storage)
    if !unique {
      _storage = _copy(capacity: capacity)
    }
  }

  internal func _grow(desired: Int) -> Int {
    let next = Int(1.75 * Double(self.capacity))
    return Swift.max(next, desired)
  }

  internal mutating func ensureUnique(capacity: Int) {
    let unique = isKnownUniquelyReferenced(&_storage)
    if !unique || self.capacity < capacity {
      _storage = _copy(capacity: _grow(desired: capacity))
    }
  }

  internal func withUnsafeBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    guard let storage = _storage else {
      return try body(UnsafeRawBufferPointer(start: nil, count: 0))
    }
    return try storage.withUnsafeMutablePointers { count, bytes in
      let buffer = UnsafeRawBufferPointer(start: bytes, count: count.pointee)
      return try body(buffer)
    }
  }

  internal mutating func withUnsafeMutableBytes<R>(
    _ body: (UnsafeMutableRawBufferPointer) throws -> R
  ) rethrows -> R {
    guard _storage != nil else {
      return try body(UnsafeMutableRawBufferPointer(start: nil, count: 0))
    }
    ensureUnique()
    return try _storage!.withUnsafeMutablePointers { count, bytes in
      let buffer = UnsafeMutableRawBufferPointer(start: bytes, count: count.pointee)
      return try body(buffer)
    }
  }
}

extension _RawBuffer {
  internal class Storage: ManagedBuffer<Int, UInt8> {
    internal static func create(minimumCapacity: Int) -> Storage {
      Storage.create(
        minimumCapacity: minimumCapacity,
        makingHeaderWith: {
#if os(OpenBSD)
          minimumCapacity
#else
          $0.capacity
#endif
        }
      ) as! Storage
    }
  }

  internal func _copy(capacity: Int) -> Storage {
    let copy = Storage.create(minimumCapacity: capacity)
    copy.withUnsafeMutablePointers { dstlen, dst in
      self.withUnsafeBytes { src in
        guard src.count > 0 else { return }
        assert(src.count <= dstlen.pointee)
        UnsafeMutableRawPointer(dst)
          .copyMemory(
            from: src.baseAddress!,
            byteCount: Swift.min(src.count, dstlen.pointee))
      }
    }
    return copy
  }
}
