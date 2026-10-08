//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// |-----------------------------------------------------------------------------------------------------------------------------|
// | Swift API to C Mapping                                                                                                      |
// |-----------------------------------------------------------------------------------------------------------------------------|
// | MountFlags                     | Darwin               | FreeBSD         | OpenBSD         | Linux          | Android        |
// |--------------------------------|----------------------|-----------------|-----------------|----------------|----------------|
// | readOnly                       | MNT_RDONLY           | MNT_RDONLY      | MNT_RDONLY      | ST_RDONLY      | ST_RDONLY      |
// | synchronous                    | MNT_SYNCHRONOUS      | MNT_SYNCHRONOUS | MNT_SYNCHRONOUS | ST_SYNCHRONOUS | ST_SYNCHRONOUS |
// | noExecution                    | MNT_NOEXEC           | MNT_NOEXEC      | MNT_NOEXEC      | ST_NOEXEC      | ST_NOEXEC      |
// | noSetUserID                    | MNT_NOSUID           | MNT_NOSUID      | MNT_NOSUID      | ST_NOSUID      | ST_NOSUID      |
// | noAccessTime                   | MNT_NOATIME          | MNT_NOATIME     | MNT_NOATIME     | ST_NOATIME     | ST_NOATIME     |
// | noDevices                      | MNT_NODEV            | N/A             | MNT_NODEV       | ST_NODEV       | ST_NODEV       |
// | mandatoryLocking               | N/A                  | N/A             | N/A             | ST_MANDLOCK    | ST_MANDLOCK    |
// | noDirectoryAccessTime          | N/A                  | N/A             | N/A             | ST_NODIRATIME  | ST_NODIRATIME  |
// | relativeAccessTime             | N/A                  | N/A             | N/A             | ST_RELATIME    | ST_RELATIME    |
// | noSymlinkFollowing             | N/A                  | MNT_NOSYMFOLLOW | N/A             | ST_NOSYMFOLLOW | ST_NOSYMFOLLOW |
// | asynchronous                   | MNT_ASYNC            | MNT_ASYNC       | MNT_ASYNC       | N/A            | N/A            |
// | exported                       | MNT_EXPORTED         | MNT_EXPORTED    | MNT_EXPORTED    | N/A            | N/A            |
// | local                          | MNT_LOCAL            | MNT_LOCAL       | MNT_LOCAL       | N/A            | N/A            |
// | quotasEnabled                  | MNT_QUOTA            | MNT_QUOTA       | MNT_QUOTA       | N/A            | N/A            |
// | rootFileSystem                 | MNT_ROOTFS           | MNT_ROOTFS      | MNT_ROOTFS      | N/A            | N/A            |
// | union                          | MNT_UNION            | MNT_UNION       | N/A             | N/A            | N/A            |
// | automounted                    | MNT_AUTOMOUNTED      | MNT_AUTOMOUNTED | N/A             | N/A            | N/A            |
// | multiLabel                     | MNT_MULTILABEL       | MNT_MULTILABEL  | N/A             | N/A            | N/A            |
// | exportedReadOnly               | N/A                  | MNT_EXRDONLY    | MNT_EXRDONLY    | N/A            | N/A            |
// | exportedByDefault              | N/A                  | MNT_DEFEXPORTED | MNT_DEFEXPORTED | N/A            | N/A            |
// | exportedAnonymously            | N/A                  | MNT_EXPORTANON  | MNT_EXPORTANON  | N/A            | N/A            |
// | softUpdates                    | N/A                  | MNT_SOFTDEP     | MNT_SOFTDEP     | N/A            | N/A            |
// | contentProtection              | MNT_CPROTECT         | N/A             | N/A             | N/A            | N/A            |
// | removable                      | MNT_REMOVABLE        | N/A             | N/A             | N/A            | N/A            |
// | quarantined                    | MNT_QUARANTINE       | N/A             | N/A             | N/A            | N/A            |
// | supportsVolfs                  | MNT_DOVOLFS          | N/A             | N/A             | N/A            | N/A            |
// | noBrowsing                     | MNT_DONTBROWSE       | N/A             | N/A             | N/A            | N/A            |
// | ignoresOwnership               | MNT_IGNORE_OWNERSHIP | N/A             | N/A             | N/A            | N/A            |
// | journaled                      | MNT_JOURNALED        | N/A             | N/A             | N/A            | N/A            |
// | noUserExtendedAttributes       | MNT_NOUSERXATTR      | N/A             | N/A             | N/A            | N/A            |
// | defersWrites                   | MNT_DEFWRITE         | N/A             | N/A             | N/A            | N/A            |
// | noSymlinkFollowingAtMountPoint | MNT_NOFOLLOW         | N/A             | N/A             | N/A            | N/A            |
// | snapshot                       | MNT_SNAPSHOT         | N/A             | N/A             | N/A            | N/A            |
// | strictAccessTime               | MNT_STRICTATIME      | N/A             | N/A             | N/A            | N/A            |
// | exportedWithKerberos           | N/A                  | MNT_EXKERB      | N/A             | N/A            | N/A            |
// | exportedPublicly               | N/A                  | MNT_EXPUBLIC    | N/A             | N/A            | N/A            |
// | posixACLs                      | N/A                  | MNT_ACLS        | N/A             | N/A            | N/A            |
// | geomJournaled                  | N/A                  | MNT_GJOURNAL    | N/A             | N/A            | N/A            |
// | excludedFromDiskFreeReports    | N/A                  | MNT_IGNORE      | N/A             | N/A            | N/A            |
// | nfs4ACLs                       | N/A                  | MNT_NFS4ACLS    | N/A             | N/A            | N/A            |
// | noClusteredReads               | N/A                  | MNT_NOCLUSTERR  | N/A             | N/A            | N/A            |
// | noClusteredWrites              | N/A                  | MNT_NOCLUSTERW  | N/A             | N/A            | N/A            |
// | setUserIDDirectories           | N/A                  | MNT_SUIDDIR     | N/A             | N/A            | N/A            |
// | softUpdatesJournaling          | N/A                  | MNT_SUJ         | N/A             | N/A            | N/A            |
// | untrusted                      | N/A                  | MNT_UNTRUSTED   | N/A             | N/A            | N/A            |
// | userMounted                    | N/A                  | MNT_USER        | N/A             | N/A            | N/A            |
// | verified                       | N/A                  | MNT_VERIFIED    | N/A             | N/A            | N/A            |
// | noPermissionChecks             | N/A                  | N/A             | MNT_NOPERM      | N/A            | N/A            |
// | writeExecuteAllowed            | N/A                  | N/A             | MNT_WXALLOWED   | N/A            | N/A            |
// |-----------------------------------------------------------------------------------------------------------------------------|

