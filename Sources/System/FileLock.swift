#if !os(Windows)
extension FileDescriptor {
  /// The kind of a lock: read (aka "shared") or write (aka "exclusive")
  public enum LockKind {
    /// Read-only or shared lock
    case read

    /// Write or exclusive lock
    case write

    fileprivate var flockValue: Int16 /* TODO: short? */ {
      // TODO: cleanup
      switch self {
      case .read: return FileDescriptor.Control.FileLock.Kind.readLock.rawValue
      case .write: return FileDescriptor.Control.FileLock.Kind.writeLock.rawValue
      }
    }
  }

  /// Get information about an open file description lock.
  ///
  /// Open file description locks are associated with an open file
  /// description (see `FileDescriptor.open`). Duplicated
  /// file descriptors (see `FileDescriptor.duplicate`) share open file
  /// description locks.
  ///
  /// Locks are advisory, which allow cooperating code to perform
  /// consistent operations on files, but do not guarantee consistency.
  /// (i.e. other code may still access files without using advisory locks
  /// possibly resulting in inconsistencies).
  ///
  /// TODO: Something about what happens on fork
  ///
  /// FIXME: Any caveats for Darwin?
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_GETLK`.
  @_alwaysEmitIntoClient
  public func getLock() throws -> FileDescriptor.LockKind {
    try _getLock().get()
  }

  @usableFromInline
  internal func _getLock() -> Result<FileDescriptor.LockKind, Errno> {
    // FIXME: Do we need to issue two calls? From GNU:
    //
    // If there is a lock already in place that would block the lock described
    // by the lockp argument, information about that lock is written
    // to *lockp. Existing locks are not reported if they are compatible with
    // making a new lock as specified. Thus, you should specify a lock type
    // of F_WRLCK if you want to find out about both read and write locks, or
    // F_RDLCK if you want to find out about write locks only.
    // 
    // There might be more than one lock affecting the region specified by the
    // lockp argument, but fcntl only returns information about one of them.
    // Which lock is returned in this situation is undefined.
    fatalError("TODO: implement")
  }

  /// Set an open file description lock.
  ///
  /// If the open file description already has a lock, the old lock is
  /// replaced. If the lock cannot be set because it is blocked by an
  /// existing lock on a file, `Errno.resourceTemporarilyUnavailable` is
  /// thrown.
  ///
  /// Open file description locks are associated with an open file
  /// description (see `FileDescriptor.open`). Duplicated
  /// file descriptors (see `FileDescriptor.duplicate`) share open file
  /// description locks.
  ///
  /// Locks are advisory, which allow cooperating code to perform
  /// consistent operations on files, but do not guarantee consistency.
  /// (i.e. other code may still access files without using advisory locks
  /// possibly resulting in inconsistencies).
  ///
  /// TODO: Something about what happens on fork
  ///
  /// FIXME: Any caveats for Darwin?
  ///
  /// FIXME: The non-wait isn't documented to throw EINTR, but fcnl in general
  /// might. Do we do retry on interrupt or not?
  ///
  /// TODO: describe non-blocking
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` or
  /// `F_OFD_SETLKW`.
  @_alwaysEmitIntoClient
  public func lock(
    kind: FileDescriptor.LockKind = .read,
    nonBlocking: Bool = false,
    retryOnInterrupt: Bool = true
  ) throws {
    try _lock(kind: kind, nonBlocking: nonBlocking, retryOnInterrupt: retryOnInterrupt).get()
  }

  /// Remove an open file description lock.
  ///
  /// Open file description locks are associated with an open file
  /// description (see `FileDescriptor.open`). Duplicated
  /// file descriptors (see `FileDescriptor.duplicate`) share open file
  /// description locks.
  ///
  /// Locks are advisory, which allow cooperating code to perform
  /// consistent operations on files, but do not guarantee consistency.
  /// (i.e. other code may still access files without using advisory locks
  /// possibly resulting in inconsistencies).
  ///
  /// TODO: Something about what happens on fork
  ///
  /// FIXME: Any caveats for Darwin?
  ///
  /// FIXME: The non-wait isn't documented to throw EINTR, but fcnl in general
  /// might. Do we do retry on interrupt or not?
  ///
  /// TODO: Do we need a non-blocking argument? Does that even make sense?
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` (TODO: or
  /// `F_OFD_SETLKW`?) and a lock type of `F_UNLCK`.
  @_alwaysEmitIntoClient
  public func unlock(retryOnInterrupt: Bool = true) throws {
    try _unlock(retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _lock(
    kind: FileDescriptor.LockKind,
    nonBlocking: Bool,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    // TODO: OFD locks
    var operation: CInt
    if kind == .write {
      operation = _LOCK_EX
    } else {
      operation = _LOCK_SH
    }
    if nonBlocking {
      operation |= _LOCK_NB
    }
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_flock(self.rawValue, operation)
    }
  }

  @usableFromInline
  internal func _unlock(
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    // TODO: OFD locks
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_flock(self.rawValue, _LOCK_UN)
    }
  }
}
#endif

