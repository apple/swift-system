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

// MARK: - RawRepresentable wrappers
extension FileDescriptor {
  /// File descriptor flags.
  @frozen
  public struct Flags: OptionSet, Sendable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// The given file descriptor will be automatically closed in the
    /// successor process image when one of the execv(2) or posix_spawn(2)
    /// family of system calls is invoked.
    ///
    /// The corresponding C global is `FD_CLOEXEC`.
    @_alwaysEmitIntoClient
    public static var closeOnExec: Flags { Flags(rawValue: FD_CLOEXEC) }
  }

  /// File descriptor status flags.
  @frozen
  public struct StatusFlags: OptionSet, Sendable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    fileprivate init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Non-blocking I/O; if no data is available to a read
    /// call, or if a write operation would block, the read or
    /// write call throws `Errno.resourceTemporarilyUnavailable`.
    ///
    /// The corresponding C constant is `O_NONBLOCK`.
    @_alwaysEmitIntoClient
    public static var nonBlocking: StatusFlags { StatusFlags(O_NONBLOCK) }

    /// Force each write to append at the end of file; corre-
    /// sponds to `OpenOptions.append`.
    ///
    /// The corresponding C constant is `O_APPEND`.
    @_alwaysEmitIntoClient
    public static var append: StatusFlags { StatusFlags(O_APPEND) }

    /// Enable the SIGIO signal to be sent to the process
    /// group when I/O is possible, e.g., upon availability of
    /// data to be read.
    ///
    /// The corresponding C constant is `O_ASYNC`.
    @_alwaysEmitIntoClient
    public static var async: StatusFlags { StatusFlags(O_ASYNC) }
  }
}


// - MARK: Commands

// TODO: Make below API as part of broader `fcntl` support.
extension FileDescriptor {
  /// Commands (and various constants) to pass to `fcntl`.
  @frozen
  public struct Command: RawRepresentable, Hashable, Codable, Sendable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Duplicate file descriptor.
    ///
    /// Note: A Swiftier wrapper is
    /// `FileDescriptor.duplicate(minRawValue:closeOnExec:)`.
    ///
    /// The corresponding C constant is `F_DUPFD`.
    @_alwaysEmitIntoClient
    public static var duplicate: Command { Command(F_DUPFD) }

    /// Mark the dup with FD_CLOEXEC.
    ///
    /// The corresponding C constant is `F_DUPFD_CLOEXEC`
    @_alwaysEmitIntoClient
    public static var duplicateCloseOnExec: Command {
      Command(F_DUPFD_CLOEXEC)
    }

    /// Get file descriptor flags.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.getFlags()`.
    ///
    /// The corresponding C constant is `F_GETFD`.
    @_alwaysEmitIntoClient
    public static var getFlags: Command { Command(F_GETFD) }

    /// Set file descriptor flags.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.setFlags(_:)`.
    ///
    /// The corresponding C constant is `F_SETFD`.
    @_alwaysEmitIntoClient
    public static var setFlags: Command { Command(F_SETFD) }

    /// Get file status flags.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.getStatusFlags()`.
    ///
    /// The corresponding C constant is `F_GETFL`.
    @_alwaysEmitIntoClient
    public static var getStatusFlags: Command {
      Command(F_GETFL)
    }

    /// Set file status flags.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.setStatusFlags(_:)`.
    ///
    /// The corresponding C constant is `F_SETFL`.
    @_alwaysEmitIntoClient
    public static var setStatusFlags: Command {
      Command(F_SETFL)
    }

    /// Get SIGIO/SIGURG proc/pgrp.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.getOwner()`.
    ///
    /// The corresponding C constant is `F_GETOWN`.
    @_alwaysEmitIntoClient
    public static var getOwner: Command { Command(F_GETOWN) }

    /// Set SIGIO/SIGURG proc/pgrp.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.setOwner(_:)`.
    ///
    /// The corresponding C constant is `F_SETOWN`.
    @_alwaysEmitIntoClient
    public static var setOwner: Command { Command(F_SETOWN) }

    /// Get record locking information.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.getLock(_:_:)`.
    ///
    /// The corresponding C constant is `F_GETLK`.
    @_alwaysEmitIntoClient
    public static var getLock: Command { Command(F_GETLK) }