#if !os(Windows) && !os(WASI)

/// Flags describing a mounted file system.
///
/// These are the flags reported in the `f_flags` field of a `statfs` struct.
/// Some reflect options employed when mounting the file system, while others,
/// like `local` and `rootFileSystem`, describe state the kernel reports.
///
/// - Note: Not available on Windows or WASI.
@frozen
@available(System 199, *)
public struct MountFlags: OptionSet, Sendable, Hashable, Codable {

  /// The raw C flags.
  @_alwaysEmitIntoClient
  public let rawValue: CInterop.MountFlags

  /// Creates a strongly-typed `MountFlags` from the raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.MountFlags) { self.rawValue = rawValue }

  // MARK: Flags Available on All Platforms

  /// The file system is mounted read-only, even for the super-user.
  ///
  /// The corresponding C constant is `MNT_RDONLY` on Darwin and BSD,
  /// or `ST_RDONLY` otherwise.
  @_alwaysEmitIntoClient
  public static var readOnly: MountFlags { MountFlags(rawValue: _MOUNT_RDONLY) }

  /// The file system is written to synchronously.
  ///
  /// The corresponding C constant is `MNT_SYNCHRONOUS` on Darwin and BSD,
  /// or `ST_SYNCHRONOUS` otherwise.
  @_alwaysEmitIntoClient
  public static var synchronous: MountFlags { MountFlags(rawValue: _MOUNT_SYNCHRONOUS) }

