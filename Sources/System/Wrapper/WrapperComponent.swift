/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - FilePath.Component
//
// A thin dispatching wrapper, like `Root` and `ComponentView`.
//
// It was a typealias to the SE-0529 component at first, on the reasoning that a
// component is just a separator-free byte run, so both eras agree on what one
// *is* and only disagree about how paths decompose into them. That reasoning
// holds for a component that already exists. It does not hold for VALIDATION:
// deciding whether a given string is one component is era-specific.
//
//   legacy:  `Component("a/")` succeeds, yielding `a`. Historical swift-system
//            ran the string through path normalization first, which stripped a
//            trailing separator, and then checked for a single component.
//   SE-0529: `Component("a/")` is nil. A trailing separator is now significant,
//            so a string carrying one is not a bare component.
//
// With a shared typealias there is one initializer answering for both eras, and
// the only way to serve both is to ask the global backing selection inside it.
// That was the band-aid this type replaces: it fixed the one divergence we had
// found and would need another `if` for the next one. Trailing separators are
// unlikely to be the only case, since normalization is exactly where the eras
// differ and every failable construction here runs input through it.
//
// So `Component` holds each backing's own component and forwards. Construction
// routes through `_make` / `_makeIfSome`, the same funnel `FilePath` uses, which
// means the era rule is applied by the backing that owns it rather than by a
// conditional here.
//
// Not vended: `codeUnits` and `init?(codeUnits:)`, the SE-0529 `Span` API. The
// `FilePath` wrapper does not vend `Span` either, for the same reason: a `Span`
// borrowed from an enum payload cannot outlive the `switch` that binds it. That
// API stays reachable on `_StdlibFilePath.Component`.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Represents an individual, non-root component of a file path.
  ///
  /// Components can be one of the special directory components (`.` or `..`)
  /// or a file or directory name. Components are never empty and never
  /// contain the directory separator.
  ///
  /// Example:
  ///
  ///     var path: FilePath = "/tmp"
  ///     let file: FilePath.Component = "foo.txt"
  ///     file.kind == .regular           // true
  ///     file.extension                  // "txt"
  ///     path.append(file)               // path is "/tmp/foo.txt"
  public struct Component: Sendable {
    @usableFromInline
    internal enum Backing: Sendable {
      case stdlib(_StdlibFilePath.Component)
      case swiftSystem(_SwiftSystemFilePath.Component)
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
extension FilePath.Component {
  internal static func _make(
    stdlib: () -> _StdlibFilePath.Component,
    swiftSystem: () -> _SwiftSystemFilePath.Component
  ) -> FilePath.Component {
    _filePathSelect(
      stdlib: { FilePath.Component(_backing: .stdlib(stdlib())) },
      swiftSystem: {
        FilePath.Component(_backing: .swiftSystem(swiftSystem()))
      })
  }

  internal static func _makeIfSome(
    stdlib: () -> _StdlibFilePath.Component?,
    swiftSystem: () -> _SwiftSystemFilePath.Component?
  ) -> FilePath.Component? {
    _filePathSelect(
      stdlib: { stdlib().map { FilePath.Component(_backing: .stdlib($0)) } },
      swiftSystem: {
        swiftSystem().map { FilePath.Component(_backing: .swiftSystem($0)) }
      })
  }
}

// MARK: - Backing access

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  internal var _stdlib: _StdlibFilePath.Component {
    guard case .stdlib(let c) = _backing else {
      _filePathBackingMismatch("FilePath.Component")
    }
    return c
  }

  internal var _swiftSystem: _SwiftSystemFilePath.Component {
    guard case .swiftSystem(let c) = _backing else {
      _filePathBackingMismatch("FilePath.Component")
    }
    return c
  }
}

// MARK: - Kind

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  /// Whether a component is a regular file or directory name, or a special
  /// directory `.` or `..`
  @frozen
  public enum Kind: Sendable, Equatable {
    /// The special directory `.`, representing the current directory.
    case currentDirectory

    /// The special directory `..`, representing the parent directory.
    case parentDirectory

    /// A file or directory name
    case regular
  }

  /// The kind of this component.
  public var kind: Kind {
    switch _backing {
    case .stdlib(let c):
      switch c.kind {
      case .currentDirectory: return .currentDirectory
      case .parentDirectory: return .parentDirectory
      case .regular: return .regular
      }
    case .swiftSystem(let c):
      switch c.kind {
      case .currentDirectory: return .currentDirectory
      case .parentDirectory: return .parentDirectory
      case .regular: return .regular
      }
    }
  }
}

