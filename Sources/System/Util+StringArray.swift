/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension Array where Element == String {
  internal typealias CStr = UnsafePointer<CChar>?

  /// Call `body` with a buffer of `UnsafePointer<CChar>?` values,
  /// suitable for passing to a C function that expects a C string array.
  /// The buffer is guaranteed to be followed by an extra storage slot
  /// containing a null pointer. (For C functions that expect an array
  /// terminated with a null pointer.)
  ///
  /// This function is careful not to heap allocate memory unless there are
  /// too many strings, or if it needs to copy too much character data.
  internal func _withCStringArray<R>(
    _ body: (UnsafeBufferPointer<UnsafePointer<CChar>?>) throws -> R
  ) rethrows -> R {
    if self.count == 0 {
      // Fast path: empty array.
      let p: CStr = nil
      return try Swift.withUnsafePointer(to: p) { array in
        try body(UnsafeBufferPointer(start: array, count: 0))
      }
    }
    #if SYSTEM_OS_BUILD // String._guts isn't accessible from SwiftPM or CMake
    if self.count == 1, self[0]._guts._isLargeZeroTerminatedContiguousUTF8 {
      // Fast path: Single fast string.
      let start = self[0]._guts._largeContiguousUTF8CodeUnits.baseAddress!
      var p: (CStr, CStr) = (
        UnsafeRawPointer(start).assumingMemoryBound(to: CChar.self),
        nil
      )
      return try Swift.withUnsafeBytes(of: &p) { buffer in
        let start = buffer.baseAddress!.assumingMemoryBound(to: CStr.self)
        return try body(UnsafeBufferPointer(start: start, count: 1))
      }
    }
    #endif
    // We need to create a buffer for the C array.
    return try _withStackBuffer(
      capacity: (self.count + 1) * MemoryLayout<CStr>.stride
    ) { array in
      let array = array.bindMemory(to: CStr.self)
      // Calculate number of bytes we need for character storage
      let bytes = self.reduce(into: 0) { count, string in
        #if SYSTEM_OS_BUILD
        if string._guts._isLargeZeroTerminatedContiguousUTF8 { return }
        #endif
        count += string.utf8.count + 1 // Plus one for terminating NUL
      }
      #if SYSTEM_OS_BUILD
      if bytes == 0 {
        // Fast path: we only contain strings with stable null-terminated storage
        for i in self.indices {
          let string = self[i]
          precondition(string._guts._isLargeZeroTerminatedContiguousUTF8)
          let address = string._guts._largeContiguousUTF8CodeUnits.baseAddress!
          array[i] = UnsafeRawPointer(address).assumingMemoryBound(to: CChar.self)
        }
        array[self.count] = nil
        return try body(UnsafeBufferPointer(rebasing: array.dropLast()))
      }
      #endif
      return try _withStackBuffer(capacity: bytes) { chars in
        var chars = chars
        for i in self.indices {
          let (cstr, scratchUsed) = self[i]._getCStr(with: chars)
          array[i] = cstr.assumingMemoryBound(to: CChar.self)
          chars = .init(rebasing: chars[scratchUsed...])
        }
        array[self.count] = nil
        return try body(UnsafeBufferPointer(rebasing: array.dropLast()))
      }
    }
  }
}

extension String {
  fileprivate func _getCStr(
    with scratch: UnsafeMutableRawBufferPointer
  ) -> (cstr: UnsafeRawPointer, scratchUsed: Int) {
    #if SYSTEM_OS_BUILD
    if _guts._isLargeZeroTerminatedContiguousUTF8 {
      // This is a wonderful string, we can just use its storage address.
      let address = _guts._largeContiguousUTF8CodeUnits.baseAddress!
      return (UnsafeRawPointer(address), 0)
    }
    #endif
    let r: (UnsafeRawPointer, Int)? = self.utf8.withContiguousStorageIfAvailable { source in
      // This is a somewhat okay string -- we need to use memcpy.
      precondition(source.count <= scratch.count)
      let start = scratch.baseAddress!
      start.copyMemory(from: source.baseAddress!, byteCount: source.count)
      start.storeBytes(of: 0, toByteOffset: source.count, as: UInt8.self)
      return (UnsafeRawPointer(start), source.count + 1)
    }
    if let r = r { return r }

    // What a horrible string; we need to copy individual bytes.
    precondition(self.utf8.count <= scratch.count)
    var c = 0
    for byte in self.utf8 {
      scratch[c] = byte
      c += 1
    }
    scratch[c] = 0
    c += 1
    return (UnsafeRawPointer(scratch.baseAddress!), c)
  }
}

