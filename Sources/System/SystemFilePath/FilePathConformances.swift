/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// Conformances swift-system's FilePath has always shipped that the stdlib
// implementation deliberately does not. SE-0529 excludes Codable from the
// stdlib FilePath by design (serialization is left to application-level
// code), so this file is permanent package-side surface, not a port shim.
//
// Wire-format compatibility contract: the historical encoding was the
// synthesized form over `_storage: SystemString`, i.e.
//   { "_storage": { "nullTerminatedStorage": [code units...] } }
// SystemString still carries its original Codable (including the
// invariant-validating decoder), so encoding through it reproduces the old
// bytes exactly.
//
// Forward-compat side channel (`_v2`). The new FilePath can carry a trailing
// separator, which the historical `_storage` decoder rejects. So `_storage`
// stays in the historical (separator-stripped) form old decoders accept, and
// new-only distinctions travel in a sibling `_v2` object old decoders ignore:
//
//   { "_storage": <stripped SystemString>,
//     "_v2": { "hasTrailingSeparator": <bool> } }
//
// `_v2` is append-only: decode each field with `decodeIfPresent` and default
// when absent, never remove or repurpose a field, and always emit `_v2` (no
// omit-when-default branch to keep in sync). That yields new->old (old reads
// `_storage`, ignores `_v2`), old->new (no `_v2`, fields default), and
// new->new (full fidelity).
//
// `hasTrailingSeparator` covers the removable trailing separator (`/tmp/foo`
// vs `/tmp/foo/`) only; a structural anchor separator (`\\server\share\`)
// stays in `_storage`, so the flag is false and old still reads it correctly.
//
// TODO: validate against real archives. The decoder also normalizes
// non-normal `_storage` the historical one rejected (safe for old->new). Other
// new-only forms with no old equivalent (Darwin resource forks, canonicalized
// `.vol`/`.nofollow` anchors) are out of scope for `_v2`.

@available(System 0.0.1, *)
extension FilePath: Codable {
  private enum CodingKeys: String, CodingKey {
    case _storage
    case _v2
  }

  // Append-only side channel; see the contract above.
  private struct _V2: Codable {
    var hasTrailingSeparator: Bool = false

    private enum CodingKeys: String, CodingKey {
      case hasTrailingSeparator
    }

    init(hasTrailingSeparator: Bool) {
      self.hasTrailingSeparator = hasTrailingSeparator
    }