    /// Set record locking information.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.setLock(_:_:)`.
    ///
    /// The corresponding C constant is `F_SETLK`.
    @_alwaysEmitIntoClient
    public static var setLock: Command { Command(F_SETLK) }

    /// Wait if blocked.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.setLock(_:_:)`.
    ///
    /// The corresponding C constant is `F_SETLKW`.
    @_alwaysEmitIntoClient
    public static var setLockWait: Command { Command(F_SETLKW) }

#if !os(Linux)

    /// Wait if blocked, return on timeout.
    ///
    /// TODO: A Swiftier wrapper
    ///
    /// The corresponding C constant is `F_SETLKWTIMEOUT`.
    @_alwaysEmitIntoClient
    public static var setLockWaitTimout: Command {
      Command(F_SETLKWTIMEOUT)
    }

    /// The corresponding C constant is `F_FLUSH_DATA`.
    @_alwaysEmitIntoClient
    public static var flushData: Command {
      Command(F_FLUSH_DATA)
    }

    /// Used for regression test.
    ///
    /// The corresponding C constant is `F_CHKCLEAN`.
    @_alwaysEmitIntoClient
    public static var checkClean: Command { Command(F_CHKCLEAN) }

    // TODO: Higher level API which will call `fallocate(2)` on Linux and use
    // TODO: the below on Darwin. Then we can call out to that.

    /// Preallocate storage.
    ///
    /// The corresponding C constant is `F_PREALLOCATE`.
    @_alwaysEmitIntoClient
    public static var preallocate: Command {
      Command(F_PREALLOCATE)
    }

    /// Truncate a file. Equivalent to calling truncate(2).
    ///
    /// The corresponding C constant is `F_SETSIZE`.
    @_alwaysEmitIntoClient
    public static var setSize: Command { Command(F_SETSIZE) }

    /// Issue an advisory read async with no copy to user.
    ///
    /// The corresponding C constant is `F_RDADVISE`.
    @_alwaysEmitIntoClient
    public static var readAdvise: Command { Command(F_RDADVISE) }

    /// Turn read ahead off/on for this fd.
    ///
    /// The corresponding C constant is `F_RDAHEAD`.
    @_alwaysEmitIntoClient
    public static var readAhead: Command { Command(F_RDAHEAD) }

    /// Turn data caching off/on for this fd.
    ///
    /// The corresponding C constant is `F_NOCACHE`.
    @_alwaysEmitIntoClient
    public static var noCache: Command { Command(F_NOCACHE) }

    /// File offset to device offset.
    ///
    /// The corresponding C constant is `F_LOG2PHYS`.
    @_alwaysEmitIntoClient
    public static var logicalToPhysical: Command { Command(F_LOG2PHYS) }

    /// Return the full path of the fd.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.getPath(_:)`.
    ///
    /// The corresponding C constant is `F_GETPATH`.
    @_alwaysEmitIntoClient
    public static var getPath: Command { Command(F_GETPATH) }

    /// Synchronize the file system and ask the drive to flush to the media.
    ///
    /// The corresponding C constant is `F_FULLFSYNC`.
    @_alwaysEmitIntoClient
    public static var fullFileSystemSync: Command { Command(F_FULLFSYNC) }

    /// Find which component (if any) is a package.
    ///
    /// The corresponding C constant is `F_PATHPKG_CHECK`.
    @_alwaysEmitIntoClient
    public static var pathPackageCheck: Command {
      Command(F_PATHPKG_CHECK)
    }

    /// "Freeze" all file system operations.
    ///
    /// The corresponding C constant is `F_FREEZE_FS`.
    @_alwaysEmitIntoClient
    public static var freezeFileSystem: Command { Command(F_FREEZE_FS) }

    /// "Thaw" all file system operations.
    ///
    /// The corresponding C constant is `F_THAW_FS`.
    @_alwaysEmitIntoClient
    public static var thawFileSystem: Command { Command(F_THAW_FS) }

    /// Turn data caching off/on (globally) for this file.
    ///
    /// The corresponding C constant is `F_GLOBAL_NOCACHE`.
    @_alwaysEmitIntoClient
    public static var globalNoCache: Command {
      Command(F_GLOBAL_NOCACHE)
    }

