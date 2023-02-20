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
  /// Set an advisory open file description lock.
  ///
  /// If the open file description already has a lock, the old lock is
  /// replaced. If the lock cannot be set because it is blocked by an existing lock,
  /// this will wait until the lock can be set.
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
  ///   - retryOnInterrupt: Whether to retry the operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLKW`.
  @_alwaysEmitIntoClient
  public func lock(
    _ kind: FileDescriptor.FileLock.Kind = .read,
    byteRange: (some RangeExpression<Int64>)? = Range?.none,
    retryOnInterrupt: Bool = true
  ) throws {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    try _lock(
      kind,
      start: start,
      length: len,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  /// Try to set an advisory open file description lock.
  ///
  /// If the open file description already has a lock, the old lock is
  /// replaced. If the lock cannot be set because it is blocked by an existing lock,
  /// that is if the syscall would throw `.resourceTemporarilyUnavailable`
  /// (aka `EAGAIN`), this will return `false`.
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
  ///   - retryOnInterrupt: Whether to retry the operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  /// - Returns: `true` if the lock was aquired, `false` otherwise
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK`.
  @_alwaysEmitIntoClient
  public func tryLock(
    _ kind: FileDescriptor.FileLock.Kind = .read,
    byteRange: (some RangeExpression<Int64>)? = Range?.none,
    retryOnInterrupt: Bool = true
  ) throws -> Bool {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    guard let _ = try _tryLock(
      kind,
      waitUntilTimeout: false,
      start: start,
      length: len,
      retryOnInterrupt: retryOnInterrupt
    )?.get() else {
      return false
    }
    return true
  }

  #if !os(Linux)
  /// Try to set an advisory open file description lock.
  ///
  /// If the open file description already has a lock, the old lock is
  /// replaced. If the lock cannot be set because it is blocked by an existing lock,
  /// that is if the syscall would throw `.resourceTemporarilyUnavailable`
  /// (aka `EAGAIN`), this will return `false`.
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
  ///   - waitUntilTimeout: If `true`, will wait until a timeout (determined by the operating system)
  ///   - retryOnInterrupt: Whether to retry the operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  /// - Returns: `true` if the lock was aquired, `false` otherwise
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` or `F_OFD_SETLKWTIMEOUT` .
  @_alwaysEmitIntoClient
  public func tryLock(
    _ kind: FileDescriptor.FileLock.Kind = .read,
    byteRange: (some RangeExpression<Int64>)? = Range?.none,
    waitUntilTimeout: Bool,
    retryOnInterrupt: Bool = true
  ) throws -> Bool {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    guard let _ = try _tryLock(
      kind,
      waitUntilTimeout: waitUntilTimeout,
      start: start,
      length: len,
      retryOnInterrupt: retryOnInterrupt
    )?.get() else {
      return false
    }
    return true
  }
  #endif

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
    guard let res = _tryLock(
      .none,
      waitUntilTimeout: false, // TODO: or we wait for timeout?
      start: start,
      length: len,
      retryOnInterrupt: retryOnInterrupt
    ) else {
      preconditionFailure("TODO: Unlock should always succeed?")
    }
    return try res.get()
  }

  @usableFromInline
  internal func _lock(
    _ kind: FileDescriptor.FileLock.Kind,
    start: Int64,
    length: Int64,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    var lock = FileDescriptor.FileLock(
      ofdType: kind, start: start, length: length)
    return _fcntl(.setOFDLockWait, &lock, retryOnInterrupt: retryOnInterrupt)
  }

  @usableFromInline
  internal func _tryLock(
    _ kind: FileDescriptor.FileLock.Kind,
    waitUntilTimeout: Bool,
    start: Int64,
    length: Int64,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno>? {
#if os(Linux)
    precondition(!waitUntilTimeout, "`waitUntilTimeout` unavailable on Linux")
#endif

    let cmd: Control.Command
    if waitUntilTimeout {
      cmd = .setOFDLockWaitTimout
    } else {
      cmd = .setOFDLock
    }
    var lock = FileDescriptor.FileLock(
      ofdType: kind, start: start, length: length)
    return _extractWouldBlock(
      _fcntl(cmd, &lock, retryOnInterrupt: retryOnInterrupt))
  }
}
#endif

