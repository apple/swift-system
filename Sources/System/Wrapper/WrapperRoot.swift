/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - FilePath.Root
//
// A thin dispatching wrapper, like `ComponentView` and unlike `Component`.
//
// `Component` can be a stdlib-side typealias with conversion at the boundary
// because a component is a separator-free byte run: every backing agrees such a
// value is well formed, so it is always representable on the other side.
//
// A root is not like that. Root validity is platform-dependent, and the two
// backings do not decide platform-ness the same way. The historical backing
// honors the runtime `withWindowsPaths(enabled:)` mock, while SE-0529's base
// resolves the platform at compile time from `#if os(Windows)`. So on a Unix
// host under a forced-Windows test, the historical backing hands out roots like
// `C:` and `\` that the base cannot parse as roots at all, and a converting
// design has nowhere to put them.
//
// Holding each backing's own root representation removes the conversion, and
// with it the failure. Note also that SE-0529's base has no `Root` of its own,
// only `Anchor`; `_StdlibFilePath.Root` is itself a shim presenting
// swift-system's `Root` over that `Anchor`. So both arms of this wrapper are
// already era-specific presentations, and this type just picks one.
//
// `Root` stays exposed because swift-system's public API has it.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// A path's root, such as `/` on Unix or `C:\` on Windows.
  public struct Root: Sendable {
    @usableFromInline
    internal enum Backing: Sendable {
      case stdlib(_StdlibFilePath.Root)
      case swiftSystem(_SwiftSystemFilePath.Root)
    }

    @usableFromInline
    internal var _backing: Backing

    @usableFromInline
    internal init(_backing: Backing) {
      self._backing = _backing
    }
  }
}

// MARK: - Construction funnel

@available(SwiftStdlib 9999, *)
extension FilePath.Root {
  internal static func _make(
    stdlib: () -> _StdlibFilePath.Root,
    swiftSystem: () -> _SwiftSystemFilePath.Root
  ) -> FilePath.Root {
    _filePathSelect(
      stdlib: { FilePath.Root(_backing: .stdlib(stdlib())) },
      swiftSystem: { FilePath.Root(_backing: .swiftSystem(swiftSystem())) })
  }

  internal static func _makeIfSome(
    stdlib: () -> _StdlibFilePath.Root?,
    swiftSystem: () -> _SwiftSystemFilePath.Root?
  ) -> FilePath.Root? {
    _filePathSelect(
      stdlib: { stdlib().map { FilePath.Root(_backing: .stdlib($0)) } },
      swiftSystem: {
        swiftSystem().map { FilePath.Root(_backing: .swiftSystem($0)) }
      })
  }
}

// MARK: - Backing access

@available(SwiftStdlib 9999, *)
extension FilePath.Root {
  internal var _stdlib: _StdlibFilePath.Root {
    guard case .stdlib(let r) = _backing else {
      _filePathBackingMismatch("FilePath.Root")
    }
    return r
  }

  internal var _swiftSystem: _SwiftSystemFilePath.Root {
    guard case .swiftSystem(let r) = _backing else {
      _filePathBackingMismatch("FilePath.Root")
    }
    return r
  }
}

// MARK: - Construction from strings

