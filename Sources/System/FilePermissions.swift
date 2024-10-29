/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// The access permissions for a file.
///
/// The following example
/// creates an instance of the `FilePermissions` structure
/// from a raw octal literal and compares it
/// to a file permission created using named options:
///
///     let perms = FilePermissions(rawValue: 0o644)
///     perms == [.ownerReadWrite, .groupRead, .otherRead] // true
@frozen
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
public struct FilePermissions: OptionSet, Sendable, Hashable, Codable {
  /// The raw C file permissions.
  @_alwaysEmitIntoClient
  public let rawValue: CModeT

  /// Create a strongly-typed file permission from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CModeT) { self.rawValue = rawValue }

  /// Indicates that other users have read-only permission.
  @_alwaysEmitIntoClient
  public static var otherRead: FilePermissions { .init(rawValue: 0o4) }

  /// Indicates that other users have write-only permission.
  @_alwaysEmitIntoClient
  public static var otherWrite: FilePermissions { .init(rawValue: 0o2) }

  /// Indicates that other users have execute-only permission.
  @_alwaysEmitIntoClient
  public static var otherExecute: FilePermissions { .init(rawValue: 0o1) }

  /// Indicates that other users have read-write permission.
  @_alwaysEmitIntoClient
  public static var otherReadWrite: FilePermissions { .init(rawValue: 0o6) }

  /// Indicates that other users have read-execute permission.
  @_alwaysEmitIntoClient
  public static var otherReadExecute: FilePermissions { .init(rawValue: 0o5) }

  /// Indicates that other users have write-execute permission.
  @_alwaysEmitIntoClient
  public static var otherWriteExecute: FilePermissions { .init(rawValue: 0o3) }

  /// Indicates that other users have read, write, and execute permission.
  @_alwaysEmitIntoClient
  public static var otherReadWriteExecute: FilePermissions { .init(rawValue: 0o7) }

  /// Indicates that the group has read-only permission.
  @_alwaysEmitIntoClient
  public static var groupRead: FilePermissions { .init(rawValue: 0o40) }

  /// Indicates that the group has write-only permission.
  @_alwaysEmitIntoClient
  public static var groupWrite: FilePermissions { .init(rawValue: 0o20) }

  /// Indicates that the group has execute-only permission.
  @_alwaysEmitIntoClient
  public static var groupExecute: FilePermissions { .init(rawValue: 0o10) }

  /// Indicates that the group has read-write permission.
  @_alwaysEmitIntoClient
  public static var groupReadWrite: FilePermissions { .init(rawValue: 0o60) }

  /// Indicates that the group has read-execute permission.
  @_alwaysEmitIntoClient
  public static var groupReadExecute: FilePermissions { .init(rawValue: 0o50) }

  /// Indicates that the group has write-execute permission.
  @_alwaysEmitIntoClient
  public static var groupWriteExecute: FilePermissions { .init(rawValue: 0o30) }

  /// Indicates that the group has read, write, and execute permission.
  @_alwaysEmitIntoClient
  public static var groupReadWriteExecute: FilePermissions { .init(rawValue: 0o70) }

  /// Indicates that the owner has read-only permission.
  @_alwaysEmitIntoClient
  public static var ownerRead: FilePermissions { .init(rawValue: 0o400) }

  /// Indicates that the owner has write-only permission.
  @_alwaysEmitIntoClient
  public static var ownerWrite: FilePermissions { .init(rawValue: 0o200) }

  /// Indicates that the owner has execute-only permission.
  @_alwaysEmitIntoClient
  public static var ownerExecute: FilePermissions { .init(rawValue: 0o100) }

  /// Indicates that the owner has read-write permission.
  @_alwaysEmitIntoClient
  public static var ownerReadWrite: FilePermissions { .init(rawValue: 0o600) }

  /// Indicates that the owner has read-execute permission.
  @_alwaysEmitIntoClient
  public static var ownerReadExecute: FilePermissions { .init(rawValue: 0o500) }

  /// Indicates that the owner has write-execute permission.
  @_alwaysEmitIntoClient
  public static var ownerWriteExecute: FilePermissions { .init(rawValue: 0o300) }

  /// Indicates that the owner has read, write, and execute permission.
  @_alwaysEmitIntoClient
  public static var ownerReadWriteExecute: FilePermissions { .init(rawValue: 0o700) }

  /// Indicates that the file is executed as the owner.
  ///
  /// For more information, see the `setuid(2)` man page.
  @_alwaysEmitIntoClient
  public static var setUserID: FilePermissions { .init(rawValue: 0o4000) }

  /// Indicates that the file is executed as the group.
  ///
  /// For more information, see the `setgid(2)` man page.
  @_alwaysEmitIntoClient
  public static var setGroupID: FilePermissions { .init(rawValue: 0o2000) }

  /// Indicates that executable's text segment
  /// should be kept in swap space even after it exits.
  ///
  /// For more information, see the `chmod(2)` man page's
  /// discussion of `S_ISVTX` (the sticky bit).
  @_alwaysEmitIntoClient
  public static var saveText: FilePermissions { .init(rawValue: 0o1000) }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FilePermissions
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the file permissions.
  @inline(never)
  public var description: String {
    let descriptions: [(Element, StaticString)] = [
      (.ownerReadWriteExecute, ".ownerReadWriteExecute"),
      (.ownerReadWrite, ".ownerReadWrite"),
      (.ownerReadExecute, ".ownerReadExecute"),
      (.ownerWriteExecute, ".ownerWriteExecute"),
      (.ownerRead, ".ownerRead"),
      (.ownerWrite, ".ownerWrite"),
      (.ownerExecute, ".ownerExecute"),
      (.groupReadWriteExecute, ".groupReadWriteExecute"),
      (.groupReadWrite, ".groupReadWrite"),
      (.groupReadExecute, ".groupReadExecute"),
      (.groupWriteExecute, ".groupWriteExecute"),
      (.groupRead, ".groupRead"),
      (.groupWrite, ".groupWrite"),
      (.groupExecute, ".groupExecute"),
      (.otherReadWriteExecute, ".otherReadWriteExecute"),
      (.otherReadWrite, ".otherReadWrite"),
      (.otherReadExecute, ".otherReadExecute"),
      (.otherWriteExecute, ".otherWriteExecute"),
      (.otherRead, ".otherRead"),
      (.otherWrite, ".otherWrite"),
      (.otherExecute, ".otherExecute"),
      (.setUserID, ".setUserID"),
      (.setGroupID, ".setGroupID"),
      (.saveText, ".saveText")
    ]

    return _buildDescription(descriptions)
  }

  /// A textual representation of the file permissions, suitable for debugging.
  public var debugDescription: String { self.description }
}