  /// Programs may not be executed from the file system.
  ///
  /// The corresponding C constant is `MNT_NOEXEC` on Darwin and BSD,
  /// or `ST_NOEXEC` otherwise.
  @_alwaysEmitIntoClient
  public static var noExecution: MountFlags { MountFlags(rawValue: _MOUNT_NOEXEC) }

  /// Set-user-ID and set-group-ID (setuid and setgid) bits are not honored on
  /// the file system.
  ///
  /// The corresponding C constant is `MNT_NOSUID` on Darwin and BSD,
  /// or `ST_NOSUID` otherwise.
  @_alwaysEmitIntoClient
  public static var noSetUserID: MountFlags { MountFlags(rawValue: _MOUNT_NOSUID) }

  /// Access times are not updated on the file system.
  ///
  /// - Note: On OpenBSD, access time may still be updated when the
  ///   modification or status-change time is also being updated.
  ///
  /// The corresponding C constant is `MNT_NOATIME` on Darwin and BSD,
  /// or `ST_NOATIME` otherwise.
  @_alwaysEmitIntoClient
  public static var noAccessTime: MountFlags { MountFlags(rawValue: _MOUNT_NOATIME) }

  // MARK: Flags Available on All Platforms Except FreeBSD

  #if !os(FreeBSD)
  /// Special files may not be interpreted on the file system.
  ///
  /// - Note: Not available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_NODEV` on Darwin and OpenBSD,
  /// or `ST_NODEV` otherwise.
  @_alwaysEmitIntoClient
  public static var noDevices: MountFlags { MountFlags(rawValue: _MOUNT_NODEV) }
  #endif

  // MARK: Flags Available on Linux and Android

  // Glibc and musl also define `ST_WRITE`, `ST_APPEND`, and `ST_IMMUTABLE`, but
  // Linux never reports them in `f_flags`, so they have no corresponding flag.

  #if os(Linux) || os(Android)
  /// Mandatory file locking is enabled on the file system.
  ///
  /// - Note: Only available on Linux and Android.
  /// - Note: Mandatory locking was deprecated and removed in Linux 5.15.
  ///
  /// The corresponding C constant is `ST_MANDLOCK`.
  @_alwaysEmitIntoClient
  public static var mandatoryLocking: MountFlags { MountFlags(rawValue: _ST_MANDLOCK) }

  /// Directory access times are not updated on the file system.
  ///
  /// - Note: Only available on Linux and Android.
  ///
  /// The corresponding C constant is `ST_NODIRATIME`.
  @_alwaysEmitIntoClient
  public static var noDirectoryAccessTime: MountFlags { MountFlags(rawValue: _ST_NODIRATIME) }

  /// The access time is only updated if it's earlier than or equal to the file's
  /// last modification or status-change time, or if it's more than a day old.
  ///
  /// - Note: Only available on Linux and Android.
  ///
  /// The corresponding C constant is `ST_RELATIME`.
  @_alwaysEmitIntoClient
  public static var relativeAccessTime: MountFlags { MountFlags(rawValue: _ST_RELATIME) }
  #endif

  // MARK: Flags Available on Linux, Android, and FreeBSD

  #if os(Linux) || os(Android) || os(FreeBSD)
  /// Symbolic links are not followed when resolving paths on the file system.
  ///
  /// - Note: Only available on Linux, Android, and FreeBSD.
  ///
  /// The corresponding C constant is `MNT_NOSYMFOLLOW` on FreeBSD,
  /// or `ST_NOSYMFOLLOW` on Linux and Android.
  @_alwaysEmitIntoClient
  public static var noSymlinkFollowing: MountFlags { MountFlags(rawValue: _MOUNT_NOSYMFOLLOW) }
  #endif

  // MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// The file system is written to asynchronously.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_ASYNC`.
  @_alwaysEmitIntoClient
  public static var asynchronous: MountFlags { MountFlags(rawValue: _MNT_ASYNC) }

  /// The file system is exported for use over the network via NFS.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_EXPORTED`.
  @_alwaysEmitIntoClient
  public static var exported: MountFlags { MountFlags(rawValue: _MNT_EXPORTED) }

