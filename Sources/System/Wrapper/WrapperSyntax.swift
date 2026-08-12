/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Syntactic operations
//
// Straight forwarding. Every member below switches on the backing and calls the
// same member on it. Nothing here re-derives era-specific behavior: the members
// that recompose a path (append, push, removeLastComponent, lexicallyNormalize
// and their non-mutating twins) are precisely the ones whose rules changed in
// SE-0529, so each backing's own implementation has to be the one that runs.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Creates an empty path.
  public init() {
    self = FilePath._make(
      stdlib: { _StdlibFilePath() },
      swiftSystem: { _SwiftSystemFilePath() })
  }
}

// MARK: - Queries

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Whether this path uniquely identifies a location independent of any
  /// working directory.
  public var isAbsolute: Bool {
    switch _backing {
    case .stdlib(let p): return p.isAbsolute
    case .swiftSystem(let p): return p.isAbsolute
    }
  }

  /// Whether this path is not absolute.
  public var isRelative: Bool { !isAbsolute }

  /// Whether this path is empty.
  public var isEmpty: Bool {
    switch _backing {
    case .stdlib(let p): return p.isEmpty
    case .swiftSystem(let p): return p.isEmpty
    }
  }

  /// The length of this path's content, in code units.
  public var length: Int {
    switch _backing {
    case .stdlib(let p): return p.length
    case .swiftSystem(let p): return p.length
    }
  }

  /// Whether `other` is a prefix of this path.
  public func starts(with other: FilePath) -> Bool {
    switch _backing {
    case .stdlib(let p): return p.starts(with: other._stdlib)
    case .swiftSystem(let p): return p.starts(with: other._swiftSystem)
    }
  }

  /// Whether `other` is a suffix of this path.
  public func ends(with other: FilePath) -> Bool {
    switch _backing {
    case .stdlib(let p): return p.ends(with: other._stdlib)
    case .swiftSystem(let p): return p.ends(with: other._swiftSystem)
    }
  }
}

// MARK: - Root

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// This path's root, if it has one.
  ///
  /// Both sides stay in their own era's root representation; nothing is
  /// converted. See WrapperRoot.swift.
  public var root: FilePath.Root? {
    get {
      switch _backing {
      case .stdlib(let p):
        return p.root.map { FilePath.Root(_backing: .stdlib($0)) }
      case .swiftSystem(let p):
        return p.root.map { FilePath.Root(_backing: .swiftSystem($0)) }
      }
    }
    set {
      switch _backing {
      case .stdlib(var p):
        p.root = newValue?._stdlib
        _backing = .stdlib(p)
      case .swiftSystem(var p):
        p.root = newValue?._swiftSystem
        _backing = .swiftSystem(p)
      }
    }
  }
}

// MARK: - Components

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// This path's last component, if it has one.
  public var lastComponent: Component? {
    switch _backing {
    case .stdlib(let p):
      return p.lastComponent.map { Component(_backing: .stdlib($0)) }
    case .swiftSystem(let p):
      return p.lastComponent.map { Component(_backing: .swiftSystem($0)) }
    }
  }

  /// Removes this path's last component, returning whether it did so.
  @discardableResult
  public mutating func removeLastComponent() -> Bool {
    switch _backing {
    case .stdlib(var p):
      let r = p.removeLastComponent()
      _backing = .stdlib(p)
      return r
    case .swiftSystem(var p):
      let r = p.removeLastComponent()
      _backing = .swiftSystem(p)
      return r
    }
  }

  /// This path with its last component removed.
  public __consuming func removingLastComponent() -> FilePath {
    switch _backing {
    case .stdlib(let p): return FilePath(_backing: .stdlib(p.removingLastComponent()))
    case .swiftSystem(let p):
      return FilePath(_backing: .swiftSystem(p.removingLastComponent()))
    }
  }

  /// This path with its last component removed.
  public var dirname: FilePath { removingLastComponent() }

  /// This path's last component, if it has one.
  public var basename: Component? { lastComponent }
}

// MARK: - Extension and stem

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// The file extension of this path's last component.
  public var `extension`: String? {
    get {
      switch _backing {
      case .stdlib(let p): return p.extension
      case .swiftSystem(let p): return p.extension
      }
    }
    set {
      switch _backing {
      case .stdlib(var p):
        p.extension = newValue
        _backing = .stdlib(p)
      case .swiftSystem(var p):
        p.extension = newValue
        _backing = .swiftSystem(p)
      }
    }
  }

  /// The non-extension portion of this path's last component.
  public var stem: String? { lastComponent?.stem }
}

