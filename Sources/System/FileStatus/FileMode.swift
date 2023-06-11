/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// FIXME: should the subtypes of Mode mask their rawValues to only allow their bits to be changed?

/// The superset of access permissions and type for a file.
///
/// The following example creates an instance of the `FileMode` structure
/// from a raw octal literal and reads the file type from it:
///
///     let mode = FileMode(rawValue: 0o140000)
///     mode.type == .socket // true
@frozen
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct FileMode: RawRepresentable {
  /// The raw C file mode.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.Mode

  /// Create a strongly-typed file mode from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Mode) { self.rawValue = rawValue }

  /// Subset of mode for accessing and modifying file permissions.
  @_alwaysEmitIntoClient
  public var permissions: FilePermissions {
    get { FilePermissions(rawValue: rawValue & _MODE_PERMISSIONS) }
    set { rawValue = (rawValue & ~_MODE_PERMISSIONS) | (newValue.rawValue & _MODE_PERMISSIONS ) }
  }

  /// Subset of mode for accessing and modifying file type.
  @_alwaysEmitIntoClient
  public var type: FileType {
    get { FileType(rawValue: rawValue & _MODE_TYPE) }
    set { rawValue = (rawValue & ~_MODE_TYPE) | (newValue.rawValue & _MODE_TYPE ) }
  }
}

#endif
