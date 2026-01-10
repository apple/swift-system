/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

/// An index identifying a specific control character.
@frozen
@available(System 99, *)
public struct ControlCharacter: RawRepresentable, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInt

  @_alwaysEmitIntoClient
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  @_alwaysEmitIntoClient
  public static var endOfFile: Self { Self(rawValue: _VEOF) }

  @_alwaysEmitIntoClient
  public static var endOfLine: Self { Self(rawValue: _VEOL) }

  @_alwaysEmitIntoClient
  public static var erase: Self { Self(rawValue: _VERASE) }

  @_alwaysEmitIntoClient
  public static var interrupt: Self { Self(rawValue: _VINTR) }

  @_alwaysEmitIntoClient
  public static var kill: Self { Self(rawValue: _VKILL) }

  @_alwaysEmitIntoClient
  public static var minimum: Self { Self(rawValue: _VMIN) }

  @_alwaysEmitIntoClient
  public static var quit: Self { Self(rawValue: _VQUIT) }

  @_alwaysEmitIntoClient
  public static var start: Self { Self(rawValue: _VSTART) }

  @_alwaysEmitIntoClient
  public static var stop: Self { Self(rawValue: _VSTOP) }

  @_alwaysEmitIntoClient
  public static var suspend: Self { Self(rawValue: _VSUSP) }

  @_alwaysEmitIntoClient
  public static var time: Self { Self(rawValue: _VTIME) }

  @_alwaysEmitIntoClient
  public static var endOfLine2: Self { Self(rawValue: _VEOL2) }

  @_alwaysEmitIntoClient
  public static var wordErase: Self { Self(rawValue: _VWERASE) }

  @_alwaysEmitIntoClient
  public static var reprint: Self { Self(rawValue: _VREPRINT) }

  @_alwaysEmitIntoClient
  public static var discard: Self { Self(rawValue: _VDISCARD) }

  @_alwaysEmitIntoClient
  public static var literalNext: Self { Self(rawValue: _VLNEXT) }

  #if canImport(Darwin)
  @_alwaysEmitIntoClient
  public static var status: Self { Self(rawValue: _VSTATUS) }

  @_alwaysEmitIntoClient
  public static var delayedSuspend: Self { Self(rawValue: _VDSUSP) }
  #endif

  #if os(Linux)
  @_alwaysEmitIntoClient
  public static var switchCharacter: Self { Self(rawValue: _VSWTC) }
  #endif
}

/// The control characters for a terminal.
@frozen
@available(System 99, *)
public struct ControlCharacters: Sendable {
  #if SYSTEM_PACKAGE_DARWIN
  @usableFromInline
  internal var storage: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
  #elseif os(Linux)
  @usableFromInline
  internal var storage: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
  #endif

  @_alwaysEmitIntoClient
  public init() {
    #if SYSTEM_PACKAGE_DARWIN
    self.storage = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    #elseif os(Linux)
    self.storage = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    #endif
  }

  @_alwaysEmitIntoClient
  public static var count: Int { Int(_NCCS) }

  @_alwaysEmitIntoClient
  public static var disabled: CInterop.ControlCharacterValue { __POSIX_VDISABLE }

  @_alwaysEmitIntoClient
  public subscript(_ character: ControlCharacter) -> CInterop.ControlCharacterValue {
    get {
      withUnsafeBytes(of: storage) { buffer in
        buffer[Int(character.rawValue)]
      }
    }
    set {
      withUnsafeMutableBytes(of: &storage) { buffer in
        buffer[Int(character.rawValue)] = newValue
      }
    }
  }

  @_alwaysEmitIntoClient
  public subscript(rawIndex index: Int) -> CInterop.ControlCharacterValue {
    get {
      precondition(index >= 0 && index < Self.count, "Index out of bounds")
      return withUnsafeBytes(of: storage) { $0[index] }
    }
    set {
      precondition(index >= 0 && index < Self.count, "Index out of bounds")
      withUnsafeMutableBytes(of: &storage) { $0[index] = newValue }
    }
  }
}

#endif

// Manual Hashable conformance
@available(System 99, *)
extension ControlCharacters: Hashable {
  @_alwaysEmitIntoClient
  public static func == (lhs: ControlCharacters, rhs: ControlCharacters) -> Bool {
    withUnsafeBytes(of: lhs.storage) { lhsBytes in
      withUnsafeBytes(of: rhs.storage) { rhsBytes in
        lhsBytes.elementsEqual(rhsBytes)
      }
    }
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    withUnsafeBytes(of: storage) { bytes in
      hasher.combine(bytes: bytes)
    }
  }
}