// MARK: - Construction from strings

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  /// Creates a file path component from a string.
  ///
  /// Returns `nil` if `string` is empty, is a root, or has more than one
  /// component in it.
  ///
  /// The era difference lives here rather than in a conditional: each backing
  /// applies its own rule, so `"a/"` is accepted (and stripped) under the
  /// historical backing and rejected under SE-0529.
  public init?(_ string: String) {
    guard let c = FilePath.Component._makeIfSome(
      stdlib: { _StdlibFilePath.Component(string) },
      swiftSystem: { _SwiftSystemFilePath.Component(string) })
    else { return nil }
    self = c
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath.Component: ExpressibleByStringLiteral {
  /// Creates a file path component from a string literal.
  ///
  /// Precondition: `stringLiteral` is non-empty, is not a root, and has only
  /// one component in it.
  public init(stringLiteral: String) {
    self = FilePath.Component._make(
      stdlib: { _StdlibFilePath.Component(stringLiteral: stringLiteral) },
      swiftSystem: {
        _SwiftSystemFilePath.Component(stringLiteral: stringLiteral)
      })
  }
}

// MARK: - Platform string

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  /// Creates a file path component by copying bytes from a null-terminated
  /// platform string.
  ///
  /// Returns `nil` if `platformString` is empty, is a root, or has more than
  /// one component in it.
  public init?(platformString: UnsafePointer<CInterop.PlatformChar>) {
    guard let c = FilePath.Component._makeIfSome(
      stdlib: { _StdlibFilePath.Component(platformString: platformString) },
      swiftSystem: {
        _SwiftSystemFilePath.Component(platformString: platformString)
      })
    else { return nil }
    self = c
  }

  /// Creates a file path component by copying bytes from a null-terminated
  /// platform string.
  ///
  /// - Note It is a precondition that `platformString` must be null-terminated.
  /// The absence of a null byte will trigger a runtime error.
  public init?(platformString: [CInterop.PlatformChar]) {
    guard let c = FilePath.Component._makeIfSome(
      stdlib: { _StdlibFilePath.Component(platformString: platformString) },
      swiftSystem: {
        _SwiftSystemFilePath.Component(platformString: platformString)
      })
    else { return nil }
    self = c
  }

  @available(*, deprecated, message: "Use FilePath.Component.init(_ scalar: Unicode.Scalar)")
  public init?(platformString: inout CInterop.PlatformChar) {
    guard let c = FilePath.Component._makeIfSome(
      stdlib: { _StdlibFilePath.Component(platformString: &platformString) },
      swiftSystem: {
        _SwiftSystemFilePath.Component(platformString: &platformString)
      })
    else { return nil }
    self = c
  }

  @available(*, deprecated, message: "Use FilePath.Component.init(_: String)")
  public init?(platformString: String) {
    guard let c = FilePath.Component._makeIfSome(
      stdlib: { _StdlibFilePath.Component(platformString: platformString) },
      swiftSystem: {
        _SwiftSystemFilePath.Component(platformString: platformString)
      })
    else { return nil }
    self = c
  }

  /// Calls `body` with a pointer to this component's null-terminated
  /// platform-string contents.
  public func withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    switch _backing {
    case .stdlib(let c): return try c.withPlatformString(body)
    case .swiftSystem(let c): return try c.withPlatformString(body)
    }
  }
}

