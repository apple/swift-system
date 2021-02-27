/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension SocketDescriptor {
  /// Writes a sequence of bytes to the socket
  ///
  /// This is equivalent to calling `fileDescriptor.writeAll(_:)`
  ///
  /// - Parameter sequence: The bytes to write.
  /// - Returns: The number of bytes written, equal to the number of elements in `sequence`.
  @_alwaysEmitIntoClient
  @discardableResult
  public func writeAll<S: Sequence>(
    _ sequence: S
  ) throws -> Int where S.Element == UInt8 {
    try fileDescriptor.writeAll(sequence)
  }

  /// Runs a closure and then closes the socket, even if an error occurs.
  ///
  /// This is equivalent to calling `fileDescriptor.closeAfter(_:)`
  ///
  /// - Parameter body: The closure to run.
  ///   If the closure throws an error,
  ///   this method closes the socket before it rethrows that error.
  ///
  /// - Returns: The value returned by the closure.
  ///
  /// If `body` throws an error
  /// or an error occurs while closing the socket,
  /// this method rethrows that error.
  public func closeAfter<R>(_ body: () throws -> R) throws -> R {
    try fileDescriptor.closeAfter(body)
  }
}

