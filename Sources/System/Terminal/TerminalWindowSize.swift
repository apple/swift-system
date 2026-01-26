/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

// MARK: - Window Size

@available(System 99, *)
extension TerminalDescriptor {
  /// The size of a terminal window in characters.
  @frozen
  @available(System 99, *)
  public struct WindowSize: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.WinSize

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.WinSize) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public init(rows: UInt16, columns: UInt16) {
      var size = CInterop.WinSize()
      size.ws_row = rows
      size.ws_col = columns
      self.rawValue = size
    }

    @_alwaysEmitIntoClient
    public var rows: UInt16 {
      get { rawValue.ws_row }
      set { rawValue.ws_row = newValue }
    }

    @_alwaysEmitIntoClient
    public var columns: UInt16 {
      get { rawValue.ws_col }
      set { rawValue.ws_col = newValue }
    }

    // MARK: - Equatable & Hashable

    @_alwaysEmitIntoClient
    public static func == (lhs: WindowSize, rhs: WindowSize) -> Bool {
      lhs.rows == rhs.rows && lhs.columns == rhs.columns
    }

    @_alwaysEmitIntoClient
    public func hash(into hasher: inout Hasher) {
      hasher.combine(rows)
      hasher.combine(columns)
    }
  }

  /// Returns the current window size.
  @_alwaysEmitIntoClient
  public func windowSize() throws(Errno) -> WindowSize {
    try _windowSize().get()
  }

  @usableFromInline
  internal func _windowSize() -> Result<WindowSize, Errno> {
    var size = CInterop.WinSize()
    let result = withUnsafeMutablePointer(to: &size) { sizePtr in
      valueOrErrno(retryOnInterrupt: false) {
        system_tiocgwinsz(rawValue, sizePtr)
      }
    }
    return result.map { _ in WindowSize(rawValue: size) }
  }

  /// Sets the window size.
  @_alwaysEmitIntoClient
  public func setWindowSize(_ size: WindowSize) throws(Errno) {
    try _setWindowSize(size).get()
  }

  @usableFromInline
  internal func _setWindowSize(_ size: WindowSize) -> Result<Void, Errno> {
    var ws = size.rawValue
    return withUnsafePointer(to: &ws) { sizePtr in
      nothingOrErrno(retryOnInterrupt: false) {
        system_tiocswinsz(rawValue, sizePtr)
      }
    }
  }
}

#endif
