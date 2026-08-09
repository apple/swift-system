/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - String and platform-string interop
//
// Signatures here are the ABI contract. They are fixed at compile time and do
// not vary with the backing: a client links against one set of symbols whether
// or not the opt-in is set. Only the bodies dispatch.

// MARK: - Construction from a String

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Creates a file path from a string.
  ///
  /// Non-failable, because that is the signature swift-system ships. The
  /// signature cannot depend on the backing even though the two eras disagree
  /// about what an embedded NUL means:
  ///
  ///   .stdlib       NUL is not a valid path byte, so this traps. SE-0529
  ///                 exposes a failable `init?` for callers that want to
  ///                 handle it, but that is a different signature and not this
  ///                 one.
  ///   .swiftSystem  truncates at the first NUL, as swift-system always did.
  ///
  /// A string literal does not reach this initializer: `FilePath("...")`
  /// coerces to `init(stringLiteral:)` under SE-0213, so literals keep working
  /// exactly as before.
  public init(_ string: String) {
    self = FilePath._make(
      stdlib: {
        guard let p = _StdlibFilePath(string) else {
          preconditionFailure(
            """
            FilePath(_: String): the string contains NUL, which is not a valid \
            path byte. Use the failable initializer to handle this case.
            """)
        }
        return p
      },
      swiftSystem: { _SwiftSystemFilePath(string) })
  }

  /// This path rendered as a string, repairing any invalid code unit sequences.
  public var string: String {
    switch _backing {
    case .stdlib(let p): return p.string
    case .swiftSystem(let p): return p.string
    }
  }
}

// MARK: - ExpressibleByStringLiteral

@available(SwiftStdlib 9999, *)
extension FilePath: ExpressibleByStringLiteral {
  /// Creates a file path from a string literal.
  public init(stringLiteral: String) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(stringLiteral: stringLiteral) },
      swiftSystem: { _SwiftSystemFilePath(stringLiteral: stringLiteral) })
  }
}

// MARK: - Platform string

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Creates a file path by copying bytes from a null-terminated platform
  /// string.
  public init(platformString: UnsafePointer<CInterop.PlatformChar>) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(platformString: platformString) },
      swiftSystem: { _SwiftSystemFilePath(platformString: platformString) })
  }

  /// Creates a file path by copying bytes from a null-terminated platform
  /// string.
  public init(platformString: [CInterop.PlatformChar]) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(platformString: platformString) },
      swiftSystem: { _SwiftSystemFilePath(platformString: platformString) })
  }

  @available(*, deprecated, message: "Use FilePath.init(_ scalar: Unicode.Scalar)")
  public init(platformString: inout CInterop.PlatformChar) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(platformString: &platformString) },
      swiftSystem: { _SwiftSystemFilePath(platformString: &platformString) })
  }

  @available(*, deprecated, message: "Use FilePath(_: String) to create a path from a String")
  public init(platformString: String) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(platformString: platformString) },
      swiftSystem: { _SwiftSystemFilePath(platformString: platformString) })
  }

  /// Calls `body` with a pointer to this path's null-terminated platform-string
  /// contents.
  public func withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    switch _backing {
    case .stdlib(let p): return try p.withPlatformString(body)
    case .swiftSystem(let p): return try p.withPlatformString(body)
    }
  }
}

// MARK: - C string (deprecated spellings)

@available(SwiftStdlib 9999, *)
extension FilePath {
  @available(*, deprecated, renamed: "init(platformString:)")
  public init(cString: UnsafePointer<CChar>) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(cString: cString) },
      swiftSystem: { _SwiftSystemFilePath(cString: cString) })
  }

  @available(*, deprecated, renamed: "init(platformString:)")
  public init(cString: [CChar]) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(cString: cString) },
      swiftSystem: { _SwiftSystemFilePath(cString: cString) })
  }

  @available(*, deprecated, renamed: "init(platformString:)")
  public init(cString: inout CChar) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(cString: &cString) },
      swiftSystem: { _SwiftSystemFilePath(cString: &cString) })
  }

  @available(*, deprecated, renamed: "init(platformString:)")
  public init(cString: String) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(cString: cString) },
      swiftSystem: { _SwiftSystemFilePath(cString: cString) })
  }

  @available(*, deprecated, renamed: "withPlatformString")
  public func withCString<Result>(
    _ body: (UnsafePointer<CChar>) throws -> Result
  ) rethrows -> Result {
    switch _backing {
    case .stdlib(let p): return try p.withCString(body)
    case .swiftSystem(let p): return try p.withCString(body)
    }
  }
}

// MARK: - _PlatformStringable

// Lets the substrate's generic platform-string helpers accept the wrapper the
// same way they accept either backing.
@available(SwiftStdlib 9999, *)
extension FilePath: _PlatformStringable {
  internal func _withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    try withPlatformString(body)
  }

  internal init(_platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(platformString: _platformString)
  }
}

// MARK: - String from a path

@available(SwiftStdlib 9999, *)
extension String {
  /// Creates a string by decoding this path's content, repairing any invalid
  /// code unit sequences.
  public init(decoding path: FilePath) {
    switch path._backing {
    case .stdlib(let p): self.init(decoding: p)
    case .swiftSystem(let p): self.init(decoding: p)
    }
  }

  /// Creates a string from this path, or `nil` if its content is not valid in
  /// the platform's encoding.
  public init?(validating path: FilePath) {
    switch path._backing {
    case .stdlib(let p):
      guard let s = String(validating: p) else { return nil }
      self = s
    case .swiftSystem(let p):
      guard let s = String(validating: p) else { return nil }
      self = s
    }
  }

  @available(*, deprecated, renamed: "init(decoding:)")
  public init(_ path: FilePath) { self.init(decoding: path) }

  @available(*, deprecated, renamed: "init(validating:)")
  public init?(validatingUTF8 path: FilePath) { self.init(validating: path) }
}
