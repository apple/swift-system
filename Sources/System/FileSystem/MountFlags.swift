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

// |-------------------------------------------------------------------------------------------------------------------------------------------|
// | Swift API to C Mapping                                                                                                                    |
// |-------------------------------------------------------------------------------------------------------------------------------------------|
// | MountFlags                  | Darwin               | FreeBSD         | OpenBSD         | Linux          | Android        | WASI           |
// |-----------------------------|----------------------|-----------------|-----------------|----------------|----------------|----------------|
// | readOnly                    | MNT_RDONLY           | MNT_RDONLY      | MNT_RDONLY      | ST_RDONLY      | ST_RDONLY      | ST_RDONLY      |
// | synchronous                 | MNT_SYNCHRONOUS      | MNT_SYNCHRONOUS | MNT_SYNCHRONOUS | ST_SYNCHRONOUS | ST_SYNCHRONOUS | ST_SYNCHRONOUS |
// | noExecution                 | MNT_NOEXEC           | MNT_NOEXEC      | MNT_NOEXEC      | ST_NOEXEC      | ST_NOEXEC      | ST_NOEXEC      |
// | noSetUserID                 | MNT_NOSUID           | MNT_NOSUID      | MNT_NOSUID      | ST_NOSUID      | ST_NOSUID      | ST_NOSUID      |
// | noAccessTime                | MNT_NOATIME          | MNT_NOATIME     | MNT_NOATIME     | ST_NOATIME     | ST_NOATIME     | ST_NOATIME     |
// | noDevices                   | MNT_NODEV            | N/A             | MNT_NODEV       | ST_NODEV       | ST_NODEV       | ST_NODEV       |
// | mandatoryLockingPermitted   | N/A                  | N/A             | N/A             | ST_MANDLOCK    | ST_MANDLOCK    | ST_MANDLOCK    |
// | noDirectoryAccessTime       | N/A                  | N/A             | N/A             | ST_NODIRATIME  | ST_NODIRATIME  | ST_NODIRATIME  |
// | relativeAccessTime          | N/A                  | N/A             | N/A             | ST_RELATIME    | ST_RELATIME    | ST_RELATIME    |
// | write                       | N/A                  | N/A             | N/A             | ST_WRITE       | N/A            | ST_WRITE       |
// | appendOnly                  | N/A                  | N/A             | N/A             | ST_APPEND      | N/A            | ST_APPEND      |
// | immutable                   | N/A                  | N/A             | N/A             | ST_IMMUTABLE   | N/A            | ST_IMMUTABLE   |
// | noSymlinkFollow             | N/A                  | MNT_NOSYMFOLLOW | N/A             | ST_NOSYMFOLLOW | ST_NOSYMFOLLOW | N/A            |
// | asynchronous                | MNT_ASYNC            | MNT_ASYNC       | MNT_ASYNC       | N/A            | N/A            | N/A            |
// | exported                    | MNT_EXPORTED         | MNT_EXPORTED    | MNT_EXPORTED    | N/A            | N/A            | N/A            |
// | local                       | MNT_LOCAL            | MNT_LOCAL       | MNT_LOCAL       | N/A            | N/A            | N/A            |
// | quota                       | MNT_QUOTA            | MNT_QUOTA       | MNT_QUOTA       | N/A            | N/A            | N/A            |
// | rootFileSystem              | MNT_ROOTFS           | MNT_ROOTFS      | MNT_ROOTFS      | N/A            | N/A            | N/A            |
// | union                       | MNT_UNION            | MNT_UNION       | N/A             | N/A            | N/A            | N/A            |
// | automounted                 | MNT_AUTOMOUNTED      | MNT_AUTOMOUNTED | N/A             | N/A            | N/A            | N/A            |
// | multiLabel                  | MNT_MULTILABEL       | MNT_MULTILABEL  | N/A             | N/A            | N/A            | N/A            |
// | exportedReadOnly            | N/A                  | MNT_EXRDONLY    | MNT_EXRDONLY    | N/A            | N/A            | N/A            |
// | exportedByDefault           | N/A                  | MNT_DEFEXPORTED | MNT_DEFEXPORTED | N/A            | N/A            | N/A            |
// | exportedAnonymously         | N/A                  | MNT_EXPORTANON  | MNT_EXPORTANON  | N/A            | N/A            | N/A            |
// | softUpdates                 | N/A                  | MNT_SOFTDEP     | MNT_SOFTDEP     | N/A            | N/A            | N/A            |
// | contentProtection           | MNT_CPROTECT         | N/A             | N/A             | N/A            | N/A            | N/A            |
// | removable                   | MNT_REMOVABLE        | N/A             | N/A             | N/A            | N/A            | N/A            |
// | quarantine                  | MNT_QUARANTINE       | N/A             | N/A             | N/A            | N/A            | N/A            |
// | volumeFileSystem            | MNT_DOVOLFS          | N/A             | N/A             | N/A            | N/A            | N/A            |
// | noBrowsing                  | MNT_DONTBROWSE       | N/A             | N/A             | N/A            | N/A            | N/A            |
// | ignoreOwnership             | MNT_IGNORE_OWNERSHIP | N/A             | N/A             | N/A            | N/A            | N/A            |
// | journaled                   | MNT_JOURNALED        | N/A             | N/A             | N/A            | N/A            | N/A            |
// | noUserExtendedAttributes    | MNT_NOUSERXATTR      | N/A             | N/A             | N/A            | N/A            | N/A            |
// | deferWrites                 | MNT_DEFWRITE         | N/A             | N/A             | N/A            | N/A            | N/A            |
// | noSymlinkFollowAtMountPoint | MNT_NOFOLLOW         | N/A             | N/A             | N/A            | N/A            | N/A            |
// | snapshot                    | MNT_SNAPSHOT         | N/A             | N/A             | N/A            | N/A            | N/A            |
// | strictAccessTime            | MNT_STRICTATIME      | N/A             | N/A             | N/A            | N/A            | N/A            |
// | exportedKerberos            | N/A                  | MNT_EXKERB      | N/A             | N/A            | N/A            | N/A            |
// | exportedPublic              | N/A                  | MNT_EXPUBLIC    | N/A             | N/A            | N/A            | N/A            |
// | posixACLs                   | N/A                  | MNT_ACLS        | N/A             | N/A            | N/A            | N/A            |
// | geomJournaled               | N/A                  | MNT_GJOURNAL    | N/A             | N/A            | N/A            | N/A            |
// | excludedFromDiskFreeReports | N/A                  | MNT_IGNORE      | N/A             | N/A            | N/A            | N/A            |
// | nfs4ACLs                    | N/A                  | MNT_NFS4ACLS    | N/A             | N/A            | N/A            | N/A            |
// | noClusterRead               | N/A                  | MNT_NOCLUSTERR  | N/A             | N/A            | N/A            | N/A            |
// | noClusterWrite              | N/A                  | MNT_NOCLUSTERW  | N/A             | N/A            | N/A            | N/A            |
// | setUserIDDirectory          | N/A                  | MNT_SUIDDIR     | N/A             | N/A            | N/A            | N/A            |
// | softUpdateJournaling        | N/A                  | MNT_SUJ         | N/A             | N/A            | N/A            | N/A            |
// | untrusted                   | N/A                  | MNT_UNTRUSTED   | N/A             | N/A            | N/A            | N/A            |
// | mountedByUser               | N/A                  | MNT_USER        | N/A             | N/A            | N/A            | N/A            |
// | verified                    | N/A                  | MNT_VERIFIED    | N/A             | N/A            | N/A            | N/A            |
// | noPermissionChecks          | N/A                  | N/A             | MNT_NOPERM      | N/A            | N/A            | N/A            |
// | writeExecuteAllowed         | N/A                  | N/A             | MNT_WXALLOWED   | N/A            | N/A            | N/A            |
// |-------------------------------------------------------------------------------------------------------------------------------------------|

