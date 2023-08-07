/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// A platform-native character representation, currently used for file paths
public struct _SystemChar: RawRepresentable, Comparable, Hashable, Codable {
  public typealias RawValue = CInterop.PlatformChar

  public var rawValue: RawValue

  public init(rawValue: RawValue) { self.rawValue = rawValue }

  public init(_ rawValue: RawValue) { self.init(rawValue: rawValue) }

  public static func < (lhs: _SystemChar, rhs: _SystemChar) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension _SystemChar {
  internal init(ascii: Unicode.Scalar) {
    self.init(rawValue: numericCast(UInt8(ascii: ascii)))
  }
  internal init(codeUnit: CInterop.PlatformUnicodeEncoding.CodeUnit) {
    self.init(rawValue: codeUnit._platformChar)
  }

  internal static var null: _SystemChar { _SystemChar(0x0) }
  internal static var slash: _SystemChar { _SystemChar(ascii: "/") }
  internal static var backslash: _SystemChar { _SystemChar(ascii: #"\"#) }
  internal static var dot: _SystemChar { _SystemChar(ascii: ".") }
  internal static var colon: _SystemChar { _SystemChar(ascii: ":") }
  internal static var question: _SystemChar { _SystemChar(ascii: "?") }

  internal var codeUnit: CInterop.PlatformUnicodeEncoding.CodeUnit {
    rawValue._platformCodeUnit
  }

  internal var asciiScalar: Unicode.Scalar? {
    guard isASCII else { return nil }
    return Unicode.Scalar(UInt8(truncatingIfNeeded: rawValue))
  }

  internal var isASCII: Bool {
    (0...0x7F).contains(rawValue)
  }

  internal var isLetter: Bool {
    guard isASCII else { return false }
    let asciiRaw: UInt8 = numericCast(rawValue)
    return (UInt8(ascii: "a") ... UInt8(ascii: "z")).contains(asciiRaw) ||
           (UInt8(ascii: "A") ... UInt8(ascii: "Z")).contains(asciiRaw)
  }
}

// A platform-native string representation, currently for file paths
//
// Always null-terminated.

public struct _SystemString {
  public typealias Storage = [_SystemChar]
  internal var nullTerminatedStorage: Storage
}

extension _SystemString {
  public init() {
    self.nullTerminatedStorage = [.null]
    _invariantCheck()
  }

  internal var length: Int {
    let len = nullTerminatedStorage.count - 1
    assert(len == self.count)
    return len
  }

  // Common funnel point. Ensure all non-empty inits go here.
  internal init(nullTerminated storage: Storage) {
    self.nullTerminatedStorage = storage
    _invariantCheck()
  }

  // Ensures that result is null-terminated
  internal init<C: Collection>(_ chars: C) where C.Element == _SystemChar {
    var rawChars = Storage(chars)
    if rawChars.last != .null {
      rawChars.append(.null)
    }
    self.init(nullTerminated: rawChars)
  }
}

extension _SystemString {
  fileprivate func _invariantCheck() {
    #if DEBUG
    precondition(nullTerminatedStorage.last! == .null)
    precondition(nullTerminatedStorage.firstIndex(of: .null) == length)
    #endif // DEBUG
  }
}

extension _SystemString: RandomAccessCollection, MutableCollection {
  public typealias Element = _SystemChar
  public typealias Index = Storage.Index
  public typealias Indices = Range<Index>

  public var startIndex: Index {
    nullTerminatedStorage.startIndex
  }

  public var endIndex: Index {
    nullTerminatedStorage.index(before: nullTerminatedStorage.endIndex)
  }

  public subscript(position: Index) -> _SystemChar {
    _read {
      precondition(position >= startIndex && position <= endIndex)
      yield nullTerminatedStorage[position]
    }
    set(newValue) {
      precondition(position >= startIndex && position <= endIndex)
      nullTerminatedStorage[position] = newValue
      _invariantCheck()
    }
  }
}
extension _SystemString: RangeReplaceableCollection {
  public mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where C.Element == _SystemChar {
    defer { _invariantCheck() }
    nullTerminatedStorage.replaceSubrange(subrange, with: newElements)
  }

  public mutating func reserveCapacity(_ n: Int) {
    defer { _invariantCheck() }
    nullTerminatedStorage.reserveCapacity(1 + n)
  }

  // TODO: Below include null terminator, is this desired?

  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<_SystemChar>) throws -> R
  ) rethrows -> R? {
    try nullTerminatedStorage.withContiguousStorageIfAvailable(body)
  }

  public mutating func withContiguousMutableStorageIfAvailable<R>(
    _ body: (inout UnsafeMutableBufferPointer<_SystemChar>) throws -> R
  ) rethrows -> R? {
    defer { _invariantCheck() }
    return try nullTerminatedStorage.withContiguousMutableStorageIfAvailable(body)
  }
}

extension _SystemString: Hashable, Codable {}

extension _SystemString {
  // TODO: Below include null terminator, is this desired?

  internal func withSystemChars<T>(
    _ f: (UnsafeBufferPointer<_SystemChar>) throws -> T
  ) rethrows -> T {
    try withContiguousStorageIfAvailable(f)!
  }

  internal func withCodeUnits<T>(
    _ f: (UnsafeBufferPointer<CInterop.PlatformUnicodeEncoding.CodeUnit>) throws -> T
  ) rethrows -> T {
    try withSystemChars { chars in
      let length = chars.count * MemoryLayout<_SystemChar>.stride
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

extension Slice where Base == _SystemString {
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
    return try _SystemString(self).withPlatformString(f)
  }

}

extension String {
  internal init(decoding str: _SystemString) {
    // TODO: Can avoid extra strlen
    self = str.withPlatformString {
      String(platformString: $0)
    }
  }
  internal init?(validating str: _SystemString) {
    // TODO: Can avoid extra strlen
    guard let str = str.withPlatformString(String.init(validatingPlatformString:))
    else { return nil }

    self = str
  }
}

extension _SystemString: ExpressibleByStringLiteral {
  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  internal init(_ string: String) {
    // TODO: can avoid extra strlen
    self = string.withPlatformString {
     _SystemString(platformString: $0)
    }
  }
}

extension _SystemString: CustomStringConvertible, CustomDebugStringConvertible {
  internal var string: String { String(decoding: self) }

  public var description: String { string }
  public var debugDescription: String { description.debugDescription }
}

extension _SystemString {
  /// Creates a system string by copying bytes from a null-terminated platform string.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform string.
  internal init(platformString: UnsafePointer<CInterop.PlatformChar>) {
    let count = 1 + system_platform_strlen(platformString)

    // TODO: Is this the right way?
    let chars: Array<_SystemChar> = platformString.withMemoryRebound(
      to: _SystemChar.self, capacity: count
    ) {
      let bufPtr = UnsafeBufferPointer(start: $0, count: count)
      return Array(bufPtr)
    }

    self.init(nullTerminated: chars)
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
  internal func withPlatformString<T>(
    _ f: (UnsafePointer<CInterop.PlatformChar>) throws -> T
  ) rethrows -> T {
    try withSystemChars { chars in
      let length = chars.count * MemoryLayout<_SystemChar>.stride
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

#if compiler(>=5.5) && canImport(_Concurrency)
extension _SystemChar: Sendable {}
extension _SystemString: Sendable {}
#endif

// TODO: _SystemString should use a COW-interchangable storage form rather
// than array, so you could "borrow" the storage from a non-bridged String
// or Data or whatever