    /// Add detached signatures.
    ///
    /// The corresponding C constant is `F_ADDSIGS`.
    @_alwaysEmitIntoClient
    public static var addSignatures: Command {
      Command(F_ADDSIGS)
    }

    /// Add signature from same file (used by dyld for shared libs).
    ///
    /// The corresponding C constant is `F_ADDFILESIGS`.
    @_alwaysEmitIntoClient
    public static var addFileSignatures: Command {
      Command(F_ADDFILESIGS)
    }

    /// Used in conjunction with `.noCache` to indicate that DIRECT,
    /// synchonous writes should not be used (i.e. its ok to temporaily create
    /// cached pages).
    ///
    /// The corresponding C constant is `F_NODIRECT`.
    @_alwaysEmitIntoClient
    public static var noDirect: Command { Command(F_NODIRECT) }

    /// Get the protection class of a file from the EA, returns int.
    ///
    /// The corresponding C constant is `F_GETPROTECTIONCLASS`.
    @_alwaysEmitIntoClient
    public static var getProtectionClass: Command {
      Command(F_GETPROTECTIONCLASS)
    }

    /// Set the protection class of a file for the EA, requires int.
    ///
    /// The corresponding C constant is `F_SETPROTECTIONCLASS`.
    @_alwaysEmitIntoClient
    public static var setProtectionClass: Command {
      Command(F_SETPROTECTIONCLASS)
    }

    /// File offset to device offset, extended.
    ///
    /// The corresponding C constant is `F_LOG2PHYS_EXT`.
    @_alwaysEmitIntoClient
    public static var log2physExtended: Command {
      Command(F_LOG2PHYS_EXT)
    }

    /// Get record locking information, per-process.
    ///
    /// The corresponding C constant is `F_GETLKPID`.
    @_alwaysEmitIntoClient
    public static var getLockPID: Command { Command(F_GETLKPID) }

    /// Mark the file as being the backing store for another filesystem.
    ///
    /// The corresponding C constant is `F_SETBACKINGSTORE`.
    @_alwaysEmitIntoClient
    public static var setBackingStore: Command {
      Command(F_SETBACKINGSTORE)
    }

    /// Return the full path of the FD, but error in specific mtmd
    /// circumstances.
    ///
    /// The corresponding C constant is `F_GETPATH_MTMINFO`.
    @_alwaysEmitIntoClient
    public static var getPathMTMDInfo: Command {
      Command(F_GETPATH_MTMINFO)
    }

    /// Returns the code directory, with associated hashes, to the caller.
    ///
    /// The corresponding C constant is `F_GETCODEDIR`.
    @_alwaysEmitIntoClient
    public static var getCodeDirectory: Command {
      Command(F_GETCODEDIR)
    }

    /// No SIGPIPE generated on EPIPE.
    ///
    /// The corresponding C constant is `F_SETNOSIGPIPE`.
    @_alwaysEmitIntoClient
    public static var setNoSigPipe: Command {
      Command(F_SETNOSIGPIPE)
    }

    /// Status of SIGPIPE for this fd.
    ///
    /// The corresponding C constant is `F_GETNOSIGPIPE`.
    @_alwaysEmitIntoClient
    public static var getNoSigPipe: Command {
      Command(F_GETNOSIGPIPE)
    }

    /// For some cases, we need to rewrap the key for AKS/MKB.
    ///
    /// The corresponding C constant is `F_TRANSCODEKEY`.
    @_alwaysEmitIntoClient
    public static var transcodeKey: Command {
      Command(F_TRANSCODEKEY)
    }

    /// File being written to a by single writer... if throttling enabled,
    /// writes may be broken into smaller chunks with throttling in between.
    ///
    /// The corresponding C constant is `F_SINGLE_WRITER`.
    @_alwaysEmitIntoClient
    public static var singleWriter: Command {
      Command(F_SINGLE_WRITER)
    }


    /// Get the protection version number for this filesystem.
    ///
    /// The corresponding C constant is `F_GETPROTECTIONLEVEL`.
    @_alwaysEmitIntoClient
    public static var getProtectionLevel: Command {
      Command(F_GETPROTECTIONLEVEL)
    }


    /// Add detached code signatures (used by dyld for shared libs).
    ///
    /// The corresponding C constant is `F_FINDSIGS`.
    @_alwaysEmitIntoClient
    public static var findSignatures: Command {
      Command(F_FINDSIGS)
    }

