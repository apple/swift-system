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
#elseif os(Windows)
// Nothing
#else
#error("Unsupported Platform")
#endif


#if !os(Windows)

extension FileDescriptor {
  /// A namespace for types and values for `FileDescriptor.control()`, aka `fcntl`.
  ///
  /// TODO: a better name? "Internals", "Raw", "FCNTL"? I feel like a
  /// precedent would be useful for sysctl, ioctl, and other grab-bag
  /// things. "junk drawer" can be an anti-pattern, but is better than
  /// trashing the higher namespace.
  public enum Control {}

  /// File descriptor flags.
  ///
  /// These flags are not shared across duplicated file descriptors.
  @frozen
  public struct Flags: OptionSet {
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

  /// File status flags.
  ///
  /// File status flags are associated with an open file description
  /// (see `FileDescriptor.open`). Duplicated file descriptors
  /// (see `FileDescriptor.duplicate`) share file status flags.
  @frozen
  public struct StatusFlags: OptionSet {
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

// - MARK: RawRepresentable wrappers

extension FileDescriptor.Control {
  /// Advisory record locks.
  ///
  /// The corresponding C type is `struct flock`.
  @frozen
  public struct FileLock: RawRepresentable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.FileLock

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.FileLock) { self.rawValue = rawValue }

    /// The type of the lock.
    @frozen
    public struct Kind: RawRepresentable, Hashable {
      @_alwaysEmitIntoClient
      public var rawValue: Int16 // TODO: Linux `short` too? `CShort`?

      @_alwaysEmitIntoClient
      public init(rawValue: Int16) { self.rawValue = rawValue }

      /// Shared or read lock.
      ///
      /// The corresponding C constant is `F_RDLCK`.
      @_alwaysEmitIntoClient
      public static var readLock: Self { Self(rawValue: Int16(F_RDLCK)) }

      /// Unlock.
      ///
      /// The corresponding C constant is `F_UNLCK`.
      @_alwaysEmitIntoClient
      public static var unlock: Self { Self(rawValue: Int16(F_UNLCK)) }

      /// Exclusive or write lock.
      ///
      /// The corresponding C constant is `F_WRLCK`.
      @_alwaysEmitIntoClient
      public static var writeLock: Self { Self(rawValue: Int16(F_WRLCK)) }
    }

    // TOOO: convenience initializers / static constructors

    /// The type of the locking operation.
    ///
    /// The corresponding C field is `l_type`.
    @_alwaysEmitIntoClient
    public var type: Kind {
      get { Kind(rawValue: rawValue.l_type) }
      set { rawValue.l_type = newValue.rawValue }
    }

    /// The origin of the locked region.
    ///
    /// The corresponding C field is `l_whence`.
    @_alwaysEmitIntoClient
    public var origin: FileDescriptor.SeekOrigin {
      get { FileDescriptor.SeekOrigin(rawValue: CInt(rawValue.l_whence)) }
      set { rawValue.l_whence = Int16(newValue.rawValue) }
    }

    /// The start offset (from the origin) of the locked region.
    ///
    /// The corresponding C field is `l_start`.
    @_alwaysEmitIntoClient
    public var start: Int64 {
      get { Int64(rawValue.l_start) }
      set { rawValue.l_start = CInterop.Offset(newValue) }
    }

    /// The number of consecutive bytes to lock.
    ///
    /// The corresponding C field is `l_len`.
    @_alwaysEmitIntoClient
    public var length: Int64 {
      get { Int64(rawValue.l_len) }
      set { rawValue.l_len = CInterop.Offset(newValue) }
    }

    /// The process ID of the lock holder, filled in by`FileDescriptor.getLock()`.
    ///
    /// TODO: Actual ProcessID type
    ///
    /// The corresponding C field is `l_pid`
    @_alwaysEmitIntoClient
    public var pid: CInterop.PID {
      get { rawValue.l_pid }
      set { rawValue.l_pid = newValue }
    }
  }  
}

// - MARK: Commands

extension FileDescriptor.Control {
  /// Commands (and various constants) to pass to `fcntl`.
  @frozen
  public struct Command: RawRepresentable, Hashable {
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
    /// TODO:  `setOwner` is pending the `PIDOrPGID` type decision
    ///
    /// The corresponding C constant is `F_SETOWN`.
    @_alwaysEmitIntoClient
    public static var setOwner: Command { Command(F_SETOWN) }

    /// Get open file description record locking information.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.isLocked() or something like that
    ///
    /// The corresponding C constant is `F_GETLK`.
    @_alwaysEmitIntoClient
    public static var getOFDLock: Command { Command(_F_OFD_GETLK) }

    /// Set open file description record locking information.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.lock()
    ///
    /// The corresponding C constant is `F_SETLK`.
    @_alwaysEmitIntoClient
    public static var setOFDLock: Command { Command(_F_OFD_SETLK) }

