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
extension SystemString {
  /// Convert from the stdlib copy's string representation.
  internal init(_ str: _SystemString) {
    self.init(
      nullTerminated: str.nullTerminatedStorage.map { SystemChar(rawValue: $0) }
    )
  }
}

@available(SwiftStdlib 9999, *)
extension _SystemString {
  /// Convert from the old package string representation.
  internal init(_ str: SystemString) {
    self.init(
      nullTerminated: str.nullTerminatedStorage.map { $0.rawValue }
    )
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Construct from the old package string representation.
  ///
  /// Goes through the copy's `_normalizing` funnel so the result satisfies
  /// the stdlib implementation's storage invariants (coalesced separators,
  /// normalized dots). Note this can store a different byte spelling than
  /// the old FilePath(SystemString) did.
  internal init(_ str: SystemString) {
    self.init(_normalizing: _SystemString(str))
  }

  /// View the copy's storage as the old package string representation.
  /// O(n) copy; port-transition use only.
  internal var _systemStringStorage: SystemString {
    SystemString(_storage)
  }
}

@available(SwiftStdlib 9999, *)
extension _SystemString {
  /// Calls `body` with a null-terminated platform-string view of the
  /// contents. Mirrors the old `SystemString.withPlatformString`;
  /// `FilePath.CodeUnit` and `CInterop.PlatformChar` are layout-identical
  /// on every platform (CChar on Unix, UInt16 on Windows).
  internal func withPlatformString<T>(
    _ f: (UnsafePointer<CInterop.PlatformChar>) throws -> T
  ) rethrows -> T {
    try withNullTerminatedCodeUnits { units in
      try units.baseAddress!.withMemoryRebound(
        to: CInterop.PlatformChar.self, capacity: units.count
      ) { pointer in
        assert(pointer[self.count] == 0)
        return try f(pointer)
      }
    }
  }
}
