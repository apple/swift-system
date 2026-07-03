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
  /// storage must be a fixed point of the `_normalizing` funnel.
  internal func _invariantCheck() {
    #if DEBUG
    // The copy's storage invariant, stated as a property: normal form is a
    // fixed point of the normalizing funnel. Catches any old-API code path
    // that mutates _storage directly and leaves it non-normal.
    let renormalized = FilePath(_normalizing: _storage)
    precondition(
      renormalized._storage == self._storage,
      "FilePath storage not in stdlib normal form")
    #endif
  }

  /// Whether the path begins with an anchor/root.
  ///
  /// Mirrors the copy's `anchor != nil`: the root is non-empty iff parsing
  /// finds an anchor that ends past the start of storage.
  internal var _hasRoot: Bool {
    _storage._parseRoot().rootEnd != _storage.startIndex
  }

  /// The index in `_storage` where the relative portion begins, i.e. just
  /// past the anchor and any gap separator. Equivalent to the copy's
  /// `_parseRoot().relativeBegin`.
  internal var _relativeStart: _SystemString.Index {
    _storage._parseRoot().relativeBegin
  }

  /// Append raw path bytes, inserting a platform separator between existing
  /// content and the new bytes when the current storage does not already end
  /// in one. Routes the result through the copy's `_normalizing` funnel so
  /// storage keeps the copy's invariants (coalesced separators, dot rules).
  internal mutating func _append(
    unchecked newElements: some Collection<FilePath.CodeUnit>
  ) {
    guard !newElements.isEmpty else { return }
    var storage = _storage
    if !storage.isEmpty, !_isSeparator(storage.last!) {
      storage.append(_platformSeparator)
    }
    storage.append(contentsOf: newElements)
    self = FilePath(_normalizing: storage)
  }

  /// Drop a trailing directory separator, if the path has a non-structural
  /// one. Delegates to the copy's `hasTrailingSeparator` setter, which
  /// preserves separators that belong to the anchor (e.g. `\\server\share\`).
  internal mutating func _removeTrailingSeparator() {
    hasTrailingSeparator = false
  }

  /// Lexically collapse `.` and `..` components in place.
  internal mutating func _normalizeSpecialDirectories() {
    // PORT-TODO: no stdlib-copy equivalent. The copy normalizes at
    // construction (`_SystemString._normalizeDots`) but deliberately
    // PRESERVES `..`, whereas the old `_normalizeSpecialDirectories`
    // lexically resolved `..` against preceding components (this is what
    // `lexicallyNormalize()` relied on). The copy exposes no lexical-collapse
    // primitive, so this needs a real port; left unimplemented rather than
    // inventing semantics.
    fatalError(
      "PORT-TODO: _normalizeSpecialDirectories has no stdlib-copy equivalent")
  }
}
