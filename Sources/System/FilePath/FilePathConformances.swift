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

@available(System 0.0.1, *)
extension FilePath: Codable {
  private enum CodingKeys: String, CodingKey {
    case _storage
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(SystemString(_storage), forKey: ._storage)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let storage = try container.decode(SystemString.self, forKey: ._storage)
    // SystemString's decoder has already validated storage invariants on
    // untrusted input, matching the old explicit FilePath decoder.
    //
    // Construction goes through the stdlib copy's normalizing funnel: every
    // payload the old decoder accepted still decodes, but the stored byte
    // spelling is the copy's normal form, which can differ from the encoded
    // spelling. If byte-faithful round-trips are required instead, switch to
    // init(_storage:) plus a strict is-normal check (rejects some old
    // payloads).
    self.init(storage)
  }
}

// Historical wire format for Component and Root was synthesized over their
// stored properties: {_path, _range} and {_path, _rootEnd}, with integer
// indices into the encoded path's bytes. Decoding must slice those raw bytes
// BEFORE any normalization (the modern FilePath decode normalizes), so both
// decoders below read the path's storage through a raw mirror, slice, and
// reconstruct. Their Codable obligation comes via _StrSlice, so only the
// members are provided here, not the conformance.

// Raw mirror of FilePath's encoded form; decodes storage without normalizing.
private struct _EncodedFilePath: Codable {
  var _storage: SystemString
}

@available(System 0.0.2, *)
extension FilePath.Component {
  private enum CodingKeys: String, CodingKey {
    case _path, _range, _verbatimContext
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(_path, forKey: ._path)
    try container.encode(_range, forKey: ._range)
    // Additive vs the historical two-key format; old decoders ignore it.
    try container.encode(_verbatimContext, forKey: ._verbatimContext)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw = _SystemString(
      try container.decode(_EncodedFilePath.self, forKey: ._path)._storage)
    let range = try container.decode(Range<Int>.self, forKey: ._range)
    guard range.lowerBound >= raw.startIndex,
          range.upperBound <= raw.endIndex else {
      throw DecodingError.dataCorruptedError(
        forKey: ._range, in: container,
        debugDescription: "Component range outside encoded path storage")
    }
    var bytes = _SystemString()
    bytes.append(contentsOf: raw[range])
    // Reconstruction re-derives _verbatimContext from the bytes; the encoded
    // flag (absent in historical payloads) is not needed.
    guard let component = FilePath.Component(bytes) else {
      throw DecodingError.dataCorruptedError(
        forKey: ._range, in: container,
        debugDescription: "Encoded bytes do not form a single path component")
    }
    self = component
  }
}

@available(System 0.0.2, *)
extension FilePath.Root {
  private enum CodingKeys: String, CodingKey {
    case _path, _rootEnd
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(_path, forKey: ._path)
    try container.encode(_rootEnd, forKey: ._rootEnd)
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw = _SystemString(
      try container.decode(_EncodedFilePath.self, forKey: ._path)._storage)
    let rootEnd = try container.decode(Int.self, forKey: ._rootEnd)
    guard rootEnd > raw.startIndex, rootEnd <= raw.endIndex else {
      throw DecodingError.dataCorruptedError(
        forKey: ._rootEnd, in: container,
        debugDescription: "Root end outside encoded path storage")
    }
    var bytes = _SystemString()
    bytes.append(contentsOf: raw[raw.startIndex..<rootEnd])
    guard let root = FilePath.Root(bytes) else {
      throw DecodingError.dataCorruptedError(
        forKey: ._rootEnd, in: container,
        debugDescription: "Encoded bytes do not form a path root")
    }
    self = root
  }
}
