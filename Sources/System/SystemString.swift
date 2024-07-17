/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// A platform-native character representation, currently used for file paths
internal struct SystemChar:
  RawRepresentable, Sendable, Comparable, Hashable, Codable {
  internal typealias RawValue = CInterop.PlatformChar

  internal var rawValue: RawValue

  internal init(rawValue: RawValue) { self.rawValue = rawValue }

  internal init(_ rawValue: RawValue) { self.init(rawValue: rawValue) }

  static func < (lhs: SystemChar, rhs: SystemChar) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension SystemChar {
  internal init(ascii: Unicode.Scalar) {
    self.init(rawValue: numericCast(UInt8(ascii: ascii)))
  }
  internal init(codeUnit: CInterop.PlatformUnicodeEncoding.CodeUnit) {
    self.init(rawValue: codeUnit._platformChar)
  }

  internal static var null: SystemChar { SystemChar(0x0) }
  internal static var slash: SystemChar { SystemChar(ascii: "/") }
  internal static var backslash: SystemChar { SystemChar(ascii: #"\"#) }
  internal static var dot: SystemChar { SystemChar(ascii: ".") }
  internal static var colon: SystemChar { SystemChar(ascii: ":") }
  internal static var question: SystemChar { SystemChar(ascii: "?") }

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
internal struct SystemString: Sendable {
  internal typealias Storage = [SystemChar]
  internal var nullTerminatedStorage: Storage
}

extension SystemString {
  internal init() {
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
  internal init<C: Collection>(_ chars: C) where C.Element == SystemChar {
    var rawChars = Storage(chars)
    if rawChars.last != .null {
      rawChars.append(.null)
    }
    self.init(nullTerminated: rawChars)
  }
}

extension SystemString {
  fileprivate func _invariantsSatisfied() -> Bool {
    guard !nullTerminatedStorage.isEmpty else { return false }
    guard nullTerminatedStorage.last! == .null else { return false }
    guard nullTerminatedStorage.firstIndex(of: .null) == length else {
      return false
    }
    return true
  }
  
  fileprivate func _invariantCheck() {
    #if DEBUG
    precondition(_invariantsSatisfied())
    #endif // DEBUG
  }
}

extension SystemString: RandomAccessCollection, MutableCollection {
  internal typealias Element = SystemChar
  internal typealias Index = Storage.Index
  internal typealias Indices = Range<Index>

  internal var startIndex: Index {
    nullTerminatedStorage.startIndex
  }

  internal var endIndex: Index {
    nullTerminatedStorage.index(before: nullTerminatedStorage.endIndex)
  }

  internal subscript(position: Index) -> SystemChar {
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
extension SystemString: RangeReplaceableCollection {
  internal mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where C.Element == SystemChar {
    defer { _invariantCheck() }
    nullTerminatedStorage.replaceSubrange(subrange, with: newElements)
  }

  internal mutating func reserveCapacity(_ n: Int) {
    defer { _invariantCheck() }
    nullTerminatedStorage.reserveCapacity(1 + n)
  }

  internal func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<SystemChar>) throws -> R
  ) rethrows -> R? {
    // Do not include the null terminator, it is outside the Collection
    try nullTerminatedStorage.withContiguousStorageIfAvailable {
      try body(.init(start: $0.baseAddress, count: $0.count-1))
    }
  }

  internal mutating func withContiguousMutableStorageIfAvailable<R>(
    _ body: (inout UnsafeMutableBufferPointer<SystemChar>) throws -> R
  ) rethrows -> R? {
    defer { _invariantCheck() }
    // Do not include the null terminator, it is outside the Collection
    return try nullTerminatedStorage.withContiguousMutableStorageIfAvailable {
      var buffer = UnsafeMutableBufferPointer<SystemChar>(
        start: $0.baseAddress, count: $0.count-1
      )
      return try body(&buffer)
    }
  }
}

extension SystemString: Hashable, Codable {
  // Encoder is synthesized; it probably should have been explicit and used
  // a single-value container, but making that change now is somewhat risky.
  
  // Decoder is written explicitly to ensure that we validate invariants on
  // untrusted input.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.nullTerminatedStorage = try container.decode(
      Storage.self, forKey: .nullTerminatedStorage
    )
    guard _invariantsSatisfied() else {
      throw DecodingError.dataCorruptedError(
        forKey: .nullTerminatedStorage,
        in: container,
        debugDescription:
          "Encoding does not satisfy the invariants of SystemString"
      )
    }
  }
}

extension SystemString {

  internal func withNullTerminatedSystemChars<T>(
    _ f: (UnsafeBufferPointer<SystemChar>) throws -> T
  ) rethrows -> T {
    try nullTerminatedStorage.withUnsafeBufferPointer(f)
  }

  // withCodeUnits does not include the null terminator
  internal func withCodeUnits<T>(
    _ f: (UnsafeBufferPointer<CInterop.PlatformUnicodeEncoding.CodeUnit>) throws -> T
  ) rethrows -> T {
    try withNullTerminatedSystemChars {
      try $0.withMemoryRebound(to: CInterop.PlatformUnicodeEncoding.CodeUnit.self) {
        assert($0.last == .zero)
        return try f(.init(start: $0.baseAddress, count: $0.count&-1))
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
    withCodeUnits {
      String(decoding: $0, as: CInterop.PlatformUnicodeEncoding.self)
    }
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
  internal init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  internal init(_ string: String) {
    // TODO: can avoid extra strlen
    self = string.withPlatformString {
      SystemString(platformString: $0)
    }
  }
}

extension SystemString: CustomStringConvertible, CustomDebugStringConvertible {
  internal var string: String {
    self.withCodeUnits {
      String(decoding: $0, as: CInterop.PlatformUnicodeEncoding.self)
    }
  }

  internal var description: String { string }
  internal var debugDescription: String { description.debugDescription }
}

extension SystemString {
  /// Creates a system string by copying bytes from a null-terminated platform string.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform string.
  internal init(platformString: UnsafePointer<CInterop.PlatformChar>) {
    let count = 1 + system_platform_strlen(platformString)

    // TODO: Is this the right way?
    let chars: Array<SystemChar> = platformString.withMemoryRebound(
      to: SystemChar.self, capacity: count
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
    try withNullTerminatedSystemChars { chars in
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
