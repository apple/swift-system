/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
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
