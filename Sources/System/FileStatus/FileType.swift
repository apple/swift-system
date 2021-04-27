/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// FIXME: Document
@frozen
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct FileType: RawRepresentable {
  /// The raw C file type.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Mode

  /// Create a strongly-typed file type from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Mode) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  private init(_ raw: CInterop.Mode) { self.init(rawValue: raw) }

  /// Named pipe (fifo)
  ///
  /// The corresponding C constant is `S_IFIFO`
  @_alwaysEmitIntoClient
  public static var fifo: FileType { FileType(_S_IFIFO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "fifo")
  public static var S_IFIFO: FileType { fifo }

  /// Character special
  ///
  /// The corresponding C constant is `S_IFCHR`
  @_alwaysEmitIntoClient
  public static var characterDevice: FileType { FileType(_S_IFCHR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "characterDevice")
  public static var S_IFCHR: FileType { characterDevice }

  /// Directory
  ///
  /// The corresponding C constant is `S_IFDIR`
  @_alwaysEmitIntoClient
  public static var directory: FileType { FileType(_S_IFDIR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "directory")
  public static var S_IFDIR: FileType { directory }

  /// Block special
  ///
  /// The corresponding C constant is `S_IFBLK`
  @_alwaysEmitIntoClient
  public static var blockDevice: FileType { FileType(_S_IFBLK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "blockDevice")
  public static var S_IFBLK: FileType { blockDevice }

  /// Regular
  ///
  /// The corresponding C constant is `S_IFREG`
  @_alwaysEmitIntoClient
  public static var regular: FileType { FileType(_S_IFREG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "regular")
  public static var S_IFREG: FileType { regular }

  /// Symbolic link
  ///
  /// The corresponding C constant is `S_IFLNK`
  @_alwaysEmitIntoClient
  public static var symbolicLink: FileType { FileType(_S_IFLNK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "symbolicLink")
  public static var S_IFLNK: FileType { symbolicLink }

  /// Socket
  ///
  /// The corresponding C constant is `S_IFSOCK`
  @_alwaysEmitIntoClient
  public static var socket: FileType { FileType(_S_IFSOCK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "socket")
  public static var S_IFSOCK: FileType { socket }

  /// Whiteout
  ///
  /// The corresponding C constant is `S_IFWHT`
  @_alwaysEmitIntoClient
  // FIXME: rename with inclusive language
  public static var whiteout: FileType { FileType(_S_IFWHT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "whiteout")
  public static var S_IFWHT: FileType { whiteout }
}

#endif
