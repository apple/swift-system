/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Platform string

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  /// Creates a file path by copying bytes from a null-terminated platform
  /// string.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform
  ///   string.
  public init(platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(_platformString: platformString)
  }

  /// Calls the given closure with a pointer to the contents of the file path,
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
  public func withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    try _withPlatformString(body)
  }
}

// MARK: - String literals

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath: ExpressibleByStringLiteral {
  /// Creates a file path from a string literal.
  ///
  /// - Parameter stringLiteral: A string literal
  ///   whose Unicode encoded contents to use as the contents of the path.
  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  /// Creates a file path from a string.
  ///
  /// - Parameter string: A string
  ///   whose Unicode encoded contents to use as the contents of the path.
  public init(_ string: String) {
    self.init(SystemString(string))
  }
}

// MARK: - Printing and dumping

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath: CustomStringConvertible, CustomDebugStringConvertible {
  /// A textual representation of the file path.
  ///
  /// If the content of the path isn't a well-formed Unicode string,
  /// this replaces invalid bytes with U+FFFD. See `String.init(decoding:)`
  @inline(never)
  public var description: String { String(decoding: self) }

  /// A textual representation of the file path, suitable for debugging.
  ///
  /// If the content of the path isn't a well-formed Unicode string,
  /// this replaces invalid bytes with U+FFFD. See `String.init(decoding:)`
  public var debugDescription: String { description.debugDescription }
}

// MARK: - Convenience helpers

// Convenience helpers
extension FilePath {
  /// Creates a string by interpreting the path’s content as UTF-8 on Unix
  /// and UTF-16 on Windows.
  ///
  /// This property is equivalent to calling `String(decoding: path)`
  public var string: String {
    String(decoding: self)
  }
}

// MARK: - Decoding and validating

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension String {
  /// Creates a string by interpreting the file path's content as UTF-8 on Unix
  /// and UTF-16 on Windows.
  ///
  /// - Parameter path: The file path to be interpreted as
  /// `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the content of the file path isn't a well-formed Unicode string,
  /// this initializer replaces invalid bytes with U+FFFD.
  /// This means that, depending on the semantics of the specific file system,
  /// conversion to a string and back to a path
  /// might result in a value that's different from the original path.
  public init(decoding path: FilePath) {
    self.init(_decoding: path)
  }

  /// Creates a string from a file path, validating its contents as UTF-8 on
  /// Unix and UTF-16 on Windows.
  ///
  /// - Parameter path: The file path to be interpreted as
  ///   `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the contents of the file path isn't a well-formed Unicode string,
  /// this initializer returns `nil`.
  public init?(validating path: FilePath) {
    self.init(_validating: path)
  }
}

// MARK: - Internal helpers

extension String {
  fileprivate init<PS: _PlatformStringable>(_decoding ps: PS) {
    self = ps._withPlatformString { String(platformString: $0) }
  }

  fileprivate init?<PS: _PlatformStringable>(_validating ps: PS) {
    guard let str = ps._withPlatformString(
      String.init(validatingPlatformString:)
    ) else {
      return nil
    }
    self = str
  }
}

extension FilePath: _PlatformStringable {
   func _withPlatformString<Result>(_ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result) rethrows -> Result {
     try _storage.withPlatformString(body)
   }

   init(_platformString: UnsafePointer<CInterop.PlatformChar>) {
     self.init(SystemString(platformString: _platformString))
   }

 }

// MARK: - Deprecations

extension String {
  @available(*, deprecated, renamed: "init(decoding:)")
  public init(_ path: FilePath) { self.init(decoding: path) }

  @available(*, deprecated, renamed: "init(validating:)")
  public init?(validatingUTF8 path: FilePath) { self.init(validating: path) }
}

extension FilePath {
  @available(*, deprecated, renamed: "init(platformString:)")
  public init(cString: UnsafePointer<CChar>) {
    #if os(Windows)
    fatalError("FilePath.init(cString:) unsupported on Windows ")
    #else
    self.init(platformString: cString)
    #endif
  }

  @available(*, deprecated, renamed: "withPlatformString(_:)")
  public func withCString<Result>(
    _ body: (UnsafePointer<CChar>) throws -> Result
  ) rethrows -> Result {
    #if os(Windows)
    fatalError("FilePath.withCString() unsupported on Windows ")
    #else
    return try withPlatformString(body)
    #endif
  }
}
