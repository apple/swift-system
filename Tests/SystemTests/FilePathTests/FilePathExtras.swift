
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Proposed API that didn't make the cut, but we stil want to keep our testing for
@available(System 0.0.2, *)
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

    // Re-expressed on public API: one `..` component per remaining base
    // component, then the tail components. (Was: splice the tail's raw
    // storage bytes behind a `../`-prefix SystemString via `_storageSlice`,
    // which reached FilePath internals `_path` / `_storage`.)
    var result = FilePath()
    for _ in 0..<baseTail.count {
      result.append("..")
    }
    result.append(tail)
    return result
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
