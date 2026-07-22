/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
*/

/// A file path is a null-terminated sequence of bytes that represents
/// a location in the file system.
@available(SwiftStdlib 9999, *)
public struct FilePath: Sendable {
  internal var _storage: _SystemString

  /// Creates an empty file path.
  @available(SwiftStdlib 9999, *)
  public init() {
    self._storage = _SystemString()
  }

  internal init(_storage: _SystemString) {
    self._storage = _storage
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath {
  // Normalizing init: the funnel for all path construction.
  //
  // All three platforms coalesce separators first, then parse. Darwin
  // additionally canonicalizes the anchor and excludes the resource-fork
  // suffix from dot-normalization (see _normalizeDarwin).
  internal init(_normalizing str: _SystemString) {
    if _isDarwin {
      self = _normalizeDarwin(str)
    } else if _isWindows {
      self = _normalizeWindows(str)
    } else {
      self = _normalizeLinux(str)
    }
  }

  /// Creates a file path by normalizing a sequence of platform code units.
  ///
  /// This is the non-failable construction funnel: it coalesces separators
  /// and applies the platform's dot rules, the same normalization every
  /// public initializer performs, but without the `NUL`-rejection of the
  /// public initializers. The caller is responsible for ensuring the code
  /// units contain no `NUL`.
  ///
  /// Underscored SPI: this is the primitive a source-compatibility layer
  /// (e.g. swift-system's FilePath API) constructs paths through when it has
  /// already-validated bytes and needs a non-failable, non-`Span` entry
  /// point. It is not public API in the proposal.
  @available(SwiftStdlib 9999, *)
  public init<C: Sequence<FilePath.CodeUnit>>(_normalizing codeUnits: C) {
    self.init(_normalizing: _SystemString(codeUnits))
  }

  /// The platform's canonical directory separator, as a code unit.
  ///
  /// On Linux and Darwin, this is the code unit for `/`.
  /// On Windows, it is the code unit for `\`.
  @available(SwiftStdlib 9999, *)
  public static var separator: FilePath.CodeUnit {
    _platformSeparator
  }

  /// Whether this path is empty.
  @available(SwiftStdlib 9999, *)
  public var isEmpty: Bool { _storage.isEmpty }
}

// MARK: - Lexical normalization

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Lexically normalize this path in place. Purely lexical: it consults
  /// only the path's own bytes, never the file system, so a result that
  /// resolves `..` may not match what following symlinks would produce.
  ///
  /// Each flag selects one independent aspect of normalization. The anchor
  /// is never altered; only the relative components are folded.
  ///
  /// - `removeCurrentDirectory`: drop every `.` (current-directory)
  ///   component.
  /// - `collapseParentDirectory`: resolve each `..` (parent-directory)
  ///   component against a preceding regular component, dropping both. A
  ///   `..` with nothing to resolve is dropped when the path is rooted (it
  ///   cannot climb above the anchor) and preserved when the path is
  ///   rootless — a leading run of `..` on a relative path survives, since
  ///   a `..` never resolves another `..`.
  /// - `removeTrailingSeparator`: drop a trailing directory separator from
  ///   the relative portion (a structural separator belonging to the anchor
  ///   is left in place).
  ///
  /// In a Windows verbatim path (`\\?\…`), `.` and `..` are ordinary
  /// component names, so the two dot flags leave them untouched.
  ///
  /// Underscored SPI: the low-level primitive that source-compatibility
  /// layers and higher-level normalization API build on. `.` -dropping and
  /// `..` -collapsing legacy lexical normalization is all three flags set.
  /// Not public API in the proposal.
  @available(SwiftStdlib 9999, *)
  public mutating func _lexicallyNormalize(
    removeCurrentDirectory: Bool,
    collapseParentDirectory: Bool,
    removeTrailingSeparator: Bool
  ) {
    let src = _storage
    guard !src.isEmpty else { return }

    let verbatim = _isVerbatimComponentPath(src)
    let (rootEnd, relBegin) = src._parseRoot()

    // "Rooted" here means: does an underflowing `..` get dropped? Only when
    // there is an anchor it cannot climb above. The Windows drive-relative
    // form `C:` is not such an anchor (`C:..` is meaningful), matching the
    // construction funnel's notion of rooted.
    let rooted: Bool
    if rootEnd == src.startIndex {
      rooted = false
    } else if _isWindows {
      rooted = !_isDriveRelativeAnchor(src[src.startIndex..<rootEnd])
    } else {
      rooted = true
    }

    // result = anchor + gap, then the folded relative components. `relBegin`
    // already includes the gap separator, so the first appended component
    // needs no separator before it. Components are appended without a
    // trailing separator, so during the walk the byte before `result`'s end
    // is always a component byte.
    var result = _SystemString()
    result.append(contentsOf: src[..<relBegin])
    let prefixEnd = result.endIndex

    var lastComponentStart = prefixEnd
    var appendedAny = false
    var sourceHadTrailingSep = false

    var readIdx = relBegin
    let end = src.endIndex
    while readIdx < end {
      // Storage is coalesced, so separators are single; one at the end of the
      // range is a trailing separator on the relative portion.
      if _isSeparator(src[readIdx]) {
        let next = src.index(after: readIdx)
        if next >= end { sourceHadTrailingSep = true }
        readIdx = next
        continue
      }

      let compStart = readIdx
      while readIdx < end && !_isSeparator(src[readIdx]) {
        readIdx = src.index(after: readIdx)
      }
      let compEnd = readIdx
      let compLen = src.distance(from: compStart, to: compEnd)

      // In a verbatim path `.` and `..` are ordinary component names.
      let isDot =
        !verbatim && compLen == 1 && src[compStart] == ._dot
      let isDotDot =
        !verbatim && compLen == 2 && src[compStart] == ._dot
        && src[src.index(after: compStart)] == ._dot

      if isDot {
        if removeCurrentDirectory { continue }
      } else if isDotDot && collapseParentDirectory {
        // Resolve against the last appended component if it is regular. The
        // only non-regular thing we ever append is a `..` (rootless case),
        // which a `..` cannot resolve.
        var poppable = false
        if appendedAny {
          let len = result.distance(from: lastComponentStart, to: result.endIndex)
          let lastIsDotDot =
            len == 2 && result[lastComponentStart] == ._dot
            && result[result.index(after: lastComponentStart)] == ._dot
          poppable = !lastIsDotDot
        }
        if poppable {
          // Drop the last component and the separator that precedes it.
          var cut = lastComponentStart
          if cut > prefixEnd { cut = result.index(before: cut) }
          result.removeSubrange(cut..<result.endIndex)
          // Re-derive the new last component's start by scanning back over
          // its bytes (bounded by the anchor prefix).
          var i = result.endIndex
          while i > prefixEnd
                && !_isSeparator(result[result.index(before: i)]) {
            result.formIndex(before: &i)
          }
          lastComponentStart = i
          appendedAny = result.endIndex > prefixEnd
          continue
        }
        if rooted { continue }
        // Rootless underflow: fall through and preserve the `..`.
      }

      if result.endIndex > prefixEnd { result.append(_platformSeparator) }
      lastComponentStart = result.endIndex
      result.append(contentsOf: src[compStart..<compEnd])
      appendedAny = true
    }

    if sourceHadTrailingSep && !removeTrailingSeparator && appendedAny {
      result.append(_platformSeparator)
    }

    _storage = result
  }
}

// MARK: - Per-platform normalization

@available(SwiftStdlib 9999, *)
private func _normalizeLinux(_ str: _SystemString) -> FilePath {
  _internalInvariant(_isLinux)
  var s = str
  s._normalizeSeparators()
  let (rootEnd, relBegin) = s._parseRoot()
  let isRooted = rootEnd != s.startIndex
  var result = _SystemString()
  result.append(contentsOf: s[s.startIndex..<relBegin])  // anchor + gap
  _ = s._normalizeDots(
    over: relBegin..<s.endIndex, isRooted: isRooted, into: &result)
  return FilePath(_storage: result)
}

@available(SwiftStdlib 9999, *)
private func _normalizeWindows(_ str: _SystemString) -> FilePath {
  var s = str
  s._normalizeSeparators()
  let isVerbatim = _isVerbatimComponentPath(s)
  let (rootEnd, relBegin) = s._parseRoot()
  // The only non-rooted Windows anchor is the 2-byte drive-relative `C:`;
  // empty/no-root counts as not rooted. Every other anchor (`\`, `C:\`,
  // UNC, verbatim, …) is rooted.
  let isRooted = rootEnd != s.startIndex
    && !_isDriveRelativeAnchor(s[s.startIndex..<rootEnd])
  var result = _SystemString()
  result.append(contentsOf: s[s.startIndex..<relBegin])  // anchor + gap
  if isVerbatim {
    // Verbatim paths: `.` and `..` are regular component names.
    result.append(contentsOf: s[relBegin..<s.endIndex])
  } else {
    _ = s._normalizeDots(
      over: relBegin..<s.endIndex, isRooted: isRooted, into: &result)
  }
  return FilePath(_storage: result)
}

@available(SwiftStdlib 9999, *)
private func _normalizeDarwin(_ str: _SystemString) -> FilePath {
  // Coalesce separators across the whole string first, then canonicalize
  // the anchor and parse the anchor / resource-fork suffix boundaries on
  // those coalesced bytes the way XNU classifies them.
  //
  // This is deliberately *not* what XNU does byte-for-byte: the kernel
  // does not coalesce separators before recognizing the
  // .vol/.resolve/.nofollow anchors. Because we coalesce first, our
  // canonicalization is XNU's modulo separator-coalescing — spellings
  // that differ only in runs of separators store identically. e.g.
  // /.resolve//1/foo and /.resolve/1/foo both coalesce and canonicalize
  // to /.nofollow/foo.
  var s = str
  s._normalizeSeparators()
  s._canonicalizeDarwinAnchor()

  // Parse the anchor and resource-fork suffix on the
  // coalesced+canonicalized string.
  let (rootEnd, relBegin) = s._parseRoot()
  let hasAnchor = rootEnd != s.startIndex
  var suffixStart = s._resourceForkSuffixStart ?? s.endIndex
  // If the suffix overlaps the anchor region, it's not a real suffix.
  if suffixStart < relBegin {
    suffixStart = s.endIndex
  }

  // TODO(post-PR): Single pass instead of both `s` and `result` copies.

  // Reassemble: anchor + gap + dot-normalized relative + suffix —
  // appending the relative portion into `result`
  var result = _SystemString()
  result.append(contentsOf: s[..<relBegin])

  // If the anchor doesn't already end in `/` and there is no gap
  // separator, we may need to insert one between anchor and relative.
  // Insert speculatively; roll back if the relative dot-normalizes to
  // empty.
  let needsAnchorSep =
    hasAnchor && rootEnd == relBegin
    && s[s.index(before: rootEnd)] != ._slash
  if needsAnchorSep {
    result.append(._slash)
  }

  let didEmitRelative = s._normalizeDots(
    over: relBegin..<suffixStart, isRooted: hasAnchor, into: &result)

  if needsAnchorSep && !didEmitRelative {
    _internalInvariant(result.last == ._slash)
    result.removeLast()
  }

  // Strip a trailing separator on the relative portion when a suffix
  // follows it.
  let hasSuffix = suffixStart < s.endIndex
  if hasSuffix && didEmitRelative
     && _isSeparator(result[result.index(before: result.endIndex)]) {
    _internalInvariant(_isSeparator(result.last!))
    result.removeLast()
  }

  result.append(contentsOf: s[suffixStart..<s.endIndex])

  return FilePath(_storage: result)
}

// Check if a path is a verbatim-component Windows path
@available(SwiftStdlib 9999, *)
internal func _isVerbatimComponentPath(_ storage: _SystemString) -> Bool {
  guard _isWindows else { return false }
  guard let parsed = storage._parseWindowsRootInternal() else { return false }
  return parsed.isVerbatimComponent
}