// MARK: - Normalization

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Whether this path is in lexical-normal form.
  ///
  /// Given its own switch rather than derived, because what counts as normal is
  /// one of the things SE-0529 changes.
  public var isLexicallyNormal: Bool {
    switch _backing {
    case .stdlib(let p): return p.isLexicallyNormal
    case .swiftSystem(let p): return p.isLexicallyNormal
    }
  }

  /// Normalizes this path lexically, without consulting the file system.
  public mutating func lexicallyNormalize() {
    switch _backing {
    case .stdlib(var p):
      p.lexicallyNormalize()
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.lexicallyNormalize()
      _backing = .swiftSystem(p)
    }
  }

  /// This path, normalized lexically.
  public __consuming func lexicallyNormalized() -> FilePath {
    switch _backing {
    case .stdlib(let p): return FilePath(_backing: .stdlib(p.lexicallyNormalized()))
    case .swiftSystem(let p):
      return FilePath(_backing: .swiftSystem(p.lexicallyNormalized()))
    }
  }
}

// MARK: - Prefix removal

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Removes `prefix` from the front of this path, returning whether it did so.
  public mutating func removePrefix(_ prefix: FilePath) -> Bool {
    switch _backing {
    case .stdlib(var p):
      let r = p.removePrefix(prefix._stdlib)
      _backing = .stdlib(p)
      return r
    case .swiftSystem(var p):
      let r = p.removePrefix(prefix._swiftSystem)
      _backing = .swiftSystem(p)
      return r
    }
  }
}

// MARK: - Appending

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Appends a component.
  public mutating func append(_ other: __owned FilePath.Component) {
    switch _backing {
    case .stdlib(var p):
      p.append(other._stdlib)
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.append(other._swiftSystem)
      _backing = .swiftSystem(p)
    }
  }

  /// Appends a collection of components.
  public mutating func append<C: Collection>(
    _ components: __owned C
  ) where C.Element == FilePath.Component {
    switch _backing {
    case .stdlib(var p):
      p.append(components.map { $0._stdlib })
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.append(components.map { $0._swiftSystem })
      _backing = .swiftSystem(p)
    }
  }

  /// Appends the components of `other`, parsed from a string.
  public mutating func append(_ other: __owned String) {
    switch _backing {
    case .stdlib(var p):
      p.append(other)
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.append(other)
      _backing = .swiftSystem(p)
    }
  }

  /// This path with `other` appended.
  public __consuming func appending(
    _ other: __owned FilePath.Component
  ) -> FilePath {
    var result = self
    result.append(other)
    return result
  }

  /// This path with `components` appended.
  public __consuming func appending<C: Collection>(
    _ components: __owned C
  ) -> FilePath where C.Element == FilePath.Component {
    var result = self
    result.append(components)
    return result
  }

  /// This path with the components of `other` appended.
  public __consuming func appending(_ other: __owned String) -> FilePath {
    var result = self
    result.append(other)
    return result
  }
}

// MARK: - Pushing

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Appends `other`, replacing this path entirely if `other` is absolute.
  public mutating func push(_ other: __owned FilePath) {
    switch _backing {
    case .stdlib(var p):
      p.push(other._stdlib)
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.push(other._swiftSystem)
      _backing = .swiftSystem(p)
    }
  }

  /// This path with `other` pushed onto it.
  public __consuming func pushing(_ other: __owned FilePath) -> FilePath {
    var result = self
    result.push(other)
    return result
  }
}

// MARK: - Storage management

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Removes this path's contents.
  public mutating func removeAll(keepingCapacity: Bool = false) {
    switch _backing {
    case .stdlib(var p):
      p.removeAll(keepingCapacity: keepingCapacity)
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.removeAll(keepingCapacity: keepingCapacity)
      _backing = .swiftSystem(p)
    }
  }

  /// Reserves storage for at least `minimumCapacity` code units.
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    switch _backing {
    case .stdlib(var p):
      p.reserveCapacity(minimumCapacity)
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p.reserveCapacity(minimumCapacity)
      _backing = .swiftSystem(p)
    }
  }
}
