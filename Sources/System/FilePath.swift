/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension UnsafePointer where Pointee == UInt8 {
  internal var _asCChar: UnsafePointer<CChar> {
    UnsafeRawPointer(self).assumingMemoryBound(to: CChar.self)
  }
}
extension UnsafePointer where Pointee == CChar {
  internal var _asUInt8: UnsafePointer<UInt8> {
    UnsafeRawPointer(self).assumingMemoryBound(to: UInt8.self)
  }
}
extension UnsafeBufferPointer where Element == UInt8 {
  internal var _asCChar: UnsafeBufferPointer<CChar> {
    let base = baseAddress?._asCChar
    return UnsafeBufferPointer<CChar>(start: base, count: self.count)
  }
}
extension UnsafeBufferPointer where Element == CChar {
  internal var _asUInt8: UnsafeBufferPointer<UInt8> {
    let base = baseAddress?._asUInt8
    return UnsafeBufferPointer<UInt8>(start: base, count: self.count)
  }
}

// NOTE: FilePath not frozen for ABI flexibility

/// A null-terminated sequence of bytes
/// that represents a location in the file system.
///
/// This structure doesn't give any meaning to the bytes that it contains,
/// except for the requirement that the last byte is a NUL (`0x0`).
/// The file system defines how this string is interpreted;
/// for example, by its choice of string encoding.
///
/// The code below creates a file path from a string literal,
/// and then uses it to open and append to a log file:
///
///     let message: String = "This is a log message."
///     let path: FilePath = "/tmp/log"
///     let fd = try FileDescriptor.open(path, .writeOnly, options: .append)
///     try fd.closeAfter { try fd.writeAll(message.utf8) }
///
/// File paths conform to the
/// and <doc://com.apple.documentation/documentation/swift/equatable>
/// and <doc://com.apple.documentation/documentation/swift/hashable> protocols
/// by performing the protocols' operations on their raw byte contents.
/// This conformance allows file paths to be used,
/// for example, as keys in a dictionary.
/// However, the rules for path equivalence
/// are file-system–specific and have additional considerations
/// like case insensitivity, Unicode normalization, and symbolic links.
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public struct FilePath {
  internal typealias Storage = [CChar]
  internal var bytes: Storage

  /// Creates an empty, null-terminated path.
  public init() {
    self.bytes = [0]
    _invariantCheck()
  }
}

//
// MARK: - Public Interfaces
//
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  /// The length of the file path, excluding the null termination.
  public var length: Int { bytes.count - 1 }
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  internal init<C: Collection>(nullTerminatedBytes: C) where C.Element == CChar {
    self.bytes = Array(nullTerminatedBytes)
    _invariantCheck()
  }

  internal init<C: Collection>(byteContents bytes: C) where C.Element == CChar {
    var nulTermBytes = Array(bytes)
    nulTermBytes.append(0)
    self.init(nullTerminatedBytes: nulTermBytes)
  }
}

@_implementationOnly import SystemInternals

//
// MARK: - CString interfaces
//
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  /// Creates a file path by copying bytes from a null-terminated C string.
  ///
  /// - Parameter cString: A pointer to a null-terminated C string.
  public init(cString: UnsafePointer<CChar>) {
    self.init(nullTerminatedBytes:
      UnsafeBufferPointer(start: cString, count: 1 + system_strlen(cString)))
  }

  /// Calls the given closure with a pointer to the contents of the file path,
  /// represented as a null-terminated C string.
  ///
  /// - Parameter body: A closure with a pointer parameter
  ///   that points to a null-terminated C string.
  ///   If `body` has a return value,
  ///   that value is also used as the return value for this method.
  /// - Returns: The return value, if any, of the `body` closure parameter.
  ///
  /// The pointer passed as an argument to `body` is valid
  /// only during the execution of this method.
  /// Don't try to store the pointer for later use.
  public func withCString<Result>(
    _ body: (UnsafePointer<Int8>) throws -> Result
  ) rethrows -> Result {
    try bytes.withUnsafeBufferPointer { try body($0.baseAddress!) }
  }

  // TODO: in the future, with opaque result types with associated
  // type constraints, we want to provide a RAC for terminated
  // byte contents and unterminated byte contents.
}

//
// MARK: - String interfaces
//
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath: ExpressibleByStringLiteral {
  /// Creates a file path from a string literal.
  ///
  /// - Parameter stringLiteral: A string literal
  ///   whose UTF-8 contents to use as the contents of the path.
  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  /// Creates a file path from a string.
  ///
  /// - Parameter string: A string
  ///   whose UTF-8 contents to use as the contents of the path.
  public init(_ string: String) {
    var str = string
    self = str.withUTF8 { FilePath(byteContents: $0._asCChar) }
  }
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension String {
  /// Creates a string by interpreting the file path's content as UTF-8.
  ///
  /// - Parameter path: The file path to be interpreted as UTF-8.
  ///
  /// If the content of the file path
  /// isn't a well-formed UTF-8 string,
  /// this initializer removes invalid bytes or replaces them with U+FFFD.
  /// This means that, depending on the semantics of the specific file system,
  /// conversion to a string and back to a path
  /// might result in a value that's different from the original path.
  public init(decoding path: FilePath) {
    self = path.withCString { String(cString: $0) }
  }

  @available(*, deprecated, renamed: "String.init(decoding:)")
  public init(_ path: FilePath) {
    self.init(decoding: path)
  }

  /// Creates a string from a file path, validating its UTF-8 contents.
  ///
  /// - Parameter path: The file path be interpreted as UTF-8.
  ///
  /// If the contents of the file path
  /// isn't a well-formed UTF-8 string,
  /// this initializer returns `nil`.
  public init?(validatingUTF8 path: FilePath) {
    guard let str = path.withCString({ String(validatingUTF8: $0) }) else {
      return nil
    }
    self = str
  }

  // TODO: Consider a init?(validating:), keeping the encoding agnostic in API and
  // dependent on file system.
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath: CustomStringConvertible, CustomDebugStringConvertible {
  /// A textual representation of the file path.
  @inline(never)
  public var description: String { String(decoding: self) }

  /// A textual representation of the file path, suitable for debugging.
  public var debugDescription: String { self.description.debugDescription }
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath: Hashable, Codable {}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  fileprivate func _invariantCheck() {
    precondition(bytes.last! == 0)
    // TODO: Should this be a hard trap?
    _debugPrecondition(bytes.firstIndex(of: 0) == bytes.count - 1)
  }
}