#if !os(Windows)

/// Options employed when mounting a file system.
///
/// These are the flags reported in the `f_flags` field of a `statfs` struct on
/// Darwin and BSD, or the `f_flag` field of a `statvfs` struct on other
/// platforms.
///
/// - Note: Only available on Unix-like platforms.
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

  /// Set-user-ID and set-group-ID bits are not honored on the file system.
  ///
  /// The corresponding C constant is `MNT_NOSUID` on Darwin and BSD,
  /// or `ST_NOSUID` otherwise.
  @_alwaysEmitIntoClient
  public static var noSetUserID: MountFlags { MountFlags(rawValue: _MOUNT_NOSUID) }

  /// Access times are not updated on the file system.
  ///
  /// The corresponding C constant is `MNT_NOATIME` on Darwin and BSD,
  /// or `ST_NOATIME` otherwise.
  /// - Note: On OpenBSD, access time may still be updated when the
  ///   modification or status-change time is also being updated.
  @_alwaysEmitIntoClient
  public static var noAccessTime: MountFlags { MountFlags(rawValue: _MOUNT_NOATIME) }

  // MARK: Flags Available on All Platforms Except FreeBSD

  #if !os(FreeBSD)
  /// Special files may not be interpreted on the file system.
  ///
  /// The corresponding C constant is `MNT_NODEV` on Darwin and OpenBSD,
  /// or `ST_NODEV` otherwise.
  /// - Note: Not available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var noDevices: MountFlags { MountFlags(rawValue: _MOUNT_NODEV) }
  #endif

  // MARK: Flags Available on Linux, WASI, and Android

  #if os(Linux) || os(WASI) || os(Android)
  /// The file system permits mandatory file locking.
  ///
  /// The corresponding C constant is `ST_MANDLOCK`.
  /// - Note: Only available on Linux, WASI, and Android.
  /// - Note: Mandatory locking was deprecated and removed in Linux 5.15.
  @_alwaysEmitIntoClient
  public static var mandatoryLockingPermitted: MountFlags { MountFlags(rawValue: _ST_MANDLOCK) }

  /// Directory access times are not updated on the file system.
  ///
  /// The corresponding C constant is `ST_NODIRATIME`.
  /// - Note: Only available on Linux, WASI, and Android.
  @_alwaysEmitIntoClient
  public static var noDirectoryAccessTime: MountFlags { MountFlags(rawValue: _ST_NODIRATIME) }

  /// The access time is only updated if it's earlier than or equal to the file's
  /// last modification or status-change time, or if it's more than a day old.
  ///
  /// The corresponding C constant is `ST_RELATIME`.
  /// - Note: Only available on Linux, WASI, and Android.
  @_alwaysEmitIntoClient
  public static var relativeAccessTime: MountFlags { MountFlags(rawValue: _ST_RELATIME) }
  #endif

  // MARK: Flags Available on Linux and WASI Only

  #if os(Linux) || os(WASI)
  /// Files, directories, and symbolic links on the file system are writable.
  ///
  /// The corresponding C constant is `ST_WRITE`.
  /// - Note: Only available on Linux and WASI.
  @_alwaysEmitIntoClient
  public static var write: MountFlags { MountFlags(rawValue: _ST_WRITE) }

  /// Files on the file system are append-only.
  ///
  /// The corresponding C constant is `ST_APPEND`.
  /// - Note: Only available on Linux and WASI.
  @_alwaysEmitIntoClient
  public static var appendOnly: MountFlags { MountFlags(rawValue: _ST_APPEND) }

  /// Files on the file system are immutable.
  ///
  /// The corresponding C constant is `ST_IMMUTABLE`.
  /// - Note: Only available on Linux and WASI.
  @_alwaysEmitIntoClient
  public static var immutable: MountFlags { MountFlags(rawValue: _ST_IMMUTABLE) }
  #endif

  // MARK: Flags Available on Linux, Android, and FreeBSD

  #if os(Linux) || os(Android) || os(FreeBSD)
  /// Symbolic links are not followed when resolving paths on the file system.
  ///
  /// Unlike Darwin's `noSymlinkFollowAtMountPoint`, this suppresses symlink
  /// following for all path resolution on the mount, not just when resolving
  /// the mount point.
  ///
  /// The corresponding C constant is `MNT_NOSYMFOLLOW` on FreeBSD,
  /// or `ST_NOSYMFOLLOW` on Linux and Android.
  /// - Note: Only available on Linux, Android, and FreeBSD.
  @_alwaysEmitIntoClient
  public static var noSymlinkFollow: MountFlags { MountFlags(rawValue: _MOUNT_NOSYMFOLLOW) }
  #endif

  // MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  /// The file system is written to asynchronously.
  ///
  /// The corresponding C constant is `MNT_ASYNC`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public static var asynchronous: MountFlags { MountFlags(rawValue: _MNT_ASYNC) }

  /// The file system is exported for use over the network via NFS.
  ///
  /// The corresponding C constant is `MNT_EXPORTED`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public static var exported: MountFlags { MountFlags(rawValue: _MNT_EXPORTED) }

  /// The file system is stored locally, rather than being accessed over a network.
  ///
  /// The corresponding C constant is `MNT_LOCAL`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public static var local: MountFlags { MountFlags(rawValue: _MNT_LOCAL) }

  /// Quotas are enabled on the file system.
  ///
  /// The corresponding C constant is `MNT_QUOTA`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public static var quota: MountFlags { MountFlags(rawValue: _MNT_QUOTA) }

  /// The file system is the root file system.
  ///
  /// The corresponding C constant is `MNT_ROOTFS`.
  /// - Note: Only available on Darwin and BSD.
  @_alwaysEmitIntoClient
  public static var rootFileSystem: MountFlags { MountFlags(rawValue: _MNT_ROOTFS) }
  #endif

  // MARK: Flags Available on Darwin and FreeBSD

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// The file system is unioned with the underlying file system, rather than
  /// obscuring it.
  ///
  /// The corresponding C constant is `MNT_UNION`.
  /// - Note: Only available on Darwin and FreeBSD.
  @_alwaysEmitIntoClient
  public static var union: MountFlags { MountFlags(rawValue: _MNT_UNION) }

  /// The file system was mounted by the automounter.
  ///
  /// The corresponding C constant is `MNT_AUTOMOUNTED`.
  /// - Note: Only available on Darwin and FreeBSD. See `autofs(4)`.
  @_alwaysEmitIntoClient
  public static var automounted: MountFlags { MountFlags(rawValue: _MNT_AUTOMOUNTED) }

  /// The file system supports Mandatory Access Control (MAC) labels for
  /// individual objects.
  ///
  /// The corresponding C constant is `MNT_MULTILABEL`.
  /// - Note: Only available on Darwin and FreeBSD.
  @_alwaysEmitIntoClient
  public static var multiLabel: MountFlags { MountFlags(rawValue: _MNT_MULTILABEL) }
  #endif

  // MARK: Flags Available on FreeBSD and OpenBSD

  #if os(FreeBSD) || os(OpenBSD)
  /// The file system is exported for reading only.
  ///
  /// The corresponding C constant is `MNT_EXRDONLY`.
  /// - Note: Only available on FreeBSD and OpenBSD.
  @_alwaysEmitIntoClient
  public static var exportedReadOnly: MountFlags { MountFlags(rawValue: _MNT_EXRDONLY) }

  /// The file system is exported for reading and writing to any host by default.
  ///
  /// The corresponding C constant is `MNT_DEFEXPORTED`.
  /// - Note: Only available on FreeBSD and OpenBSD.
  @_alwaysEmitIntoClient
  public static var exportedByDefault: MountFlags { MountFlags(rawValue: _MNT_DEFEXPORTED) }

  /// The file system maps all remote users to the anonymous user account.
  ///
  /// The corresponding C constant is `MNT_EXPORTANON`.
  /// - Note: Only available on FreeBSD and OpenBSD.
  @_alwaysEmitIntoClient
  public static var exportedAnonymously: MountFlags { MountFlags(rawValue: _MNT_EXPORTANON) }

  /// The file system uses soft updates.
  ///
  /// The corresponding C constant is `MNT_SOFTDEP`.
  /// - Note: Only available on FreeBSD and OpenBSD. Accepted for compatibility
  ///   on OpenBSD, but has no effect there.
  @_alwaysEmitIntoClient
  public static var softUpdates: MountFlags { MountFlags(rawValue: _MNT_SOFTDEP) }
  #endif

  // MARK: Flags Available on Darwin Only

  #if SYSTEM_PACKAGE_DARWIN
  /// The file system supports per-file encrypted data protection.
  ///
  /// The corresponding C constant is `MNT_CPROTECT`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var contentProtection: MountFlags { MountFlags(rawValue: _MNT_CPROTECT) }

  /// The file system resides on removable media.
  ///
  /// The corresponding C constant is `MNT_REMOVABLE`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var removable: MountFlags { MountFlags(rawValue: _MNT_REMOVABLE) }

  /// The file system is quarantined.
  ///
  /// The corresponding C constant is `MNT_QUARANTINE`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var quarantine: MountFlags { MountFlags(rawValue: _MNT_QUARANTINE) }

  /// The file system supports volfs.
  ///
  /// The corresponding C constant is `MNT_DOVOLFS`.
  /// - Note: Only available on Darwin. Deprecated since Mac OS X 10.5 and
  ///   not set on modern systems.
  @_alwaysEmitIntoClient
  public static var volumeFileSystem: MountFlags { MountFlags(rawValue: _MNT_DOVOLFS) }

  /// The file system should not be presented to the user for browsing
  /// (e.g. hidden in Finder).
  ///
  /// The corresponding C constant is `MNT_DONTBROWSE`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var noBrowsing: MountFlags { MountFlags(rawValue: _MNT_DONTBROWSE) }

  /// Ownership information on the file system is ignored.
  ///
  /// The corresponding C constant is `MNT_IGNORE_OWNERSHIP`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var ignoreOwnership: MountFlags { MountFlags(rawValue: _MNT_IGNORE_OWNERSHIP) }

  /// The file system is journaled.
  ///
  /// The corresponding C constant is `MNT_JOURNALED`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var journaled: MountFlags { MountFlags(rawValue: _MNT_JOURNALED) }

  /// User extended attributes are not allowed on the file system.
  ///
  /// The corresponding C constant is `MNT_NOUSERXATTR`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var noUserExtendedAttributes: MountFlags { MountFlags(rawValue: _MNT_NOUSERXATTR) }

  /// The file system defers writes.
  ///
  /// The corresponding C constant is `MNT_DEFWRITE`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var deferWrites: MountFlags { MountFlags(rawValue: _MNT_DEFWRITE) }

  /// Symbolic links are not followed when resolving the mount point.
  ///
  /// The corresponding C constant is `MNT_NOFOLLOW`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var noSymlinkFollowAtMountPoint: MountFlags { MountFlags(rawValue: _MNT_NOFOLLOW) }

  /// The mount is a snapshot.
  ///
  /// The corresponding C constant is `MNT_SNAPSHOT`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var snapshot: MountFlags { MountFlags(rawValue: _MNT_SNAPSHOT) }

  /// Access times are always updated on access. Relatime-style optimizations
  /// are disabled.
  ///
  /// The corresponding C constant is `MNT_STRICTATIME`.
  /// - Note: Only available on Darwin.
  @_alwaysEmitIntoClient
  public static var strictAccessTime: MountFlags { MountFlags(rawValue: _MNT_STRICTATIME) }
  #endif

  // MARK: Flags Available on FreeBSD Only

  #if os(FreeBSD)
  /// The file system is exported with Kerberos user-ID mapping.
  ///
  /// The corresponding C constant is `MNT_EXKERB`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var exportedKerberos: MountFlags { MountFlags(rawValue: _MNT_EXKERB) }

  /// The file system is exported publicly for WebNFS clients.
  ///
  /// The corresponding C constant is `MNT_EXPUBLIC`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var exportedPublic: MountFlags { MountFlags(rawValue: _MNT_EXPUBLIC) }

  /// The file system supports POSIX.1e ACLs.
  ///
  /// The corresponding C constant is `MNT_ACLS`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var posixACLs: MountFlags { MountFlags(rawValue: _MNT_ACLS) }

  /// The file system uses `gjournal`.
  ///
  /// The corresponding C constant is `MNT_GJOURNAL`.
  /// - Note: Only available on FreeBSD. See `gjournal(8)`.
  @_alwaysEmitIntoClient
  public static var geomJournaled: MountFlags { MountFlags(rawValue: _MNT_GJOURNAL) }

  /// The file system is omitted from `df(1)` listings.
  ///
  /// The corresponding C constant is `MNT_IGNORE`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var excludedFromDiskFreeReports: MountFlags { MountFlags(rawValue: _MNT_IGNORE) }

  /// The file system supports NFSv4 ACLs.
  ///
  /// The corresponding C constant is `MNT_NFS4ACLS`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var nfs4ACLs: MountFlags { MountFlags(rawValue: _MNT_NFS4ACLS) }

  /// Clustered reads are disabled on the file system.
  ///
  /// The corresponding C constant is `MNT_NOCLUSTERR`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var noClusterRead: MountFlags { MountFlags(rawValue: _MNT_NOCLUSTERR) }

  /// Clustered writes are disabled on the file system.
  ///
  /// The corresponding C constant is `MNT_NOCLUSTERW`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var noClusterWrite: MountFlags { MountFlags(rawValue: _MNT_NOCLUSTERW) }

  /// Newly created files in a directory with the set-user-ID bit set are owned
  /// by that directory's owner, rather than by the creating user.
  ///
  /// The corresponding C constant is `MNT_SUIDDIR`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var setUserIDDirectory: MountFlags { MountFlags(rawValue: _MNT_SUIDDIR) }

  /// The file system uses soft updates with journaling.
  ///
  /// The corresponding C constant is `MNT_SUJ`.
  /// - Note: Only available on FreeBSD. Combines `softUpdates` with a journal
  ///   for fast recovery.
  @_alwaysEmitIntoClient
  public static var softUpdateJournaling: MountFlags { MountFlags(rawValue: _MNT_SUJ) }

  /// The file system is untrusted, as the integrity of its media is unknown.
  ///
  /// The corresponding C constant is `MNT_UNTRUSTED`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var untrusted: MountFlags { MountFlags(rawValue: _MNT_UNTRUSTED) }

  /// The file system was mounted by a non-root user.
  ///
  /// The corresponding C constant is `MNT_USER`.
  /// - Note: Only available on FreeBSD.
  @_alwaysEmitIntoClient
  public static var mountedByUser: MountFlags { MountFlags(rawValue: _MNT_USER) }

  /// The file system is marked as verified, so per-file integrity checks are
  /// skipped on execution.
  ///
  /// The corresponding C constant is `MNT_VERIFIED`.
  /// - Note: Only available on FreeBSD. See `mac_veriexec(4)`.
  @_alwaysEmitIntoClient
  public static var verified: MountFlags { MountFlags(rawValue: _MNT_VERIFIED) }
  #endif

  // MARK: Flags Available on OpenBSD Only

  #if os(OpenBSD)
  /// File permissions are not checked on the file system (FFS only).
  ///
  /// The corresponding C constant is `MNT_NOPERM`.
  /// - Note: Only available on OpenBSD.
  @_alwaysEmitIntoClient
  public static var noPermissionChecks: MountFlags { MountFlags(rawValue: _MNT_NOPERM) }

  /// Programs residing on the file system may create memory mappings that are
  /// both writable and executable.
  ///
  /// By default, requesting such a mapping (via `mmap(2)` or `mprotect(2)`)
  /// kills the process. This flag lifts that restriction.
  ///
  /// The corresponding C constant is `MNT_WXALLOWED`.
  /// - Note: Only available on OpenBSD.
  @_alwaysEmitIntoClient
  public static var writeExecuteAllowed: MountFlags { MountFlags(rawValue: _MNT_WXALLOWED) }
  #endif
}

#endif // !os(Windows)