    /// Add signature from same file, only if it is signed by Apple (used by
    /// dyld for simulator).
    ///
    /// The corresponding C constant is `F_ADDFILESIGS_FOR_DYLD_SIM`.
    @_alwaysEmitIntoClient
    public static var addFileSignaturesForDYLDSim: Command {
      Command(F_ADDFILESIGS_FOR_DYLD_SIM)
    }

    /// Fsync + issue barrier to drive.
    ///
    /// The corresponding C constant is `F_BARRIERFSYNC`.
    @_alwaysEmitIntoClient
    public static var barrierFsync: Command {
      Command(F_BARRIERFSYNC)
    }

    /// Add signature from same file, return end offset in structure on success.
    ///
    /// The corresponding C constant is `F_ADDFILESIGS_RETURN`.
    @_alwaysEmitIntoClient
    public static var addFileSignaturesReturn: Command {
      Command(F_ADDFILESIGS_RETURN)
    }

    /// Check if Library Validation allows this Mach-O file to be mapped into
    /// the calling process.
    ///
    /// The corresponding C constant is `F_CHECK_LV`.
    @_alwaysEmitIntoClient
    public static var checkLibraryValidation: Command {
      Command(F_CHECK_LV)
    }

    /// Deallocate a range of the file.
    ///
    /// The corresponding C constant is `F_PUNCHHOLE`.
    @_alwaysEmitIntoClient
    public static var punchhole: Command { Command(F_PUNCHHOLE) }

    /// Trim an active file.
    ///
    /// The corresponding C constant is `F_TRIM_ACTIVE_FILE`.
    @_alwaysEmitIntoClient
    public static var trimActiveFile: Command {
      Command(F_TRIM_ACTIVE_FILE)
    }

    /// Synchronous advisory read fcntl for regular and compressed file.
    ///
    /// The corresponding C constant is `F_SPECULATIVE_READ`.
    @_alwaysEmitIntoClient
    public static var speculativeRead: Command {
      Command(F_SPECULATIVE_READ)
    }

    /// Return the full path without firmlinks of the fd.
    ///
    /// Note: A Swiftier wrapper is `FileDescriptor.getPath(_:)`.
    ///
    /// The corresponding C constant is `F_GETPATH_NOFIRMLINK`.
    @_alwaysEmitIntoClient
    public static var getPathNoFirmLink: Command {
      Command(F_GETPATH_NOFIRMLINK)
    }

    /// Add signature from same file, return information.
    ///
    /// The corresponding C constant is `F_ADDFILESIGS_INFO`.
    @_alwaysEmitIntoClient
    public static var addFileSignatureInfo: Command {
      Command(F_ADDFILESIGS_INFO)
    }

    /// Add supplemental signature from same file with fd reference to original.
    ///
    /// The corresponding C constant is `F_ADDFILESUPPL`.
    @_alwaysEmitIntoClient
    public static var addFileSupplementalSignature: Command {
      Command(F_ADDFILESUPPL)
    }

    /// Look up code signature information attached to a file or slice.
    ///
    /// The corresponding C constant is `F_GETSIGSINFO`.
    @_alwaysEmitIntoClient
    public static var getSignatureInfo: Command {
      Command(F_GETSIGSINFO)
    }

    /// Allocate contigious space.
    ///
    /// TODO: This is actually a flag for the PREALLOCATE struct...
    ///
    /// The corresponding C constant is `F_ALLOCATECONTIG`.
    @_alwaysEmitIntoClient
    public static var allocateContiguous: Command {
      Command(F_ALLOCATECONTIG)
    }

    /// Allocate all requested space or no space at all.
    ///
    /// TODO: This is actually a flag for the PREALLOCATE struct...
    ///
    /// The corresponding C constant is `F_ALLOCATEALL`.
    @_alwaysEmitIntoClient
    public static var allocateAll: Command {
      Command(F_ALLOCATEALL)
    }

    /// Allocate from the physical end of file. In this case, fst_length
    /// indicates the number of newly allocated bytes desired.
    ///
    /// TODO: This is actually a flag for the PREALLOCATE struct...
    ///
    /// The corresponding C constant is `F_PEOFPOSMODE`.
    @_alwaysEmitIntoClient
    public static var endOfFile: Command {
      Command(F_PEOFPOSMODE)
    }

