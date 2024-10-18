/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
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
    #if !os(Windows)
    return try path.withCString {
      try FileDescriptor.open(
        $0, mode, options: options, permissions: permissions, retryOnInterrupt: retryOnInterrupt)
    }
    #else 
    return try path.withPlatformString {
      try FileDescriptor.open(
        $0, mode, options: options, permissions: permissions, retryOnInterrupt: retryOnInterrupt)
    }
    #endif
  }

  #if !os(Windows) 
  // On Darwin, `CInterop.PlatformChar` is less available than 
  // `FileDescriptor.open`, so we need to use `CChar` instead.
  
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
    _ path: UnsafePointer<CChar>,
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
    _ path: UnsafePointer<CChar>,
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
  #else
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
      return system_open(path, oFlag)
    }
    return descOrError.map { FileDescriptor(rawValue: $0) }
  }
  #endif

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

  /// Repositions the offset for the given file descriptor.
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
  /// The <doc://com.apple.documentation/documentation/swift/unsafemutablerawbufferpointer/count-95usp> property of `buffer`
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
  /// The <doc://com.apple.documentation/documentation/swift/unsafemutablerawbufferpointer/count-95usp> property of `buffer`
  /// determines the maximum number of bytes that are read into that buffer.
  ///
  /// Unlike <doc:FileDescriptor/read(into:retryOnInterrupt:)>,
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
}

#if !os(WASI)
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FileDescriptor {
  /// Duplicates this file descriptor and return the newly created copy.
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
  @available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
  public func duplicate(
    as target: FileDescriptor? = nil,
    retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    try _duplicate(as: target, retryOnInterrupt: retryOnInterrupt).get()
  }

  @available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
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
}
#endif

#if !os(WASI)
@available(/*System 1.1.0: macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4*/iOS 8, *)
extension FileDescriptor {
  /// Creates a unidirectional data channel, which can be used for interprocess communication.
  ///
  /// - Returns: The pair of file descriptors.
  ///
  /// The corresponding C function is `pipe`.
  @_alwaysEmitIntoClient
  @available(/*System 1.1.0: macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4*/iOS 8, *)
  public static func pipe() throws -> (readEnd: FileDescriptor, writeEnd: FileDescriptor) {
    try _pipe().get()
  }

  @available(/*System 1.1.0: macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4*/iOS 8, *)
  @usableFromInline
  internal static func _pipe() -> Result<(readEnd: FileDescriptor, writeEnd: FileDescriptor), Errno> {
    var fds: (Int32, Int32) = (-1, -1)
    return withUnsafeMutablePointer(to: &fds) { pointer in
      pointer.withMemoryRebound(to: Int32.self, capacity: 2) { fds in
        valueOrErrno(retryOnInterrupt: false) {
          system_pipe(fds)
        }.map { _ in (.init(rawValue: fds[0]), .init(rawValue: fds[1])) }
      }
    }
  }
}
#endif

@available(/*System 1.2.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
extension FileDescriptor {
  /// Truncates or extends the file referenced by this file descriptor.
  ///
  /// - Parameters:
  ///   - newSize: The length in bytes to resize the file to.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///      if it throws ``Errno/interrupted``. The default is `true`.
  ///      Pass `false` to try only once and throw an error upon interruption.
  ///
  /// The file referenced by this file descriptor will by truncated (or extended) to `newSize`.
  ///
  /// If the current size of the file exceeds `newSize`, any extra data is discarded. If the current
  /// size of the file is smaller than `newSize`, the file is extended and filled with zeros to the
  /// provided size.
  ///
  /// This function requires that the file has been opened for writing.
  ///
  /// - Note: This function does not modify the current offset for any open file descriptors
  /// associated with the file.
  ///
  /// The corresponding C function is `ftruncate`.
  @available(/*System 1.2.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  @_alwaysEmitIntoClient
  public func resize(
    to newSize: Int64,
    retryOnInterrupt: Bool = true
  ) throws {
    try _resize(
      to: newSize,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @available(/*System 1.2.0: macOS 9999, iOS 9999, watchOS 9999, tvOS 9999*/iOS 8, *)
  @usableFromInline
  internal func _resize(
    to newSize: Int64,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_ftruncate(self.rawValue, _COffT(newSize))
    }
  }
}

extension FilePermissions {
  /// The file creation permission mask (aka "umask").
  ///
  /// Permissions set in this mask will be cleared by functions that create
  /// files or directories.  Note that this mask is process-wide, and that
  /// *getting* it is not thread safe.
  internal static var creationMask: FilePermissions {
    get {
      let oldMask = _umask(0o22)
      _ = _umask(oldMask)
      return FilePermissions(rawValue: oldMask)
    }
    set {
      _ = _umask(newValue.rawValue)
    }
  }

  /// Change the file creation permission mask, run some code, then
  /// restore it to its original value.
  ///
  /// - Parameters:
  ///   - permissions: The new permission mask.
  ///
  /// This is more efficient than reading `creationMask` and restoring it
  /// afterwards, because of the way reading the creation mask works.
  internal static func withCreationMask<R>(
    _ permissions: FilePermissions,
    body: () throws -> R
  ) rethrows -> R {
    let oldMask = _umask(permissions.rawValue)
    defer {
      _ = _umask(oldMask)
    }
    return try body()
  }

  internal static func _umask(_ mode: CModeT) -> CModeT {
    return system_umask(mode)
  }
}