// MARK: - String rendering

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  /// Creates a string by interpreting the component's content as UTF-8 on Unix
  /// and UTF-16 on Windows.
  ///
  /// This property is equivalent to calling `String(decoding: component)`.
  public var string: String {
    switch _backing {
    case .stdlib(let c): return c.string
    case .swiftSystem(let c): return c.string
    }
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath.Component: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    switch _backing {
    case .stdlib(let c): return c.description
    case .swiftSystem(let c): return c.description
    }
  }

  public var debugDescription: String { description.debugDescription }
}

// MARK: - Extension and stem

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  /// The extension of this file or directory component.
  ///
  /// If `self` does not contain a `.` anywhere, or only at the start, returns
  /// `nil`. Otherwise, returns everything after the dot.
  ///
  /// Examples:
  ///   * `foo.txt    => txt`
  ///   * `foo.tar.gz => gz`
  ///   * `Foo.app    => app`
  ///   * `.hidden    => nil`
  ///   * `..         => nil`
  public var `extension`: String? {
    switch _backing {
    case .stdlib(let c): return c.extension
    case .swiftSystem(let c): return c.extension
    }
  }

  /// The non-extension portion of this file or directory component.
  ///
  /// Examples:
  ///   * `foo.txt => foo`
  ///   * `foo.tar.gz => foo.tar`
  ///   * `Foo.app => Foo`
  ///   * `.hidden => .hidden`
  ///   * `..      => ..`
  public var stem: String {
    switch _backing {
    case .stdlib(let c): return c.stem
    case .swiftSystem(let c): return c.stem
    }
  }
}

// MARK: - Equatable, Hashable, Comparable

@available(SwiftStdlib 9999, *)
extension FilePath.Component: Equatable, Hashable {
  public static func == (lhs: FilePath.Component, rhs: FilePath.Component) -> Bool {
    switch (lhs._backing, rhs._backing) {
    case (.stdlib(let l), .stdlib(let r)): return l == r
    case (.swiftSystem(let l), .swiftSystem(let r)): return l == r
    default: _filePathBackingMismatch("FilePath.Component")
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch _backing {
    case .stdlib(let c): hasher.combine(c)
    case .swiftSystem(let c): hasher.combine(c)
    }
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath.Component: Comparable {
  /// Orders components lexicographically by code unit.
  ///
  /// The SE-0529 component is `Comparable`; the historical one is not, so its
  /// arm spells out the same rule (`_slice.lexicographicallyPrecedes`) that the
  /// SE-0529 `<` uses. Both slice the same platform code unit type, so the two
  /// arms agree on ordering for any component representable in both.
  public static func < (lhs: FilePath.Component, rhs: FilePath.Component) -> Bool {
    switch (lhs._backing, rhs._backing) {
    case (.stdlib(let l), .stdlib(let r)): return l < r
    case (.swiftSystem(let l), .swiftSystem(let r)):
      return l._slice.lexicographicallyPrecedes(r._slice)
    default: _filePathBackingMismatch("FilePath.Component")
    }
  }
}

// MARK: - Codable

// The wire format is the historical synthesized shape over the old stored
// properties, `{ "_path": <FilePath>, "_range": [lower, upper] }`, where the
// nested `_path` is whichever backing is active. See FilePathConformances.swift
// for why the offsets force decoding to slice `_path`'s RAW storage before
// normalizing, rather than decoding `_path` as a path and slicing after.

private enum _ComponentCodingKeys: String, CodingKey {
  case _path
  case _range
}

// The old `_path` payload is `{ "_storage": SystemString }`, whatever else the
// active era adds alongside it. Reading the raw `SystemString` out directly is
// what keeps the offsets meaningful, and ignoring every other key is what lets
// one decoder accept both eras' archives.
private enum _ComponentPathStorageKeys: String, CodingKey {
  case _storage
}

@available(SwiftStdlib 9999, *)
private func _decodeSlicePayload(
  from decoder: any Decoder
) throws -> (SystemString, Range<SystemString.Index>) {
  let container = try decoder.container(keyedBy: _ComponentCodingKeys.self)
  let pathContainer = try container.nestedContainer(
    keyedBy: _ComponentPathStorageKeys.self, forKey: ._path)
  // SystemString's own decoder validates its invariants on untrusted input.
  let raw = try pathContainer.decode(SystemString.self, forKey: ._storage)
  let range = try container.decode(
    Range<SystemString.Index>.self, forKey: ._range)
  return (raw, range)
}

@available(SwiftStdlib 9999, *)
extension FilePath.Component: Codable {
  /// Encodes in the active backing's shape.
  ///
  /// Each backing already encodes its own era's format: the historical one gets
  /// the synthesized `{_path, _range}` over its real stored path and offsets,
  /// and `_StdlibFilePath.Component` synthesizes an equivalent payload plus the
  /// `_v2` side channel. Dispatching is all this needs to do, so unlike the old
  /// typealias there is no era switch inside the encoder.
  public func encode(to encoder: any Encoder) throws {
    switch _backing {
    case .stdlib(let c): try c.encode(to: encoder)
    case .swiftSystem(let c): try c.encode(to: encoder)
    }
  }

  /// Decodes from either era's archive.
  ///
  /// Deliberately NOT forwarded to the backing's own `init(from:)`. The
  /// historical backing's decoder is synthesized, so it validates nothing
  /// beyond what `_path` itself checks and would accept a `_range` spanning a
  /// separator or running out of bounds. The raw-slice-then-validate path below
  /// is the one that holds in both eras, and the final construction goes
  /// through `_makeIfSome`, so the era's own rule decides whether those bytes
  /// are a component.
  public init(from decoder: any Decoder) throws {
    let (raw, range) = try _decodeSlicePayload(from: decoder)
    guard range.lowerBound >= raw.startIndex,
          range.upperBound <= raw.endIndex,
          !range.isEmpty,
          let component = FilePath.Component(SystemString(raw[range]))
    else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription:
            "_range does not select a single path component from _path"))
    }
    self = component
  }
}

