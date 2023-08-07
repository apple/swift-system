/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - API

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
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
  public struct Root {
    internal var _path: FilePath
    internal var _rootEnd: _SystemString.Index

    internal init(_ path: FilePath, rootEnd: _SystemString.Index) {
      self._path = path
      self._rootEnd = rootEnd
      _invariantCheck()
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
  public struct Component {
    internal var _path: FilePath
    public var _range: Range<_SystemString.Index>

    // TODO: Make a small-component form to save on ARC overhead when
    // extracted from a path, and especially to save on allocation overhead
    // when constructing one from a String literal.

    internal init<RE: RangeExpression>(_ path: FilePath, _ range: RE)
    where RE.Bound == _SystemString.Index {
      self._path = path
      self._range = range.relative(to: path._storage)
      precondition(!self._range.isEmpty, "FilePath components cannot be empty")
      self._invariantCheck()
    }
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component {

  /// Whether a component is a regular file or directory name, or a special
  /// directory `.` or `..`
  @frozen
  public enum Kind {
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

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Root {
  // TODO: Windows analysis APIs
}

// MARK: - Internals

extension _SystemString {
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

// Unifying protocol for common functionality between roots, components,
// and views onto SystemString and FilePath.
public protocol _StrSlice: _PlatformStringable, Hashable, Codable {
  var _storage: _SystemString { get }
  var _range: Range<_SystemString.Index> { get }

  init?(_ str: _SystemString)

  func _invariantCheck()
}
extension _StrSlice {
  internal var _slice: Slice<_SystemString> {
    Slice(base: _storage, bounds: _range)
  }

  internal func _withSystemChars<T>(
    _ f: (UnsafeBufferPointer<_SystemChar>) throws -> T
  ) rethrows -> T {
    try _storage.withSystemChars {
      try f(UnsafeBufferPointer(rebasing: $0[_range]))
    }
  }
  internal func _withCodeUnits<T>(
    _ f: (UnsafeBufferPointer<CInterop.PlatformUnicodeEncoding.CodeUnit>) throws -> T
  ) rethrows -> T {
    try _slice.withCodeUnits(f)
  }

  public init?(_platformString s: UnsafePointer<CInterop.PlatformChar>) {
    self.init(_SystemString(platformString: s))
  }

  public func _withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    try _slice.withPlatformString(body)
  }

  internal var _systemString: _SystemString { _SystemString(_slice) }
}
extension _StrSlice {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs._slice.elementsEqual(rhs._slice)
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_slice.count) // discriminator
    for element in _slice {
      hasher.combine(element)
    }
  }
}
internal protocol _PathSlice: _StrSlice {
  var _path: FilePath { get }
}
extension _PathSlice {
  public var _storage: _SystemString { _path._storage }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component: _PathSlice {
}
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Root: _PathSlice {
  public var _range: Range<_SystemString.Index> {
    (..<_rootEnd).relative(to: _path._storage)
  }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FilePath: _PlatformStringable {
  public func _withPlatformString<Result>(_ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result) rethrows -> Result {
    try _storage.withPlatformString(body)
  }

  public init(_platformString: UnsafePointer<CInterop.PlatformChar>) {
    self.init(_SystemString(platformString: _platformString))
  }

}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component {
  // The index of the `.` denoting an extension
  internal func _extensionIndex() -> _SystemString.Index? {
    guard kind == .regular,
          let idx = _slice.lastIndex(of: .dot),
          idx != _slice.startIndex
    else { return nil }

    return idx
  }

  internal func _extensionRange() -> Range<_SystemString.Index>? {
    guard let idx = _extensionIndex() else { return nil }
    return _slice.index(after: idx) ..< _slice.endIndex
  }

  internal func _stemRange() -> Range<_SystemString.Index> {
    _slice.startIndex ..< (_extensionIndex() ?? _slice.endIndex)
  }
}

internal func _makeExtension(_ ext: String) -> _SystemString {
  var result = _SystemString()
  result.append(.dot)
  result.append(contentsOf: ext.unicodeScalars.lazy.map(_SystemChar.init))
  return result
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component {
  public init?(_ str: _SystemString) {
    // FIXME: explicit null root? Or something else?
    let path = FilePath(str)
    guard path.root == nil, path.components.count == 1 else {
      return nil
    }
    self = path.components.first!
    self._invariantCheck()
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Root {
  public init?(_ str: _SystemString) {
    // FIXME: explicit null root? Or something else?
    let path = FilePath(str)
    guard path.root != nil, path.components.isEmpty else {
      return nil
    }
    self = path.root!
    self._invariantCheck()
  }
}

// MARK: - Invariants

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component {
  // TODO: ensure this all gets easily optimized away in release...
  public func _invariantCheck() {
    #if DEBUG
    precondition(!_slice.isEmpty)
    precondition(_slice.last != .null)
    precondition(_slice.allSatisfy { !isSeparator($0) } )
    precondition(_path._relativeStart <= _slice.startIndex)
    #endif // DEBUG
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Root {
  public func _invariantCheck() {
    #if DEBUG
    precondition(self._rootEnd > _path._storage.startIndex)

    // TODO: Windows root invariants
    #endif
  }
}

#if compiler(>=5.5) && canImport(_Concurrency)
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Root: Sendable {}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component: Sendable {}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component.Kind: Sendable {}
#endif
