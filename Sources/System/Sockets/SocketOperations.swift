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

  /// Deletes a socket's file descriptor.
  ///
  /// This is equivalent to `socket.fileDescriptor.close()`
  @_alwaysEmitIntoClient
  public func close() throws { try fileDescriptor.close() }

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

}