// MARK: - Substrate and test SPI

// Underscored, so it can change in a patch release. These exist because the
// substrate and swift-system's own test suite reach for them; each one
// dispatches rather than deriving, so a caller sees the active era's bytes.

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  /// Creates a component from substrate string storage, per the active backing's
  /// rules.
  internal init?(_ str: SystemString) {
    guard let c = FilePath.Component._makeIfSome(
      stdlib: { _StdlibFilePath.Component(str) },
      swiftSystem: { _SwiftSystemFilePath.Component(str) })
    else { return nil }
    self = c
  }

  /// This component's code units, excluding any null terminator.
  internal var _codeUnits: [FilePath.CodeUnit] {
    switch _backing {
    case .stdlib(let c): return c._codeUnits
    case .swiftSystem(let c): return c._wrapperCodeUnits
    }
  }

  /// This component's containing storage, as substrate string storage.
  ///
  /// Spelled `_slice.base` by swift-system's test suite, which reads it to
  /// check that a component points into the path's bytes rather than a copy.
  internal var _sliceBase: SystemString {
    switch _backing {
    case .stdlib(let c): return c._sliceBase
    case .swiftSystem(let c): return c._path._storage
    }
  }
}

// MARK: - String from a component

@available(SwiftStdlib 9999, *)
extension String {
  /// Creates a string by decoding a component's content, repairing invalid code
  /// unit sequences.
  public init(decoding component: FilePath.Component) {
    switch component._backing {
    case .stdlib(let c): self.init(decoding: c)
    case .swiftSystem(let c): self.init(decoding: c)
    }
  }

  /// Creates a string from a component, or `nil` if its content is not valid in
  /// the platform's encoding.
  public init?(validating component: FilePath.Component) {
    switch component._backing {
    case .stdlib(let c):
      guard let s = String(validating: c) else { return nil }
      self = s
    case .swiftSystem(let c):
      guard let s = String(validating: c) else { return nil }
      self = s
    }
  }
}
