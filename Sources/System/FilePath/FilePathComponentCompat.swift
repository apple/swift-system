/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// PORT SHIM: internal helpers for FilePath.Component that the old package
// API (Component.extension / Component.stem in FilePathSyntax.swift) relies
// on. The SE-0529 copy has no stem/extension notion, so these are the old
// swift-system algorithms retyped from the old substrate (SystemChar,
// Slice<SystemString>) onto the copy's (FilePath.CodeUnit,
// Slice<_SystemString>). Algorithm bodies are unchanged from the originals
// in FilePathComponents.swift (now PORT-CLOBBERED there).

@available(SwiftStdlib 9999, *)
extension Slice where Base == _SystemString {
  /// Decode this slice's code units as a String. Mirrors
  /// `_SystemString.string` in the stdlib copy.
  internal var string: String {
    withCodeUnits { codeUnits in
      codeUnits.withMemoryRebound(to: FilePath._Encoding.CodeUnit.self) {
        String(decoding: $0, as: FilePath._Encoding.self)
      }
    }
  }
}

@available(SwiftStdlib 9999, *)
extension FilePath.Component {
  // The index of the `.` denoting an extension
  internal func _extensionIndex() -> _SystemString.Index? {
    guard kind == .regular,
          let idx = _slice.lastIndex(of: ._dot),
          idx != _slice.startIndex
    else { return nil }

    return idx
  }

  internal func _extensionRange() -> Range<_SystemString.Index>? {
    guard let idx = _extensionIndex() else { return nil }
    return _slice.index(after: idx) ..< _slice.endIndex
  }

  internal func _stemRange() -> Range<_SystemString.Index> {
    _slice.startIndex ..< (_extensionIndex() ?? _slice.endIndex)
  }
}
