#if !os(Windows)
extension FileDescriptor {
  /// Apply an advisory lock to the file associated with this descriptor.
  ///
  /// Advisory locks allow cooperating processes to perform consistent operations on files,
  /// but do not guarantee consistency (i.e., processes may still access files without using advisory locks
  /// possibly resulting in inconsistencies).
  ///
  /// The locking mechanism allows two types of locks: shared locks and exclusive locks.
  /// At any time multiple shared locks may be applied to a file, but at no time are multiple exclusive, or
  /// both shared and exclusive, locks allowed simultaneously on a file.
  ///
  /// A shared lock may be upgraded to an exclusive lock, and vice versa, simply by specifying the appropriate
  /// lock type; this results in the previous lock being released and the new lock
  /// applied (possibly after other processes have gained and released the lock).
  ///
  /// Requesting a lock on an object that is already locked normally causes the caller to be blocked
  /// until the lock may be acquired.  If `nonBlocking` is passed as true, then this will not
  /// happen; instead the call will fail and `Errno.wouldBlock` will be thrown.
  ///
  /// Locks are on files, not file descriptors. That is, file descriptors duplicated through `FileDescriptor.duplicate`
  /// do not result in multiple instances of a lock, but rather multiple references to a
  /// single lock.  If a process holding a lock on a file forks and the child explicitly unlocks the file, the parent will lose its lock.
  ///
  /// The corresponding C function is `flock()`
  @_alwaysEmitIntoClient
  public func lock(
    exclusive: Bool = false,
    nonBlocking: Bool = false,
    retryOnInterrupt: Bool = true
  ) throws {
    try _lock(exclusive: exclusive, nonBlocking: nonBlocking, retryOnInterrupt: retryOnInterrupt).get()
  }

  /// Unlocks an existing advisory lock on the file associated with this descriptor.
  ///
  /// The corresponding C function is `flock` passed `LOCK_UN`
  @_alwaysEmitIntoClient
  public func unlock(retryOnInterrupt: Bool = true) throws {
    try _unlock(retryOnInterrupt: retryOnInterrupt).get()

  }

  @usableFromInline
  internal func _lock(
    exclusive: Bool,
    nonBlocking: Bool,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    var operation: CInt
    if exclusive {
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
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_flock(self.rawValue, _LOCK_UN)
    }
  }
}
#endif

