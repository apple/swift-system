/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// MARK: - API

@available(System 0.0.2, *)
extension FilePath {
  /// Represents a root of a file path.
  ///
  /// On Unix, a root is simply the directory separator `/`.
  ///
  /// On Windows, a root contains the entire path prefix up to and including
  /// the final separator.
  ///
  /// Examples:
  /// * Unix:
  ///   * `/`
  /// * Windows:
  ///   * `C:\`
  ///   * `C:`
  ///   * `\`
  ///   * `\\server\share\`
  ///   * `\\?\UNC\server\share\`
  ///   * `\\?\Volume{12345678-abcd-1111-2222-123445789abc}\`
  @available(System 0.0.2, *)
  public struct Root: Sendable {
    // Root is a thin wrapper over the stdlib copy's public `Anchor`.
    internal var _anchor: FilePath.Anchor

    internal init(_ anchor: FilePath.Anchor) {
      self._anchor = anchor
    }
    // TODO: Definitely want a small form for this on Windows,
    // and intern "/" for Unix.
  }

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
#if false // PORT-CLOBBERED: superseded by stdlib copy
  @available(System 0.0.2, *)
  public struct Component: Sendable {
    internal var _path: FilePath
    internal var _range: Range<SystemString.Index>

    // TODO: Make a small-component form to save on ARC overhead when
    // extracted from a path, and especially to save on allocation overhead
    // when constructing one from a String literal.

    internal init<RE: RangeExpression>(_ path: FilePath, _ range: RE)
    where RE.Bound == SystemString.Index {
      self._path = path
      self._range = range.relative(to: path._storage)
      precondition(!self._range.isEmpty, "FilePath components cannot be empty")
      self._invariantCheck()
    }
  }
#endif
}

#if false // PORT-CLOBBERED: superseded by stdlib copy
@available(System 0.0.2, *)
extension FilePath.Component {

  /// Whether a component is a regular file or directory name, or a special
  /// directory `.` or `..`
  @frozen
  @available(System 0.0.2, *)
  public enum Kind: Sendable {
    /// The special directory `.`, representing the current directory.
    case currentDirectory

    /// The special directory `..`, representing the parent directory.
    case parentDirectory

    /// A file or directory name
    case regular
  }

  /// The kind of this component
  public var kind: Kind {
    if _path._isCurrentDirectory(_range) { return .currentDirectory }
    if _path._isParentDirectory(_range) { return .parentDirectory }
    return .regular
  }
}
#endif

@available(System 0.0.2, *)
extension FilePath.Root {
  // TODO: Windows analysis APIs
}

// Reconstruct a path from an optional root plus components. swift-system
// public API. The `ComponentView` overload copies the view's contribution
// verbatim via the public `components` setter, preserving a trailing separator
// on the source path (matching swift-system); the generic-collection overload
// rebuilds from discrete components, which carry no trailing separator.
// `Root` is a thin wrapper over the copy's `Anchor`.
@available(System 0.0.2, *)
extension FilePath {
  /// Create a file path from an optional root and no components.
  public init(root: FilePath.Root?) {
    self = FilePath(anchor: root?._anchor, [])
  }

  /// Create a file path from an optional root and a component view.
  public init(root: FilePath.Root?, _ components: FilePath.ComponentView) {
    self.init(root: root)
    self.components = components
  }

  /// Create a file path from an optional root and a collection of components.
  public init<C: Collection>(
    root: FilePath.Root?, _ components: C
  ) where C.Element == FilePath.Component {
    self = FilePath(anchor: root?._anchor, Array(components))
  }
}

// MARK: - Internals

#if false // PORT-CLOBBERED: dead code; its callers died with the old
// ComponentView, and the stdlib copy's ComponentView machinery supersedes it.
extension SystemString {
  // TODO: take insertLeadingSlash: Bool
  // TODO: turn into an insert operation with slide
  internal mutating func appendComponents<C: Collection>(
    components: C
  ) where C.Element == FilePath.Component {
    // TODO(perf): Consider pre-pass to count capacity, slide

    defer {
      _removeTrailingSeparator()
      FilePath(self)._invariantCheck()
    }

    for idx in components.indices {
      let component = components[idx]
      component._withSystemChars { self.append(contentsOf: $0) }
      self.append(platformSeparator)
    }
  }
}
#endif

// Unifying protocol for common functionality between roots and components.
// Reprovisioned over the stdlib copy's PUBLIC byte access: each conformer
// exposes its code units (no NUL) via `_codeUnits` and can be rebuilt from a
// code-unit array. No FilePath internal (`_storage`, `_range`) is named.
internal protocol _StrSlice: _PlatformStringable {
  /// The slice's code units, excluding any null terminator.
  var _codeUnits: [FilePath.CodeUnit] { get }

