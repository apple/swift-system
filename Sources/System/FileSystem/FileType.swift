//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// |------------------------|
// | Swift API to C Mapping |
// |----------------------------------------|
// | FileType         | Unix-like Platforms |
// |------------------|---------------------|
// | directory        | S_IFDIR             |
// | characterSpecial | S_IFCHR             |
// | blockSpecial     | S_IFBLK             |
// | regular          | S_IFREG             |
// | pipe             | S_IFIFO             |
// | symbolicLink     | S_IFLNK             |
// | socket           | S_IFSOCK            |
// |------------------|---------------------|
//
// |------------------------------------------------------------------|
// | FileType         | Darwin  | FreeBSD | Other Unix-like Platforms |
// |------------------|---------|---------|---------------------------|
// | whiteout         | S_IFWHT | S_IFWHT | N/A                       |
// |------------------|---------|---------|---------------------------|

#if !os(Windows)
/// A file type matching those contained in a C `mode_t`.
///
/// - Note: Only available on Unix-like platforms.
@frozen
// @available(System X.Y.Z, *)
public struct FileType: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw file-type bits from the C mode.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Mode

  /// Creates a strongly-typed file type from the raw C value.
  ///
  /// - Note: `rawValue` should only contain the mode's file-type bits. Otherwise,
  ///   use `FileMode(rawValue:)` to get a strongly-typed `FileMode`, then
  ///   call `.type` to get the properly masked `FileType`.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Mode) { self.rawValue = rawValue }

  /// Directory
  ///
  /// The corresponding C constant is `S_IFDIR`.
  @_alwaysEmitIntoClient
  public static var directory: FileType { FileType(rawValue: _S_IFDIR) }

  /// Character special device
  ///
  /// The corresponding C constant is `S_IFCHR`.
  @_alwaysEmitIntoClient
  public static var characterSpecial: FileType { FileType(rawValue: _S_IFCHR) }

  /// Block special device
  ///
  /// The corresponding C constant is `S_IFBLK`.
  @_alwaysEmitIntoClient
  public static var blockSpecial: FileType { FileType(rawValue: _S_IFBLK) }

  /// Regular file
  ///
  /// The corresponding C constant is `S_IFREG`.
  @_alwaysEmitIntoClient
  public static var regular: FileType { FileType(rawValue: _S_IFREG) }

  /// FIFO (or pipe)
  ///
  /// The corresponding C constant is `S_IFIFO`.
  @_alwaysEmitIntoClient
  public static var pipe: FileType { FileType(rawValue: _S_IFIFO) }

  /// Symbolic link
  ///
  /// The corresponding C constant is `S_IFLNK`.
  @_alwaysEmitIntoClient
  public static var symbolicLink: FileType { FileType(rawValue: _S_IFLNK) }

  /// Socket
  ///
  /// The corresponding C constant is `S_IFSOCK`.
  @_alwaysEmitIntoClient
  public static var socket: FileType { FileType(rawValue: _S_IFSOCK) }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Whiteout file
  ///
  /// The corresponding C constant is `S_IFWHT`.
  @_alwaysEmitIntoClient
  public static var whiteout: FileType { FileType(rawValue: _S_IFWHT) }
  #endif
}
#endif
