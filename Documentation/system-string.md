# SystemString for OS-native string representations

* Authors: [Michael Ilseman](https://github.com/milseman)
* Implementation: PR (**TODO**)

## Introduction

We introduce `SystemString`, which supports OS-native string operations. `SystemString` is a bag-of-bytes type without a prescribed encoding. It is a collection `SystemChar`s, which is `UInt8` on Unix platforms and `UInt16` on Windows platforms.


## Motivation

`SystemString` is the backing storage representation for `FilePath`. `FilePath` normalizes its contents (e.g. `a//b -> a/b`), and so it is insufficient as a OS-preferred bag-of-bytes string representation.

**TODO**: It would be nice to ship with a few syscalls that make use of it.

**TODO**: A little more motivation on `SystemChar`. Also, let's make sure we have clarity on layout equivalence and demonstrate how to get from a null-`SystemChar`-termianted `UBP<SystemChar>` to null-terminated `UBP<UIntX>`.

## Proposed solution

**TODO**: Brief highlights


## Detailed design

`SystemChar` is a raw wrapper around `CChar` on Linux and Darwin, and a `UInt16`on Windows. It is layout compatible with those types and exposes convenience interfaces for getting common values.

```swift
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
  public init(rawValue: RawValue)

  @_alwaysEmitIntoClient
  public init(_ rawValue: RawValue)

  @inlinable
  public static func < (lhs: SystemChar, rhs: SystemChar) -> Bool
}

extension SystemChar {
  /// Create a SystemChar from an ASCII scalar.
  @_alwaysEmitIntoClient
  public init(ascii: Unicode.Scalar)

  /// Cast `x` to a `SystemChar`
  @_alwaysEmitIntoClient
  public init(_ x: some FixedWidthInteger)

  /// The NULL character `\0`
  @_alwaysEmitIntoClient
  public static var null: SystemChar { get }

  /// The slash character `/`
  @_alwaysEmitIntoClient
  public static var slash: SystemChar { get }

  /// The backslash character `\`
  @_alwaysEmitIntoClient
  public static var backslash: SystemChar { get }

  /// The dot character `.`
  @_alwaysEmitIntoClient
  public static var dot: SystemChar { get }

  /// The colon character `:`
  @_alwaysEmitIntoClient
  public static var colon: SystemChar { get }

  /// The question mark character `?`
  @_alwaysEmitIntoClient
  public static var question: SystemChar { get }

  /// Returns `self` as a `Unicode.Scalar` if ASCII, else `nil`
  @_alwaysEmitIntoClient
  public var asciiScalar: Unicode.Scalar? { get }

  /// Whether `self` is ASCII
  @_alwaysEmitIntoClient
  public var isASCII: Bool { get }

  /// Whether `self` is an ASCII letter, i.e. in `[a-zA-Z]`
  @_alwaysEmitIntoClient
  public var isASCIILetter: Bool { get }
}
```

`SystemString` is a `RangeReplaceableCollection` of `SystemChar`s and ensures that it is always `NULL`-terminated. The `NULL` is not considered part of the count and the string must not contain `NULL`s inside of it.

```swift

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
  public var nullTerminatedStorage: Storage { get }
}

extension SystemString {
  /// Create an empty `SystemString`
  public init()

  /// Create a `SystemString` from a collection of `SystemChar`s.
  /// A NULL terminator will be added if `chars` lacks one. `chars` must not
  /// include any interior NULLs.
  @_alwaysEmitIntoClient
  public init<C: Collection>(_ chars: C) where C.Element == SystemChar 
}

extension SystemString: RandomAccessCollection, MutableCollection {
  public typealias Element = SystemChar
  public typealias Index = Int
  public typealias Indices = Range<Index>

  @inlinable
  public var startIndex: Index { get }

  @inlinable
  public var endIndex: Index { get }

  @inlinable
  public subscript(position: Index) -> SystemChar {
    _read, set
  }
}
extension SystemString: RangeReplaceableCollection {
  @inlinable
  public mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where C.Element == SystemChar

  @inlinable
  public mutating func reserveCapacity(_ n: Int)

  @inlinable
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<SystemChar>) throws -> R
  ) rethrows -> R?
}

extension SystemString: Hashable, Codable {}

extension SystemString: ExpressibleByStringLiteral {
  public init(stringLiteral: String)

  public init(_ string: String)
}

extension SystemString: CustomStringConvertible, CustomDebugStringConvertible {

  public var description: String { get }

  public var debugDescription: String { get }
}

extension SystemString {
  /// Creates a `SystemString` by copying bytes from a null-terminated platform string.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform string.
  public init(platformString: UnsafePointer<CInterop.PlatformChar>)

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
  ) rethrows -> T
}

```

You can create `String`s from `SystemString`, either decoding them (i.e. performing Unicode error correction on the contents) or validating them (i.e. returning `nil` if invalidly-encoded Unicode content).

```swift

extension String {
  /// Creates a string by interpreting `str`'s content as UTF-8 on Unix
  /// and UTF-16 on Windows.
  ///
  /// - Parameter str: The system string to be interpreted as
  /// `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the content of the system string isn't a well-formed Unicode string,
  /// this initializer replaces invalid bytes with U+FFFD.
  /// This means that conversion to a string and back to a system string
  /// might result in a value that's different from the original system string.
  public init(decoding str: SystemString)

  /// Creates a string from a system string, validating its contents as UTF-8 on
  /// Unix and UTF-16 on Windows.
  ///
  /// - Parameter str: The system string to be interpreted as
  ///   `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the contents of the system string isn't well-formed Unicode,
  /// this initializer returns `nil`.
  public init?(validating str: SystemString)
}


```

You can create a `FilePath`, `FilePath.Root`, and `FilePath.Component` from a `SystemString`.

```swift
extension FilePath {
  /// Create a `FilePath` with the contents of `str`, normalizing separators.
  public init(_ str: SystemString)
}

extension FilePath.Component {
  /// Create a `FilePath.Component` with the contents of `str`.
  ///
  /// Returns `nil` if `str` is empty or contains the directory separator.
  public init?(_ str: SystemString)
}

extension FilePath.Root {
  /// Create a `FilePath.Root` with the contents of `str`.
  ///
  /// Returns `nil` if `str` is empty or is not a root
  public init?(_ str: SystemString)
}

```

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.


## Alternatives considered

**TODO**: Consider not having `SystemChar`

**TODO**: Consider separate `SystemByteString` and `SystemBytePairString` types.

**TODO**: Why we don't want to have a single-byte ASCII representation on Windows and have syscall wrapper adjust/dispatch appropriately.


## Future directions

**TODO**: Map out some future syscalls that this would (partially) unblock

## Acknowledgments

**TODO**


