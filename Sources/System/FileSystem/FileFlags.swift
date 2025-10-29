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
// |------------------------------------------------------------------|
// | FileFlags        | Darwin        | FreeBSD       | OpenBSD       |
// |------------------|---------------|---------------|---------------|
// | noDump           | UF_NODUMP     | UF_NODUMP     | UF_NODUMP     |
// | userImmutable    | UF_IMMUTABLE  | UF_IMMUTABLE  | UF_IMMUTABLE  |
// | userAppend       | UF_APPEND     | UF_APPEND     | UF_APPEND     |
// | archived         | SF_ARCHIVED   | SF_ARCHIVED   | SF_ARCHIVED   |
// | systemImmutable  | SF_IMMUTABLE  | SF_IMMUTABLE  | SF_IMMUTABLE  |
// | systemAppend     | SF_APPEND     | SF_APPEND     | SF_APPEND     |
// | opaque           | UF_OPAQUE     | UF_OPAQUE     | N/A           |
// | hidden           | UF_HIDDEN     | UF_HIDDEN     | N/A           |
// | systemNoUnlink   | SF_NOUNLINK   | SF_NOUNLINK   | N/A           |
// | compressed       | UF_COMPRESSED | N/A           | N/A           |
// | tracked          | UF_TRACKED    | N/A           | N/A           |
// | dataVault        | UF_DATAVAULT  | N/A           | N/A           |
// | restricted       | SF_RESTRICTED | N/A           | N/A           |
// | firmlink         | SF_FIRMLINK   | N/A           | N/A           |
// | dataless         | SF_DATALESS   | N/A           | N/A           |
// | userNoUnlink     | N/A           | UF_NOUNLINK   | N/A           |
// | offline          | N/A           | UF_OFFLINE    | N/A           |
// | readOnly         | N/A           | UF_READONLY   | N/A           |
// | reparse          | N/A           | UF_REPARSE    | N/A           |
// | sparse           | N/A           | UF_SPARSE     | N/A           |
// | system           | N/A           | UF_SYSTEM     | N/A           |
// | snapshot         | N/A           | SF_SNAPSHOT   | N/A           |
// |------------------|---------------|---------------|---------------|

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
@available(System 99, *)
extension CInterop {
  public typealias FileFlags = UInt32
}

/// File-specific flags found in the `st_flags` property of a `stat` struct
/// or used as input to `chflags()`.
///
/// - Note: Only available on Darwin, FreeBSD, and OpenBSD.
@frozen
@available(System 99, *)
public struct FileFlags: OptionSet, Sendable, Hashable, Codable {
  
  /// The raw C flags.
  @_alwaysEmitIntoClient
  public let rawValue: CInterop.FileFlags

  /// Creates a strongly-typed `FileFlags` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.FileFlags) { self.rawValue = rawValue }

  // MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

  /// Do not dump the file during backups.
  ///
  /// The corresponding C constant is `UF_NODUMP`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var noDump: FileFlags { FileFlags(rawValue: _UF_NODUMP) }

  /// File may not be changed.
  ///
  /// The corresponding C constant is `UF_IMMUTABLE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var userImmutable: FileFlags { FileFlags(rawValue: _UF_IMMUTABLE) }

  /// Writes to the file may only append.
  ///
  /// The corresponding C constant is `UF_APPEND`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var userAppend: FileFlags { FileFlags(rawValue: _UF_APPEND) }

  /// File has been archived.
  ///
  /// The corresponding C constant is `SF_ARCHIVED`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var archived: FileFlags { FileFlags(rawValue: _SF_ARCHIVED) }

  /// File may not be changed.
  ///
  /// The corresponding C constant is `SF_IMMUTABLE`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var systemImmutable: FileFlags { FileFlags(rawValue: _SF_IMMUTABLE) }

  /// Writes to the file may only append.
  ///
  /// The corresponding C constant is `SF_APPEND`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var systemAppend: FileFlags { FileFlags(rawValue: _SF_APPEND) }

  // MARK: Flags Available on Darwin and FreeBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Directory is opaque when viewed through a union mount.
  ///
  /// The corresponding C constant is `UF_OPAQUE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var opaque: FileFlags { FileFlags(rawValue: _UF_OPAQUE) }

  /// File should not be displayed in a GUI.
  ///
  /// The corresponding C constant is `UF_HIDDEN`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var hidden: FileFlags { FileFlags(rawValue: _UF_HIDDEN) }

