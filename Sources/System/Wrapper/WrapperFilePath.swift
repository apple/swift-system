/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - The wrapper
//
// `FilePath` is swift-system's public path type. It carries no path storage of
// its own: it holds one of two complete implementations and forwards every
// member to whichever is active.
//
//   .swiftSystem  the historical swift-system implementation, recovered at
//                 commit 8ac955b. The default, so existing behavior is what a
//                 client gets unless it opts in.
//   .stdlib       the SE-0529 implementation destined for the standard library.
//
// Forwarding is the whole design. The wrapper must not re-derive behavior that
// differs between the two eras, because the interesting differences all live in
// how a path is recomposed after an edit (appending, pushing,
// removeLastComponent, the component setters, normalization). Each backing
// already implements its own era's rules, so the wrapper's job is only to pick
// one and get out of the way.

// MARK: - Backing selection

/// Chooses which implementation backs every `FilePath` in this process.
///
/// The environment default is read once, on first use, and cached. A client can
/// override it at runtime with `_setFilePathSemanticMode`, which affects only
/// `FilePath`s constructed afterward: an existing instance keeps the backing it
/// was built with, so a path never changes era underneath its owner.
@available(SwiftStdlib 9999, *)
internal enum _FilePathBackingSelection {
  /// True when `_SWIFT_SYSTEM_NEW_FILEPATH` is present in the environment.
  ///
  /// Presence alone opts in, whatever the value. Absence keeps the historical
  /// implementation, which is the safe default.
  private static let envDefault: Bool = system_hasEnv(
    "_SWIFT_SYSTEM_NEW_FILEPATH")

  /// Opt-in override. `nil` means defer to `envDefault`.
  ///
  /// Mutated only by `_setFilePathSemanticMode`. Marked
  /// `nonisolated(unsafe)` rather than guarded: the intended use is a single
  /// selection made during start-up, before paths exist and before other
  /// threads run. Flipping it concurrently with `FilePath` construction is a
  /// data race and is the caller's responsibility to avoid.
  nonisolated(unsafe) internal static var _override: Bool? = nil

  internal static var useStdlib: Bool { _override ?? envDefault }
}

/// Which set of path semantics `FilePath` implements.
@available(SwiftStdlib 9999, *)
public enum _FilePathSemanticMode {
  /// swift-system's historical semantics. The default.
  case legacy

  /// The SE-0529 semantics destined for the standard library.
  case stdlibNew
}

/// Selects the path semantics used by `FilePath`s constructed after this call.
///
/// Overrides the `_SWIFT_SYSTEM_NEW_FILEPATH` environment default, which
/// otherwise sets the mode for the lifetime of the process.
///
/// Instances built before the switch keep their original backing. Combining a
/// pre-switch and a post-switch value in one operation traps: see
/// `_filePathBackingMismatch`. Call this once during start-up, before any
/// `FilePath` exists.
@available(SwiftStdlib 9999, *)
public func _setFilePathSemanticMode(_ mode: _FilePathSemanticMode) {
  _FilePathBackingSelection._override = (mode == .stdlibNew)
}

/// The only place the backing selection is read.
///
/// Both closures are written at every call site even though only one runs. That
/// is deliberate: it keeps the two eras' construction visibly paired, so a
/// reader can see what each does side by side.
@available(SwiftStdlib 9999, *)
internal func _filePathSelect<T>(
  stdlib: () -> T,
  swiftSystem: () -> T
) -> T {
  _FilePathBackingSelection.useStdlib ? stdlib() : swiftSystem()
}

// MARK: - FilePath

/// Represents a location in the file system.
@available(SwiftStdlib 9999, *)
public struct FilePath: Sendable {
  @usableFromInline
  internal enum Backing: Sendable {
    case stdlib(_StdlibFilePath)
    case swiftSystem(_SwiftSystemFilePath)
  }

  @usableFromInline
  internal var _backing: Backing

  @usableFromInline
  internal init(_backing: Backing) {
    self._backing = _backing
  }
}

