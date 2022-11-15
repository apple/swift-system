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
  public struct FileLock: RawRepresentable {
    @_alwaysEmitIntoClient
    public var rawValue: CInterop.FileLock

    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.FileLock) { self.rawValue = rawValue }
  }
}

extension FileDescriptor.FileLock {
  /// TODO: docs
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

// MARK: - Convenience for `struct flock`
extension FileDescriptor.FileLock {

  // For whole-file OFD locks
  internal init(
    ofdType: Kind,
    start: Int64,
    length: Int64
  ) {
    self.init()
    self.type = ofdType
    self.start = start
    self.length = length
    self.pid = 0
  }

  // TOOO: convenience initializers or static constructors


}

extension FileDescriptor.FileLock {
  /// The kind of a lock: read ("shared"), write ("exclusive"), or none
  /// ("unlock").
  @frozen
  public struct Kind: RawRepresentable, Hashable {
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


// TODO: Need to version this carefully
// TODO: Don't do this, make a new type, but figure out ranges for that new type
extension FileDescriptor.SeekOrigin: Comparable, Strideable {
  // TODO: Should stride be CInt or Int?

  public func distance(to other: FileDescriptor.SeekOrigin) -> Int {
    Int(other.rawValue - self.rawValue)
  }

  public func advanced(by n: Int) -> FileDescriptor.SeekOrigin {
    .init(rawValue: self.rawValue + CInt(n))
  }
  public static func < (
    lhs: FileDescriptor.SeekOrigin, rhs: FileDescriptor.SeekOrigin
  ) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

extension FileDescriptor {
  struct FileRange {
    // Note: if it has an origin it wouldn't be comparable really or strideable
  }
}


extension FileDescriptor {
  /// All bytes in a file
  ///
  /// NOTE: We can't make byteRange optional _and_ generic in our API below because that requires type inference even when passed `nil`.
  ///
  @_alwaysEmitIntoClient
  internal var _allFileBytes: Range<Int64> { Int64.min ..< Int64.max }

  /// Get any conflicting locks held by other  open file descriptions.
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
  ///     `nil` to consider the entire file (TODO: default value with Swift
  ///     5.7)
  ///   - retryOnInterrupt: Whether to retry the open operation if it throws
  ///     ``Errno/interrupted``. The default is `true`. Pass `false` to try
  ///     only once and throw an error upon interruption.
  /// - Returns; `.none` if there are no other locks, otherwise returns the
  ///   strongest conflicting lock
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_GETLK`.
  ///
  /// FIXME: Does this only return OFD locks or process locks too?
  /// TODO: document byte-range
  /// FIXME: Can we just state the OFD docs once and link to it?
  /// TODO: would a better API be e.g. `canGetLock(.read)`? or `getConflictingLock()`?
  ///
  @_alwaysEmitIntoClient
  public func getConflictingLock(
    byteRange: some RangeExpression<Int64>,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor.FileLock.Kind {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    return try _getConflictingLock(
      start: start, length: len, retryOnInterrupt: retryOnInterrupt
    ).get()
  }


  @_alwaysEmitIntoClient
  public func getConflictingLock(
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor.FileLock.Kind {
    try getConflictingLock(
      byteRange: _allFileBytes, retryOnInterrupt: retryOnInterrupt)
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
//    print(lock.type)
    if case let .failure(err) = self._fcntl(
      .getOFDLock, &lock, retryOnInterrupt: retryOnInterrupt
    ) {
      return .failure(err)
    }
    if lock.type == .write {
//      print(lock.type)
      return .success(.write)
    }
    guard lock.type == .none else {
      fatalError("FIXME: really shouldn't be possible")
    }
    // This means there was no conflicting lock, so try to detect reads
    lock = FileDescriptor.FileLock(ofdType: .write, start: start, length: length)

    let secondTry = self._fcntl(.getOFDLock, &lock, retryOnInterrupt: retryOnInterrupt)
//    print(lock.type)
    return secondTry.map { lock.type }
  }

  /// Set an open file description lock.
  ///
  /// If the open file description already has a lock, the old lock is
  /// replaced.
  ///
  /// If the lock cannot be set because it is blocked by an existing lock on a
  /// file and (TODO: blocking paremeter is false),
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
  /// TODO: describe non-blocking
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` or
  /// `F_OFD_SETLKW`.
  @_alwaysEmitIntoClient
  public func lock(
    _ kind: FileDescriptor.FileLock.Kind = .read,
    byteRange: (some RangeExpression<Int64>)? = nil,
    nonBlocking: Bool = false, // FIXME: named "wait" or "blocking"? Which default is best?
    retryOnInterrupt: Bool = true
  ) throws {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    try _lock(
      kind,
      start: start,
      length: len,
      nonBlocking: nonBlocking,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @_alwaysEmitIntoClient
  public func lock(
    _ kind: FileDescriptor.FileLock.Kind = .read,
    nonBlocking: Bool = false, // FIXME: named "wait" or "blocking"? Which default is best?
    retryOnInterrupt: Bool = true
  ) throws {
    try lock(
      kind,
      byteRange: _allFileBytes,
      nonBlocking: nonBlocking,
      retryOnInterrupt: retryOnInterrupt)
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
  /// TODO: Do we need a non-blocking argument? Does that even make sense?
  ///
  /// The corresponding C function is `fcntl` with `F_OFD_SETLK` (TODO: or
  /// `F_OFD_SETLKW`?) and a lock type of `F_UNLCK`.
  @_alwaysEmitIntoClient
  public func unlock(
    byteRange: (some RangeExpression<Int64>)? = nil,
    nonBlocking: Bool = false, // FIXME: needed?
    retryOnInterrupt: Bool = true
  ) throws {
    let (start, len) = _mapByteRangeToByteOffsets(byteRange)
    try _lock(
      .none,
      start: start,
      length: len,
      nonBlocking: nonBlocking,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @_alwaysEmitIntoClient
  public func unlock(
    nonBlocking: Bool = false, // FIXME: needed?
    retryOnInterrupt: Bool = true
  ) throws {
    try unlock(
      byteRange: _allFileBytes,
      nonBlocking: nonBlocking,
      retryOnInterrupt: retryOnInterrupt)
  }


  @usableFromInline
  internal func _lock(
    _ kind: FileDescriptor.FileLock.Kind,
    start: Int64,
    length: Int64,
    nonBlocking: Bool,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    var lock = FileDescriptor.FileLock(ofdType: kind, start: start, length: length)
    let command: FileDescriptor.Control.Command =
      nonBlocking ? .setOFDLock : .setOFDLockWait
    return _fcntl(command, &lock, retryOnInterrupt: retryOnInterrupt)
  }
}
#endif

