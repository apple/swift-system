/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(Windows)
import CSystem
import ucrt
#endif

extension CInterop {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  /// The C `stat` type.
  public typealias Stat = stat
  /// The C `mode_t` type.
  public typealias Mode = mode_t
  /// The C `uid_t` type.
  public typealias UserID = uid_t
  /// The C `gid_t` type.
  public typealias GroupID = gid_t
  /// The C `dev_t` type.
  public typealias DeviceID = dev_t
  /// The C `nlink_t` type.
  public typealias NumberOfLinks = nlink_t
  /// The C `ino_t` type.
  public typealias INodeNumber = ino_t
  /// The C `timespec` type.
  public typealias TimeSpec = timespec
  /// The C `off_t` type.
  public typealias Offset = off_t
  /// The C `blkcnt_t` type.
  public typealias BlockCount = blkcnt_t
  /// The C `blksize_t` type.
  public typealias BlockSize = blksize_t
  /// The C `UInt32` type.
  public typealias GenerationID = UInt32
  /// The C `UInt32` type.
  public typealias FileFlags = UInt32
#endif

#if os(Windows)
  public typealias Mode = CInt
#endif
}
