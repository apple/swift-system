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
extension FilePath.Component {
  /// The index, into this component's code units (`_codeUnits`), of the `.`
  /// that denotes an extension — or `nil` if there is none (no interior `.`,
  /// a leading-only `.`, or a special `.`/`..` component).
  internal func _extensionIndex(_ bytes: [FilePath.CodeUnit]) -> Int? {
    guard kind == .regular,
          let idx = bytes.lastIndex(of: ._dot),
          idx != bytes.startIndex
    else { return nil }

    return idx
  }
}
