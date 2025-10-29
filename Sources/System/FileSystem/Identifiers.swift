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

#if !os(Windows)
/// A Swift wrapper of the C `uid_t` type.
@frozen
@available(System 99, *)
public struct UserID: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw C `uid_t`.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.UserID

  /// Creates a strongly-typed `UserID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.UserID) { self.rawValue = rawValue }

  /// Creates a strongly-typed `UserID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: CInterop.UserID) { self.rawValue = rawValue }
}

/// A Swift wrapper of the C `gid_t` type.
@frozen
@available(System 99, *)
public struct GroupID: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw C `gid_t`.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.GroupID

  /// Creates a strongly-typed `GroupID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.GroupID) { self.rawValue = rawValue }

  /// Creates a strongly-typed `GroupID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: CInterop.GroupID) { self.rawValue = rawValue }
}

/// A Swift wrapper of the C `dev_t` type.
@frozen
@available(System 99, *)
public struct DeviceID: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw C `dev_t`.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.DeviceID

  /// Creates a strongly-typed `DeviceID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.DeviceID) { self.rawValue = rawValue }

  /// Creates a strongly-typed `DeviceID` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: CInterop.DeviceID) { self.rawValue = rawValue }
}

/// A Swift wrapper of the C `ino_t` type.
@frozen
@available(System 99, *)
public struct Inode: RawRepresentable, Sendable, Hashable, Codable {

  /// The raw C `ino_t`.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Inode

  /// Creates a strongly-typed `Inode` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Inode) { self.rawValue = rawValue }

  /// Creates a strongly-typed `Inode` from the raw C value.
  @_alwaysEmitIntoClient
  public init(_ rawValue: CInterop.Inode) { self.rawValue = rawValue }
}
#endif // !os(Windows)