// MARK: - Construction funnel

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// The single point where a `FilePath` is built from scratch.
  ///
  /// Every initializer in the wrapper routes through here or through
  /// `_makeIfSome`, so no initializer can accidentally hard-code a backing.
  internal static func _make(
    stdlib: () -> _StdlibFilePath,
    swiftSystem: () -> _SwiftSystemFilePath
  ) -> FilePath {
    _filePathSelect(
      stdlib: { FilePath(_backing: .stdlib(stdlib())) },
      swiftSystem: { FilePath(_backing: .swiftSystem(swiftSystem())) })
  }

  /// `_make` for failable initializers: the active backing decides, and its
  /// `nil` propagates.
  internal static func _makeIfSome(
    stdlib: () -> _StdlibFilePath?,
    swiftSystem: () -> _SwiftSystemFilePath?
  ) -> FilePath? {
    _filePathSelect(
      stdlib: { stdlib().map { FilePath(_backing: .stdlib($0)) } },
      swiftSystem: { swiftSystem().map { FilePath(_backing: .swiftSystem($0)) } })
  }
}

// MARK: - Backing access

/// Reports a value whose backing does not match the process-wide selection.
///
/// Reachable only by decoding a `FilePath` that a different era encoded; see
/// the `Codable` conformance, which diagnoses that case directly.
@available(SwiftStdlib 9999, *)
internal func _filePathBackingMismatch(
  _ what: String = "FilePath"
) -> Never {
  fatalError(
    """
    \(what) backing mismatch: this value was created by the other \
    implementation. A FilePath cannot mix the SE-0529 and historical \
    swift-system backings, because their path semantics differ.
    """)
}

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// The stdlib backing, or a trap when this value is swiftSystem-backed.
  internal var _stdlib: _StdlibFilePath {
    guard case .stdlib(let p) = _backing else { _filePathBackingMismatch() }
    return p
  }

  /// The swiftSystem backing, or a trap when this value is stdlib-backed.
  internal var _swiftSystem: _SwiftSystemFilePath {
    guard case .swiftSystem(let p) = _backing else { _filePathBackingMismatch() }
    return p
  }

  /// True when this value is backed by the SE-0529 implementation.
  internal var _isStdlibBacked: Bool {
    switch _backing {
    case .stdlib: return true
    case .swiftSystem: return false
    }
  }
}

// MARK: - Nested types

@available(SwiftStdlib 9999, *)
extension FilePath {
  /// The platform's path code unit: `CChar` on Unix, `UInt16` on Windows.
  public typealias CodeUnit = _StdlibFilePath.CodeUnit

  // Neither `Component` nor `Root` is a typealias. Both are thin dispatching
  // wrappers, declared in WrapperComponent.swift and WrapperRoot.swift, because
  // deciding whether a given string is one component (or one root) is
  // era-specific. See those files for the full reasoning.
}

// MARK: - Component code units

/// Copies a null-terminated platform string into a code-unit array, dropping
/// the terminator.
///
/// `CInterop.PlatformChar` and `FilePath.CodeUnit` are the same type on every
/// supported platform, so this is a copy and not a reinterpretation.
@available(SwiftStdlib 9999, *)
internal func _filePathCodeUnits(
  fromNulTerminated p: UnsafePointer<CInterop.PlatformChar>
) -> [FilePath.CodeUnit] {
  var out = [FilePath.CodeUnit]()
  var i = 0
  while p[i] != 0 {
    out.append(p[i])
    i += 1
  }
  return out
}

@available(SwiftStdlib 9999, *)
extension _SwiftSystemFilePath.Component {
  /// This component's code units, excluding any null terminator.
  ///
  /// Reads through `withPlatformString`, the backing's own public byte
  /// accessor, so this does not reach into the backing's internals.
  internal var _wrapperCodeUnits: [FilePath.CodeUnit] {
    withPlatformString { _filePathCodeUnits(fromNulTerminated: $0) }
  }
}

