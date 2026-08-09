/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - FilePath.ComponentView
//
// Unlike `Component` and `Root`, this is a wrapper type and not a typealias.
//
// It has to be. Decomposing a path into components and recomposing a path from
// edited components is exactly where the two eras disagree, so the view must
// stay on the active backing and every mutation must land in the backing's own
// `replaceSubrange`. Rebuilding a stdlib path out of bytes taken from a
// swiftSystem view would renormalize under the wrong era's rules and quietly
// produce a different path.
//
// So the view holds the backing's view, forwards iteration and mutation to it,
// and converts only at the boundary: components handed out are restated in the
// SE-0529 shape, components handed in are restated in the active backing's
// shape. The path arithmetic itself never leaves the backing.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// A view of a path's components.
  public struct ComponentView: Sendable {
    @usableFromInline
    internal enum Backing: Sendable {
      case stdlib(_StdlibFilePath.ComponentView)
      case swiftSystem(_SwiftSystemFilePath.ComponentView)
    }

    @usableFromInline
    internal var _backing: Backing

    @usableFromInline
    internal init(_backing: Backing) {
      self._backing = _backing
    }
  }
}

// MARK: - Index

@available(SwiftStdlib 9999, *)
extension FilePath.ComponentView {
  /// A position in a component view.
  public struct Index: Sendable, Comparable, Hashable {
    @usableFromInline
    internal enum Backing: Sendable, Hashable {
      case stdlib(_StdlibFilePath.ComponentView.Index)
      case swiftSystem(_SwiftSystemFilePath.ComponentView.Index)
    }

    @usableFromInline
    internal var _backing: Backing

    @usableFromInline
    internal init(_backing: Backing) {
      self._backing = _backing
    }

    internal var _stdlib: _StdlibFilePath.ComponentView.Index {
      guard case .stdlib(let i) = _backing else {
        _filePathBackingMismatch("FilePath.ComponentView.Index")
      }
      return i
    }

    internal var _swiftSystem: _SwiftSystemFilePath.ComponentView.Index {
      guard case .swiftSystem(let i) = _backing else {
        _filePathBackingMismatch("FilePath.ComponentView.Index")
      }
      return i
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
      switch (lhs._backing, rhs._backing) {
      case (.stdlib(let l), .stdlib(let r)): return l < r
      case (.swiftSystem(let l), .swiftSystem(let r)): return l < r
      default: _filePathBackingMismatch("FilePath.ComponentView.Index")
      }
    }
  }
}

// MARK: - Backing access

@available(SwiftStdlib 9999, *)
extension FilePath.ComponentView {
  internal var _stdlib: _StdlibFilePath.ComponentView {
    guard case .stdlib(let v) = _backing else {
      _filePathBackingMismatch("FilePath.ComponentView")
    }
    return v
  }

  internal var _swiftSystem: _SwiftSystemFilePath.ComponentView {
    guard case .swiftSystem(let v) = _backing else {
      _filePathBackingMismatch("FilePath.ComponentView")
    }
    return v
  }

  /// The path this view is a view of.
  ///
  /// Spelled `_path` because that is the name swift-system's own test suite
  /// reaches for. Rewrapped, so the result carries the same backing.
  internal var _path: FilePath {
    switch _backing {
    case .stdlib(let v): return FilePath(_backing: .stdlib(v._path))
    case .swiftSystem(let v): return FilePath(_backing: .swiftSystem(v._path))
    }
  }
}

// MARK: - Index storage offset

@available(SwiftStdlib 9999, *)
extension FilePath.ComponentView.Index {
  /// This index's offset into the path's substrate string storage.
  ///
  /// Spelled `_storage` because that is the name swift-system's own test suite
  /// reaches for. Both backings index a null-terminated array of the same code
  /// unit width, so the offset means the same thing on either side and matches
  /// `FilePath._storage`.
  internal var _storage: SystemString.Index {
    switch _backing {
    case .stdlib(let i): return i._storage
    case .swiftSystem(let i): return i._storage
    }
  }
}

// MARK: - Collection

@available(SwiftStdlib 9999, *)
extension FilePath.ComponentView: BidirectionalCollection {
  public typealias Element = FilePath.Component

