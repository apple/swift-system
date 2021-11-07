/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FileDescriptor {
  /// Opens or creates a file for reading or writing.
  ///
  /// - Parameters:
  ///   - path: The location of the file to open.
  ///   - mode: The read and write access to use.
  ///   - options: The behavior for opening the file.
  ///   - permissions: The file permissions to use for created files.
  ///   - retryOnInterrupt: Whether to retry the open operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A file descriptor for the open file
  ///
  /// The corresponding C function is `open`.
  @_alwaysEmitIntoClient
  public static func open(
    _ path: FilePath,
    _ mode: FileDescriptor.AccessMode,
    options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
    permissions: FilePermissions? = nil,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    try path.withPlatformString {
      try FileDescriptor.open(
        $0, mode, options: options, permissions: permissions, retryOnInterrupt: retryOnInterrupt)
    }
  }

  /// Opens or creates a file for reading or writing.
  ///
  /// - Parameters:
  ///   - path: The location of the file to open.
  ///   - mode: The read and write access to use.
  ///   - options: The behavior for opening the file.
  ///   - permissions: The file permissions to use for created files.
  ///   - retryOnInterrupt: Whether to retry the open operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A file descriptor for the open file
  ///
  /// The corresponding C function is `open`.
  @_alwaysEmitIntoClient
  public static func open(
    _ path: UnsafePointer<CInterop.PlatformChar>,
    _ mode: FileDescriptor.AccessMode,
    options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
    permissions: FilePermissions? = nil,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    try FileDescriptor._open(
      path, mode, options: options, permissions: permissions, retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal static func _open(
    _ path: UnsafePointer<CInterop.PlatformChar>,
    _ mode: FileDescriptor.AccessMode,
    options: FileDescriptor.OpenOptions,
    permissions: FilePermissions?,
    retryOnInterrupt: Bool
  ) -> Result<FileDescriptor, Errno> {
    let oFlag = mode.rawValue | options.rawValue
    let descOrError: Result<CInt, Errno> = valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      if let permissions = permissions {
        return system_open(path, oFlag, permissions.rawValue)
      }
      precondition(!options.contains(.create),
        "Create must be given permissions")
      return system_open(path, oFlag)
    }
    return descOrError.map { FileDescriptor(rawValue: $0) }
  }

  /// Deletes a file descriptor.
  ///
  /// Deletes the file descriptor from the per-process object reference table.
  /// If this is the last reference to the underlying object,
  /// the object will be deactivated.
  ///
  /// The corresponding C function is `close`.
  @_alwaysEmitIntoClient
  public func close() throws { try _close().get() }

  @usableFromInline
  internal func _close() -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: false) { system_close(self.rawValue) }
  }

  /// Reposition the offset for the given file descriptor.
  ///
  /// - Parameters:
  ///   - offset: The new offset for the file descriptor.
  ///   - whence: The origin of the new offset.
  /// - Returns: The file's offset location,
  ///   in bytes from the beginning of the file.
  ///
  /// The corresponding C function is `lseek`.
  @_alwaysEmitIntoClient
  @discardableResult
  public func seek(
    offset: Int64, from whence: FileDescriptor.SeekOrigin
  ) throws -> Int64 {
    try _seek(offset: offset, from: whence).get()
  }

  @usableFromInline
  internal func _seek(
    offset: Int64, from whence: FileDescriptor.SeekOrigin
  ) -> Result<Int64, Errno> {
    valueOrErrno(retryOnInterrupt: false) {
      Int64(system_lseek(self.rawValue, _COffT(offset), whence.rawValue))
    }
  }


  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "seek")
  public func lseek(
    offset: Int64, from whence: FileDescriptor.SeekOrigin
  ) throws -> Int64 {
    try seek(offset: offset, from: whence)
  }

  /// Reads bytes at the current file offset into a buffer.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory to read into.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were read.
  ///
  /// The <doc://com.apple.documentation/documentation/swift/unsafemutablerawbufferpointer/3019191-count> property of `buffer`
  /// determines the maximum number of bytes that are read into that buffer.
  ///
  /// After reading,
  /// this method increments the file's offset by the number of bytes read.
  /// To change the file's offset,
  /// call the ``seek(offset:from:)`` method.
  ///
  /// The corresponding C function is `read`.
  @_alwaysEmitIntoClient
  public func read(
    into buffer: UnsafeMutableRawBufferPointer,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _read(into: buffer, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _read(
    into buffer: UnsafeMutableRawBufferPointer,
    retryOnInterrupt: Bool
  ) throws -> Result<Int, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_read(self.rawValue, buffer.baseAddress, buffer.count)
    }
  }

  /// Reads bytes at the specified offset into a buffer.
  ///
  /// - Parameters:
  ///   - offset: The file offset where reading begins.
  ///   - buffer: The region of memory to read into.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were read.
  ///
  /// The <doc://com.apple.documentation/documentation/swift/unsafemutablerawbufferpointer/3019191-count> property of `buffer`
  /// determines the maximum number of bytes that are read into that buffer.
  ///
  /// Unlike <doc:System/FileDescriptor/read(into:retryOnInterrupt:)>,
  /// this method leaves the file's existing offset unchanged.
  ///
  /// The corresponding C function is `pread`.
  @_alwaysEmitIntoClient
  public func read(
    fromAbsoluteOffset offset: Int64,
    into buffer: UnsafeMutableRawBufferPointer,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _read(
      fromAbsoluteOffset: offset,
      into: buffer,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _read(
    fromAbsoluteOffset offset: Int64,
    into buffer: UnsafeMutableRawBufferPointer,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_pread(self.rawValue, buffer.baseAddress, buffer.count, _COffT(offset))
    }
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "read")
  public func pread(
    fromAbsoluteOffset offset: Int64,
    into buffer: UnsafeMutableRawBufferPointer,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try read(
      fromAbsoluteOffset: offset,
      into: buffer,
      retryOnInterrupt: retryOnInterrupt)
  }

  /// Writes the contents of a buffer at the current file offset.
  ///
  /// - Parameters:
  ///   - buffer: The region of memory that contains the data being written.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were written.
  ///
  /// After writing,
  /// this method increments the file's offset by the number of bytes written.
  /// To change the file's offset,
  /// call the ``seek(offset:from:)`` method.
  ///
  /// The corresponding C function is `write`.
  @_alwaysEmitIntoClient
  public func write(
    _ buffer: UnsafeRawBufferPointer,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _write(buffer, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _write(
    _ buffer: UnsafeRawBufferPointer,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_write(self.rawValue, buffer.baseAddress, buffer.count)
    }
  }

  /// Writes the contents of a buffer at the specified offset.
  ///
  /// - Parameters:
  ///   - offset: The file offset where writing begins.
  ///   - buffer: The region of memory that contains the data being written.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The number of bytes that were written.
  ///
  /// Unlike ``write(_:retryOnInterrupt:)``,
  /// this method leaves the file's existing offset unchanged.
  ///
  /// The corresponding C function is `pwrite`.
  @_alwaysEmitIntoClient
  public func write(
    toAbsoluteOffset offset: Int64,
    _ buffer: UnsafeRawBufferPointer,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try _write(toAbsoluteOffset: offset, buffer, retryOnInterrupt: retryOnInterrupt).get()
  }

  @usableFromInline
  internal func _write(
    toAbsoluteOffset offset: Int64,
    _ buffer: UnsafeRawBufferPointer,
    retryOnInterrupt: Bool
  ) -> Result<Int, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_pwrite(self.rawValue, buffer.baseAddress, buffer.count, _COffT(offset))
    }
  }


  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "write")
  public func pwrite(
    toAbsoluteOffset offset: Int64,
    into buffer: UnsafeRawBufferPointer,
    retryOnInterrupt: Bool = true
  ) throws -> Int {
    try write(
      toAbsoluteOffset: offset,
      buffer,
      retryOnInterrupt: retryOnInterrupt)
  }

  /// Duplicate this file descriptor and return the newly created copy.
  ///
  /// - Parameters:
  ///   - `target`: The desired target file descriptor, or `nil`, in which case
  ///      the copy is assigned to the file descriptor with the lowest raw value
  ///      that is not currently in use by the process.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///      if it throws ``Errno/interrupted``. The default is `true`.
  ///      Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The new file descriptor.
  ///
  /// If the `target` descriptor is already in use, then it is first
  /// deallocated as if a close(2) call had been done first.
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
  ///
  /// The corresponding C functions are `dup` and `dup2`.
  @_alwaysEmitIntoClient
  // @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
  public func duplicate(
    as target: FileDescriptor? = nil,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    try _duplicate(as: target, retryOnInterrupt: retryOnInterrupt).get()
  }

  // @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
  @usableFromInline
  internal func _duplicate(
    as target: FileDescriptor?,
    retryOnInterrupt: Bool
  ) throws -> Result<FileDescriptor, Errno> {
    valueOrErrno(retryOnInterrupt: retryOnInterrupt) {
      if let target = target {
        return system_dup2(self.rawValue, target.rawValue)
      }
      return system_dup(self.rawValue)
    }.map(FileDescriptor.init(rawValue:))
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "duplicate")
  public func dup() throws -> FileDescriptor {
    fatalError("Not implemented")
  }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "duplicate")
  public func dup2() throws -> FileDescriptor {
    fatalError("Not implemented")
  }
  
  #if !os(Windows)
  /// Create a pipe, a unidirectional data channel which can be used for interprocess communication.
  ///
  /// - Returns: The pair of file descriptors.
  ///
  /// The corresponding C function is `pipe`.
  @_alwaysEmitIntoClient
  // @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
  public static func pipe() throws -> (readEnd: FileDescriptor, writeEnd: FileDescriptor) {
    try _pipe().get()
  }
  
  @usableFromInline
  internal static func _pipe() -> Result<(readEnd: FileDescriptor, writeEnd: FileDescriptor), Errno> {
    var fds: (Int32, Int32) = (-1, -1)
    return withUnsafeMutablePointer(to: &fds) { pointer in
      valueOrErrno(retryOnInterrupt: false) {
        system_pipe(UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: Int32.self))
      }
    }.map { _ in (.init(rawValue: fds.0), .init(rawValue: fds.1)) }
  }
  #endif