  /// The file system is stored locally, rather than being accessed over a network.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_LOCAL`.
  @_alwaysEmitIntoClient
  public static var local: MountFlags { MountFlags(rawValue: _MNT_LOCAL) }

  /// Quotas are enabled on the file system.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_QUOTA`.
  @_alwaysEmitIntoClient
  public static var quotasEnabled: MountFlags { MountFlags(rawValue: _MNT_QUOTA) }

  /// The file system is the root file system.
  ///
  /// - Note: Only available on Darwin and BSD.
  ///
  /// The corresponding C constant is `MNT_ROOTFS`.
  @_alwaysEmitIntoClient
  public static var rootFileSystem: MountFlags { MountFlags(rawValue: _MNT_ROOTFS) }
  #endif

  // MARK: Flags Available on Darwin and FreeBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// The file system is unioned with the underlying file system, rather than
  /// obscuring it.
  ///
  /// - Note: Only available on Darwin and FreeBSD.
  ///
  /// The corresponding C constant is `MNT_UNION`.
  @_alwaysEmitIntoClient
  public static var union: MountFlags { MountFlags(rawValue: _MNT_UNION) }

  /// The file system was mounted by the automounter.
  ///
  /// - Note: Only available on Darwin and FreeBSD. See `automount(8)`.
  ///
  /// The corresponding C constant is `MNT_AUTOMOUNTED`.
  @_alwaysEmitIntoClient
  public static var automounted: MountFlags { MountFlags(rawValue: _MNT_AUTOMOUNTED) }

  /// The file system maintains Mandatory Access Control (MAC) labels for
  /// individual objects.
  ///
  /// - Note: Only available on Darwin and FreeBSD.
  ///
  /// The corresponding C constant is `MNT_MULTILABEL`.
  @_alwaysEmitIntoClient
  public static var multiLabel: MountFlags { MountFlags(rawValue: _MNT_MULTILABEL) }
  #endif

  // MARK: Flags Available on FreeBSD and OpenBSD

  #if os(FreeBSD) || os(OpenBSD)
  /// The file system is exported for reading only.
  ///
  /// - Note: Only available on FreeBSD and OpenBSD.
  ///
  /// The corresponding C constant is `MNT_EXRDONLY`.
  @_alwaysEmitIntoClient
  public static var exportedReadOnly: MountFlags { MountFlags(rawValue: _MNT_EXRDONLY) }

  /// The file system is exported to any host by default.
  ///
  /// - Note: Only available on FreeBSD and OpenBSD.
  ///
  /// The corresponding C constant is `MNT_DEFEXPORTED`.
  @_alwaysEmitIntoClient
  public static var exportedByDefault: MountFlags { MountFlags(rawValue: _MNT_DEFEXPORTED) }

  /// The file system is exported with all remote users mapped to the
  /// anonymous user account.
  ///
  /// - Note: Only available on FreeBSD and OpenBSD.
  ///
  /// The corresponding C constant is `MNT_EXPORTANON`.
  @_alwaysEmitIntoClient
  public static var exportedAnonymously: MountFlags { MountFlags(rawValue: _MNT_EXPORTANON) }

  /// Soft updates are enabled on the file system.
  ///
  /// - Note: Only available on FreeBSD and OpenBSD. Accepted for compatibility
  ///   on OpenBSD, but has no effect there.
  ///
  /// The corresponding C constant is `MNT_SOFTDEP`.
  @_alwaysEmitIntoClient
  public static var softUpdates: MountFlags { MountFlags(rawValue: _MNT_SOFTDEP) }
  #endif

  // MARK: Flags Available on Darwin Only

  #if SYSTEM_PACKAGE_DARWIN
  /// Per-file encrypted data protection is enabled on the file system.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_CPROTECT`.
  @_alwaysEmitIntoClient
  public static var contentProtection: MountFlags { MountFlags(rawValue: _MNT_CPROTECT) }

  /// The file system resides on removable media.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_REMOVABLE`.
  @_alwaysEmitIntoClient
  public static var removable: MountFlags { MountFlags(rawValue: _MNT_REMOVABLE) }

