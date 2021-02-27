/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension SocketDescriptor {
  /// Create an endpoint for communication.
  ///
  /// - Parameters:
  ///    - domain: Select the protocol family which should be used for
  ///      communication
  ///    - type: Specify the semantics of communication
  ///    - protocol: Specify a particular protocol to use with the socket.
  ///      Normally, there is only one protocol for a particular connection
  ///      type within a protocol family, so a default argument of `.default`
  ///      is provided
  ///   - retryOnInterrupt: Whether to retry the open operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  ///
  /// The corresponding C function is `socket`
  @_alwaysEmitIntoClient
  public static func open(
    _ domain: Domain,
    _ type: ConnectionType,
    _ protocol: ProtocolID = .default,
    retryOnInterrupt: Bool = true
  ) throws -> SocketDescriptor {
    try SocketDescriptor._open(
      domain, type, `protocol`, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _open(
    _ domain: Domain,
    _ type: ConnectionType,
    _ protocol: ProtocolID = .default,
    retryOnInterrupt: Bool
  ) -> Result<SocketDescriptor, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_socket(domain.rawValue, type: type.rawValue, protocol: `protocol`.rawValue)
    }.map(SocketDescriptor.init(rawValue:))
  }

  /// Shutdown part of a full-duplex connection
  ///
  /// The corresponding C function is `shutdown`
  @_alwaysEmitIntoClient
  public func shutdown(_ how: ShutdownKind) throws {
    try _shutdown(how).get()
  }

  @usableFromInline
  internal func _shutdown(_ how: ShutdownKind) -> Result<(), Errno> {
    nothingOrErrno(system_shutdown(self.rawValue, how.rawValue))
  }

  /// Listen for connections on a socket.
  ///
  /// Only applies to sockets of connection type `.stream`.
  ///
  /// - Parameters:
  ///   - backlog: the maximum length for the queue of pending connections
  ///
  /// The corresponding C function is `listen`.
  @_alwaysEmitIntoClient
  public func listen(backlog: Int) throws {
    try _listen(backlog: backlog).get()
  }

  @usableFromInline
  internal func _listen(backlog: Int) -> Result<(), Errno> {
    nothingOrErrno(system_listen(self.rawValue, CInt(backlog)))
  }


}

// MARK: - Forward FileDescriptor methods
extension SocketDescriptor {
  /// Deletes a socket's file descriptor.
  ///
  /// This is equivalent to calling `fileDescriptor.close()`
  @_alwaysEmitIntoClient
  public func close() throws { try fileDescriptor.close() }

  /// Reads bytes from a socket.
  ///
  /// This is equivalent to calling `fileDescriptor.read(into:retryOnInterrupt:)`
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to read into.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were read.
  ///
  /// The corresponding C function is `read`.
  @_alwaysEmitIntoClient
  public func read(
    into buffer: UnsafeMutableRawBufferPointer, retryOnInterrupt: Bool = true
  ) throws -> Int {
    try fileDescriptor.read(into: buffer, retryOnInterrupt: retryOnInterrupt)
  }

  /// Writes the contents of a buffer to the socket.
  ///
  /// This is equivalent to `fileDescriptor.write(_:retryOnInterrupt:)`
  ///
  /// - Parameters:
  ///   - buffer: The region of memory that contains the data being written.
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
  @_alwaysEmitIntoClient
  public func write(
    _ buffer: UnsafeRawBufferPointer, retryOnInterrupt: Bool = true
  ) throws -> Int {
    try fileDescriptor.write(buffer, retryOnInterrupt: retryOnInterrupt)
  }
}
