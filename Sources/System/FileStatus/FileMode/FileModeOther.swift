/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// FIXME: Rename
// FIXME: Document
@frozen
// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct FileModeOther: OptionSet {
  /// The raw C file mode other.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Mode

  /// Create a strongly-typed file mode other from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Mode) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  private init(_ raw: CInterop.Mode) { self.init(rawValue: raw) }

  /// Indicates that the file is executed as the owner.
  ///
  /// For more information, see the `setuid(2)` man page.
  @_alwaysEmitIntoClient
  public static var setUserID: FileModeOther { FileModeOther(0o4000) }

  /// Indicates that the file is executed as the group.
  ///
  /// For more information, see the `setgid(2)` man page.
  @_alwaysEmitIntoClient
  public static var setGroupID: FileModeOther { FileModeOther(0o2000) }

  /// Indicates that executable's text segment
  /// should be kept in swap space even after it exits.
  ///
  /// For more information, see the `chmod(2)` man page's
  /// discussion of `S_ISVTX` (the sticky bit).
  @_alwaysEmitIntoClient
  public static var saveText: FileModeOther { FileModeOther(0o1000) }
}

#endif
