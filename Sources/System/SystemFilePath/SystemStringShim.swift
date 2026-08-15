/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// PORT SHIM: bidirectional converters between the old package substrate
// (SystemString/SystemChar) and the SE-0529 stdlib copy's substrate
// (_SystemString/FilePath.CodeUnit).
//
// SystemChar.RawValue is CInterop.PlatformChar and FilePath.CodeUnit is
// CChar on Unix / UInt16 on Windows: the same underlying type on every
// platform, so conversion is a per-element rewrap, O(n) copy.
//
// Temporary by design: once one substrate wins (long-term plan: converge
// on _SystemString), these converters and their call sites are the
// mechanical removal list. Do not grow API on top of them.

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Construct from the old package string representation.
  ///
  /// Goes through the copy's `_normalizing` funnel so the result satisfies
  /// the stdlib implementation's storage invariants (coalesced separators,
  /// normalized dots). Note this can store a different byte spelling than
  /// the old FilePath(SystemString) did.
  internal init(_ str: SystemString) {
    // `SystemChar.rawValue` is `FilePath.CodeUnit` on every platform; the
    // SystemString collection excludes its null terminator, so these bytes
    // are NUL-free as `_normalizing` requires.
    self.init(_normalizing: str.map { $0.rawValue })
  }

  /// View the copy's storage as the old package string representation.
  /// O(n) copy; port-transition use only.
  internal var _systemStringStorage: SystemString {
    SystemString(
      nullTerminated: _copyToArray(nullTerminatedCodeUnits).map {
        SystemChar(rawValue: $0)
      })
  }
}
