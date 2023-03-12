/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
import CSystem
#elseif os(Windows)
// Nothing
#else
#error("Unsupported Platform")
#endif

#if !os(Windows)

extension FileDescriptor {
  /// Commands (and various constants) to pass to `fcntl`.
  @frozen
  public struct Command: RawRepresentable, Hashable, Codable, Sendable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }
  }
}

extension FileDescriptor.Command {
  @_alwaysEmitIntoClient
  private init(_ rawValue: CInt) { self.init(rawValue: rawValue) }

  /// Duplicate file descriptor.
  ///
  /// Note: A Swiftier wrapper is
  /// `FileDescriptor.duplicate(minRawValue:closeOnExec:)`.
  ///
  /// The corresponding C constant is `F_DUPFD`.
  @_alwaysEmitIntoClient
  public static var duplicate: Self { .init(F_DUPFD) }

  /// Mark the dup with FD_CLOEXEC.
  ///
  /// The corresponding C constant is `F_DUPFD_CLOEXEC`
  @_alwaysEmitIntoClient
  public static var duplicateCloseOnExec: Self {
    .init(F_DUPFD_CLOEXEC)
  }

  /// Get file descriptor flags.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.getFlags()`.
  ///
  /// The corresponding C constant is `F_GETFD`.
  @_alwaysEmitIntoClient
  public static var getFlags: Self { .init(F_GETFD) }

  /// Set file descriptor flags.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.setFlags(_:)`.
  ///
  /// The corresponding C constant is `F_SETFD`.
  @_alwaysEmitIntoClient
  public static var setFlags: Self { .init(F_SETFD) }

  /// Get file status flags.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.getStatusFlags()`.
  ///
  /// The corresponding C constant is `F_GETFL`.
  @_alwaysEmitIntoClient
  public static var getStatusFlags: Self {
    .init(F_GETFL)
  }

  /// Set file status flags.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.setStatusFlags(_:)`.
  ///
  /// The corresponding C constant is `F_SETFL`.
  @_alwaysEmitIntoClient
  public static var setStatusFlags: Self {
    .init(F_SETFL)
  }

  /// Get SIGIO/SIGURG proc/pgrp.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.getOwner()`.
  ///
  /// The corresponding C constant is `F_GETOWN`.
  @_alwaysEmitIntoClient
  public static var getOwner: Self { .init(F_GETOWN) }

  /// Set SIGIO/SIGURG proc/pgrp.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.setOwner(_:)`.
  ///
  /// The corresponding C constant is `F_SETOWN`.
  @_alwaysEmitIntoClient
  public static var setOwner: Self { .init(F_SETOWN) }

  /// Get record locking information.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.getLock(_:_:)`.
  ///
  /// The corresponding C constant is `F_GETLK`.
  @_alwaysEmitIntoClient
  public static var getLock: Self { .init(F_GETLK) }

  /// Set record locking information.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.setLock(_:_:)`.
  ///
  /// The corresponding C constant is `F_SETLK`.
  @_alwaysEmitIntoClient
  public static var setLock: Self { .init(F_SETLK) }

  /// Wait if blocked.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.setLock(_:_:)`.
  ///
  /// The corresponding C constant is `F_SETLKW`.
  @_alwaysEmitIntoClient
  public static var setLockWait: Self { .init(F_SETLKW) }

#if !os(Linux)

  /// Wait if blocked, return on timeout.
  ///
  /// TODO: A Swiftier wrapper
  ///
  /// The corresponding C constant is `F_SETLKWTIMEOUT`.
  @_alwaysEmitIntoClient
  public static var setLockWaitTimout: Self {
    .init(F_SETLKWTIMEOUT)
  }

  /// The corresponding C constant is `F_FLUSH_DATA`.
  @_alwaysEmitIntoClient
  public static var flushData: Self {
    .init(F_FLUSH_DATA)
  }

  /// Used for regression test.
  ///
  /// The corresponding C constant is `F_CHKCLEAN`.
  @_alwaysEmitIntoClient
  public static var checkClean: Self { .init(F_CHKCLEAN) }

