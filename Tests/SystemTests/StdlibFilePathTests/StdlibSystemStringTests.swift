/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// _SystemString is the null-terminated byte buffer that backs _StdlibFilePath.
// Its core invariant: storage is non-empty, the last byte is `._null`,
// and there are no other null bytes anywhere else. The user-visible
// length is `storage.count - 1` (the null doesn't count).
//
// These tests exercise the RangeReplaceableCollection surface
// (replaceSubrange, append, insert, remove) and confirm the null
// invariant is preserved across every flavor of mutation. These are
// platform-independent and never go through the platform seam, hence a
// separate top-level suite.

@Suite
struct SystemStringTests {

  // MARK: - Helpers

  /// Asserts the null invariant: storage ends with `._null` and
  /// contains no other null bytes. Returns the user-visible bytes.
  private func _checkAndExtract(
    _ s: _SystemString,
    _ sourceLocation: SourceLocation = #_sourceLocation
  ) -> [_StdlibFilePath.CodeUnit] {
    let storage = s.nullTerminatedStorage
    expectFalse(storage.isEmpty, "storage must be non-empty",
            sourceLocation: sourceLocation)
    expectEqual(storage.last, ._null, "last byte must be null",
            sourceLocation: sourceLocation)
    expectFalse(storage.dropLast().contains(._null),
            "no embedded nulls before the terminator",
            sourceLocation: sourceLocation)
    expectEqual(s.count, storage.count - 1,
            "user-visible length excludes terminator",
            sourceLocation: sourceLocation)
    return Array(s)
  }

  private func _make(_ bytes: [Int]) -> _SystemString {
    _SystemString(bytes.map { _StdlibFilePath.CodeUnit($0) })
  }

  // MARK: - Initialization

  @Test
  func defaultInitIsEmptyButTerminated() {
    let s = _SystemString()
    expectEqual(_checkAndExtract(s), [])
    expectTrue(s.isEmpty)
    expectEqual(s.count, 0)
  }

  @Test
  func initFromEmptyCollection() {
    let s = _SystemString([] as [_StdlibFilePath.CodeUnit])
    expectEqual(_checkAndExtract(s), [])
  }

  @Test
  func initFromBytesAppendsNull() {
    let s = _make([0x41, 0x42, 0x43])
    let bytes = _checkAndExtract(s)
    expectEqual(bytes.map(Int.init), [0x41, 0x42, 0x43])
    expectEqual(s.nullTerminatedStorage.count, 4)
  }

  @Test
  func initFromBytesEndingInNullDoesntDouble() {
    let s = _SystemString(nullTerminatedStorage:
      [_StdlibFilePath.CodeUnit(0x41), _StdlibFilePath.CodeUnit(0x42), ._null])
    let bytes = _checkAndExtract(s)
    expectEqual(bytes.map(Int.init), [0x41, 0x42])
    expectEqual(s.nullTerminatedStorage.count, 3)
  }

  // MARK: - Indexing boundaries

  @Test
  func endIndexIsBeforeNullByte() {
    let s = _make([0x41, 0x42, 0x43])
    expectEqual(s.endIndex, 3)
    expectEqual(s.nullTerminatedStorage[s.endIndex], ._null)
    // Iteration stops before the null
    expectEqual(Array(s).count, 3)
  }

  @Test
  func emptyStringEndIndexEqualsStartIndex() {
    let s = _SystemString()
    expectEqual(s.startIndex, s.endIndex)
    expectEqual(s.nullTerminatedStorage[s.endIndex], ._null)
  }

  // MARK: - replaceSubrange

