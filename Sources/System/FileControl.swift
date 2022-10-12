/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Strongly typed, Swifty interfaces to the most common and useful `fcntl`
// commands.

extension FileDescriptor {
  /// Get the flags associated with this file descriptor
  ///
  /// The corresponding C function is `fcntl` with the `F_GETFD` command.
  @_alwaysEmitIntoClient
  public func getFlags() throws -> Flags {
    try Flags(rawValue: fcntl(.getFlags))
  }

  /// Set the file descriptor flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETFD` command.
  @_alwaysEmitIntoClient
  public func setFlags(_ value: Flags) throws {
    _ = try fcntl(.setFlags, value.rawValue)
  }

  /// Get descriptor status flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_GETFL` command.
  @_alwaysEmitIntoClient
  public func getStatusFlags() throws -> StatusFlags {
    try StatusFlags(rawValue: fcntl(.getStatusFlags))
  }

  /// Set descriptor status flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETFL` command.
  @_alwaysEmitIntoClient
  public func setStatusFlags(_ flags: StatusFlags) throws {
    _ = try fcntl(.setStatusFlags, flags.rawValue)
  }
}


extension FileDescriptor {
  /// Duplicate this file descriptor and return the newly created copy.
  ///
  /// - Parameters:
  ///   - `minRawValue`: A lower bound on the new file descriptor's raw value.
  ///   - `closeOnExec`: Whether the new descriptor's `closeOnExec` flag is set.
  /// - Returns: The lowest numbered available descriptor whose raw value is
  ///     greater than or equal to `minRawValue`.
  ///
  /// File descriptors are merely references to some underlying system resource.
  /// The system does not distinguish between the original and the new file
  /// descriptor in any way. For example, read, write and seek operations on
  /// one of them also affect the logical file position in the other, and
  /// append mode, non-blocking I/O and asynchronous I/O options are shared
  /// between the references. If a separate pointer into the file is desired,
  /// a different object reference to the file must be obtained by issuing an
  /// additional call to `open`.
  ///
  /// However, each file descriptor maintains its own close-on-exec flag.
  ///
  /// The corresponding C functions are `fcntl` with `F_DUPFD` and
  /// `F_DUPFD_CLOEXEC`.
  @_alwaysEmitIntoClient
  public func duplicate(
    minRawValue: CInt, closeOnExec: Bool
  ) throws -> FileDescriptor {
    let cmd: Command = closeOnExec ? .duplicateCloseOnExec : .duplicate
    return try FileDescriptor(rawValue: fcntl(cmd, minRawValue))
  }

  #if !os(Linux)
  /// Get the path of the file descriptor
  ///
  /// - Parameters:
  ///   - `noFirmLink`: Get the non firmlinked path of the file descriptor.
  ///
  /// The corresponding C functions are `fcntl` with `F_GETPATH` and
  /// `F_GETPATH_NOFIRMLINK`.
  public func getPath(noFirmLink: Bool = false) throws -> FilePath {
    let cmd: Command = noFirmLink ? .getPathNoFirmLink : .getPath
    // TODO: have a uninitialized init on FilePath / SystemString...
    let bytes = try Array<SystemChar>(unsafeUninitializedCapacity: _maxPathLen) {
      (bufPtr, count: inout Int) in
      _ = try fcntl(cmd, UnsafeMutableRawPointer(bufPtr.baseAddress!))
      count = 1 + system_strlen(
        UnsafeRawPointer(bufPtr.baseAddress!).assumingMemoryBound(to: Int8.self))
    }
    return FilePath(SystemString(nullTerminated: bytes))
  }
  #endif
}

// TODO: More fsync functionality using `F_BARRIERFSYNC` and `F_FULLFSYNC`,
// coinciding with the sketch for fsync.

// MARK: - To add in the future with process support

extension FileDescriptor {
  // TODO: Flesh out PID work and see if there's a better, common formulation
  // of the process-or-group id concept.
  // TODO: @frozen
  // TODO: public
  private struct PIDOrPGID: RawRepresentable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// TODO: PID type
    @_alwaysEmitIntoClient
    public var asPID: CInt? { rawValue >= 0 ? rawValue : nil }

    /// TODO: PGID type
    @_alwaysEmitIntoClient
    public var asPositiveGroupID: CInt? {
      rawValue >= 0 ? nil : -rawValue
    }

    /// TODO: PID type
    @_alwaysEmitIntoClient
    public init(pid id: CInt) {
      precondition(id >= 0)
      self.init(rawValue: id)
    }

    /// TODO: PGID type
    @_alwaysEmitIntoClient
    public init(positiveGroupID id: CInt) {
      precondition(id >= 0)
      self.init(rawValue: -id)
    }
  }

  /// Get the process ID or process group currently receiv-
  /// ing SIGIO and SIGURG signals.
  ///
  /// The corresponding C function is `fcntl` with the `F_GETOWN` command.
  // TODO:  @_alwaysEmitIntoClient
  // TODO: public
  private func getOwner() throws -> PIDOrPGID {
    try PIDOrPGID(rawValue: fcntl(.getOwner))
  }

  /// Set the process or process group to receive SIGIO and
  /// SIGURG signals.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETOWN` command.
  // TODO:  @_alwaysEmitIntoClient
  // TODO: public
  private func setOwner(_ id: PIDOrPGID) throws {
    _ = try fcntl(.setOwner, id.rawValue)
  }
}

// MARK: - Removed and should be replaced

// TODO: We don't want to highlight fcntl's highly inadvisable
// ("completely stupid" to quote the man page) locks. Instead, we'd want to provide
// `flock` on Darwin and some Linux equivalent.

#if false

// Record locking
extension FileDescriptor {
  /// Get record locking information.
  ///
  /// Get the first lock that blocks the lock description described by `lock`.
  /// If no lock is found that would prevent this lock from being created, the
  /// structure is left unchanged by this function call except for the lock type
  /// which is set to F_UNLCK.
  ///
  /// The corresponding C function is `fcntl` with `F_GETLK`.
  @_alwaysEmitIntoClient
  public func getLock(blocking lock: FileLock) throws -> FileLock {
    var copy = lock
    try _fcntlLock(.getLock, &copy, retryOnInterrupt: false).get()
    return copy
  }

  /// Set record locking information.
  ///
  /// Set or clear a file segment lock according to the lock description
  /// `lock`.`setLock` is used to establish shared/read locks (`FileLock.read`)
  /// or exclusive/write locks, (`FileLock.write`), as well as remove either
  /// type of lock (`FileLock.unlock`).  If a shared or exclusive lock cannot be
  /// set, this throws `Errno.resourceTemporarilyUnavailable`.
  ///
  /// If `waitIfBlocked` is set and a shared or exclusive lock is blocked by
  /// other locks, the process waits until the request can be satisfied.  If a
  /// signal that is to be caught is received while this calls is waiting for a
  /// region, the it will be interrupted if the signal handler has not
  /// specified the SA_RESTART (see sigaction(2)).
  ///
  /// The corresponding C function is `fcntl` with `F_SETLK`.
  @_alwaysEmitIntoClient
  public func setLock(
    to lock: FileLock,
    waitIfBlocked: Bool = false,
    retryOnInterrupt: Bool = true
  ) throws {
    let cmd: Command = waitIfBlocked ? .setLockWait : .setLock
    var copy = lock
    try _fcntlLock(cmd, &copy, retryOnInterrupt: retryOnInterrupt).get()
    // TODO: Does `fcntl` update `copy`? Should we return it?
  }
}

#endif

