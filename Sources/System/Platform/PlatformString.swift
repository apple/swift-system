/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension CInterop {
  #if os(Windows)
  /// The platform's preferred character type. On Unix, this is an 8-bit C
  /// `char` (which may be signed or unsigned, depending on platform). On
  /// Windows, this is `UInt16` (a "wide" character).
  public typealias PlatformChar = UInt16
  #else
  /// The platform's preferred character type. On Unix, this is an 8-bit C
  /// `char` (which may be signed or unsigned, depending on platform). On
  /// Windows, this is `UInt16` (a "wide" character).
  public typealias PlatformChar = CInterop.Char
  #endif

  #if os(Windows)
  /// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
  /// Windows it is UTF-16. Native strings may contain invalid Unicode,
  /// which will be handled by either error-correction or failing, depending
  /// on API.
  public typealias PlatformUnicodeEncoding = UTF16
  #else
  /// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
  /// Windows it is UTF-16. Native strings may contain invalid Unicode,
  /// which will be handled by either error-correction or failing, depending
  /// on API.
  public typealias PlatformUnicodeEncoding = UTF8
  #endif
}

extension CInterop.PlatformChar {
  internal var _platformCodeUnit: CInterop.PlatformUnicodeEncoding.CodeUnit {
    #if os(Windows)
    return self
    #else
    return CInterop.PlatformUnicodeEncoding.CodeUnit(bitPattern: self)
    #endif
  }
}
extension CInterop.PlatformUnicodeEncoding.CodeUnit {
  internal var _platformChar: CInterop.PlatformChar {
    #if os(Windows)
    return self
    #else
    return CInterop.PlatformChar(bitPattern: self)
    #endif
  }
}

extension String {
  /// Creates a string by interpreting the null-terminated platform string as
  /// UTF-8 on Unix and UTF-16 on Windows.
  ///
  /// - Parameter platformString: The null-terminated platform string to be
  ///  interpreted as `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the content of the platform string isn't well-formed Unicode,
  /// this initializer replaces invalid bytes with U+FFFD.
  /// This means that, depending on the semantics of the specific platform,
  /// conversion to a string and back might result in a value that's different
  /// from the original platform string.
  public init(platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(_errorCorrectingPlatformString: platformString)
  }

  /// Creates a string by interpreting the null-terminated platform string as
  /// UTF-8 on Unix and UTF-16 on Windows.
  ///
  /// - Parameter platformString: The null-terminated platform string to be
  ///  interpreted as `CInterop.PlatformUnicodeEncoding`.
  ///
  /// If the contents of the platform string isn't well-formed Unicode,
  /// this initializer returns `nil`.
  public init?(
    validatingPlatformString platformString: UnsafePointer<CInterop.PlatformChar>
  ) {
    self.init(_platformString: platformString)
  }

  /// Calls the given closure with a pointer to the contents of the string,
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

internal protocol _PlatformStringable {
  func _withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result

  init?(_platformString: UnsafePointer<CInterop.PlatformChar>)
}
extension String: _PlatformStringable {}
