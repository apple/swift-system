/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// PORT SHIM: in-module reprovisions of the _StdlibFilePath-internal helpers the compat
// layer used to reach across the module boundary. Everything here is expressed
// on _StdlibFilePath's PUBLIC API (`codeUnits` / `nullTerminatedCodeUnits` spans,
// `_StdlibFilePath.separator`) or on generic code-unit sequences. No _StdlibFilePath
// internal (`_storage`, `_SystemString`, `_isSeparator`, `_platformSeparator`,
// `_Encoding`) is named.

// MARK: - Separator helpers and code-unit constants (removed)

// `_platformSeparator`, `_isSeparator`, and the `_null` / `_dot` / `_slash`
// constants used to be reprovisioned here because the base's own copies were
// _StdlibFilePath-internal, across a module boundary. The base now compiles into this
// module and each reprovision was identical to the base's by construction: the
// base's public `separator` is defined as `{ _platformSeparator }`, and the
// constants reduce to the same `numericCast(UInt8(ascii:))`. So they are gone
// and every caller resolves to the base's.

// MARK: - Span materialization

/// Copy a code-unit span into an `Array` so it can be fed to the
/// `_StdlibFilePath(_normalizing:)` funnel (which takes a `Sequence`, and `Span` is
/// not one) or iterated freely.
@available(SwiftStdlib 9999, *)
internal func _copyToArray(
  _ span: borrowing Span<_StdlibFilePath.CodeUnit>
) -> [_StdlibFilePath.CodeUnit] {
  var a = [_StdlibFilePath.CodeUnit]()
  a.reserveCapacity(span.count)
  for i in span.indices { a.append(span[i]) }
  return a
}

@available(SwiftStdlib 9999, *)
extension _StdlibFilePath {
  /// This path's code units (no null terminator) as an `Array`.
  internal var _cuArray: [_StdlibFilePath.CodeUnit] { _copyToArray(codeUnits) }
}

// MARK: - Platform-string (NUL-terminated C pointer) access

@available(SwiftStdlib 9999, *)
extension _StdlibFilePath {
  /// Calls `body` with a pointer to the path's null-terminated platform-string
  /// contents. Materializes the null-terminated code units and rebinds them to
  /// `CInterop.PlatformChar` (layout-identical to `_StdlibFilePath.CodeUnit`).
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
extension Array where Element == _StdlibFilePath.CodeUnit {
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
  internal init(_codeUnits bytes: [_StdlibFilePath.CodeUnit]) {
    self.init(
      nullTerminated: (bytes + [_StdlibFilePath.CodeUnit._null]).map {
        SystemChar(rawValue: $0)
      })
  }
}
