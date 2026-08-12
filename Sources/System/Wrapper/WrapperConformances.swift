/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Conformances

// MARK: Equatable, Hashable, Comparable

// All three get their own switch rather than being derived from `string` or from
// the code units. Equality is one of the things SE-0529 revisits: the historical
// implementation compares normalized storage bytes, while SE-0529 compares by
// decomposition, so paths that differ only in a trailing separator can compare
// differently between eras. Deriving here would impose one era's answer on both.

@available(SwiftStdlib 9999, *)
extension FilePath: Equatable {
  public static func == (lhs: FilePath, rhs: FilePath) -> Bool {
    switch (lhs._backing, rhs._backing) {
    case (.stdlib(let l), .stdlib(let r)): return l == r
    case (.swiftSystem(let l), .swiftSystem(let r)): return l == r
    default: _filePathBackingMismatch()
    }
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch _backing {
    case .stdlib(let p): hasher.combine(p)
    case .swiftSystem(let p): hasher.combine(p)
    }
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath: Comparable {
  public static func < (lhs: FilePath, rhs: FilePath) -> Bool {
    switch (lhs._backing, rhs._backing) {
    case (.stdlib(let l), .stdlib(let r)): return l < r
    case (.swiftSystem(let l), .swiftSystem(let r)):
      // The historical implementation has no `Comparable` conformance, so
      // order by content the way its own storage does.
      return l.string < r.string
    default: _filePathBackingMismatch()
    }
  }
}

// MARK: CustomStringConvertible

@available(SwiftStdlib 9999, *)
extension FilePath: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    switch _backing {
    case .stdlib(let p): return p.description
    case .swiftSystem(let p): return p.description
    }
  }

  public var debugDescription: String { description.debugDescription }
}

// MARK: Codable

// Given its own switch, and deliberately strict about era.
//
// A path's encoded form is just its string, so nothing in the payload records
// which implementation produced it. That makes a cross-era decode silently
// lossy rather than loudly wrong: the bytes would round-trip through the other
// era's normalization and could come back as a different path. Since the
// backing selection is process-wide, any value this process decodes must belong
// to the active era, so the safe thing is to decode through the active backing
// and let its own decoder reject what it cannot represent.
//
// The cross-era hazard the wrapper *can* detect is a value that was encoded by
// one era and is being compared or combined with values from the other, which
// is what `_filePathBackingMismatch` reports throughout.

@available(SwiftStdlib 9999, *)
extension FilePath: Codable {
  public func encode(to encoder: any Encoder) throws {
    switch _backing {
    case .stdlib(let p): try p.encode(to: encoder)
    case .swiftSystem(let p): try p.encode(to: encoder)
    }
  }

  public init(from decoder: any Decoder) throws {
    // Decode through the active backing. If the payload was written by the
    // other era and its content is not representable here, the backing's own
    // decoder is the right thing to raise the objection: it knows its era's
    // validity rules, and the wrapper does not.
    if _FilePathBackingSelection.useStdlib {
      self.init(_backing: .stdlib(try _StdlibFilePath(from: decoder)))
    } else {
      self.init(_backing: .swiftSystem(try _SwiftSystemFilePath(from: decoder)))
    }
  }
}
