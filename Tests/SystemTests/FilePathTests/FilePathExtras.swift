
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Why can't I write this extension on `FilePath.ComponentView.SubSequence`?
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension Slice where Base == FilePath.ComponentView {
  internal var _storageSlice: SystemString.SubSequence {
    base._path._storage[self.startIndex._storage ..< self.endIndex._storage]
  }
}


// Proposed API that didn't make the cut, but we stil want to keep our testing for
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  /// Returns `self` relative to `base`.
  /// This does not cosult the file system or resolve symlinks.
  ///
  /// Returns `nil` if `self.root != base.root`.
  ///
  /// On Windows, if any component of either path could be interpreted as the root of
  /// a traditional DOS path (e.g. a directory named `C:`), returns `nil`.
  ///
  /// Example:
  ///
  ///     let path: FilePath = "/usr/local/bin"
  ///     path.lexicallyRelative(toBase: "/usr/local") == "bin"
  ///     path.lexicallyRelative(toBase: "/usr/local/bin/ls") == ".."
  ///     path.lexicallyRelative(toBase: "/tmp/foo.txt") == "../../usr/local/bin"
  ///     path.lexicallyRelative(toBase: "local/bin") == nil
  internal func lexicallyRelative(toBase base: FilePath) -> FilePath? {
    guard root == base.root else { return nil }

    // FIXME: On Windows, return nil if any component looks like a root

    let (tail, baseTail) = _dropCommonPrefix(components, base.components)

    var prefix = SystemString()
    for _ in 0..<baseTail.count {
      prefix.append(.dot)
      prefix.append(.dot)
      prefix.append(platformSeparator)
    }

    return FilePath(prefix + tail._storageSlice)
  }

  /// Whether a lexically-normalized `self` contains a lexically-normalized
  /// `other`.
  public func lexicallyContains(_ other: FilePath) -> Bool {
    guard !other.isEmpty else { return true }
    guard !isEmpty else { return false }

    let (selfLex, otherLex) =
      (self.lexicallyNormalized(), other.lexicallyNormalized())
    if otherLex.isAbsolute { return selfLex.starts(with: otherLex) }

    // FIXME: Windows semantics with relative roots?

    // TODO: better than this naive algorithm
    var slice = selfLex.components[...]
    while !slice.isEmpty {
      if slice.starts(with: otherLex.components) { return true }
      slice = slice.dropFirst()
    }
    return false
  }
}

extension Collection where Element: Equatable, SubSequence == Slice<Self> {
  // Mock up RangeSet functionality until it's real
  func indices(where p: (Element) throws -> Bool) rethrows -> [Range<Index>] {
    var result = Array<Range<Index>>()
    guard !isEmpty else { return result }

    var i = startIndex
    while i != endIndex {
      let next = index(after: i)
      if try p(self[i]) {
        result.append(i..<next)
      }
      i = next
    }

    return result
  }
}
extension RangeReplaceableCollection {
  mutating func removeSubranges(_ subranges: [Range<Index>]) {
    guard !subranges.isEmpty else { return }

    var result = Self()
    var idx = startIndex
    for range in subranges {
      result.append(contentsOf: self[idx..<range.lowerBound])
      idx = range.upperBound
    }
    if idx != endIndex {
      result.append(contentsOf: self[idx...])
    }
    self = result
  }
}