  /// The file system is quarantined.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_QUARANTINE`.
  @_alwaysEmitIntoClient
  public static var quarantined: MountFlags { MountFlags(rawValue: _MNT_QUARANTINE) }

  /// The file system supports volfs.
  ///
  /// - Note: Only available on Darwin. Deprecated since Mac OS X 10.5.
  ///
  /// The corresponding C constant is `MNT_DOVOLFS`.
  @_alwaysEmitIntoClient
  public static var supportsVolfs: MountFlags { MountFlags(rawValue: _MNT_DOVOLFS) }

  /// The file system should not be presented to the user for browsing
  /// (e.g. hidden in Finder).
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_DONTBROWSE`.
  @_alwaysEmitIntoClient
  public static var noBrowsing: MountFlags { MountFlags(rawValue: _MNT_DONTBROWSE) }

  /// The file system ignores ownership information.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_IGNORE_OWNERSHIP`.
  @_alwaysEmitIntoClient
  public static var ignoresOwnership: MountFlags { MountFlags(rawValue: _MNT_IGNORE_OWNERSHIP) }

  /// The file system is journaled.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_JOURNALED`.
  @_alwaysEmitIntoClient
  public static var journaled: MountFlags { MountFlags(rawValue: _MNT_JOURNALED) }

  /// User extended attributes are not allowed on the file system.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_NOUSERXATTR`.
  @_alwaysEmitIntoClient
  public static var noUserExtendedAttributes: MountFlags { MountFlags(rawValue: _MNT_NOUSERXATTR) }

  /// The file system defers writes.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_DEFWRITE`.
  @_alwaysEmitIntoClient
  public static var defersWrites: MountFlags { MountFlags(rawValue: _MNT_DEFWRITE) }

  /// Symbolic links are not followed when resolving the mount point.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_NOFOLLOW`.
  @_alwaysEmitIntoClient
  public static var noSymlinkFollowingAtMountPoint: MountFlags { MountFlags(rawValue: _MNT_NOFOLLOW) }

  /// The file system is a snapshot.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_SNAPSHOT`.
  @_alwaysEmitIntoClient
  public static var snapshot: MountFlags { MountFlags(rawValue: _MNT_SNAPSHOT) }

  /// Access times are always updated when files are read. Without this flag,
  /// the file system may skip some access time updates for performance.
  ///
  /// - Note: Only available on Darwin.
  ///
  /// The corresponding C constant is `MNT_STRICTATIME`.
  @_alwaysEmitIntoClient
  public static var strictAccessTime: MountFlags { MountFlags(rawValue: _MNT_STRICTATIME) }
  #endif

  // MARK: Flags Available on FreeBSD Only

  #if os(FreeBSD)
  /// The file system is exported with Kerberos user-ID mapping.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_EXKERB`.
  @_alwaysEmitIntoClient
  public static var exportedWithKerberos: MountFlags { MountFlags(rawValue: _MNT_EXKERB) }

  /// The file system is exported publicly for WebNFS clients.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_EXPUBLIC`.
  @_alwaysEmitIntoClient
  public static var exportedPublicly: MountFlags { MountFlags(rawValue: _MNT_EXPUBLIC) }

  /// POSIX.1e ACLs are enabled on the file system.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_ACLS`.
  @_alwaysEmitIntoClient
  public static var posixACLs: MountFlags { MountFlags(rawValue: _MNT_ACLS) }

  /// The file system is journaled by `gjournal`.
  ///
  /// - Note: Only available on FreeBSD. See `gjournal(8)`.
  ///
  /// The corresponding C constant is `MNT_GJOURNAL`.
  @_alwaysEmitIntoClient
  public static var geomJournaled: MountFlags { MountFlags(rawValue: _MNT_GJOURNAL) }

  /// The file system is omitted from `df(1)` listings.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_IGNORE`.
  @_alwaysEmitIntoClient
  public static var excludedFromDiskFreeReports: MountFlags { MountFlags(rawValue: _MNT_IGNORE) }

