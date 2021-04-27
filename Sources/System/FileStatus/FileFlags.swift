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
public struct FileFlags: OptionSet, Hashable, Codable {
  /// The raw C file flags.
  @_alwaysEmitIntoClient
  public let rawValue: CInterop.FileFlags

  /// Create a strongly-typed file flags from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.FileFlags) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  private init(_ raw: CInterop.FileFlags) { self.init(rawValue: raw) }

  /// Do not dump the file. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_NODUMP`
  @_alwaysEmitIntoClient
  public static var noDump: FileFlags { FileFlags(_UF_NODUMP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noDump")
  public static var UF_NODUMP: FileFlags { noDump }

  /// The file may not be changed. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_IMMUTABLE`
  @_alwaysEmitIntoClient
  public static var immutable: FileFlags { FileFlags(_UF_IMMUTABLE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "immutable")
  public static var UF_IMMUTABLE: FileFlags { immutable }

  /// The file may only be appended to. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_APPEND`
  @_alwaysEmitIntoClient
  public static var appendOnly: FileFlags { FileFlags(_UF_APPEND) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "appendOnly")
  public static var UF_APPEND: FileFlags { appendOnly }

  /// The directory is opaque when viewed through a union stack. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_OPAQUE`
  @_alwaysEmitIntoClient
  public static var opaque: FileFlags { FileFlags(_UF_OPAQUE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "opaque")
  public static var UF_OPAQUE: FileFlags { opaque }

// #if os(FreeBSD)
//   /// The file may not be removed or renamed. Modifiable by file owner or super-user.
//   ///
//   /// The corresponding C constant is `UF_NOUNLINK`
//   @_alwaysEmitIntoClient
//   public static var noUnlink: FileFlags { FileFlags(_UF_NOUNLINK) }
//
//   @_alwaysEmitIntoClient
//   @available(*, unavailable, renamed: "noUnlink")
//   public static var UF_NOUNLINK: FileFlags { noUnlink }
// #endif

  /// The file is compressed (some file-systems). Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_COMPRESSED`
  @_alwaysEmitIntoClient
  public static var compressed: FileFlags { FileFlags(_UF_COMPRESSED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "compressed")
  public static var UF_COMPRESSED: FileFlags { compressed }

  /// No notifications will be issued for deletes or renames. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_TRACKED`
  @_alwaysEmitIntoClient
  public static var tracked: FileFlags { FileFlags(_UF_TRACKED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tracked")
  public static var UF_TRACKED: FileFlags { tracked }

  /// The file requires entitlement required for reading and writing. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_DATAVAULT`
  @_alwaysEmitIntoClient
  public static var dataVault: FileFlags { FileFlags(_UF_DATAVAULT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "dataVault")
  public static var UF_DATAVAULT: FileFlags { dataVault }

  /// The file or directory is not intended to be displayed to the user. Modifiable by file owner or super-user.
  ///
  /// The corresponding C constant is `UF_HIDDEN`
  @_alwaysEmitIntoClient
  public static var hidden: FileFlags { FileFlags(_UF_HIDDEN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "hidden")
  public static var UF_HIDDEN: FileFlags { hidden }

  /// The file has been archived. Only modifiable by the super-user.
  ///
  /// The corresponding C constant is `SF_ARCHIVED`
  @_alwaysEmitIntoClient
  public static var superUserArchived: FileFlags { FileFlags(_SF_ARCHIVED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "superUserArchived")
  public static var SF_ARCHIVED: FileFlags { superUserArchived }

  /// The file may not be changed. Only modifiable by the super-user.
  ///
  /// The corresponding C constant is `SF_IMMUTABLE`
  @_alwaysEmitIntoClient
  public static var superUserImmutable: FileFlags { FileFlags(_SF_IMMUTABLE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "superUserImmutable")
  public static var SF_IMMUTABLE: FileFlags { superUserImmutable }

  /// The file may only be appended to. Only modifiable by the super-user.
  ///
  /// The corresponding C constant is `SF_APPEND`
  @_alwaysEmitIntoClient
  public static var superUserAppend: FileFlags { FileFlags(_SF_APPEND) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "superUserAppend")
  public static var SF_APPEND: FileFlags { superUserAppend }

  /// The file requires entitlement required for reading and writing. Only modifiable by the super-user.
  ///
  /// The corresponding C constant is `SF_RESTRICTED`
  @_alwaysEmitIntoClient
  public static var superUserRestricted: FileFlags { FileFlags(_SF_RESTRICTED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "superUserRestricted")
  public static var SF_RESTRICTED: FileFlags { superUserRestricted }

  /// The file may not be removed, renamed or mounted on. Only modifiable by the super-user.
  ///
  /// The corresponding C constant is `SF_NOUNLINK`
  @_alwaysEmitIntoClient
  public static var superUserNoUnlink: FileFlags { FileFlags(_SF_NOUNLINK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "superUserNoUnlink")
  public static var SF_NOUNLINK: FileFlags { superUserNoUnlink }

// #if os(FreeBSD)
//   /// The file is a snapshot file. Only modifiable by the super-user.
//   ///
//   /// The corresponding C constant is `SF_SNAPSHOT`
//   @_alwaysEmitIntoClient
//   public static var superUserSnapshot: FileFlags { FileFlags(_SF_SNAPSHOT) }
//
//   @_alwaysEmitIntoClient
//   @available(*, unavailable, renamed: "superUserSnapshot")
//   public static var SF_SNAPSHOT: FileFlags { superUserSnapshot }
// #endif

  /// The file is a firmlink. Only modifiable by the super-user.
  ///
  /// The corresponding C constant is `SF_FIRMLINK`
  @_alwaysEmitIntoClient
  public static var superUserFirmlink: FileFlags { FileFlags(_SF_FIRMLINK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "superUserFirmlink")
  public static var SF_FIRMLINK: FileFlags { superUserFirmlink }

  /// The file is a dataless placeholder. The system will attempt to materialize it when accessed according to the dataless file materialization policy of the accessing thread or process. Cannot be modified in user-space.
  ///
  /// The corresponding C constant is `SF_DATALESS`
  @_alwaysEmitIntoClient
  public static var kernelDataless: FileFlags { FileFlags(_SF_DATALESS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "kernelDataless")
  public static var SF_DATALESS: FileFlags { kernelDataless }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileFlags
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the file permissions.
  @inline(never)
  public var description: String {
    let descriptions: [(Element, StaticString)] = [
      (.noDump, ".noDump"),
      (.immutable, ".immutable"),
      (.appendOnly, ".appendOnly"),
      (.opaque, ".opaque"),
      (.compressed, ".compressed"),
      (.tracked, ".tracked"),
      (.dataVault, ".dataVault"),
      (.hidden, ".hidden"),
      (.superUserArchived, ".superUserArchived"),
      (.superUserImmutable, ".superUserImmutable"),
      (.superUserAppend, ".superUserAppend"),
      (.superUserRestricted, ".superUserRestricted"),
      (.superUserNoUnlink, ".superUserNoUnlink"),
      (.superUserFirmlink, ".superUserFirmlink"),
      (.kernelDataless, ".kernelDataless"),
    ]

    return _buildDescription(descriptions)
  }

  /// A textual representation of the file permissions, suitable for debugging.
  public var debugDescription: String { self.description }
}

#endif