  // TODO: Higher level API which will call `fallocate(2)` on Linux and use
  // TODO: the below on Darwin. Then we can call out to that.

  /// Preallocate storage.
  ///
  /// The corresponding C constant is `F_PREALLOCATE`.
  @_alwaysEmitIntoClient
  public static var preallocate: Self {
    .init(F_PREALLOCATE)
  }

  /// Truncate a file. Equivalent to calling truncate(2).
  ///
  /// The corresponding C constant is `F_SETSIZE`.
  @_alwaysEmitIntoClient
  public static var setSize: Self { .init(F_SETSIZE) }

  /// Issue an advisory read async with no copy to user.
  ///
  /// The corresponding C constant is `F_RDADVISE`.
  @_alwaysEmitIntoClient
  public static var readAdvise: Self { .init(F_RDADVISE) }

  /// Turn read ahead off/on for this fd.
  ///
  /// The corresponding C constant is `F_RDAHEAD`.
  @_alwaysEmitIntoClient
  public static var readAhead: Self { .init(F_RDAHEAD) }

  /// Turn data caching off/on for this fd.
  ///
  /// The corresponding C constant is `F_NOCACHE`.
  @_alwaysEmitIntoClient
  public static var noCache: Self { .init(F_NOCACHE) }

  /// File offset to device offset.
  ///
  /// The corresponding C constant is `F_LOG2PHYS`.
  @_alwaysEmitIntoClient
  public static var logicalToPhysical: Self { .init(F_LOG2PHYS) }

  /// Return the full path of the fd.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.getPath(_:)`.
  ///
  /// The corresponding C constant is `F_GETPATH`.
  @_alwaysEmitIntoClient
  public static var getPath: Self { .init(F_GETPATH) }

  /// Synchronize the file system and ask the drive to flush to the media.
  ///
  /// The corresponding C constant is `F_FULLFSYNC`.
  @_alwaysEmitIntoClient
  public static var fullFileSystemSync: Self { .init(F_FULLFSYNC) }

  /// Find which component (if any) is a package.
  ///
  /// The corresponding C constant is `F_PATHPKG_CHECK`.
  @_alwaysEmitIntoClient
  public static var pathPackageCheck: Self {
    .init(F_PATHPKG_CHECK)
  }

  /// "Freeze" all file system operations.
  ///
  /// The corresponding C constant is `F_FREEZE_FS`.
  @_alwaysEmitIntoClient
  public static var freezeFileSystem: Self { .init(F_FREEZE_FS) }

  /// "Thaw" all file system operations.
  ///
  /// The corresponding C constant is `F_THAW_FS`.
  @_alwaysEmitIntoClient
  public static var thawFileSystem: Self { .init(F_THAW_FS) }

  /// Turn data caching off/on (globally) for this file.
  ///
  /// The corresponding C constant is `F_GLOBAL_NOCACHE`.
  @_alwaysEmitIntoClient
  public static var globalNoCache: Self {
    .init(F_GLOBAL_NOCACHE)
  }

  /// Add detached signatures.
  ///
  /// The corresponding C constant is `F_ADDSIGS`.
  @_alwaysEmitIntoClient
  public static var addSignatures: Self {
    .init(F_ADDSIGS)
  }

  /// Add signature from same file (used by dyld for shared libs).
  ///
  /// The corresponding C constant is `F_ADDFILESIGS`.
  @_alwaysEmitIntoClient
  public static var addFileSignatures: Self {
    .init(F_ADDFILESIGS)
  }

  /// Used in conjunction with `.noCache` to indicate that DIRECT,
  /// synchonous writes should not be used (i.e. its ok to temporaily create
  /// cached pages).
  ///
  /// The corresponding C constant is `F_NODIRECT`.
  @_alwaysEmitIntoClient
  public static var noDirect: Self { .init(F_NODIRECT) }

