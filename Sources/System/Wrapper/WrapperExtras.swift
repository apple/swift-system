/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Root-relative operations

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// This path with its root removed, leaving a relative path.
  public __consuming func removingRoot() -> FilePath {
    switch _backing {
    case .stdlib(let p):
      return FilePath(_backing: .stdlib(p.removingRoot()))
    case .swiftSystem(let p):
      return FilePath(_backing: .swiftSystem(p.removingRoot()))
    }
  }

  /// Resolves `subpath` against this path lexically, refusing to escape it.
  ///
  /// Returns `nil` when `subpath` would climb above this path. Forwarded rather
  /// than reimplemented: it is built out of `removingRoot`,
  /// `lexicallyNormalized` and component inspection, every one of which SE-0529
  /// revisits, so the answer has to come from the active backing.
  public __consuming func lexicallyResolving(
    _ subpath: __owned FilePath
  ) -> FilePath? {
    switch _backing {
    case .stdlib(let p):
      return p.lexicallyResolving(subpath._stdlib).map {
        FilePath(_backing: .stdlib($0))
      }
    case .swiftSystem(let p):
      return p.lexicallyResolving(subpath._swiftSystem).map {
        FilePath(_backing: .swiftSystem($0))
      }
    }
  }
}

// MARK: - Composition from a root and components

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Creates a path from an optional root and no components.
  public init(root: FilePath.Root?) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(root: root?._stdlib) },
      swiftSystem: { _SwiftSystemFilePath(root: root?._swiftSystem, []) })
  }

  /// Creates a path from an optional root and a collection of components.
  ///
  /// The components are handed to the active backing, which composes them by
  /// its own era's rules. Nothing is assembled here.
  public init<C: Collection>(
    root: FilePath.Root?, _ components: C
  ) where C.Element == FilePath.Component {
    self = FilePath._make(
      stdlib: {
        _StdlibFilePath(
          root: root?._stdlib, components.map { $0._stdlib })
      },
      swiftSystem: {
        _SwiftSystemFilePath(
          root: root?._swiftSystem, components.map { $0._swiftSystem })
      })
  }

  /// Creates a path from an optional root and a component view.
  public init(root: FilePath.Root?, _ components: FilePath.ComponentView) {
    self.init(root: root, Array(components))
  }

  /// Creates a path from an optional root and a list of components.
  public init(root: FilePath.Root?, components: FilePath.Component...) {
    self.init(root: root, components)
  }
}

// MARK: - Substrate and test SPI

// Underscored, so it can change in a patch release. These exist because the
// substrate and swift-system's own test suite reach for them; each one
// dispatches rather than deriving, so a caller sees the active era's bytes.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Creates a path from substrate string storage, normalizing per the active
  /// backing's rules.
  internal init(_ str: SystemString) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(str) },
      swiftSystem: { _SwiftSystemFilePath(str) })
  }

  /// Creates a path by normalizing raw code units per the active backing.
  internal init(_normalizing codeUnits: [FilePath.CodeUnit]) {
    self = FilePath._make(
      stdlib: { _StdlibFilePath(_normalizing: codeUnits) },
      swiftSystem: {
        _SwiftSystemFilePath(SystemString(_codeUnits: codeUnits))
      })
  }

  /// This path's code units, excluding the null terminator.
  internal var _cuArray: [FilePath.CodeUnit] {
    switch _backing {
    case .stdlib(let p): return p._cuArray
    case .swiftSystem(let p):
      return p.withPlatformString { _filePathCodeUnits(fromNulTerminated: $0) }
    }
  }

  /// This path's content as substrate string storage.
  internal var _systemStringStorage: SystemString {
    switch _backing {
    case .stdlib(let p): return p._systemStringStorage
    case .swiftSystem(let p): return p._storage
    }
  }

  /// This path's content as substrate string storage.
  ///
  /// Spelled `_storage` because that is the name swift-system's own test suite
  /// reaches for. On the swiftSystem backing it is the real storage; on the
  /// stdlib backing it is a restatement of that backing's bytes, so a test
  /// that asserts on *pointer identity* rather than content will legitimately
  /// diverge between the two.
  internal var _storage: SystemString { _systemStringStorage }

  /// Renormalizes separators in place, per the active backing's rules.
  ///
  /// A path built by either backing is already separator-normal, so this is a
  /// no-op on a well-formed value. It exists because swift-system's suite calls
  /// it to prove exactly that.
  internal mutating func _normalizeSeparators() {
    switch _backing {
    case .stdlib(var p):
      p._storage._normalizeSeparators()
      _backing = .stdlib(p)
    case .swiftSystem(var p):
      p._normalizeSeparators()
      _backing = .swiftSystem(p)
    }
  }
}
