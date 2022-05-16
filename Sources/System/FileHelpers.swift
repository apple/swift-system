/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
extension FileDescriptor {
  /// Runs a closure and then closes the file descriptor, even if an error occurs.
  ///
  /// - Parameter body: The closure to run.
  ///   If the closure throws an error,
  ///   this method closes the file descriptor before it rethrows that error.
  ///
  /// - Returns: The value returned by the closure.
  ///
  /// If `body` throws an error
  /// or an error occurs while closing the file descriptor,
  /// this method rethrows that error.
  public func closeAfter<R>(_ body: () throws -> R) throws -> R {
    // No underscore helper, since the closure's throw isn't necessarily typed.
    let result: R
    do {
      result = try body()
    } catch {
      _ = try? self.close() // Squash close error and throw closure's
      throw error
    }
    try self.close()
    return result
  }

  /// Writes a sequence of bytes to the current offset
  /// and then updates the offset.
  ///
  /// - Parameter sequence: The bytes to write.
  /// - Returns: The number of bytes written, equal to the number of elements in `sequence`.
  ///
  /// This method either writes the entire contents of `sequence`,
  /// or throws an error if only part of the content was written.
  ///
  /// Writes to the position associated with this file descriptor, and
  /// increments that position by the number of bytes written.
  /// See also ``seek(offset:from:)``.
  ///
  /// This method either writes the entire contents of `sequence`,
  /// or throws an error if only part of the content was written.
  ///
  /// If `sequence` doesn't implement
  /// the <doc://com.apple.documentation/documentation/swift/sequence/3128824-withcontiguousstorageifavailable> method,
  /// temporary space will be allocated as needed.
  @_alwaysEmitIntoClient
  @discardableResult
  public func writeAll<S: Sequence>(
    _ sequence: S
  ) throws -> Int where S.Element == UInt8 {
    return try _writeAll(sequence).get()
  }

  @usableFromInline
  internal func _writeAll<S: Sequence>(
    _ sequence: S
  ) -> Result<Int, Errno> where S.Element == UInt8 {
    sequence._withRawBufferPointer { buffer in
      var idx = 0
      while idx < buffer.count {
        switch _write(
          UnsafeRawBufferPointer(rebasing: buffer[idx...]), retryOnInterrupt: true
        ) {
        case .success(let numBytes): idx += numBytes
        case .failure(let err): return .failure(err)
        }
      }
      assert(idx == buffer.count)
      return .success(buffer.count)
    }
  }

  /// Reads bytes at the current file offset into a buffer until the buffer is filled.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to read into.
  /// - Returns: The number of bytes that were read, equal to `buffer.count`.
  ///
  /// This method either reads until `buffer` is full, or throws an error if
  /// only part of the buffer was filled.
  ///
  /// The <doc://com.apple.documentation/documentation/swift/unsafemutablerawbufferpointer/3019191-count> property of `buffer`
  /// determines the number of bytes that are read into the buffer.
  @_alwaysEmitIntoClient
  @discardableResult
  public func read(
    filling buffer: UnsafeMutableRawBufferPointer
  ) throws -> Int {
    return try _read(filling: buffer).get()
  }

  /// Reads bytes at the current file offset into a buffer until the buffer is filled.
  ///
  /// - Parameters:
  ///   - offset: The file offset where reading begins.
  ///   - buffer: The region of memory to read into.
  /// - Returns: The number of bytes that were read, equal to `buffer.count`.
  ///
  /// This method either reads until `buffer` is full, or throws an error if
  /// only part of the buffer was filled.
  ///
  /// The <doc://com.apple.documentation/documentation/swift/unsafemutablerawbufferpointer/3019191-count> property of `buffer`
  /// determines the number of bytes that are read into the buffer.
  @_alwaysEmitIntoClient
  @discardableResult
  public func read(
    fromAbsoluteOffset offset: Int64,
    filling buffer: UnsafeMutableRawBufferPointer
  ) throws -> Int {
    return try _read(fromAbsoluteOffset: offset, filling: buffer).get()
  }

  @usableFromInline
  internal func _read(
    fromAbsoluteOffset offset: Int64? = nil,
    filling buffer: UnsafeMutableRawBufferPointer
  ) -> Result<Int, Errno> {
    var idx = 0
    while idx < buffer.count {
      let readResult: Result<Int, Errno>
      if let offset = offset {
        readResult = _read(
          fromAbsoluteOffset: offset + Int64(idx),
          into: UnsafeMutableRawBufferPointer(rebasing: buffer[idx...]),
          retryOnInterrupt: true
        )
      } else {
        readResult = _readNoThrow(
          into: UnsafeMutableRawBufferPointer(rebasing: buffer[idx...]),
          retryOnInterrupt: true
        )
      }
      switch readResult {
        case .success(let numBytes): idx += numBytes
        case .failure(let err): return .failure(err)
      }
    }
    assert(idx == buffer.count)
    return .success(buffer.count)
  }

  /// Writes a sequence of bytes to the given offset.
  ///
  /// - Parameters:
  ///   - offset: The file offset where writing begins.
  ///   - sequence: The bytes to write.
  /// - Returns: The number of bytes written, equal to the number of elements in `sequence`.
  ///
  /// This method either writes the entire contents of `sequence`,
  /// or throws an error if only part of the content was written.
  /// Unlike ``writeAll(_:)``,
  /// this method preserves the file descriptor's existing offset.
  ///
  /// If `sequence` doesn't implement
  /// the <doc://com.apple.documentation/documentation/swift/sequence/3128824-withcontiguousstorageifavailable> method,
  /// temporary space will be allocated as needed.
  @_alwaysEmitIntoClient
  @discardableResult
  public func writeAll<S: Sequence>(
    toAbsoluteOffset offset: Int64, _ sequence: S
  ) throws -> Int where S.Element == UInt8 {
    try _writeAll(toAbsoluteOffset: offset, sequence).get()
  }

  @usableFromInline
  internal func _writeAll<S: Sequence>(
    toAbsoluteOffset offset: Int64, _ sequence: S
  ) -> Result<Int, Errno> where S.Element == UInt8 {
    sequence._withRawBufferPointer { buffer in
      var idx = 0
      while idx < buffer.count {
        switch _write(
          toAbsoluteOffset: offset + Int64(idx),
          UnsafeRawBufferPointer(rebasing: buffer[idx...]),
          retryOnInterrupt: true
        ) {
        case .success(let numBytes): idx += numBytes
        case .failure(let err): return .failure(err)
        }
      }
      assert(idx == buffer.count)
      return .success(buffer.count)
    }
  }
}
