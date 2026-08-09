/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

// MARK: - _StdlibFilePath String bridging

@available(SwiftStdlib 9999, *)
extension _StdlibFilePath: Hashable {
  @available(SwiftStdlib 9999, *)
  public static func == (lhs: _StdlibFilePath, rhs: _StdlibFilePath) -> Bool {
    lhs._storage == rhs._storage
  }

  @available(SwiftStdlib 9999, *)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_storage)
  }
}

@available(SwiftStdlib 9999, *)
extension _StdlibFilePath: Comparable {
  @available(SwiftStdlib 9999, *)
  public static func < (lhs: _StdlibFilePath, rhs: _StdlibFilePath) -> Bool {
    lhs._storage.lexicographicallyPrecedes(rhs._storage)
  }
}

@available(SwiftStdlib 9999, *)
extension _StdlibFilePath: CustomStringConvertible, CustomDebugStringConvertible {
  /// A textual representation of the file path.
  @available(SwiftStdlib 9999, *)
  public var description: String {
    unsafe _storage.withCodeUnits { codeUnits in
      unsafe codeUnits.withMemoryRebound(to: _StdlibFilePath._Encoding.CodeUnit.self) {
        unsafe String(decoding: $0, as: _StdlibFilePath._Encoding.self)
      }
    }
  }

  @available(SwiftStdlib 9999, *)
  public var debugDescription: String {
    description.debugDescription
  }
}

@available(SwiftStdlib 9999, *)
extension _StdlibFilePath: ExpressibleByStringLiteral {
  /// Creates a file path from a string literal.
  ///
  /// Traps if the literal contains `NUL` or is otherwise ill-formed.
  @available(SwiftStdlib 9999, *)
  public init(stringLiteral: String) {
    guard let path = _StdlibFilePath(_nulValidating: stringLiteral) else {
      fatalError(
        "_StdlibFilePath string literal must not contain NUL")
    }
    self = path
  }

#if !FILEPATH_SYSTEM_STRING_COMPAT
  /// Creates a file path from a string.
  ///
  /// Returns `nil` if `string` contains `NUL`, which is not a valid
  /// path byte on any supported platform.
  @available(SwiftStdlib 9999, *)
  public init?(_ string: String) {
    self.init(_nulValidating: string)
  }
#endif

  /// NUL-validating construction from a `String`, shared by the failable
  /// initializer and the `ExpressibleByStringLiteral` conformance. Always
  /// present: when a consumer defines `FILEPATH_SYSTEM_STRING_COMPAT` and
  /// replaces the public failable `init?(_:)` with a non-failable `init(_:)`,
  /// the internal callers below still have a validating entry point.
  @available(SwiftStdlib 9999, *)
  internal init?(_nulValidating string: String) {
    guard !string.utf8.contains(0) else { return nil }
    self.init(_normalizing: _SystemString(string))
  }
}

// MARK: - String decoding/validating

extension String {
  @available(SwiftStdlib 9999, *)
  public init(decoding path: _StdlibFilePath) {
    self = path.description
  }

  @available(SwiftStdlib 9999, *)
  public init?(validating path: _StdlibFilePath) {
    guard let str = String(validating: path._storage) else { return nil }
    self = str
  }

  @available(SwiftStdlib 9999, *)
  public init(decoding anchor: _StdlibFilePath.Anchor) {
    self = anchor.description
  }

  @available(SwiftStdlib 9999, *)
  public init?(validating anchor: _StdlibFilePath.Anchor) {
    // Mirror the _StdlibFilePath overload: decode, re-encode, and compare (via
    // String(validating: _SystemString)), so ill-formed content yields nil
    // instead of a lossy U+FFFD decode.
    guard let str = String(validating: _SystemString(anchor._slice)) else {
      return nil
    }
    self = str
  }

  @available(SwiftStdlib 9999, *)
  public init(decoding component: _StdlibFilePath.Component) {
    self = component.description
  }

  @available(SwiftStdlib 9999, *)
  public init?(validating component: _StdlibFilePath.Component) {
    // Mirror the _StdlibFilePath overload: decode, re-encode, and compare (via
    // String(validating: _SystemString)), so ill-formed content yields nil
    // instead of a lossy U+FFFD decode.
    guard let str = String(validating: _SystemString(component._slice)) else {
      return nil
    }
    self = str
  }
}