  /// NFSv4 ACLs are enabled on the file system.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_NFS4ACLS`.
  @_alwaysEmitIntoClient
  public static var nfs4ACLs: MountFlags { MountFlags(rawValue: _MNT_NFS4ACLS) }

  /// Clustered reads are disabled on the file system.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_NOCLUSTERR`.
  @_alwaysEmitIntoClient
  public static var noClusteredReads: MountFlags { MountFlags(rawValue: _MNT_NOCLUSTERR) }

  /// Clustered writes are disabled on the file system.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_NOCLUSTERW`.
  @_alwaysEmitIntoClient
  public static var noClusteredWrites: MountFlags { MountFlags(rawValue: _MNT_NOCLUSTERW) }

  /// Newly created files in a directory with the set-user-ID bit set are owned
  /// by that directory's owner, rather than by the creating user.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_SUIDDIR`.
  @_alwaysEmitIntoClient
  public static var setUserIDDirectories: MountFlags { MountFlags(rawValue: _MNT_SUIDDIR) }

  /// Soft updates journaling is enabled on the file system.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_SUJ`.
  @_alwaysEmitIntoClient
  public static var softUpdatesJournaling: MountFlags { MountFlags(rawValue: _MNT_SUJ) }

  /// The file system is untrusted, as the integrity of its media is unknown.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_UNTRUSTED`.
  @_alwaysEmitIntoClient
  public static var untrusted: MountFlags { MountFlags(rawValue: _MNT_UNTRUSTED) }

  /// The file system was mounted by a non-root user.
  ///
  /// - Note: Only available on FreeBSD.
  ///
  /// The corresponding C constant is `MNT_USER`.
  @_alwaysEmitIntoClient
  public static var userMounted: MountFlags { MountFlags(rawValue: _MNT_USER) }

  /// The file system is marked as verified, so per-file integrity checks are
  /// skipped on execution.
  ///
  /// - Note: Only available on FreeBSD. See `mac_veriexec(4)`.
  ///
  /// The corresponding C constant is `MNT_VERIFIED`.
  @_alwaysEmitIntoClient
  public static var verified: MountFlags { MountFlags(rawValue: _MNT_VERIFIED) }
  #endif

  // MARK: Flags Available on OpenBSD Only

  #if os(OpenBSD)
  /// File permissions are not checked on the file system (FFS only).
  ///
  /// - Note: Only available on OpenBSD.
  ///
  /// The corresponding C constant is `MNT_NOPERM`.
  @_alwaysEmitIntoClient
  public static var noPermissionChecks: MountFlags { MountFlags(rawValue: _MNT_NOPERM) }

  /// Programs residing on the file system may create memory mappings that are
  /// both writable and executable.
  ///
  /// By default, requesting such a mapping (via `mmap(2)` or `mprotect(2)`)
  /// kills the process. This flag lifts that restriction.
  ///
  /// - Note: Only available on OpenBSD.
  ///
  /// The corresponding C constant is `MNT_WXALLOWED`.
  @_alwaysEmitIntoClient
  public static var writeExecuteAllowed: MountFlags { MountFlags(rawValue: _MNT_WXALLOWED) }
  #endif
}

