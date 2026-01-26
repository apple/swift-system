/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

// MARK: - Terminal Operations

@available(System 99, *)
extension TerminalDescriptor {
  /// Returns the current terminal attributes.
  @_alwaysEmitIntoClient
  public func attributes() throws(Errno) -> TerminalAttributes {
    try _attributes().get()
  }

  @usableFromInline
  internal func _attributes() -> Result<TerminalAttributes, Errno> {
    var attrs = CInterop.Termios()
    let result = withUnsafeMutablePointer(to: &attrs) { attrsPtr in
      nothingOrErrno(retryOnInterrupt: false) {
        system_tcgetattr(rawValue, attrsPtr)
      }
    }
    return result.map { TerminalAttributes(rawValue: attrs) }
  }

  /// Sets the terminal attributes.
  @_alwaysEmitIntoClient
  public func setAttributes(
    _ attributes: TerminalAttributes,
    when action: TerminalAttributes.SetAction,
    retryOnInterrupt: Bool = true
  ) throws(Errno) {
    try _setAttributes(attributes, when: action, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _setAttributes(
    _ attributes: TerminalAttributes,
    when action: TerminalAttributes.SetAction,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    var attrs = attributes.rawValue
    return withUnsafePointer(to: &attrs) { attrsPtr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_tcsetattr(rawValue, action.rawValue, attrsPtr)
      }
    }
  }

  /// Blocks until all output written to the terminal has been transmitted.
  @_alwaysEmitIntoClient
  public func drain(retryOnInterrupt: Bool = true) throws(Errno) {
    try _drain(retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _drain(retryOnInterrupt: Bool) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_tcdrain(rawValue)
    }
  }

  /// Discards data in the specified queue(s).
  @_alwaysEmitIntoClient
  public func flush(_ queue: Queue) throws(Errno) {
    try _flush(queue).get()
  }

  @usableFromInline
  internal func _flush(_ queue: Queue) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_tcflush(rawValue, queue.rawValue)
    }
  }

  /// Suspends or resumes data transmission or reception.
  @_alwaysEmitIntoClient
  public func flow(_ action: FlowAction) throws(Errno) {
    try _flow(action).get()
  }

  @usableFromInline
  internal func _flow(_ action: FlowAction) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_tcflow(rawValue, action.rawValue)
    }
  }

  /// Sends a break signal on the terminal.
  @_alwaysEmitIntoClient
  public func sendBreak(duration: CInt = 0) throws(Errno) {
    try _sendBreak(duration: duration).get()
  }

  @usableFromInline
  internal func _sendBreak(duration: CInt) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: false) {
      system_tcsendbreak(rawValue, duration)
    }
  }

  /// Executes a closure with modified terminal attributes.
  public func withAttributes<T>(
    appliedWhen action: TerminalAttributes.SetAction = .afterFlush,
    retryOnInterrupt: Bool = true,
    _ modify: (inout TerminalAttributes) throws -> Void,
    do body: () throws -> T
  ) throws -> T {
    let original = try attributes()
    var modified = original
    try modify(&modified)
    try setAttributes(modified, when: action, retryOnInterrupt: retryOnInterrupt)
    defer {
      _ = try? setAttributes(original, when: .now)
    }
    return try body()
  }

  /// Executes a closure with the terminal in raw mode.
  public func withRawMode<T>(retryOnInterrupt: Bool = true, do body: () throws -> T) throws -> T {
    try withAttributes(retryOnInterrupt: retryOnInterrupt, { $0.makeRaw() }, do: body)
  }
}

// MARK: - Supporting Types

@available(System 99, *)
extension TerminalDescriptor {
  /// Specifies which queue(s) to flush.
  @frozen
  @available(System 99, *)
  public struct Queue: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var input: Self { Self(rawValue: _TCIFLUSH) }

    @_alwaysEmitIntoClient
    public static var output: Self { Self(rawValue: _TCOFLUSH) }

    @_alwaysEmitIntoClient
    public static var both: Self { Self(rawValue: _TCIOFLUSH) }
  }

  /// Flow control actions.
  @frozen
  @available(System 99, *)
  public struct FlowAction: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var suspendOutput: Self { Self(rawValue: _TCOOFF) }

    @_alwaysEmitIntoClient
    public static var resumeOutput: Self { Self(rawValue: _TCOON) }

    @_alwaysEmitIntoClient
    public static var sendStop: Self { Self(rawValue: _TCIOFF) }

    @_alwaysEmitIntoClient
    public static var sendStart: Self { Self(rawValue: _TCION) }
  }
}

#endif
