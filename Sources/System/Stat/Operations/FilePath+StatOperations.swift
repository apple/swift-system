/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - stat
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  /// Obtain information about the file pointed to by the FilePath.
  ///
  /// - Parameters:
  ///   - followSymlinks: Whether to follow symlinks.
  ///     The default is `true`.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A `FileStatus` for the file pointed to by `self`.
  ///
  /// Read, write or execute permission of the pointed to file is not required,
  /// but all intermediate directories must be searchable.
  ///
  /// The corresponding C functions are `stat` and `lstat`.
  @_alwaysEmitIntoClient
  public func getFileStatus(
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws -> FileStatus {
    try _getFileStatus(
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _getFileStatus(
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<FileStatus, Errno> {
    var result = CInterop.Stat()
    let fn = followSymlinks ? system_lstat : system_stat
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        fn(ptr, &result)
      }.map { FileStatus(rawValue: result) }
    }
  }

  /// Obtain information about the file pointed to by the FilePath relative to
  /// the provided FileDescriptor.
  ///
  /// - Parameters:
  ///   - relativeTo: if `self` is relative, treat it as relative to this file descriptor
  ///     rather than relative to the current working directory.
  ///   - followSymlinks: Whether to follow symlinks.
  ///     The default is `true`.
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A `FileStatus` for the file pointed to by `self`.
  ///
  /// Read, write or execute permission of the pointed to file is not required,
  /// but all intermediate directories must be searchable.
  ///
  /// The corresponding C function is `fstatat`.
  @_alwaysEmitIntoClient
  public func getFileStatus(
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws -> FileStatus {
    try _getFileStatus(
      relativeTo: fd,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _getFileStatus(
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<FileStatus, Errno>  {
    var result = CInterop.Stat()
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_fstatat(fd.rawValue, ptr, &result, fcntrl.rawValue)
      }.map { FileStatus(rawValue: result) }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - chmod
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func changeFileMode(
    to mode: FileMode,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileMode(
      to: mode,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileMode(
    to mode: FileMode,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let fn = followSymlinks ? system_lchmod : system_chmod
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        fn(ptr, mode.rawValue)
      }
    }
  }

  // valid flags: AT_SYMLINK_NOFOLLOW | AT_REALDEV | AT_FDONLY
  @_alwaysEmitIntoClient
  public func changeFileMode(
    to mode: FileMode,
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileMode(
      to: mode,
      relativeTo: fd,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileMode(
    to mode: FileMode,
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    self.withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_fchmodat(fd.rawValue, ptr, mode.rawValue, fcntrl.rawValue)
      }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - chown
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func changeOwner(
    to owner: (userID: CInterop.UserID, groupID: CInterop.GroupID),
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeOwner(
      to: owner,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeOwner(
    to owner: (userID: CInterop.UserID, groupID: CInterop.GroupID),
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let fn = followSymlinks ? system_lchown : system_chown
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        fn(ptr, owner.userID, owner.groupID)
      }
    }
  }

  @_alwaysEmitIntoClient
  public func changeOwner(
    to owner: (userID: CInterop.UserID, groupID: CInterop.GroupID),
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeOwner(
      to: owner,
      relativeTo: fd,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeOwner(
    to owner: (userID: CInterop.UserID, groupID: CInterop.GroupID),
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    self.withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_fchownat(
          fd.rawValue, ptr, owner.userID, owner.groupID, fcntrl.rawValue)
      }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - chflags
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func changeFileFlags(
    to flags: FileFlags,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileFlags(
      to: flags,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileFlags(
    to flags: FileFlags,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let fn = followSymlinks ? system_lchflags : system_chflags
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        fn(ptr, flags.rawValue)
      }
    }
  }

#if os(FreeBSD)
  @_alwaysEmitIntoClient
  public func changeFileFlags(
    to flags: FileFlags,
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileFlags(
      to: flags,
      relativeTo: fd,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileFlags(
    to flags: FileFlags,
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_chflagsat(fd.rawValue, ptr, flags.rawValue, fcntrl.rawValue)
      }
    }
  }
#endif
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - mkfifo
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func makeFIFO(
    withMode mode: FileMode,
    retryOnInterrupt: Bool = true) throws {
    try _makeFIFO(
      withMode: mode,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _makeFIFO(
    withMode mode: FileMode,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkfifo(ptr, mode.rawValue)
      }
    }
  }

  @available(macOS 13.0, *)
  @_alwaysEmitIntoClient
  public func makeFIFO(
    withMode mode: FileMode,
    relativeTo fd: FileDescriptor,
    retryOnInterrupt: Bool = true) throws {
    try _makeFIFO(
      withMode: mode,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @available(macOS 13.0, *)
  @usableFromInline
  internal func _makeFIFO(
    withMode mode: FileMode,
    relativeTo fd: FileDescriptor,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkfifoat(fd.rawValue, ptr, mode.rawValue)
      }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - mknod
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func makeNode(
    withMode mode: FileMode,
    andDeviceID deviceID: CInterop.DeviceID,
    retryOnInterrupt: Bool = true) throws {
    try _makeNode(
      withMode: mode,
      andDeviceID: deviceID,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _makeNode(
    withMode mode: FileMode,
    andDeviceID deviceID: CInterop.DeviceID,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mknod(ptr, mode.rawValue, deviceID)
      }
    }
  }

  @available(macOS 13.0, *)
  @_alwaysEmitIntoClient
  public func makeNode(
    withMode mode: FileMode,
    andDeviceID deviceID: CInterop.DeviceID,
    relativeTo fd: FileDescriptor,
    retryOnInterrupt: Bool = true) throws {
    try _makeNode(
      withMode: mode,
      andDeviceID: deviceID,
      relativeTo: fd,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @available(macOS 13.0, *)
  @usableFromInline
  internal func _makeNode(
    withMode mode: FileMode,
    andDeviceID deviceID: CInterop.DeviceID,
    relativeTo fd: FileDescriptor,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mknodat(fd.rawValue, ptr, mode.rawValue, deviceID)
      }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - mkdir
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func makeDirectory(
    withMode mode: FileMode,
    retryOnInterrupt: Bool = true) throws {
    try _makeDirectory(
      withMode: mode,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _makeDirectory(
    withMode mode: FileMode,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkdir(ptr, mode.rawValue)
      }
    }
  }

  @available(macOS 13.0, *)
  @_alwaysEmitIntoClient
  public func makeDirectory(
    withMode mode: FileMode,
    relativeTo fd: FileDescriptor,
    retryOnInterrupt: Bool = true) throws {
    try _makeDirectory(
      withMode: mode,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @available(macOS 13.0, *)
  @usableFromInline
  internal func _makeDirectory(
    withMode mode: FileMode,
    relativeTo fd: FileDescriptor,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkdirat(fd.rawValue, ptr, mode.rawValue)
      }
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - mkdir
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
#if os(FreeBSD)
  @_alwaysEmitIntoClient
  public func changeFileTimes(
    to times: (access: TimeSpecification, modification: TimeSpecification)?,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileTimes(
      to: times,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileTimes(
    to times: (access: TimeSpecification, modification: TimeSpecification)?,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let fn = followSymlinks ? system_utimens : system_lutimens
    return withPlatformString { ptr in
      if let times = times {
        return withUnsafePointer(to: times) { tuplePtr in
          tuplePtr.withMemoryRebound(to: CInterop.TimeSpec.self, capacity: 2) {
            timespecPtr in
            nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
              fn(ptr, timespecPtr)
            }
          }
        }
      } else {
        return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
          fn(ptr, nil)
        }
      }
    }
  }
#endif

  @_alwaysEmitIntoClient
  public func changeFileTimes(
    to times: (access: TimeSpecification, modification: TimeSpecification)?,
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileTimes(
      to: times,
      relativeTo: fd,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }
  
  @usableFromInline
  internal func _changeFileTimes(
    to times: (access: TimeSpecification, modification: TimeSpecification)?,
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    self.withPlatformString { ptr in
      if let times = times {
        return withUnsafePointer(to: times) { tuplePtr in
          tuplePtr.withMemoryRebound(to: CInterop.TimeSpec.self, capacity: 2) {
            timespecPtr in
            nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
              system_utimensat(fd.rawValue, ptr, timespecPtr, fcntrl.rawValue)
            }
          }
        }
      } else {
        return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
          system_utimensat(fd.rawValue, ptr, nil, fcntrl.rawValue)
        }
      }
    }
  }
}
#endif
