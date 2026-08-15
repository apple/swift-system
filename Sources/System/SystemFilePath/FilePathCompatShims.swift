/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// PORT SHIM: in-module reprovisions of the FilePath-internal helpers the compat
// layer used to reach across the module boundary. Everything here is expressed
// on FilePath's PUBLIC API (`codeUnits` / `nullTerminatedCodeUnits` spans,
// `FilePath.separator`) or on generic code-unit sequences — no FilePath
// internal (`_storage`, `_SystemString`, `_isSeparator`, `_platformSeparator`,
// `_Encoding`) is named.

// PORT DEDUP: `_platformSeparator`, `_isSeparator`, and the `_null` / `_dot` /
// `_slash` code-unit constants were reprovisioned here for the two-module prep,
// where the base's FilePath-internal versions weren't visible across the module
// boundary. Folded into one module they collide with the canonical definitions
// in FilePathParsing.swift and FilePathSystemString.swift, so they're deleted
// here in favor of the base's (verified byte-for-byte equivalent; the base also
// supplies `_backslash` / `_colon` / `_question` / `_at`).

// MARK: - Span materialization

/// Copy a code-unit span into an `Array` so it can be fed to the
/// `FilePath(_normalizing:)` funnel (which takes a `Sequence`, and `Span` is
/// not one) or iterated freely.
@available(SwiftStdlib 9999, *)
internal func _copyToArray(
  _ span: borrowing Span<FilePath.CodeUnit>
) -> [FilePath.CodeUnit] {
  var a = [FilePath.CodeUnit]()
  a.reserveCapacity(span.count)
  for i in span.indices { a.append(span[i]) }
  return a
}

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// This path's code units (no null terminator) as an `Array`.
  internal var _cuArray: [FilePath.CodeUnit] { _copyToArray(codeUnits) }
}

// MARK: - Platform-string (NUL-terminated C pointer) access

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// Calls `body` with a pointer to the path's null-terminated platform-string
  /// contents. Materializes the null-terminated code units and rebinds them to
  /// `CInterop.PlatformChar` (layout-identical to `FilePath.CodeUnit`).
  internal func _withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    let units = _copyToArray(nullTerminatedCodeUnits)
    return try units.withUnsafeBufferPointer { buf in
      try buf.baseAddress!.withMemoryRebound(
        to: CInterop.PlatformChar.self, capacity: buf.count
      ) { try body($0) }
    }
  }
}

// MARK: - Decode a code-unit sequence to String

@available(SwiftStdlib 9999, *)
extension Array where Element == FilePath.CodeUnit {
  /// Decode as `CInterop.PlatformUnicodeEncoding` (UTF-8 on Unix, UTF-16 on
  /// Windows), replacing ill-formed sequences with U+FFFD.
  internal var _decodedString: String {
    withUnsafeBufferPointer { buf in
      buf.withMemoryRebound(
        to: CInterop.PlatformUnicodeEncoding.CodeUnit.self
      ) { String(decoding: $0, as: CInterop.PlatformUnicodeEncoding.self) }
    }
  }
}

// MARK: - SystemString from raw code units

@available(SwiftStdlib 9999, *)
extension SystemString {
  /// Build a `SystemString` from raw (NUL-free) code units, adding the null
  /// terminator. Used to encode a component's / root's exact bytes.
  internal init(_codeUnits bytes: [FilePath.CodeUnit]) {
    self.init(
      nullTerminated: (bytes + [FilePath.CodeUnit._null]).map {
        SystemChar(rawValue: $0)
      })
  }
}