  /// Get the protection class of a file from the EA, returns int.
  ///
  /// The corresponding C constant is `F_GETPROTECTIONCLASS`.
  @_alwaysEmitIntoClient
  public static var getProtectionClass: Self {
    .init(F_GETPROTECTIONCLASS)
  }

  /// Set the protection class of a file for the EA, requires int.
  ///
  /// The corresponding C constant is `F_SETPROTECTIONCLASS`.
  @_alwaysEmitIntoClient
  public static var setProtectionClass: Self {
    .init(F_SETPROTECTIONCLASS)
  }

  /// File offset to device offset, extended.
  ///
  /// The corresponding C constant is `F_LOG2PHYS_EXT`.
  @_alwaysEmitIntoClient
  public static var log2physExtended: Self {
    .init(F_LOG2PHYS_EXT)
  }

  /// Get record locking information, per-process.
  ///
  /// The corresponding C constant is `F_GETLKPID`.
  @_alwaysEmitIntoClient
  public static var getLockPID: Self { .init(F_GETLKPID) }

  /// Mark the file as being the backing store for another filesystem.
  ///
  /// The corresponding C constant is `F_SETBACKINGSTORE`.
  @_alwaysEmitIntoClient
  public static var setBackingStore: Self {
    .init(F_SETBACKINGSTORE)
  }

  /// Return the full path of the FD, but error in specific mtmd
  /// circumstances.
  ///
  /// The corresponding C constant is `F_GETPATH_MTMINFO`.
  @_alwaysEmitIntoClient
  public static var getPathMTMDInfo: Self {
    .init(F_GETPATH_MTMINFO)
  }

  /// Returns the code directory, with associated hashes, to the caller.
  ///
  /// The corresponding C constant is `F_GETCODEDIR`.
  @_alwaysEmitIntoClient
  public static var getCodeDirectory: Self {
    .init(F_GETCODEDIR)
  }

  /// No SIGPIPE generated on EPIPE.
  ///
  /// The corresponding C constant is `F_SETNOSIGPIPE`.
  @_alwaysEmitIntoClient
  public static var setNoSigPipe: Self {
    .init(F_SETNOSIGPIPE)
  }

  /// Status of SIGPIPE for this fd.
  ///
  /// The corresponding C constant is `F_GETNOSIGPIPE`.
  @_alwaysEmitIntoClient
  public static var getNoSigPipe: Self {
    .init(F_GETNOSIGPIPE)
  }

  /// For some cases, we need to rewrap the key for AKS/MKB.
  ///
  /// The corresponding C constant is `F_TRANSCODEKEY`.
  @_alwaysEmitIntoClient
  public static var transcodeKey: Self {
    .init(F_TRANSCODEKEY)
  }

  /// File being written to a by single writer... if throttling enabled,
  /// writes may be broken into smaller chunks with throttling in between.
  ///
  /// The corresponding C constant is `F_SINGLE_WRITER`.
  @_alwaysEmitIntoClient
  public static var singleWriter: Self {
    .init(F_SINGLE_WRITER)
  }


  /// Get the protection version number for this filesystem.
  ///
  /// The corresponding C constant is `F_GETPROTECTIONLEVEL`.
  @_alwaysEmitIntoClient
  public static var getProtectionLevel: Self {
    .init(F_GETPROTECTIONLEVEL)
  }


  /// Add detached code signatures (used by dyld for shared libs).
  ///
  /// The corresponding C constant is `F_FINDSIGS`.
  @_alwaysEmitIntoClient
  public static var findSignatures: Self {
    .init(F_FINDSIGS)
  }

  /// Add signature from same file, only if it is signed by Apple (used by
  /// dyld for simulator).
  ///
  /// The corresponding C constant is `F_ADDFILESIGS_FOR_DYLD_SIM`.
  @_alwaysEmitIntoClient
  public static var addFileSignaturesForDYLDSim: Self {
    .init(F_ADDFILESIGS_FOR_DYLD_SIM)
  }