  public var startIndex: Index {
    switch _backing {
    case .stdlib(let v): return Index(_backing: .stdlib(v.startIndex))
    case .swiftSystem(let v): return Index(_backing: .swiftSystem(v.startIndex))
    }
  }

  public var endIndex: Index {
    switch _backing {
    case .stdlib(let v): return Index(_backing: .stdlib(v.endIndex))
    case .swiftSystem(let v): return Index(_backing: .swiftSystem(v.endIndex))
    }
  }

  public func index(after i: Index) -> Index {
    switch _backing {
    case .stdlib(let v):
      return Index(_backing: .stdlib(v.index(after: i._stdlib)))
    case .swiftSystem(let v):
      return Index(_backing: .swiftSystem(v.index(after: i._swiftSystem)))
    }
  }

  public func index(before i: Index) -> Index {
    switch _backing {
    case .stdlib(let v):
      return Index(_backing: .stdlib(v.index(before: i._stdlib)))
    case .swiftSystem(let v):
      return Index(_backing: .swiftSystem(v.index(before: i._swiftSystem)))
    }
  }

  /// The component at `position`, wrapped so it carries this view's backing.
  public subscript(position: Index) -> FilePath.Component {
    switch _backing {
    case .stdlib(let v):
      return FilePath.Component(_backing: .stdlib(v[position._stdlib]))
    case .swiftSystem(let v):
      return FilePath.Component(
        _backing: .swiftSystem(v[position._swiftSystem]))
    }
  }
}

// MARK: - RangeReplaceableCollection

@available(SwiftStdlib 9999, *)
extension FilePath.ComponentView: RangeReplaceableCollection {
  /// An empty component view, backed by whichever implementation is active.
  public init() {
    self = _filePathSelect(
      stdlib: {
        FilePath.ComponentView(_backing: .stdlib(_StdlibFilePath.ComponentView()))
      },
      swiftSystem: {
        FilePath.ComponentView(
          _backing: .swiftSystem(_SwiftSystemFilePath.ComponentView()))
      })
  }

  /// Replaces components in `subrange` with `newElements`.
  ///
  /// Forwarded to the active backing's own `replaceSubrange`, which is what
  /// makes the resulting path era-correct. Incoming components are unwrapped to
  /// the backing's own type first; no path is rebuilt here.
  public mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where C.Element == FilePath.Component {
    switch _backing {
    case .stdlib(var v):
      v.replaceSubrange(
        subrange.lowerBound._stdlib..<subrange.upperBound._stdlib,
        with: newElements.map { $0._stdlib })
      _backing = .stdlib(v)
    case .swiftSystem(var v):
      v.replaceSubrange(
        subrange.lowerBound._swiftSystem..<subrange.upperBound._swiftSystem,
        with: newElements.map { $0._swiftSystem })
      _backing = .swiftSystem(v)
    }
  }
}

// MARK: - Equatable, Hashable

@available(SwiftStdlib 9999, *)
extension FilePath.ComponentView: Equatable, Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs._backing, rhs._backing) {
    case (.stdlib(let l), .stdlib(let r)): return l == r
    case (.swiftSystem(let l), .swiftSystem(let r)): return l == r
    default: _filePathBackingMismatch("FilePath.ComponentView")
    }
  }

  public func hash(into hasher: inout Hasher) {
    switch _backing {
    case .stdlib(let v): hasher.combine(v)
    case .swiftSystem(let v): hasher.combine(v)
    }
  }
}

// MARK: - The components property

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// A view of this path's components.
  ///
  /// Both getter and setter forward to the active backing's own `components`
  /// accessor, which is where each era's recomposition rules live. In
  /// particular the setter does not rebuild the path here: the backing decides
  /// how an edited component list becomes a path again.
  public var components: ComponentView {
    get {
      switch _backing {
      case .stdlib(let p):
        return ComponentView(_backing: .stdlib(p.components))
      case .swiftSystem(let p):
        return ComponentView(_backing: .swiftSystem(p.components))
      }
    }
    set {
      switch (_backing, newValue._backing) {
      case (.stdlib(var p), .stdlib(let v)):
        p.components = v
        _backing = .stdlib(p)
      case (.swiftSystem(var p), .swiftSystem(let v)):
        p.components = v
        _backing = .swiftSystem(p)
      default:
        _filePathBackingMismatch("FilePath.ComponentView")
      }
    }
  }
}