  /// File may not be removed or renamed.
  ///
  /// The corresponding C constant is `SF_NOUNLINK`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var systemNoUnlink: FileFlags { FileFlags(rawValue: _SF_NOUNLINK) }
  #endif

  // MARK: Flags Available on Darwin only

  #if SYSTEM_PACKAGE_DARWIN
  /// File is compressed at the file system level.
  ///
  /// The corresponding C constant is `UF_COMPRESSED`.
  /// - Note: This flag is read-only. Attempting to change it will result in undefined behavior.
  @_alwaysEmitIntoClient
  public static var compressed: FileFlags { FileFlags(rawValue: _UF_COMPRESSED) }

  /// File is tracked for the purpose of document IDs.
  ///
  /// The corresponding C constant is `UF_TRACKED`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var tracked: FileFlags { FileFlags(rawValue: _UF_TRACKED) }

  /// File requires an entitlement for reading and writing.
  ///
  /// The corresponding C constant is `UF_DATAVAULT`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var dataVault: FileFlags { FileFlags(rawValue: _UF_DATAVAULT) }

  /// File requires an entitlement for writing.
  ///
  /// The corresponding C constant is `SF_RESTRICTED`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var restricted: FileFlags { FileFlags(rawValue: _SF_RESTRICTED) }

  /// File is a firmlink.
  ///
  /// Firmlinks are used by macOS to create transparent links between
  /// the read-only system volume and writable data volume. For example,
  /// the `/Applications` folder on the system volume is a firmlink to
  /// the `/Applications` folder on the data volume, allowing the user
  /// to see both system- and user-installed applications in a single folder.
  ///
  /// The corresponding C constant is `SF_FIRMLINK`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var firmlink: FileFlags { FileFlags(rawValue: _SF_FIRMLINK) }

  /// File is a dataless placeholder (content is stored remotely).
  ///
  /// The system will attempt to materialize the file when accessed according to
  /// the dataless file materialization policy of the accessing thread or process.
  /// See `getiopolicy_np(3)`.
  ///
  /// The corresponding C constant is `SF_DATALESS`.
  /// - Note: This flag is read-only. Attempting to change it will result in undefined behavior.
  @_alwaysEmitIntoClient
  public static var dataless: FileFlags { FileFlags(rawValue: _SF_DATALESS) }
  #endif

  // MARK: Flags Available on FreeBSD Only

  #if os(FreeBSD)
  /// File may not be removed or renamed.
  ///
  /// The corresponding C constant is `UF_NOUNLINK`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var userNoUnlink: FileFlags { FileFlags(rawValue: _UF_NOUNLINK) }

  /// File has the Windows offline attribute.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_OFFLINE` attribute,
  /// but otherwise provide no special handling when it's set.
  ///
  /// The corresponding C constant is `UF_OFFLINE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var offline: FileFlags { FileFlags(rawValue: _UF_OFFLINE) }

  /// File is read-only.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_READONLY` attribute.
  ///
  /// The corresponding C constant is `UF_READONLY`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var readOnly: FileFlags { FileFlags(rawValue: _UF_READONLY) }

  /// File contains a Windows reparse point.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_REPARSE_POINT` attribute.
  ///
  /// The corresponding C constant is `UF_REPARSE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var reparse: FileFlags { FileFlags(rawValue: _UF_REPARSE) }

  /// File is sparse.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_SPARSE_FILE` attribute,
  /// or to indicate a sparse file.
  ///
  /// The corresponding C constant is `UF_SPARSE`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var sparse: FileFlags { FileFlags(rawValue: _UF_SPARSE) }

  /// File has the Windows system attribute.
  ///
  /// File systems may use this flag for compatibility with the Windows `FILE_ATTRIBUTE_SYSTEM` attribute,
  /// but otherwise provide no special handling when it's set.
  ///
  /// The corresponding C constant is `UF_SYSTEM`.
  /// - Note: This flag may be changed by the file owner or superuser.
  @_alwaysEmitIntoClient
  public static var system: FileFlags { FileFlags(rawValue: _UF_SYSTEM) }

  /// File is a snapshot.
  ///
  /// The corresponding C constant is `SF_SNAPSHOT`.
  /// - Note: This flag may only be changed by the superuser.
  @_alwaysEmitIntoClient
  public static var snapshot: FileFlags { FileFlags(rawValue: _SF_SNAPSHOT) }
  #endif
}
#endif