    /// Set open file description record locking information and wait until
    /// the request can be completed.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.lock()
    ///
    /// The corresponding C constant is `F_SETLKW`.
    @_alwaysEmitIntoClient
    public static var setOFDLockWait: Command { Command(_F_OFD_SETLKW) }

#if !os(Linux)
    /// Set open file description record locking information and wait until
    /// the request can be completed, returning on timeout.
    ///
    /// TODO: link to https://www.gnu.org/software/libc/manual/html_node/Open-File-Description-Locks.html
    /// TODO: reference FileDesciptor.lock()
    ///
    /// The corresponding C constant is `F_SETLKWTIMEOUT`.
    @_alwaysEmitIntoClient
    public static var setOFDLockWaitTimout: Command {
      Command(_F_OFD_SETLKWTIMEOUT)
    }
#endif

    /// Get POSIX process-level record locking information.
    ///
    /// Note: This implements POSIX.1 record locking semantics. The vast
    /// majority of uses are better served by either OFD locks
    /// (i.e. per-`open` locks) or `flock`-style per-process locks.
    ///
    /// The corresponding C constant is `F_GETLK`.
    @_alwaysEmitIntoClient
    public static var getPOSIXProcessLock: Command { Command(F_GETLK) }

    /// Set POSIX process-level record locking information.
    ///
    /// Note: This implements POSIX.1 record locking semantics. The vast
    /// majority of uses are better served by either OFD locks
    /// (i.e. per-`open` locks) or `flock`-style per-process locks.
    ///
    /// The corresponding C constant is `F_SETLK`.
    @_alwaysEmitIntoClient
    public static var setPOSIXProcessLock: Command { Command(F_SETLK) }

    /// Set POSIX process-level record locking information and wait until the
    /// request can be completed.
    ///
    /// Note: This implements POSIX.1 record locking semantics. The vast
    /// majority of uses are better served by either OFD locks
    /// (i.e. per-`open` locks) or `flock`-style per-process locks.
    ///
    /// The corresponding C constant is `F_SETLKW`.
    @_alwaysEmitIntoClient
    public static var setPOSIXProcessLockWait: Command { Command(F_SETLKW) }

    #if !os(Linux)
    /// Set POSIX process-level record locking information and wait until the
    /// request can be completed, returning on timeout.
    ///
    /// Note: This implements POSIX.1 record locking semantics. The vast
    /// majority of uses are better served by either OFD locks
    /// (i.e. per-`open` locks) or `flock`-style per-process locks.
    ///
    /// The corresponding C constant is `F_SETLKWTIMEOUT`.
    @_alwaysEmitIntoClient
    public static var setPOSIXProcessLockWaitTimout: Command {
      Command(F_SETLKWTIMEOUT)
    }

    /// ??? TODO: Where is this documented?
    ///
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

    ///
    /// Header says: 46,47 used to be F_READBOOTSTRAP and F_WRITEBOOTSTRAP
    /// FIXME: What do we do here?
    ///

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

    /// Fsync + ask the drive to flush to the media.
    ///
    /// The corresponding C constant is `F_FULLFSYNC`.
    @_alwaysEmitIntoClient
    public static var fullFsync: Command { Command(F_FULLFSYNC) }

    /// Find which component (if any) is a package.
    ///
    /// The corresponding C constant is `F_PATHPKG_CHECK`.
    @_alwaysEmitIntoClient
    public static var pathPackageCheck: Command {
      Command(F_PATHPKG_CHECK)
    }

    /// "Freeze" all fs operations.
    ///
    /// The corresponding C constant is `F_FREEZE_FS`.
    @_alwaysEmitIntoClient
    public static var freezeFileSystem: Command { Command(F_FREEZE_FS) }

    /// "Thaw" all fs operations.
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

    /// Used in conjunction with F_NOCACHE to indicate that DIRECT,
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
    public static var logToPhysicalExtended: Command {
      Command(F_LOG2PHYS_EXT)
    }

    /// Get record locking information, per-process.
    ///
    /// The corresponding C constant is `F_GETLKPID`.
    @_alwaysEmitIntoClient
    public static var getLockPID: Command { Command(F_GETLKPID) }
    #endif

    /// Mark the dup with FD_CLOEXEC.
    ///
    /// The corresponding C constant is `F_DUPFD_CLOEXEC`
    @_alwaysEmitIntoClient
    public static var duplicateCloseOnExec: Command {
      Command(F_DUPFD_CLOEXEC)
    }

    #if !os(Linux)
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
    #endif

    #if !os(Linux)
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

    /// Allocate from the physical end of file.
    ///
    /// The corresponding C constant is `F_PEOFPOSMODE`.
    @_alwaysEmitIntoClient
    public static var endOfFile: Command {
      Command(F_PEOFPOSMODE)
    }

    /// Specify volume starting postion.
    ///
    /// The corresponding C constant is `F_VOLPOSMODE`.
    @_alwaysEmitIntoClient
    public static var startOfVolume: Command {
      Command(F_VOLPOSMODE)
    }
    #endif
  }
}

// - MARK: Raw escape hatch

#if !os(Linux)
internal var _maxPathLen: Int { Int(MAXPATHLEN) }
#endif

#endif
