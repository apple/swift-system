/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// PORT SHIM: re-plumbs the internal `FilePath` helpers that the old package
// API (FilePathSyntax.swift, FilePathString.swift, …) still calls onto the
// SE-0529 stdlib copy's internals. These names used to live in the old
// FilePath implementation files that were emptied during the port; the
// bodies below are reimplemented on the copy's `_storage: _SystemString`,
// its `_parseRoot()` boundaries, and the `_normalizing` construction funnel.
//
// Temporary by design: once the call sites move to the copy's own API
// (`anchor`, `hasTrailingSeparator`, `components`, …) these compat members
// and their call sites are the mechanical removal list. Do not grow API here.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Old debug invariant hook. The stdlib copy has no whole-path recheck
  /// method (it asserts inline via `_internalInvariant` and establishes
  /// invariants at construction), so this checks the invariant directly:
  /// the path must be a fixed point of the `_normalizing` funnel.
  internal func _invariantCheck() {
    #if DEBUG
    // Normal form is a fixed point of the normalizing funnel: renormalizing
    // this path's own code units must reproduce it.
    precondition(
      FilePath(_normalizing: _cuArray) == self,
      "FilePath storage not in stdlib normal form")
    #endif
  }

  /// Whether the path begins with an anchor/root.
  ///
  /// Mirrors the copy's `anchor != nil`.
  internal var _hasRoot: Bool { anchor != nil }

  /// Append raw path bytes, inserting a platform separator between existing
  /// content and the new bytes when the current storage does not already end
  /// in one. Routes the result through the copy's `_normalizing` funnel so
  /// storage keeps the copy's invariants (coalesced separators, dot rules).
  internal mutating func _append(
    unchecked newElements: some Collection<FilePath.CodeUnit>
  ) {
    guard !newElements.isEmpty else { return }
    var bytes = _cuArray
    if !bytes.isEmpty, !_isSeparator(bytes.last!) {
      bytes.append(_platformSeparator)
    }
    bytes.append(contentsOf: newElements)
    self = FilePath(_normalizing: bytes)
  }

  /// Drop a trailing directory separator, if the path has a non-structural
  /// one. Delegates to the copy's `hasTrailingSeparator` setter, which
  /// preserves separators that belong to the anchor (e.g. `\\server\share\`).
  internal mutating func _removeTrailingSeparator() {
    hasTrailingSeparator = false
  }

  /// Lexically collapse `.` and `..` components in place, matching
  /// swift-system's legacy `lexicallyNormalize()`: drop `.`, resolve `..`
  /// against preceding regular components, and drop any trailing separator.
  ///
  /// This is the legacy configuration of `FilePath._lexicallyNormalize` —
  /// all three aspects enabled.
  internal mutating func _normalizeSpecialDirectories() {
    guard !isLexicallyNormal else { return }
    defer { assert(isLexicallyNormal) }
    _lexicallyNormalize(
      removeCurrentDirectory: true,
      collapseParentDirectory: true,
      removeTrailingSeparator: true)
  }
}
