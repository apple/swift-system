/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// FIXME: Document
@frozen
// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct FileStatus: RawRepresentable {
  /// The raw C file status.
  @_alwaysEmitIntoClient
  public let rawValue: CInterop.Stat

  /// Create a strongly-typed file status from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Stat) { self.rawValue = rawValue }

  // FIXME: replace with swift type DeviceId that splits out major/minor
  /// ID of device containing file.
  @_alwaysEmitIntoClient
  public var deviceId: CInterop.DeviceId { rawValue.st_dev }

  /// Mode of file.
  @_alwaysEmitIntoClient
  public var mode: FileMode { FileMode(rawValue: rawValue.st_mode) }

  /// Number of hard links.
  @_alwaysEmitIntoClient
  public var hardLinkCount: CInterop.NumberOfLinks { rawValue.st_nlink }

  /// File serial number.
  @_alwaysEmitIntoClient
  public var inodeNumber: CInterop.INodeNumber { rawValue.st_ino }

  /// User ID of the file.
  @_alwaysEmitIntoClient
  public var userId: CInterop.UserId { rawValue.st_uid }

  /// Group ID of the file.
  @_alwaysEmitIntoClient
  public var groupId: CInterop.GroupId { rawValue.st_gid }

  // FIXME: whats the difference between this and deviceId?
  /// Device ID.
  @_alwaysEmitIntoClient
  public var rDeviceID: CInterop.DeviceId { rawValue.st_rdev }

  /// Time of last access.
  @_alwaysEmitIntoClient
  public var accessTime: TimeSpecification { TimeSpecification(rawValue: rawValue.st_atimespec) }

  /// Time of last data modification.
  @_alwaysEmitIntoClient
  public var modifyTime: TimeSpecification { TimeSpecification(rawValue: rawValue.st_mtimespec) }

  /// Time of last status change.
  @_alwaysEmitIntoClient
  public var statusChangeTime: TimeSpecification { TimeSpecification(rawValue: rawValue.st_ctimespec) }

  /// Time of file creation.
  @_alwaysEmitIntoClient
  public var creationTime: TimeSpecification { TimeSpecification(rawValue: rawValue.st_birthtimespec) }

  /// File size, in bytes.
  @_alwaysEmitIntoClient
  public var fileSize: CInterop.Offset { rawValue.st_size }

  /// Blocks allocated for file.
  @_alwaysEmitIntoClient
  public var blockCount: CInterop.BlockCount { rawValue.st_blocks }

  /// Optimal blocksize for I/O.
  @_alwaysEmitIntoClient
  public var blockSize: CInterop.BlockSize { rawValue.st_blksize }

  /// User defined flags for file.
  @_alwaysEmitIntoClient
  public var fileFlags: FileFlags { FileFlags(rawValue: rawValue.st_flags) }

  /// File generation number.
  @_alwaysEmitIntoClient
  public var generation: CInterop.GenerationId { rawValue.st_gen }
}

#endif
