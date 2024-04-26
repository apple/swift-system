/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// A platform-native character representation.
///
/// A SystemChar is a `CChar` on Linux and Darwin, and a `UInt16` on Windows.
///
/// Note that no particular encoding is assumed.
@frozen
public struct SystemChar:
  RawRepresentable, Sendable, Comparable, Hashable, Codable {
  public typealias RawValue = CInterop.PlatformChar

  public var rawValue: RawValue

  @inlinable
  public init(rawValue: RawValue) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  public init(_ rawValue: RawValue) {
    self.init(rawValue: rawValue)
  }

  @inlinable
  public static func < (lhs: SystemChar, rhs: SystemChar) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension SystemChar {
  /// Create a SystemChar from an ASCII scalar.
  @_alwaysEmitIntoClient
  public init(ascii: Unicode.Scalar) {
    precondition(ascii.isASCII)
    self.init(rawValue: numericCast(ascii.value))
  }

  /// Cast `x` to a `SystemChar`
  @_alwaysEmitIntoClient
  public init(_ x: some FixedWidthInteger) {
    self.init(numericCast(x))
  }

  /// The NULL character `\0`
  @_alwaysEmitIntoClient
  public static var null: SystemChar { SystemChar(0x0) }

  /// The slash character `/`
  @_alwaysEmitIntoClient
  public static var slash: SystemChar { SystemChar(ascii: "/") }

  /// The backslash character `\`
  @_alwaysEmitIntoClient
  public static var backslash: SystemChar { SystemChar(ascii: #"\"#) }

  /// The dot character `.`
  @_alwaysEmitIntoClient
  public static var dot: SystemChar { SystemChar(ascii: ".") }

  /// The colon character `:`
  @_alwaysEmitIntoClient
  public static var colon: SystemChar { SystemChar(ascii: ":") }

  /// The question mark character `?`
  @_alwaysEmitIntoClient
  public static var question: SystemChar { SystemChar(ascii: "?") }

  /// Returns `self` as a `Unicode.Scalar` if ASCII, else `nil`
  @_alwaysEmitIntoClient
  public var asciiScalar: Unicode.Scalar? {
    guard isASCII else { return nil }
    return Unicode.Scalar(UInt8(truncatingIfNeeded: rawValue))
  }

  /// Whether `self` is ASCII
  @_alwaysEmitIntoClient
  public var isASCII: Bool {
    (0...0x7F).contains(rawValue)
  }

  /// Whether `self` is an ASCII letter, i.e. in `[a-zA-Z]`
  @_alwaysEmitIntoClient
  public var isASCIILetter: Bool {
    guard isASCII else { return false }
    let asciiRaw: UInt8 = numericCast(rawValue)
    switch asciiRaw {
    case UInt8(ascii: "a")...UInt8(ascii: "z"): return true
    case UInt8(ascii: "A")...UInt8(ascii: "Z"): return true
    default: return false
    }
  }
}


/// A platform-native string representation. A `SystemString` is a collection
/// of non-NULL `SystemChar`s followed by a NULL terminator.
///
/// TODO: example use or two, showing that innards are not NULL, but there's
/// always a null at the end, NULL is not part of the count
@frozen
public struct SystemString: Sendable {
  public typealias Storage = [SystemChar]

  @usableFromInline
  internal var _nullTerminatedStorage: Storage

  /// Access the back storage, including the null terminator. Note that
  /// `nullTerminatedStorage.count == self.count + 1`, due
  /// to the null terminator.
  @_alwaysEmitIntoClient
  public var nullTerminatedStorage: Storage { _nullTerminatedStorage }

  /// Create a SystemString from pre-existing null-terminated storage
  @usableFromInline
  internal init(_nullTerminatedStorage storage: [SystemChar]) {
    self._nullTerminatedStorage = storage
    _invariantCheck()
  }
}

extension SystemString {
  /// Create an empty `SystemString`
  public init() {
    self.init(_nullTerminatedStorage: [.null])
  }

  /// Create a `SystemString` from a collection of `SystemChar`s.
  /// A NULL terminator will be added if `chars` lacks one. `chars` must not
  /// include any interior NULLs.
  @_alwaysEmitIntoClient
  public init<C: Collection>(_ chars: C) where C.Element == SystemChar {
    var rawChars = Array(chars)
    if rawChars.last != .null {
      rawChars.append(.null)
    }
    precondition(
      rawChars.dropLast(1).allSatisfy { $0 != .null },
      "Embedded NULL detected")
    self.init(_nullTerminatedStorage: rawChars)
  }
}

extension SystemString {
  @_alwaysEmitIntoClient
  internal func _invariantCheck() {
    #if DEBUG
    precondition(_nullTerminatedStorage.last! == .null)
    precondition(_nullTerminatedStorage.firstIndex(of: .null) == endIndex)
    #endif // DEBUG
  }
}

extension SystemString: RandomAccessCollection, MutableCollection {
  public typealias Element = SystemChar
  public typealias Index = Int
  public typealias Indices = Range<Index>

  @inlinable
  public var startIndex: Index {
    _nullTerminatedStorage.startIndex
  }

  @inlinable
  public var endIndex: Index {
    _nullTerminatedStorage.index(before: _nullTerminatedStorage.endIndex)
  }

  @inlinable
  public subscript(position: Index) -> SystemChar {
    _read {
      precondition(position >= startIndex && position <= endIndex)
      yield _nullTerminatedStorage[position]
    }
    set(newValue) {
      precondition(position >= startIndex && position <= endIndex)
      _nullTerminatedStorage[position] = newValue
      _invariantCheck()
    }
  }
}
extension SystemString: RangeReplaceableCollection {
  @inlinable
  public mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where C.Element == SystemChar {
    defer { _invariantCheck() }
    _nullTerminatedStorage.replaceSubrange(subrange, with: newElements)
  }

  @inlinable
  public mutating func reserveCapacity(_ n: Int) {
    defer { _invariantCheck() }
    _nullTerminatedStorage.reserveCapacity(1 + n)
  }

  @inlinable
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<SystemChar>) throws -> R
  ) rethrows -> R? {
    // Do not include the null terminator, it is outside the Collection
    try _nullTerminatedStorage.withContiguousStorageIfAvailable {
      try body(.init(start: $0.baseAddress, count: $0.count-1))
    }
  }
}

extension SystemString: Hashable, Codable {}

extension SystemString {

  // withSystemChars includes the null terminator
  internal func withSystemChars<T>(
    _ f: (UnsafeBufferPointer<SystemChar>) throws -> T
  ) rethrows -> T {
    try _nullTerminatedStorage.withContiguousStorageIfAvailable(f)!
  }

  internal func withCodeUnits<T>(
    _ f: (UnsafeBufferPointer<CInterop.PlatformUnicodeEncoding.CodeUnit>) throws -> T
  ) rethrows -> T {
    try withSystemChars { chars in
      let length = chars.count * MemoryLayout<SystemChar>.stride
      let count = length / MemoryLayout<CInterop.PlatformUnicodeEncoding.CodeUnit>.stride
      return try chars.baseAddress!.withMemoryRebound(
        to: CInterop.PlatformUnicodeEncoding.CodeUnit.self,
        capacity: count
      ) { pointer in
        try f(UnsafeBufferPointer(start: pointer, count: count))
      }
    }
  }
}

extension Slice where Base == SystemString {
  internal func withCodeUnits<T>(
    _ f: (UnsafeBufferPointer<CInterop.PlatformUnicodeEncoding.CodeUnit>) throws -> T
  ) rethrows -> T {
    try base.withCodeUnits {
      try f(UnsafeBufferPointer(rebasing: $0[indices]))
    }
  }

  internal var string: String {
    withCodeUnits { String(decoding: $0, as: CInterop.PlatformUnicodeEncoding.self) }
  }

  internal func withPlatformString<T>(
    _ f: (UnsafePointer<CInterop.PlatformChar>) throws -> T
  ) rethrows -> T {
    // FIXME: avoid allocation if we're at the end
    return try SystemString(self).withPlatformString(f)
  }

}

extension String {
  internal init(decoding str: SystemString) {
    // TODO: Can avoid extra strlen
    self = str.withPlatformString {
      String(platformString: $0)
    }
  }
  internal init?(validating str: SystemString) {
    // TODO: Can avoid extra strlen
    guard let str = str.withPlatformString(String.init(validatingPlatformString:))
    else { return nil }

    self = str
  }
}

extension SystemString: ExpressibleByStringLiteral {
  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  public init(_ string: String) {
    // TODO: can avoid extra strlen
    self = string.withPlatformString {
      SystemString(platformString: $0)
    }
  }
}

extension SystemString: CustomStringConvertible, CustomDebugStringConvertible {
  internal var string: String { String(decoding: self) }

  public var description: String { string }
  public var debugDescription: String { description.debugDescription }
}

extension SystemString {
  /// Creates a `SystemString` by copying bytes from a null-terminated platform string.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform string.
  public init(platformString: UnsafePointer<CInterop.PlatformChar>) {
    let count = 1 + system_platform_strlen(platformString)

    // TODO: Is this the right way?
    let chars: Array<SystemChar> = platformString.withMemoryRebound(
      to: SystemChar.self, capacity: count
    ) {
      Array(UnsafeBufferPointer(start: $0, count: count))
    }
    self.init(_nullTerminatedStorage: chars)
  }

  /// Calls the given closure with a pointer to the contents of the sytem string,
  /// represented as a null-terminated platform string.
  ///
  /// - Parameter body: A closure with a pointer parameter
  ///   that points to a null-terminated platform string.
  ///   If `body` has a return value,
  ///   that value is also used as the return value for this method.
  /// - Returns: The return value, if any, of the `body` closure parameter.
  ///
  /// The pointer passed as an argument to `body` is valid
  /// only during the execution of this method.
  /// Don't try to store the pointer for later use.
  public func withPlatformString<T>(
    _ f: (UnsafePointer<CInterop.PlatformChar>) throws -> T
  ) rethrows -> T {
    try withSystemChars { chars in
      let length = chars.count * MemoryLayout<SystemChar>.stride
      return try chars.baseAddress!.withMemoryRebound(
        to: CInterop.PlatformChar.self,
        capacity: length / MemoryLayout<CInterop.PlatformChar>.stride
      ) { pointer in
        assert(pointer[self.count] == 0)
        return try f(pointer)
      }
    }
  }
}

// TODO: SystemString should use a COW-interchangable storage form rather
// than array, so you could "borrow" the storage from a non-bridged String
// or Data or whatever