@available(System 199, *)
extension MountFlags
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the mount flags.
  @inline(never)
  public var description: String {
    #if SYSTEM_PACKAGE_DARWIN
    let descriptions: [(Element, StaticString)] = [
      (.readOnly, ".readOnly"),
      (.synchronous, ".synchronous"),
      (.noExecution, ".noExecution"),
      (.noSetUserID, ".noSetUserID"),
      (.noAccessTime, ".noAccessTime"),
      (.noDevices, ".noDevices"),
      (.asynchronous, ".asynchronous"),
      (.exported, ".exported"),
      (.local, ".local"),
      (.quotasEnabled, ".quotasEnabled"),
      (.rootFileSystem, ".rootFileSystem"),
      (.union, ".union"),
      (.automounted, ".automounted"),
      (.multiLabel, ".multiLabel"),
      (.contentProtection, ".contentProtection"),
      (.removable, ".removable"),
      (.quarantined, ".quarantined"),
      (.supportsVolfs, ".supportsVolfs"),
      (.noBrowsing, ".noBrowsing"),
      (.ignoresOwnership, ".ignoresOwnership"),
      (.journaled, ".journaled"),
      (.noUserExtendedAttributes, ".noUserExtendedAttributes"),
      (.defersWrites, ".defersWrites"),
      (.noSymlinkFollowingAtMountPoint, ".noSymlinkFollowingAtMountPoint"),
      (.snapshot, ".snapshot"),
      (.strictAccessTime, ".strictAccessTime"),
    ]
    #elseif os(FreeBSD)
    let descriptions: [(Element, StaticString)] = [
      (.readOnly, ".readOnly"),
      (.synchronous, ".synchronous"),
      (.noExecution, ".noExecution"),
      (.noSetUserID, ".noSetUserID"),
      (.noAccessTime, ".noAccessTime"),
      (.noSymlinkFollowing, ".noSymlinkFollowing"),
      (.asynchronous, ".asynchronous"),
      (.exported, ".exported"),
      (.local, ".local"),
      (.quotasEnabled, ".quotasEnabled"),
      (.rootFileSystem, ".rootFileSystem"),
      (.union, ".union"),
      (.automounted, ".automounted"),
      (.multiLabel, ".multiLabel"),
      (.exportedReadOnly, ".exportedReadOnly"),
      (.exportedByDefault, ".exportedByDefault"),
      (.exportedAnonymously, ".exportedAnonymously"),
      (.softUpdates, ".softUpdates"),
      (.exportedWithKerberos, ".exportedWithKerberos"),
      (.exportedPublicly, ".exportedPublicly"),
      (.posixACLs, ".posixACLs"),
      (.geomJournaled, ".geomJournaled"),
      (.excludedFromDiskFreeReports, ".excludedFromDiskFreeReports"),
      (.nfs4ACLs, ".nfs4ACLs"),
      (.noClusteredReads, ".noClusteredReads"),
      (.noClusteredWrites, ".noClusteredWrites"),
      (.setUserIDDirectories, ".setUserIDDirectories"),
      (.softUpdatesJournaling, ".softUpdatesJournaling"),
      (.untrusted, ".untrusted"),
      (.userMounted, ".userMounted"),
      (.verified, ".verified"),
    ]
    #elseif os(OpenBSD)
    let descriptions: [(Element, StaticString)] = [
      (.readOnly, ".readOnly"),
      (.synchronous, ".synchronous"),
      (.noExecution, ".noExecution"),
      (.noSetUserID, ".noSetUserID"),
      (.noAccessTime, ".noAccessTime"),
      (.noDevices, ".noDevices"),
      (.asynchronous, ".asynchronous"),
      (.exported, ".exported"),
      (.local, ".local"),
      (.quotasEnabled, ".quotasEnabled"),
      (.rootFileSystem, ".rootFileSystem"),
      (.exportedReadOnly, ".exportedReadOnly"),
      (.exportedByDefault, ".exportedByDefault"),
      (.exportedAnonymously, ".exportedAnonymously"),
      (.softUpdates, ".softUpdates"),
      (.noPermissionChecks, ".noPermissionChecks"),
      (.writeExecuteAllowed, ".writeExecuteAllowed"),
    ]
    #elseif os(Linux) || os(Android)
    let descriptions: [(Element, StaticString)] = [
      (.readOnly, ".readOnly"),
      (.synchronous, ".synchronous"),
      (.noExecution, ".noExecution"),
      (.noSetUserID, ".noSetUserID"),
      (.noAccessTime, ".noAccessTime"),
      (.noDevices, ".noDevices"),
      (.mandatoryLocking, ".mandatoryLocking"),
      (.noDirectoryAccessTime, ".noDirectoryAccessTime"),
      (.relativeAccessTime, ".relativeAccessTime"),
      (.noSymlinkFollowing, ".noSymlinkFollowing"),
    ]
    #endif

    return _buildDescription(descriptions)
  }

  /// A textual representation of the mount flags, suitable for debugging.
  public var debugDescription: String { self.description }
}

#endif // !os(Windows) && !os(WASI)