  @Test
  func replaceSubrangeMiddleSameSize() {
    var s = _make([0x41, 0x42, 0x43, 0x44])
    s.replaceSubrange(1..<3, with: [_StdlibFilePath.CodeUnit(0x58), _StdlibFilePath.CodeUnit(0x59)])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x58, 0x59, 0x44])
  }

  @Test
  func replaceSubrangeMiddleGrows() {
    var s = _make([0x41, 0x42, 0x43])
    s.replaceSubrange(1..<2, with: [
      _StdlibFilePath.CodeUnit(0x58), _StdlibFilePath.CodeUnit(0x59), _StdlibFilePath.CodeUnit(0x5A),
    ])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x58, 0x59, 0x5A, 0x43])
  }

  @Test
  func replaceSubrangeMiddleShrinks() {
    var s = _make([0x41, 0x42, 0x43, 0x44, 0x45])
    s.replaceSubrange(1..<4, with: [_StdlibFilePath.CodeUnit(0x58)])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x58, 0x45])
  }

  @Test
  func replaceSubrangeAtFront() {
    var s = _make([0x41, 0x42, 0x43])
    s.replaceSubrange(0..<1, with: [_StdlibFilePath.CodeUnit(0x58), _StdlibFilePath.CodeUnit(0x59)])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x58, 0x59, 0x42, 0x43])
  }

  @Test
  func replaceSubrangeAtEndIndex() {
    // Replacing range at endIndex is a pure insertion; null stays.
    var s = _make([0x41, 0x42])
    s.replaceSubrange(2..<2, with: [_StdlibFilePath.CodeUnit(0x58)])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x58])
  }

  @Test
  func replaceSubrangeFullToEnd() {
    // Range running to endIndex must not consume the null byte.
    var s = _make([0x41, 0x42, 0x43])
    s.replaceSubrange(1..<3, with: [_StdlibFilePath.CodeUnit(0x58)])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x58])
  }

  @Test
  func replaceSubrangeWholeStringWithEmpty() {
    var s = _make([0x41, 0x42, 0x43])
    s.replaceSubrange(0..<3, with: [] as [_StdlibFilePath.CodeUnit])
    expectEqual(_checkAndExtract(s), [])
  }

  @Test
  func replaceSubrangeWholeStringWithBytes() {
    var s = _make([0x41, 0x42, 0x43])
    s.replaceSubrange(0..<3, with: [
      _StdlibFilePath.CodeUnit(0x58), _StdlibFilePath.CodeUnit(0x59),
    ])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x58, 0x59])
  }

  @Test
  func replaceSubrangeEmptyRangeWithEmptyIsNoOp() {
    var s = _make([0x41, 0x42])
    s.replaceSubrange(1..<1, with: [] as [_StdlibFilePath.CodeUnit])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42])
  }

  @Test
  func replaceSubrangeOnEmptyString() {
    var s = _SystemString()
    s.replaceSubrange(0..<0, with: [
      _StdlibFilePath.CodeUnit(0x41), _StdlibFilePath.CodeUnit(0x42),
    ])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42])
  }

  // MARK: - append (default RRC impl)

  @Test
  func appendSingleByte() {
    var s = _make([0x41])
    s.append(_StdlibFilePath.CodeUnit(0x42))
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42])
  }

  @Test
  func appendToEmpty() {
    var s = _SystemString()
    s.append(_StdlibFilePath.CodeUnit(0x41))
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41])
  }

  @Test
  func appendContentsOfCollection() {
    var s = _make([0x41])
    s.append(contentsOf: [
      _StdlibFilePath.CodeUnit(0x42), _StdlibFilePath.CodeUnit(0x43),
    ])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x43])
  }

  @Test
  func appendContentsOfEmpty() {
    var s = _make([0x41])
    s.append(contentsOf: [] as [_StdlibFilePath.CodeUnit])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41])
  }

  // MARK: - insert

  @Test
  func insertAtStart() {
    var s = _make([0x42, 0x43])
    s.insert(_StdlibFilePath.CodeUnit(0x41), at: 0)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x43])
  }

  @Test
  func insertAtMiddle() {
    var s = _make([0x41, 0x43])
    s.insert(_StdlibFilePath.CodeUnit(0x42), at: 1)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x43])
  }

  @Test
  func insertAtEndIndex() {
    var s = _make([0x41, 0x42])
    s.insert(_StdlibFilePath.CodeUnit(0x43), at: 2)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x43])
  }

  @Test
  func insertContentsOfAtMiddle() {
    var s = _make([0x41, 0x44])
    s.insert(contentsOf: [
      _StdlibFilePath.CodeUnit(0x42), _StdlibFilePath.CodeUnit(0x43),
    ], at: 1)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x43, 0x44])
  }

  @Test
  func insertContentsOfAtEnd() {
    var s = _make([0x41, 0x42])
    s.insert(contentsOf: [
      _StdlibFilePath.CodeUnit(0x43), _StdlibFilePath.CodeUnit(0x44),
    ], at: 2)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x43, 0x44])
  }

  // MARK: - remove

  @Test
  func removeFirst() {
    var s = _make([0x41, 0x42, 0x43])
    let removed = s.removeFirst()
    expectEqual(removed, _StdlibFilePath.CodeUnit(0x41))
    expectEqual(_checkAndExtract(s).map(Int.init), [0x42, 0x43])
  }

  @Test
  func removeLast() {
    var s = _make([0x41, 0x42, 0x43])
    let removed = s.removeLast()
    expectEqual(removed, _StdlibFilePath.CodeUnit(0x43))
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42])
  }

  @Test
  func removeSubrangeMiddle() {
    var s = _make([0x41, 0x42, 0x43, 0x44])
    s.removeSubrange(1..<3)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x44])
  }

  @Test
  func removeSubrangeToEnd() {
    var s = _make([0x41, 0x42, 0x43])
    s.removeSubrange(1..<3)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41])
  }

  @Test
  func removeAll() {
    var s = _make([0x41, 0x42, 0x43])
    s.removeAll()
    expectEqual(_checkAndExtract(s), [])
  }

  @Test
  func removeAllOnEmpty() {
    var s = _SystemString()
    s.removeAll()
    expectEqual(_checkAndExtract(s), [])
  }

  // MARK: - Subscript

  @Test
  func subscriptReadAtIndices() {
    let s = _make([0x41, 0x42, 0x43])
    expectEqual(s[0], _StdlibFilePath.CodeUnit(0x41))
    expectEqual(s[1], _StdlibFilePath.CodeUnit(0x42))
    expectEqual(s[2], _StdlibFilePath.CodeUnit(0x43))
  }

  @Test
  func subscriptSetMiddle() {
    var s = _make([0x41, 0x42, 0x43])
    s[1] = _StdlibFilePath.CodeUnit(0x58)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x58, 0x43])
  }

  // MARK: - Sequenced operations (the patterns Decomposition.swift uses)

  @Test
  func truncateThenAppendBytes() {
    // Mirrors the components-setter pattern: removeSubrange to a
    // boundary, then append the contribution. Null must stay at end.
    var s = _make([0x41, 0x42, 0x43, 0x44, 0x45])
    s.removeSubrange(2..<5)
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42])
    s.append(_StdlibFilePath.CodeUnit(0x2F))  // separator-shaped byte
    s.append(contentsOf: [
      _StdlibFilePath.CodeUnit(0x58), _StdlibFilePath.CodeUnit(0x59),
    ])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x41, 0x42, 0x2F, 0x58, 0x59])
  }

  @Test
  func replaceFrontThenInsert() {
    // Mirrors the anchor-setter pattern: replace [0..<rootEnd] then
    // maybe insert a separator just after. Null stays at end.
    var s = _make([0x41, 0x42, 0x43, 0x44])
    s.replaceSubrange(0..<2, with: [
      _StdlibFilePath.CodeUnit(0x58), _StdlibFilePath.CodeUnit(0x59),
      _StdlibFilePath.CodeUnit(0x5A),
    ])
    expectEqual(_checkAndExtract(s).map(Int.init), [0x58, 0x59, 0x5A, 0x43, 0x44])
    s.insert(_StdlibFilePath.CodeUnit(0x2F), at: 3)
    expectEqual(_checkAndExtract(s).map(Int.init), [
      0x58, 0x59, 0x5A, 0x2F, 0x43, 0x44,
    ])
  }

  @Test
  func splicePreservesNullAcrossManyOps() {
    var s = _make([0x41, 0x42, 0x43, 0x44, 0x45])
    s.replaceSubrange(1..<3, with: [_StdlibFilePath.CodeUnit(0x58)])
    s.append(_StdlibFilePath.CodeUnit(0x59))
    s.insert(_StdlibFilePath.CodeUnit(0x5A), at: 0)
    s.removeFirst()
    s.removeLast()
    s.replaceSubrange(0..<s.count, with: [] as [_StdlibFilePath.CodeUnit])
    s.append(contentsOf: [_StdlibFilePath.CodeUnit(0x60)])
    // After all that, null still at end and only at end.
    expectEqual(_checkAndExtract(s).map(Int.init), [0x60])
  }
}