    /// Specify volume starting postion.
    ///
    /// TODO: This is actually a flag for the PREALLOCATE struct...
    ///
    /// The corresponding C constant is `F_VOLPOSMODE`.
    @_alwaysEmitIntoClient
    public static var startOfVolume: Command {
      Command(F_VOLPOSMODE)
    }

#endif // !os(Linux)

    /// Get open file description record locking information.
    ///
    /// The corresponding C constant is `F_GETLK`.
    @_alwaysEmitIntoClient
    public static var getOFDLock: Command { Command(_F_OFD_GETLK) }

    /// Set open file description record locking information.
    ///
    /// The corresponding C constant is `F_SETLK`.
    @_alwaysEmitIntoClient
    public static var setOFDLock: Command { Command(_F_OFD_SETLK) }

    /// Set open file description record locking information and wait until
    /// the request can be completed.
    ///
    /// The corresponding C constant is `F_SETLKW`.
    @_alwaysEmitIntoClient
    public static var setOFDLockWait: Command { Command(_F_OFD_SETLKW) }

#if !os(Linux)
    /// Set open file description record locking information and wait until
    /// the request can be completed, returning on timeout.
    ///
    /// The corresponding C constant is `F_SETLKWTIMEOUT`.
    @_alwaysEmitIntoClient
    public static var setOFDLockWaitTimout: Command {
      Command(_F_OFD_SETLKWTIMEOUT)
    }
#endif

  }
}


extension FileDescriptor {
  /// Low-level interface equivalent to C's `fcntl`. Note, most common operations have Swiftier
  /// alternatives directly on `FileDescriptor`.
  @_alwaysEmitIntoClient
  public func control(
    _ cmd: Command, retryOnInterrupt: Bool = true
  ) throws -> CInt {
    try _control(cmd, retryOnInterrupt: retryOnInterrupt).get()
  }

  /// Low-level interface equivalent to C's `fcntl`. Note, most common operations have Swiftier
  /// alternatives directly on `FileDescriptor`.
  @_alwaysEmitIntoClient
  public func control(
    _ cmd: Command, _ arg: CInt, retryOnInterrupt: Bool = true
  ) throws -> CInt {
    try _control(cmd, arg, retryOnInterrupt: retryOnInterrupt).get()
  }

  /// Low-level interface equivalent to C's `fcntl`. Note, most common operations have Swiftier
  /// alternatives directly on `FileDescriptor`.
  @_alwaysEmitIntoClient
  public func control(
    _ cmd: Command,
    _ ptr: UnsafeMutableRawPointer,
    retryOnInterrupt: Bool = true
  ) throws -> CInt {
    try _control(cmd, ptr, retryOnInterrupt: retryOnInterrupt).get()
  }

  /// Low-level interface equivalent to C's `fcntl`. Note, most common operations have Swiftier
  /// alternatives directly on `FileDescriptor`.
  @_alwaysEmitIntoClient
  public func control(
    _ cmd: Command,
    _ lock: inout FileDescriptor.FileLock,
    retryOnInterrupt: Bool = true
  ) throws -> CInt {
    try _control(cmd, &lock, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _control(
    _ cmd: Command, retryOnInterrupt: Bool
  ) -> Result<CInt, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fcntl(self.rawValue, cmd.rawValue)
    }
  }
  @usableFromInline
  internal func _control(
    _ cmd: Command, _ arg: CInt, retryOnInterrupt: Bool
  ) -> Result<CInt, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fcntl(self.rawValue, cmd.rawValue, arg)
    }
  }
  @usableFromInline
  internal func _control(
    _ cmd: Command,
    _ ptr: UnsafeMutableRawPointer,
    retryOnInterrupt: Bool
  ) -> Result<CInt, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fcntl(self.rawValue, cmd.rawValue, ptr)
    }
  }

  @usableFromInline
  internal func _control(
    _ cmd: Command,
    _ lock: inout FileDescriptor.FileLock,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      withUnsafeMutablePointer(to: &lock) {
        system_fcntl(self.rawValue, cmd.rawValue, $0)
      }
    }
  }
}

internal var _maxPathLen: Int { Int(MAXPATHLEN) }

#endif // !os(Windows)