  /// Fsync + issue barrier to drive.
  ///
  /// The corresponding C constant is `F_BARRIERFSYNC`.
  @_alwaysEmitIntoClient
  public static var barrierFileSystemSync: Self {
    .init(F_BARRIERFSYNC)
  }

  /// Add signature from same file, return end offset in structure on success.
  ///
  /// The corresponding C constant is `F_ADDFILESIGS_RETURN`.
  @_alwaysEmitIntoClient
  public static var addFileSignaturesReturn: Self {
    .init(F_ADDFILESIGS_RETURN)
  }

  /// Check if Library Validation allows this Mach-O file to be mapped into
  /// the calling process.
  ///
  /// The corresponding C constant is `F_CHECK_LV`.
  @_alwaysEmitIntoClient
  public static var checkLibraryValidation: Self {
    .init(F_CHECK_LV)
  }

  /// Deallocate a range of the file.
  ///
  /// The corresponding C constant is `F_PUNCHHOLE`.
  @_alwaysEmitIntoClient
  public static var punchhole: Self { .init(F_PUNCHHOLE) }

  /// Trim an active file.
  ///
  /// The corresponding C constant is `F_TRIM_ACTIVE_FILE`.
  @_alwaysEmitIntoClient
  public static var trimActiveFile: Self {
    .init(F_TRIM_ACTIVE_FILE)
  }

  /// Synchronous advisory read fcntl for regular and compressed file.
  ///
  /// The corresponding C constant is `F_SPECULATIVE_READ`.
  @_alwaysEmitIntoClient
  public static var speculativeRead: Self {
    .init(F_SPECULATIVE_READ)
  }

  /// Return the full path without firmlinks of the fd.
  ///
  /// Note: A Swiftier wrapper is `FileDescriptor.getPath(_:)`.
  ///
  /// The corresponding C constant is `F_GETPATH_NOFIRMLINK`.
  @_alwaysEmitIntoClient
  public static var getPathNoFirmLink: Self {
    .init(F_GETPATH_NOFIRMLINK)
  }

  /// Add signature from same file, return information.
  ///
  /// The corresponding C constant is `F_ADDFILESIGS_INFO`.
  @_alwaysEmitIntoClient
  public static var addFileSignatureInfo: Self {
    .init(F_ADDFILESIGS_INFO)
  }

  /// Add supplemental signature from same file with fd reference to original.
  ///
  /// The corresponding C constant is `F_ADDFILESUPPL`.
  @_alwaysEmitIntoClient
  public static var addFileSupplementalSignature: Self {
    .init(F_ADDFILESUPPL)
  }

  /// Look up code signature information attached to a file or slice.
  ///
  /// The corresponding C constant is `F_GETSIGSINFO`.
  @_alwaysEmitIntoClient
  public static var getSignatureInfo: Self {
    .init(F_GETSIGSINFO)
  }

#endif // !os(Linux)

  /// Get open file description record locking information.
  ///
  /// The corresponding C constant is `F_GETLK`.
  @_alwaysEmitIntoClient
  public static var getOFDLock: Self { .init(_F_OFD_GETLK) }

  /// Set open file description record locking information.
  ///
  /// The corresponding C constant is `F_SETLK`.
  @_alwaysEmitIntoClient
  public static var setOFDLock: Self { .init(_F_OFD_SETLK) }

  /// Set open file description record locking information and wait until
  /// the request can be completed.
  ///
  /// The corresponding C constant is `F_SETLKW`.
  @_alwaysEmitIntoClient
  public static var setOFDLockWait: Self { .init(_F_OFD_SETLKW) }

#if !os(Linux)
  /// Set open file description record locking information and wait until
  /// the request can be completed, returning on timeout.
  ///
  /// The corresponding C constant is `F_SETLKWTIMEOUT`.
  @_alwaysEmitIntoClient
  public static var setOFDLockWaitTimout: Self {
    .init(_F_OFD_SETLKWTIMEOUT)
  }
#endif
}

internal var _maxPathLen: Int { Int(MAXPATHLEN) }

#endif // !os(Windows)

