/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// TODO: Below should return an optional of what was eaten

extension Slice where Element: Equatable {
  // PORT DEDUP: `_eat(if:)`, `_eat(_:)`, and `_eatUntil(_ idx:)` were defined
  // here for the two-module prep; folded into one module they collide with the
  // byte-identical primitives in FilePathInternals.swift, so they're deleted in
  // favor of the base's. The derived helpers below (`_eat(asserting:)`,
  // `_eatThrough`, `_eatUntil(_ e:)`) call those base primitives.

  internal mutating func _eat(asserting e: Element) {
    let p = _eat(e)
    assert(p != nil)
  }

  internal mutating func _eatThrough(_ idx: Index) -> Slice {
    precondition(idx >= startIndex && idx <= endIndex)
    guard idx != endIndex else {
      defer { self = self[endIndex ..< endIndex] }
      return self
    }
    defer { self = self[index(after: idx)...] }
    return self[...idx]
  }

  // If `e` is present, eat up to first occurrence of `e`
  internal mutating func _eatUntil(_ e: Element) -> Slice? {
    guard let idx = self.firstIndex(of: e) else { return nil }
    return _eatUntil(idx)
  }

  // If `e` is present, eat up to and through first occurrence of `e`
  internal mutating func _eatThrough(_ e: Element) -> Slice? {
    guard let idx = self.firstIndex(of: e) else { return nil }
    return _eatThrough(idx)
  }
}