  init?(_ codeUnits: [FilePath.CodeUnit])

  func _invariantCheck()
}
extension _StrSlice {
  internal func _withSystemChars<T>(
    _ f: (UnsafeBufferPointer<FilePath.CodeUnit>) throws -> T
  ) rethrows -> T {
    try _codeUnits.withUnsafeBufferPointer(f)
  }
  internal func _withCodeUnits<T>(
    _ f: (UnsafeBufferPointer<CInterop.PlatformUnicodeEncoding.CodeUnit>) throws -> T
  ) rethrows -> T {
    try _codeUnits.withUnsafeBufferPointer { buf in
      try buf.withMemoryRebound(
        to: CInterop.PlatformUnicodeEncoding.CodeUnit.self
      ) { try f($0) }
    }
  }

  internal init?(_platformString s: UnsafePointer<CInterop.PlatformChar>) {
    // Copy the C string's code units (up to the NUL) via the substrate, then
    // validate. `SystemChar.rawValue` is `CInterop.PlatformChar`, which is
    // `FilePath.CodeUnit` on every platform.
    self.init(SystemString(platformString: s).map { $0.rawValue })
  }

  internal func _withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    var units = _codeUnits
    units.append(._null)
    return try units.withUnsafeBufferPointer { buf in
      try buf.baseAddress!.withMemoryRebound(
        to: CInterop.PlatformChar.self, capacity: buf.count
      ) { try body($0) }
    }
  }
}

@available(System 0.0.2, *)
extension FilePath.Component: _StrSlice {
  internal var _codeUnits: [FilePath.CodeUnit] { _copyToArray(codeUnits) }
}
@available(System 0.0.2, *)
extension FilePath.Root: _StrSlice {
  internal var _codeUnits: [FilePath.CodeUnit] { _copyToArray(_anchor.codeUnits) }
}

// Root's currency conformances (Component's come from the stdlib copy).
@available(System 0.0.2, *)
extension FilePath.Root: Equatable, Hashable {
  public static func == (lhs: FilePath.Root, rhs: FilePath.Root) -> Bool {
    lhs._anchor == rhs._anchor
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_anchor)
  }
}

@available(System 0.0.1, *)
extension FilePath: _PlatformStringable {
  // `_withPlatformString` is provided in FilePathCompatShims.swift.
  init(_platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(SystemString(platformString: _platformString))
  }
}

#if false // PORT-CLOBBERED: superseded by stdlib copy
@available(System 0.0.2, *)
extension FilePath.Component {
  // The index of the `.` denoting an extension
  internal func _extensionIndex() -> SystemString.Index? {
    guard kind == .regular,
          let idx = _slice.lastIndex(of: .dot),
          idx != _slice.startIndex
    else { return nil }

    return idx
  }

  internal func _extensionRange() -> Range<SystemString.Index>? {
    guard let idx = _extensionIndex() else { return nil }
    return _slice.index(after: idx) ..< _slice.endIndex
  }

  internal func _stemRange() -> Range<SystemString.Index> {
    _slice.startIndex ..< (_extensionIndex() ?? _slice.endIndex)
  }
}
#endif

internal func _makeExtension(_ ext: String) -> SystemString {
  var result = SystemString()
  result.append(.dot)
  result.append(contentsOf: ext.unicodeScalars.lazy.map(SystemChar.init))
  return result
}

@available(System 0.0.2, *)
extension FilePath.Component {
  internal init?(_ codeUnits: [FilePath.CodeUnit]) {
    let path = FilePath(_normalizing: codeUnits)
    guard path.anchor == nil, path.components.count == 1 else {
      return nil
    }
    self = path.components.first!
    self._invariantCheck()
  }
}

@available(System 0.0.2, *)
extension FilePath.Root {
  internal init?(_ codeUnits: [FilePath.CodeUnit]) {
    let path = FilePath(_normalizing: codeUnits)
    guard let anchor = path.anchor, path.components.isEmpty else {
      return nil
    }
    self = FilePath.Root(anchor)
    self._invariantCheck()
  }
}

// MARK: - Invariants

@available(System 0.0.2, *)
extension FilePath.Component {
  // TODO: ensure this all gets easily optimized away in release...
  internal func _invariantCheck() {
    #if DEBUG
    let bytes = _codeUnits
    precondition(!bytes.isEmpty)
    precondition(bytes.last != ._null)
    precondition(bytes.allSatisfy { !_isSeparator($0) } )
    #endif // DEBUG
  }
}

@available(System 0.0.2, *)
extension FilePath.Root {
  internal func _invariantCheck() {
    #if DEBUG
    precondition(!_anchor.codeUnits.isEmpty)
    // TODO: Windows root invariants
    #endif
  }
}
