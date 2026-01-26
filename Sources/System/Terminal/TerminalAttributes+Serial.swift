/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

// MARK: - Serial Port Conveniences

extension TerminalAttributes {
  /// The number of data bits per character.
  @frozen
  @available(System 99, *)
  public struct CharacterSize: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.TerminalFlags

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.TerminalFlags) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var bits5: CharacterSize { CharacterSize(rawValue: _CS5) }
    @_alwaysEmitIntoClient
    public static var bits6: CharacterSize { CharacterSize(rawValue: _CS6) }
    @_alwaysEmitIntoClient
    public static var bits7: CharacterSize { CharacterSize(rawValue: _CS7) }
    @_alwaysEmitIntoClient
    public static var bits8: CharacterSize { CharacterSize(rawValue: _CS8) }
  }

  /// The parity mode for error detection.
  @frozen
  @available(System 99, *)
  public struct Parity: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.TerminalFlags

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.TerminalFlags) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var none: Parity { Parity(rawValue: 0) }
    @_alwaysEmitIntoClient
    public static var even: Parity { Parity(rawValue: _PARENB) }
    @_alwaysEmitIntoClient
    public static var odd: Parity { Parity(rawValue: _PARENB | _PARODD) }

    #if os(Linux)
    @_alwaysEmitIntoClient
    public static var mark: Parity { Parity(rawValue: _PARENB | _PARODD | _CMSPAR) }
    @_alwaysEmitIntoClient
    public static var space: Parity { Parity(rawValue: _PARENB | _CMSPAR) }
    #endif
  }

  /// The number of stop bits per character.
  @frozen
  @available(System 99, *)
  public struct StopBits: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.TerminalFlags

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.TerminalFlags) {
      self.rawValue = rawValue
    }

    @_alwaysEmitIntoClient
    public static var one: StopBits { StopBits(rawValue: 0) }
    @_alwaysEmitIntoClient
    public static var two: StopBits { StopBits(rawValue: _CSTOPB) }
  }

  /// The number of data bits per character.
  @_alwaysEmitIntoClient
  public var characterSize: CharacterSize {
    get {
      CharacterSize(rawValue: controlFlags.rawValue & _CSIZE)
    }
    set {
      // CRITICAL: Clear CSIZE mask first to avoid combining bits
      controlFlags.rawValue = (controlFlags.rawValue & ~_CSIZE) | newValue.rawValue
    }
  }

  /// The parity mode for error detection.
  @_alwaysEmitIntoClient
  public var parity: Parity {
    get {
      #if os(Linux)
      let parityBits = controlFlags.rawValue & (_PARENB | _PARODD | _CMSPAR)
      #else
      let parityBits = controlFlags.rawValue & (_PARENB | _PARODD)
      #endif
      return Parity(rawValue: parityBits)
    }
    set {
      #if os(Linux)
      let mask: CInterop.TerminalFlags = _PARENB | _PARODD | _CMSPAR
      #else
      let mask: CInterop.TerminalFlags = _PARENB | _PARODD
      #endif
      controlFlags.rawValue = (controlFlags.rawValue & ~mask) | newValue.rawValue
    }
  }

  /// The number of stop bits per character.
  @_alwaysEmitIntoClient
  public var stopBits: StopBits {
    get {
      StopBits(rawValue: controlFlags.rawValue & _CSTOPB)
    }
    set {
      controlFlags.rawValue = (controlFlags.rawValue & ~_CSTOPB) | newValue.rawValue
    }
  }
}

#endif
