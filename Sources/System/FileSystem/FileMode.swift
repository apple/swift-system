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
/// A strongly-typed file mode representing a C `mode_t`.
///
/// - Note: Only available on Unix-like platforms.
@frozen
// @available(System X.Y.Z, *)
public struct FileMode: RawRepresentable, Sendable, Hashable, Codable {
  
  /// The raw C mode.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Mode

  /// Creates a strongly-typed `FileMode` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Mode) { self.rawValue = rawValue }

  /// Creates a `FileMode` from the given file type and permissions.
  ///
  /// - Note: This initializer masks the inputs with their respective bit masks.
  @_alwaysEmitIntoClient
  public init(type: FileType, permissions: FilePermissions) {
    self.rawValue = (type.rawValue & _MODE_FILETYPE_MASK) | (permissions.rawValue & _MODE_PERMISSIONS_MASK)
  }

  /// The file's type, from the mode's file-type bits.
  ///
  /// Setting this property will mask the `newValue` with the file-type bit mask `S_IFMT`.
  @_alwaysEmitIntoClient
  public var type: FileType {
    get { FileType(rawValue: rawValue & _MODE_FILETYPE_MASK) }
    set { rawValue = (rawValue & ~_MODE_FILETYPE_MASK) | (newValue.rawValue & _MODE_FILETYPE_MASK) }
  }

  /// The file's permissions, from the mode's permission bits.
  ///
  /// Setting this property will mask the `newValue` with the permissions bit mask `ALLPERMS`.
  @_alwaysEmitIntoClient
  public var permissions: FilePermissions {
    get { FilePermissions(rawValue: rawValue & _MODE_PERMISSIONS_MASK) }
    set { rawValue = (rawValue & ~_MODE_PERMISSIONS_MASK) | (newValue.rawValue & _MODE_PERMISSIONS_MASK) }
  }
}
#endif