#if !os(Windows)
  // MARK: Memory Mapping

  /// Describes the desired memory protection of the
  /// mapping (and must not conflict with the open mode of the file).
  /// Flags can be the bitwise OR of one or more of each case.
  @frozen
  public struct MemoryProtection: RawRepresentable, Hashable, Codable {
    /// The raw C protection number.
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    /// Creates a strongly typed error number from a raw C error number.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Pages may not be accessed.
    @_alwaysEmitIntoClient
    public static var none: MemoryProtection { MemoryProtection(rawValue: _PROT_NONE) }
    /// Pages may be read.
    @_alwaysEmitIntoClient
    public static var read: MemoryProtection { MemoryProtection(rawValue: _PROT_READ) }
    /// Pages may be written.
    @_alwaysEmitIntoClient
    public static var write: MemoryProtection { MemoryProtection(rawValue: _PROT_WRITE) }
    /// Pages may be executed.
    @_alwaysEmitIntoClient
    public static var executed: MemoryProtection { MemoryProtection(rawValue: _PROT_EXEC) }
  }

  /// Determines whether updates to the mapping are
  /// visible to other processes mapping the same region, and whether
  /// updates are carried through to the underlying file.  This
  /// behavior is determined by exactly one flag.
  public struct MemoryMapKind: RawRepresentable, Hashable, Codable {
    /// The raw C flag number.
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    /// Creates a strongly typed error number from a raw C error number.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Share this mapping.  Updates to the mapping are visible to
    /// other processes mapping the same region, and (in the case
    /// of file-backed mappings) are carried through to the
    /// underlying file.
    @_alwaysEmitIntoClient
    public static var shared: MemoryMapKind { MemoryMapKind(rawValue: _MAP_SHARED) }
    /// Create a private copy-on-write mapping.  Updates to the
    /// mapping are not visible to other processes mapping the
    /// same file, and are not carried through to the underlying
    /// file.  It is unspecified whether changes made to the file
    /// after the `memoryMap` call are visible in the mapped region.
    @_alwaysEmitIntoClient
    public static var `private`: MemoryMapKind { MemoryMapKind(rawValue: _MAP_PRIVATE) }

    // TODO: There are several other MemoryMapKinds.
  }

  /// Determines whether memory sync should be
  /// synchronous, asynchronous, and/or invalidate
  /// other mappings of the same file.
  @frozen
  public struct MemorySyncKind: RawRepresentable, Hashable, Codable {
    /// The raw C flag number.
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    /// Creates a strongly typed error number from a raw C error number.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: raw) }

    /// Requests an update and waits for it to complete.
    @_alwaysEmitIntoClient
    public static var synchronous: MemorySyncKind { MemorySyncKind(rawValue: _MS_SYNC) }
    /// Specifies that an update be scheduled, but the call
    /// returns immediately.
    @_alwaysEmitIntoClient
    public static var asynchronous: MemorySyncKind { MemorySyncKind(rawValue: _MS_ASYNC) }
    /// Asks to invalidate other mappings of the same file (so
    /// that they can be updated with the fresh values just
    /// written).
    @_alwaysEmitIntoClient
    public static var invalidate: MemorySyncKind { MemorySyncKind(rawValue: _MS_INVALIDATE) }
  }

  /// Create a new mapping in the virtual address space of the
  /// calling process.
  /// After the `memoryMap` call has returned, the file descriptor can
  /// be closed immediately without invalidating the mapping.
  /// - Parameters:
  ///   - length: Specifies the length of the mapping (which must be greater than 0).
  ///   - pageOffset: The page offset to map. Page size is determined by `sysconf(_SC_PAGE_SIZE)`
  ///   - kind: Determines the kind of mapping returned. Currently limited to `MAP_SHARED` and `MAP_PRIVATE`.
  ///   - protection: Describes the desired memory protection of the mapping (and must not conflict with the open mode of the file).
  /// - Returns: The new memory mapping.
  @_alwaysEmitIntoClient
  public func memoryMap(
    length: Int, pageOffset: Int, kind: MemoryMapKind, protection: [MemoryProtection]
  ) throws -> UnsafeMutableRawPointer {
    try _memoryMap(length: length,
                   pageOffset: pageOffset,
                   kind: kind,
                   protection: protection).get()
  }

  @usableFromInline
  internal func _memoryMap(
    length: Int, pageOffset: Int, kind: MemoryMapKind, protection: [MemoryProtection]
  ) throws -> Result<UnsafeMutableRawPointer, Errno> {
    valueOrErrno(valueOnFail: _MAP_FAILED, retryOnInterrupt: false) {
      system_mmap(self.rawValue, length, protection.reduce(into: Int32(), { partialResult, prot in
        partialResult |= prot.rawValue
      }), kind.rawValue, _COffT(pageOffset))
    }
  }

  /// Deletes the mappings for the specified
  /// mapping, and causes further references to addresses within
  /// the range to generate invalid memory references.  The region is
  /// also automatically unmapped when the process is terminated.  On
  /// the other hand, closing the file descriptor does not unmap the
  /// region.
  /// - Parameters:
  ///   - memoryMap: The memory map to unmap
  ///   - length: Amount in bytes to unmap.
  @_alwaysEmitIntoClient
  public func memoryUnmap(memoryMap: UnsafeMutableRawPointer, length: Int) throws {
    _ = try _memoryUnmap(memoryMap: memoryMap, length: length).get()
  }

  @usableFromInline
  internal func _memoryUnmap(memoryMap: UnsafeMutableRawPointer, length: Int) throws -> Result<CInt, Errno> {
    valueOrErrno(retryOnInterrupt: false) {
      system_munmap(memoryMap, length)
    }
  }

  /// Flushes changes made to the in-core copy of a file that
  /// was mapped into memory using `memoryMap` back to the filesystem.
  /// Without use of this call, there is no guarantee that changes are
  /// written back before `memoryUnmap` is called.  To be more precise, the
  /// part of the file that corresponds to the memory area at the start
  /// of the map and having length of `length` is updated.
  /// - Parameters:
  ///   - memoryMap: The memory map to sync.
  ///   - length: Length to update.
  ///   - kind: Should specify one of `MemorySyncKind.synchronous` or `MemorySyncKind.asynchronous`.
  ///   - invalidateOtherMappings: Asks to invalidate other mappings of the same file (so
  ///                              that they can be updated with the fresh values just
  ///                              written).
  @_alwaysEmitIntoClient
  public func memorySync(
    memoryMap: UnsafeMutableRawPointer,
    length: Int,
    kind: MemorySyncKind,
    invalidateOtherMappings: Bool = false
  ) throws {
    _ = try _memorySync(memoryMap: memoryMap,
                        length: length,
                        flags: invalidateOtherMappings ? kind.rawValue & _MS_INVALIDATE : kind.rawValue)
      .get()
  }

  @usableFromInline
  internal func _memorySync(memoryMap: UnsafeMutableRawPointer, length: Int, flags: CInt) throws -> Result<CInt, Errno> {
    valueOrErrno(retryOnInterrupt: false) {
      system_msync(memoryMap, length, flags)
    }
  }
#endif
}

