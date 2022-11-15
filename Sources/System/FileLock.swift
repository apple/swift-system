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
  /// Advisory record locks.
  ///
  /// The corresponding C type is `struct flock`.
  @frozen
  public struct FileLock: RawRepresentable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.FileLock

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.FileLock) { self.rawValue = rawValue }
  }
}

extension FileDescriptor.FileLock {
  @_alwaysEmitIntoClient
  public init() { self.init(rawValue: .init()) }

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

  /// The process ID of the lock holder (if applicable).
  ///
  /// The corresponding C field is `l_pid`
  @_alwaysEmitIntoClient
  public var pid: ProcessID {
    get { ProcessID(rawValue: rawValue.l_pid) }
    set { rawValue.l_pid = newValue.rawValue }
  }
}

// MARK: - Convenience for `struct flock`
extension FileDescriptor.FileLock {
  // For OFD locks
  internal init(
    ofdType: Kind,
    start: Int64,
    length: Int64
  ) {
    self.init()
    self.type = ofdType
    self.start = start
    self.length = length
    self.pid = ProcessID(rawValue: 0)
  }
}

extension FileDescriptor.FileLock {
  /// The kind or type of a lock: read (aka "shared"), write (aka "exclusive"), or none
  /// (aka "unlock").
  @frozen
  public struct Kind: RawRepresentable, Hashable, Sendable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.CShort

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.CShort) { self.rawValue = rawValue }

    /// Read lock (aka "shared")
    ///
    /// The corresponding C constant is `F_RDLCK`.
    @_alwaysEmitIntoClient
    public static var read: Self {
      Self(rawValue: CInterop.CShort(truncatingIfNeeded: F_RDLCK))
    }

    /// Write lock (aka "exclusive")
    ///
    /// The corresponding C constant is `F_WRLCK`.
    @_alwaysEmitIntoClient
    public static var write: Self {
      Self(rawValue: CInterop.CShort(truncatingIfNeeded: F_WRLCK))
    }

    /// No lock (aka "unlock").
    ///
    /// The corresponding C constant is `F_UNLCK`.
    @_alwaysEmitIntoClient
    public static var none: Self {
      Self(rawValue: CInterop.CShort(truncatingIfNeeded: F_UNLCK))
    }
  }
}

extension FileDescriptor {
  /// All bytes in a file
  @_alwaysEmitIntoClient
  internal var _allFileBytes: Range<Int64> { Int64.min ..< Int64.max }

  /// Get any conflicting locks held by other open file descriptions.
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
  /// Open file description locks are inherited by child processes across
  /// `fork`, etc.
  ///
  /// - Parameters:
  ///   - byteRange: The range of bytes over which to check for a lock. Pass
  ///     `nil` to consider the entire file.
  ///   - retryOnInterrupt: Whether to retry the operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  /// - Returns; `.none` if there are no locks, otherwise returns the
  ///   strongest conflicting lock
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_GETLK`.
  @_alwaysEmitIntoClient
  public func getConflictingLock(
    byteRange: (some RangeExpression<Int64>)? = Range?.none,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor.FileLock.Kind {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    return try _getConflictingLock(
      start: start, length: len, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _getConflictingLock(
    start: Int64, length: Int64, retryOnInterrupt: Bool
  ) -> Result<FileDescriptor.FileLock.Kind, Errno> {
    // If there are multiple locks already in place on a file region, the lock that
    // is returned is unspecified. E.g. there could be a write lock over one
    // portion of the file and a read lock over another overlapping
    // region. Thus, we first check if there are any write locks, and if not
    // we issue another call to check for any reads-or-writes.
    //
    // 1) Try with a read lock, which will tell us if there's a conflicting
    // write lock in place.
    //
    // 2) Try with a write lock, which will tell us if there's either a
    // conflicting read or write lock in place.
    var lock = FileDescriptor.FileLock(ofdType: .read, start: start, length: length)
    if case let .failure(err) = self._fcntl(
      .getOFDLock, &lock, retryOnInterrupt: retryOnInterrupt
    ) {
      return .failure(err)
    }
    if lock.type == .write {
      return .success(.write)
    }
    guard lock.type == .none else {
      fatalError("FIXME: really shouldn't be possible")
    }
    // This means there was no conflicting lock, so try to detect reads
    lock = FileDescriptor.FileLock(ofdType: .write, start: start, length: length)

    let secondTry = self._fcntl(.getOFDLock, &lock, retryOnInterrupt: retryOnInterrupt)
    return secondTry.map { lock.type }
  }

  /// Set an open file description lock.
  ///
  /// If the open file description already has a lock, the old lock is
  /// replaced.
  ///
  /// If the lock cannot be set because it is blocked by an existing lock on a
  /// file and `wait` is `false`,
  /// `Errno.resourceTemporarilyUnavailable` is thrown.
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
  /// Open file description locks are inherited by child processes across
  /// `fork`, etc.
  ///
  /// Passing a lock kind of `.none` will remove a lock (equivalent to calling
  /// `FileDescriptor.unlock()`).
  ///
  /// - Parameters:
  ///   - kind: The kind of lock to set
  ///   - byteRange: The range of bytes over which to lock. Pass
  ///     `nil` to consider the entire file.
  ///   - wait: Whether to wait (block) until the request can be completed
  ///   - retryOnInterrupt: Whether to retry the operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` or
  /// `F_OFD_SETLKW`.
  @_alwaysEmitIntoClient
  public func lock(
    _ kind: FileDescriptor.FileLock.Kind = .read,
    byteRange: (some RangeExpression<Int64>)? = Range?.none,
    wait: Bool = false,
    retryOnInterrupt: Bool = true
  ) throws {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    try _lock(
      kind,
      start: start,
      length: len,
      wait: wait,
      retryOnInterrupt: retryOnInterrupt
    ).get()
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
  /// Open file description locks are inherited by child processes across
  /// `fork`, etc.
  ///
  /// Calling `unlock()` is equivalent to passing `.none` as the lock kind to
  /// `FileDescriptor.lock()`.
  ///
  /// - Parameters:
  ///   - byteRange: The range of bytes over which to lock. Pass
  ///     `nil` to consider the entire file.
  ///   - wait: Whether to wait (block) until the request can be completed
  ///   - retryOnInterrupt: Whether to retry the operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` or
  /// `F_OFD_SETLKW` and a lock type of `F_UNLCK`.
  @_alwaysEmitIntoClient
  public func unlock(
    byteRange: (some RangeExpression<Int64>)? = Range?.none,
    wait: Bool = false, // FIXME: needed?
    retryOnInterrupt: Bool = true
  ) throws {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    try _lock(
      .none,
      start: start,
      length: len,
      wait: wait,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _lock(
    _ kind: FileDescriptor.FileLock.Kind,
    start: Int64,
    length: Int64,
    wait: Bool,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    var lock = FileDescriptor.FileLock(ofdType: kind, start: start, length: length)
    let command: FileDescriptor.Control.Command =
      wait ? .setOFDLockWait : .setOFDLock
    return _fcntl(command, &lock, retryOnInterrupt: retryOnInterrupt)
  }
}
#endif