@available(SwiftStdlib 9999, *)
extension FilePath.Root {
  /// Creates a root from a string, or `nil` if it is not exactly a root.
  public init?(_ string: String) {
    guard let r = FilePath.Root._makeIfSome(
      stdlib: { _StdlibFilePath.Root(string) },
      swiftSystem: { _SwiftSystemFilePath.Root(string) })
    else { return nil }
    self = r
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath.Root: ExpressibleByStringLiteral {
  /// Creates a root from a string literal.
  public init(stringLiteral: String) {
    self = FilePath.Root._make(
      stdlib: { _StdlibFilePath.Root(stringLiteral: stringLiteral) },
      swiftSystem: { _SwiftSystemFilePath.Root(stringLiteral: stringLiteral) })
  }
}

// MARK: - Platform string

@available(SwiftStdlib 9999, *)
extension FilePath.Root {
  /// Creates a root by copying bytes from a null-terminated platform string.
  public init?(platformString: UnsafePointer<CInterop.PlatformChar>) {
    guard let r = FilePath.Root._makeIfSome(
      stdlib: { _StdlibFilePath.Root(platformString: platformString) },
      swiftSystem: { _SwiftSystemFilePath.Root(platformString: platformString) })
    else { return nil }
    self = r
  }

  /// Creates a root by copying bytes from a null-terminated platform string.
  public init?(platformString: [CInterop.PlatformChar]) {
    guard let r = FilePath.Root._makeIfSome(
      stdlib: { _StdlibFilePath.Root(platformString: platformString) },
      swiftSystem: { _SwiftSystemFilePath.Root(platformString: platformString) })
    else { return nil }
    self = r
  }

  @available(*, deprecated, message: "Use FilePath.Root.init(_ scalar: Unicode.Scalar)")
  public init?(platformString: inout CInterop.PlatformChar) {
    guard let r = FilePath.Root._makeIfSome(
      stdlib: { _StdlibFilePath.Root(platformString: &platformString) },
      swiftSystem: { _SwiftSystemFilePath.Root(platformString: &platformString) })
    else { return nil }
    self = r
  }

  @available(*, deprecated, message: "Use FilePath.Root.init(_: String)")
  public init?(platformString: String) {
    guard let r = FilePath.Root._makeIfSome(
      stdlib: { _StdlibFilePath.Root(platformString: platformString) },
      swiftSystem: { _SwiftSystemFilePath.Root(platformString: platformString) })
    else { return nil }
    self = r
  }

  /// Calls `body` with a pointer to this root's null-terminated platform-string
  /// contents.
  public func withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    switch _backing {
    case .stdlib(let r): return try r.withPlatformString(body)
    case .swiftSystem(let r): return try r.withPlatformString(body)
    }
  }
}

// MARK: - String rendering

@available(SwiftStdlib 9999, *)
extension FilePath.Root {
  /// This root rendered as a string, repairing invalid code unit sequences.
  public var string: String {
    switch _backing {
    case .stdlib(let r): return r.string
    case .swiftSystem(let r): return r.string
    }
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath.Root: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    switch _backing {
    case .stdlib(let r): return r.description
    case .swiftSystem(let r): return r.description
    }
  }

  public var debugDescription: String { description.debugDescription }
}

// MARK: - Equatable, Hashable

@available(SwiftStdlib 9999, *)
extension FilePath.Root: Equatable, Hashable {
  public static func == (lhs: FilePath.Root, rhs: FilePath.Root) -> Bool {
    switch (lhs._backing, rhs._backing) {
    case (.stdlib(let l), .stdlib(let r)): return l == r
    case (.swiftSystem(let l), .swiftSystem(let r)): return l == r
    default: _filePathBackingMismatch("FilePath.Root")
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch _backing {
    case .stdlib(let r): hasher.combine(r)
    case .swiftSystem(let r): hasher.combine(r)
    }
  }
}

// MARK: - Codable

@available(SwiftStdlib 9999, *)
extension FilePath.Root: Codable {
  public func encode(to encoder: any Encoder) throws {
    switch _backing {
    case .stdlib(let r): try r.encode(to: encoder)
    case .swiftSystem(let r): try r.encode(to: encoder)
    }
  }

  public init(from decoder: any Decoder) throws {
    if _FilePathBackingSelection.useStdlib {
      self.init(_backing: .stdlib(try _StdlibFilePath.Root(from: decoder)))
    } else {
      self.init(
        _backing: .swiftSystem(try _SwiftSystemFilePath.Root(from: decoder)))
    }
  }
}

// MARK: - String from a root

@available(SwiftStdlib 9999, *)
extension String {
  /// Creates a string by decoding a root's content, repairing invalid code unit
  /// sequences.
  public init(decoding root: FilePath.Root) {
    switch root._backing {
    case .stdlib(let r): self.init(decoding: r)
    case .swiftSystem(let r): self.init(decoding: r)
    }
  }

  /// Creates a string from a root, or `nil` if its content is not valid in the
  /// platform's encoding.
  public init?(validating root: FilePath.Root) {
    switch root._backing {
    case .stdlib(let r):
      guard let s = String(validating: r) else { return nil }
      self = s
    case .swiftSystem(let r):
      guard let s = String(validating: r) else { return nil }
      self = s
    }
  }
}