    init(from decoder: any Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      // Every field defaulted when absent, per the append-only contract.
      self.hasTrailingSeparator =
        try c.decodeIfPresent(Bool.self, forKey: .hasTrailingSeparator)
        ?? false
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    // Keep `_storage` in old-normal form so old decoders accept it: strip the
    // removable trailing separator, if any. Structural anchor separators are
    // not removable and stay in `_storage` (the setter no-ops on them), so
    // `stripped != self` is true only for the removable case.
    let stripped = withoutTrailingSeparator()
    let hadTrailingSeparator = (stripped != self)
    try container.encode(stripped._systemStringStorage, forKey: ._storage)

    // Always emit `_v2` (append-only contract; no omit-when-default check).
    try container.encode(
      _V2(hasTrailingSeparator: hadTrailingSeparator), forKey: ._v2)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let storage = try container.decode(SystemString.self, forKey: ._storage)
    // SystemString's decoder has already validated storage invariants on
    // untrusted input, matching the old explicit FilePath decoder.
    //
    // Construction goes through the stdlib copy's normalizing funnel: every
    // payload the old decoder accepted still decodes. The stored byte spelling
    // is the copy's normal form (which for old-normal input matches).
    var path = FilePath(storage)

    // Absent `_v2` (old / v1 archives) defaults every field, reproducing old
    // behavior. Present `_v2` re-applies the new-only distinctions.
    if let v2 = try container.decodeIfPresent(_V2.self, forKey: ._v2) {
      if v2.hasTrailingSeparator {
        path.hasTrailingSeparator = true
      }
    }
    self = path
  }
}

// Component and Root historically got their Codable synthesized over their
// stored properties, via the internal `_StrSlice` protocol's Codable
// requirement:
//
//   Component = { _path: FilePath, _range: Range<SystemString.Index> }
//   Root      = { _path: FilePath, _rootEnd: SystemString.Index }
//
// with SystemString.Index == Array<SystemChar>.Index == Int. On the wire:
//
//   Component: { "_path": <FilePath>, "_range": [lower, upper] }
//   Root:      { "_path": <FilePath>, "_rootEnd": N }
//
// (Range's stdlib Codable uses an unkeyed container: lower, then upper.)
//
// Two things to keep straight.
//
// DECODE: the offsets index the ENCODED bytes. The old FilePath decoder did
// not normalize — it validated and rejected — so `_path`'s stored bytes are
// exactly what the offsets were computed against. Decoding `_path` as a
// FilePath here would run the copy's normalizing funnel and shift those bytes
// out from under the offsets: old stored "/./foo" verbatim with a Component
// `_range` of 3..<6, and the copy normalizes that to "/foo", where 3..<6 is
// out of bounds. So we reach into `_path`'s nested `{_storage:}` container,
// take the raw SystemString, slice THAT, and only then normalize the slice
// into a Component/Root.
//
// ENCODE: the copy's Component and Root cannot reproduce the old `_path`. The
// originating path is FilePath-internal (Component's `_path`/`_range`,
// Anchor's `_path`) and invisible across the module boundary, so `_path` is
// synthesized from the value's own bytes with the offsets spanning it. Old
// swift-system decodes that to an equal value — its `==` and `hash` are
// slice-only — so the format is preserved even though the payload is narrower
// than old would have emitted for the same value.

// The old `_path` payload is `{ "_storage": SystemString }`. Pulling the raw
// SystemString out directly is what keeps the offsets meaningful; see DECODE
// above.
private enum _PathStorageKeys: String, CodingKey {
  case _storage
}

extension KeyedDecodingContainer {
  fileprivate func _decodeRawPathStorage(
    forKey key: Key
  ) throws -> SystemString {
    let pathContainer = try nestedContainer(
      keyedBy: _PathStorageKeys.self, forKey: key)
    // SystemString's own decoder validates its invariants on untrusted input.
    return try pathContainer.decode(SystemString.self, forKey: ._storage)
  }
}

// Shared by Component and Root: synthesize the `_path` payload from a slice's
// own bytes. Throws when normalization would not reproduce those bytes, i.e.
// when the synthesized `_path` would not actually contain the value at the
// offsets we are about to write. On Linux and Darwin this cannot fire: slice
// bytes are non-empty and separator-free, separator coalescing is a no-op on
// them, and the dot rules keep a leading `.` on a rootless path and always
// keep `..`. On Windows it fires for a component of a verbatim (\\?\) path
// containing `/`, which is a component byte there but a separator everywhere
// else — a value the old format has no encoding for either, since old
// `Component.init?(SystemString)` would have split it and returned nil.
@available(System 0.0.2, *)
private func _synthesizePathPayload<T>(
  for value: T,
  bytes: [FilePath.CodeUnit],
  codingPath: [any CodingKey]
) throws -> FilePath {
  let path = FilePath(_normalizing: bytes)
  guard path._cuArray == bytes else {
    throw EncodingError.invalidValue(
      value,
      EncodingError.Context(
        codingPath: codingPath,
        debugDescription: """
          Bytes do not survive path normalization, so the historical \
          {_path, _range} encoding cannot represent this value. This fires on \
          Windows for components of verbatim (\\\\?\\) paths containing '/'. \
          Such values have no old-format encoding.
          """))
  }
  return path
}

@available(System 0.0.2, *)
extension FilePath.Component: Codable {
  private enum CodingKeys: String, CodingKey {
    case _path
    case _range
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let bytes = _codeUnits
    let path = try _synthesizePathPayload(
      for: self, bytes: bytes, codingPath: container.codingPath)
    try container.encode(path, forKey: ._path)
    // The synthesized path holds exactly this component, so the historical
    // offsets into it span the whole storage.
    try container.encode(0 ..< bytes.count, forKey: ._range)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw = try container._decodeRawPathStorage(forKey: ._path)
    let range = try container.decode(
      Range<SystemString.Index>.self, forKey: ._range)
    // Slice the RAW bytes, then normalize. Not the other way around.
    guard range.lowerBound >= raw.startIndex,
          range.upperBound <= raw.endIndex,
          !range.isEmpty,
          let component = FilePath.Component(raw[range].map { $0.rawValue })
    else {
      throw DecodingError.dataCorruptedError(
        forKey: ._range, in: container,
        debugDescription:
          "_range does not select a single path component from _path")
    }
    self = component
  }
}

@available(System 0.0.2, *)
extension FilePath.Root: Codable {
  private enum CodingKeys: String, CodingKey {
    case _path
    case _rootEnd
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let bytes = _codeUnits
    let path = try _synthesizePathPayload(
      for: self, bytes: bytes, codingPath: container.codingPath)
    try container.encode(path, forKey: ._path)
    // Old `Root._range` was `(..<_rootEnd)`, so `_rootEnd` is the root's byte
    // count. The synthesized path is root-only, so that is its whole storage.
    try container.encode(bytes.count, forKey: ._rootEnd)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw = try container._decodeRawPathStorage(forKey: ._path)
    let rootEnd = try container.decode(
      SystemString.Index.self, forKey: ._rootEnd)
    // Slice the RAW bytes, then normalize. `rootEnd > startIndex` mirrors the
    // old Root invariant check.
    guard rootEnd > raw.startIndex,
          rootEnd <= raw.endIndex,
          let root = FilePath.Root(raw[..<rootEnd].map { $0.rawValue })
    else {
      throw DecodingError.dataCorruptedError(
        forKey: ._rootEnd, in: container,
        debugDescription: "_rootEnd does not select a path root from _path")
    }
    self = root
  }
}
