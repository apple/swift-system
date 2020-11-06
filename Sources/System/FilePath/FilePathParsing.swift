/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

private typealias SystemChar = SystemString.Element

// The separator we use internally
private var genericSeparator: SystemChar {
  numericCast(UInt8(ascii: "/"))
}

// The platform preferred separator
//
// TODO: Make private
private var platformSeparator: SystemChar {
#if os(Windows)
  return numericCast(UInt8(ascii: "\\"))
#else
  return genericSeparator
#endif
}

// TODO: Make private
private func isSeparator(_ c: SystemChar) -> Bool {
  c == genericSeparator || c == platformSeparator
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  // For invariant enforcing/checking. Should always return `nil` on
  // a fully-formed path
  private func _trailingSepIdx() -> Storage.Index? {
    guard bytes.count > 2 else { return nil }
    let idx = bytes.index(bytes.endIndex, offsetBy: -2)
    return isSeparator(bytes[idx]) ? idx : nil
  }

  // Enforce invariants by removing a trailing separator.
  //
  // Precondition: There is exactly zero or one trailing slashes
  //
  // Postcondition: Path is root, or has no trailing separator
  private mutating func _removeTrailingSeparator() {
    assert(bytes.last == 0, "even empty paths have null termiantor")
    defer { assert(_trailingSepIdx() == nil) }

    guard let sepIdx = _trailingSepIdx() else { return }
    bytes.remove(at: sepIdx)

  }

  // Enforce invariants by normalizing the internal separator representation.
  //
  // 1) Normalize all separators to platform-preferred separator
  // 2) Drop redundant separators
  // 3) Drop trailing separators
  //
  // On Windows, UNC and device paths are allowed to begin with two separators
  //
  // The POSIX standard does allow two leading separators to
  // denote implementation-specific handling, but Darwin and Linux
  // do not treat these differently.
  //
  internal mutating func _normalizeSeparators() {
    var (writeIdx, readIdx) = (bytes.startIndex, bytes.startIndex)
    #if os(Windows)
    // TODO: skip over two leading backslashes
    #endif

    while readIdx < bytes.endIndex {
      assert(writeIdx <= readIdx)

      let wasSeparator = isSeparator(bytes[readIdx])
      if wasSeparator {
        bytes[readIdx] = platformSeparator
      }
      bytes.swapAt(writeIdx, readIdx)
      bytes.formIndex(after: &writeIdx)
      bytes.formIndex(after: &readIdx)

      if readIdx == bytes.endIndex { break }

      while wasSeparator && isSeparator(bytes[readIdx]) {
        bytes.formIndex(after: &readIdx)
        if readIdx == bytes.endIndex { break }
      }
    }
    bytes.removeLast(bytes.distance(from: writeIdx, to: readIdx))
    self._removeTrailingSeparator()
  }

  internal func _invariantCheck() {
  #if DEBUG
    precondition(bytes.last! == 0)

    // TODO: Should this be a hard trap unconditionally??
    precondition(bytes.firstIndex(of: 0) == bytes.count - 1)

    var normal = self
    normal._normalizeSeparators()
    precondition(self == normal)
    precondition(self._trailingSepIdx() == nil)

  #endif // DEBUG
  }
}

