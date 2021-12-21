/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Platform string

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
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
  @_alwaysEmitIntoClient
  public func withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    // For backwards deployment, call withCString if available.
    #if !os(Windows)
    return try withCString(body)
    #else
    return try _withPlatformString(body)
    #endif
  }
}

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Component {
  /// Creates a file path component by copying bytes from a null-terminated
  /// platform string.
  ///
  /// Returns `nil` if `platformString` is empty, is a root, or has more than
  /// one component in it.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform
  ///   string.
  ///
  public init?(platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(_platformString: platformString)
  }

  /// Calls the given closure with a pointer to the contents of the file path
  /// component, represented as a null-terminated platform string.
  ///
  /// If this is not the last component of a path, an allocation will occur in
  /// order to add the null terminator.
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

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Root {
  /// Creates a file path root by copying bytes from a null-terminated platform
  /// string.
  ///
  /// Returns `nil` if `platformString` is empty or is not a root.
  ///
  /// - Parameter platformString: A pointer to a null-terminated platform
  ///   string.
  ///
  public init?(platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(_platformString: platformString)
  }

  /// Calls the given closure with a pointer to the contents of the file path
  /// root, represented as a null-terminated platform string.
  ///
  /// If the path has a relative portion, an allocation will occur in order to
  /// add the null terminator.
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

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
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

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Component: ExpressibleByStringLiteral {
  /// Create a file path component from a string literal.
  ///
  /// Precondition: `stringLiteral` is non-empty, is not a root,
  /// and has only one component in it.
  public init(stringLiteral: String) {
    guard let s = FilePath.Component(stringLiteral) else {
      // TODO: static assert
      preconditionFailure("""
        FilePath.Component must be created from exactly one non-root component
        """)
    }
    self = s
  }

  /// Create a file path component from a string.
  ///
  /// Returns `nil` if `string` is empty, a root, or has more than one component
  /// in it.
  public init?(_ string: String) {
    self.init(SystemString(string))
  }
}

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Root: ExpressibleByStringLiteral {
  /// Create a file path root from a string literal.
  ///
  /// Precondition: `stringLiteral` is non-empty and is a root.
  public init(stringLiteral: String) {
    guard let s = FilePath.Root(stringLiteral) else {
      // TODO: static assert
      preconditionFailure("""
        FilePath.Root must be created from a root
        """)
    }
    self = s
  }

  /// Create a file path root from a string.
  ///
  /// Returns `nil` if `string` is empty or is not a root.
  public init?(_ string: String) {
    self.init(SystemString(string))
  }
}

// MARK: - Printing and dumping

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
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

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Component: CustomStringConvertible, CustomDebugStringConvertible {

  /// A textual representation of the path component.
  ///
  /// If the content of the path component isn't a well-formed Unicode string,
  /// this replaces invalid bytes with U+FFFD. See `String.init(decoding:)`.
  @inline(never)
  public var description: String { String(decoding: self) }

  /// A textual representation of the path component, suitable for debugging.
  ///
  /// If the content of the path component isn't a well-formed Unicode string,
  /// this replaces invalid bytes with U+FFFD. See `String.init(decoding:)`.
  public var debugDescription: String { description.debugDescription }
}

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Root: CustomStringConvertible, CustomDebugStringConvertible {

  /// A textual representation of the path root.
  ///
  /// If the content of the path root isn't a well-formed Unicode string,
  /// this replaces invalid bytes with U+FFFD. See `String.init(decoding:)`.
  @inline(never)
  public var description: String { String(decoding: self) }

  /// A textual representation of the path root, suitable for debugging.
  ///
  /// If the content of the path root isn't a well-formed Unicode string,
  /// this replaces invalid bytes with U+FFFD. See `String.init(decoding:)`.
  public var debugDescription: String { description.debugDescription }
}

// MARK: - Convenience helpers

// Convenience helpers
/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath {
  /// Creates a string by interpreting the path’s content as UTF-8 on Unix
  /// and UTF-16 on Windows.
  ///
  /// This property is equivalent to calling `String(decoding: path)`
  public var string: String {
    String(decoding: self)
  }
}

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Component {
  /// Creates a string by interpreting the component’s content as UTF-8 on Unix
  /// and UTF-16 on Windows.
  ///
  /// This property is equivalent to calling `String(decoding: component)`.
  public var string: String {
    String(decoding: self)
  }
}

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension FilePath.Root {
  /// On Unix, this returns `"/"`.
  ///
  /// On Windows, interprets the root's content as UTF-16 on Windows.
  ///
  /// This property is equivalent to calling `String(decoding: root)`.
  public var string: String {
    String(decoding: self)
  }
}

// MARK: - Decoding and validating

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
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

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension String {
  /// Creates a string by interpreting the path component's content as UTF-8 on
  /// Unix and UTF-16 on Windows.
  ///
  /// - Parameter component: The path component to be interpreted as
  ///   `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the content of the path component isn't a well-formed Unicode string,
  /// this initializer replaces invalid bytes with U+FFFD.
  /// This means that, depending on the semantics of the specific file system,
  /// conversion to a string and back to a path component
  /// might result in a value that's different from the original path component.
  public init(decoding component: FilePath.Component) {
    self.init(_decoding: component)
  }

  /// Creates a string from a path component, validating its contents as UTF-8
  /// on Unix and UTF-16 on Windows.
  ///
  /// - Parameter component: The path component to be interpreted as
  ///   `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the contents of the path component isn't a well-formed Unicode string,
  /// this initializer returns `nil`.
  public init?(validating component: FilePath.Component) {
    self.init(_validating: component)
  }
}

/*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
extension String {
  /// On Unix, creates the string `"/"`
  ///
  /// On Windows, creates a string by interpreting the path root's content as
  /// UTF-16.
  ///
  /// - Parameter root: The path root to be interpreted as
  ///   `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the content of the path root isn't a well-formed Unicode string,
  /// this initializer replaces invalid bytes with U+FFFD.
  /// This means that on Windows,
  /// conversion to a string and back to a path root
  /// might result in a value that's different from the original path root.
  public init(decoding root: FilePath.Root) {
    self.init(_decoding: root)
  }

  /// On Unix, creates the string `"/"`
  ///
  /// On Windows, creates a string from a path root, validating its contents as
  /// UTF-16 on Windows.
  ///
  /// - Parameter root: The path root to be interpreted as
  ///   `CInterop.PlatformUnicodeEncoding`.
  ///
  /// On Windows, if the contents of the path root isn't a well-formed Unicode
  /// string, this initializer returns `nil`.
  public init?(validating root: FilePath.Root) {
    self.init(_validating: root)
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

// MARK: - Deprecations

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
extension String {
  @available(*, deprecated, renamed: "init(decoding:)")
  public init(_ path: FilePath) { self.init(decoding: path) }

  @available(*, deprecated, renamed: "init(validating:)")
  public init?(validatingUTF8 path: FilePath) { self.init(validating: path) }
}

#if !os(Windows)
/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
extension FilePath {
  /// For backwards compatibility only. This initializer is equivalent to
  /// the preferred `FilePath(platformString:)`.
  public init(cString: UnsafePointer<CChar>) {
    self.init(platformString: cString)
  }

  /// For backwards compatibility only. This function is equivalent to
  /// the preferred `withPlatformString`.
  public func withCString<Result>(
    _ body: (UnsafePointer<CChar>) throws -> Result
  ) rethrows -> Result {
    return try _withPlatformString(body)
  }
}
#endif
