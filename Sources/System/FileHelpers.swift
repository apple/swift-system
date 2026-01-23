/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

@available(System 0.0.1, *)
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
      _writeAllBuffer(buffer)
    }
  }

  @_alwaysEmitIntoClient
  internal func _writeAllBuffer(
    _ buffer: UnsafeRawBufferPointer
  ) -> Result<Int, Errno> {
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
      _writeAllBuffer(toAbsoluteOffset: offset, buffer)
    }
  }

  @_alwaysEmitIntoClient
  internal func _writeAllBuffer(
    toAbsoluteOffset offset: Int64, _ buffer: UnsafeRawBufferPointer
  ) -> Result<Int, Errno> {
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

  /// Writes the entire contents of a buffer, retrying on partial writes.
  ///
  /// - Parameters:
  ///   - data: The region of memory that contains the data being written.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were written.
  ///
  /// After writing,
  /// this method increments the file's offset by the number of bytes written.
  /// To change the file's offset,
  /// call the ``seek(offset:from:)`` method.
  ///
  /// The corresponding C function is `write`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func writeAll(
    _ data: RawSpan,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    do {
      return try data.withUnsafeBytes { buffer in
        try _writeAllBuffer(buffer).get()
      }
    } catch let error as Errno {
      throw error
    } catch {
      fatalError("Unexpected error type")
    }
  }

  /// Writes the entire contents of a buffer at the specified offset,
  /// retrying on partial writes.
  ///
  /// - Parameters:
  ///   - offset: The file offset where writing begins.
  ///   - data: The region of memory that contains the data being written.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were written.
  ///
  /// Unlike ``writeAll(_:retryOnInterrupt:)``,
  /// this method leaves the file's existing offset unchanged.
  ///
  /// The corresponding C function is `pwrite`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  public func writeAll(
    toAbsoluteOffset offset: Int64,
    _ data: RawSpan,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    do {
      return try data.withUnsafeBytes { buffer in
        try _writeAllBuffer(toAbsoluteOffset: offset, buffer).get()
      }
    } catch let error as Errno {
      throw error
    } catch {
      fatalError("Unexpected error type")
    }
  }

  /// Reads bytes into a buffer, retrying until it is full.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to read into.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were read.
  ///
  /// After reading,
  /// this method increments the file's offset by the number of bytes read.
  /// To change the file's offset,
  /// call the ``seek(offset:from:)`` method.
  ///
  /// The corresponding C function is `read`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  @discardableResult
  public func read(
    filling buffer: inout OutputRawSpan,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    let originalCapacity = buffer.freeCapacity
    while buffer.freeCapacity > 0 {
      let bytesRead = try read(into: &buffer, retryOnInterrupt: retryOnInterrupt)
      if bytesRead == 0 {
        break  // EOF
      }
    }
    return originalCapacity - buffer.freeCapacity
  }

  /// Reads bytes at the specified offset into a buffer,
  /// retrying until it is full.
  ///
  /// - Parameters:
  ///   - offset: The file offset where reading begins.
  ///   - buffer: The region of memory to read into.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were read.
  ///
  /// Unlike ``read(filling:retryOnInterrupt:)``,
  /// this method leaves the file's existing offset unchanged.
  ///
  /// The corresponding C function is `pread`.
  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @_alwaysEmitIntoClient
  @discardableResult
  public func read(
    fromAbsoluteOffset offset: Int64,
    filling buffer: inout OutputRawSpan,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> Int {
    let originalCapacity = buffer.freeCapacity
    var currentOffset = offset
    while buffer.freeCapacity > 0 {
      let bytesRead = try read(fromAbsoluteOffset: currentOffset, into: &buffer, retryOnInterrupt: retryOnInterrupt)
      if bytesRead == 0 {
        break  // EOF
      }
      currentOffset += Int64(bytesRead)
    }
    return originalCapacity - buffer.freeCapacity
  }
}
