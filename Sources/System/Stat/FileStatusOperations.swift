/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// FIXME: this is wrong and should be done with wrapping fcntrl
// FIXME: go through and figure out the right way to express `at` methods
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  public struct ControlFlags {
    let rawValue: Int32
    // Test stub
    public static var none: ControlFlags = ControlFlags(rawValue: 0)
    // Out of scope of this sketch
  }
}

// MARK: - stat

// [x] int stat(const char *, struct stat *)
// [x] int lstat(const char *, struct stat *)
// [x] int fstat(int, struct stat *)
// [x] int fstatat(int, const char *, struct stat *, int)
// [ ] int statx_np(const char *, struct stat *, filesec_t)
// [ ] int lstatx_np(const char *, struct stat *, filesec_t)
// [ ] int fstatx_np(int, struct stat *, filesec_t)

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
  public func stat(
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws -> FileStatus {
    try _stat(
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _stat(
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
  public func stat(
    relativeTo fd: FileDescriptor,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws -> FileStatus {
    try _fstatat(
      relativeTo: fd,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fstatat(
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

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  /// Obtain information about the file pointed to by the FileDescriptor.
  ///
  /// - Parameters:
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A `FileStatus` for the file pointed to by `self`.
  ///
  /// The corresponding C function is `fstat`.
  @_alwaysEmitIntoClient
  public func stat(retryOnInterrupt: Bool = true) throws -> FileStatus {
    try _fstat(
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fstat(
    retryOnInterrupt: Bool = true
  ) -> Result<FileStatus, Errno> {
    var result = CInterop.Stat()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fstat(self.rawValue, &result)
    }.map { FileStatus(rawValue: result) }
  }
}

// MARK: - chmod

// [x] int chmod(const char *, mode_t)
// [x] int lchmod(const char *, mode_t)
// [x] int fchmod(int, mode_t)
// [x] int fchmodat(int, const char *, mode_t, int)
// [ ] int chmodx_np(const char *, filesec_t)
// [ ] int fchmodx_np(int, filesec_t)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func chmod(
    permissions: FilePermissions,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _chmod(
      permissions: permissions,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _chmod(
    permissions: FilePermissions,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let _chmod = followSymlinks ? system_lchmod : system_chmod
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chmod(ptr, permissions.rawValue)
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func fchmod(
    permissions: FilePermissions,
    retryOnInterrupt: Bool = true
  ) throws {
    try _fchmod(
      permissions: permissions,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fchmod(
    permissions: FilePermissions,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fchmod(self.rawValue, permissions.rawValue)
    }
  }

  // valid flags: AT_SYMLINK_NOFOLLOW | AT_REALDEV | AT_FDONLY
  @_alwaysEmitIntoClient
  public func fchmodat(
    path: FilePath,
    permissions: FilePermissions,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _fchmodat(
      path: path,
      permissions: permissions,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fchmodat(
    path: FilePath,
    permissions: FilePermissions,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    path.withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_fchmodat(
          self.rawValue, ptr, permissions.rawValue, fcntrl.rawValue)
      }
    }
  }
}

// MARK: - chown

// [x] int chown(const char *, uid_t, gid_t)
// [x] int lchown(const char *, uid_t, gid_t)
// [x] int fchown(int, uid_t, gid_t)
// [x] int fchownat(int, const char *, uid_t, gid_t, int)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func chown(
    userID: CInterop.UserID,
    groupID: CInterop.GroupID,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _chown(
      userID: userID,
      groupID: groupID,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _chown(
    userID: CInterop.UserID,
    groupID: CInterop.GroupID,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let _chown = followSymlinks ? system_lchown : system_chown
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chown(ptr, userID, groupID)
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func fchown(
    userID: CInterop.UserID,
    groupID: CInterop.GroupID,
    retryOnInterrupt: Bool = true
  ) throws {
    try _fchown(
      userID: userID,
      groupID: groupID,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fchown(
    userID: CInterop.UserID,
    groupID: CInterop.GroupID,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fchown(self.rawValue, userID, groupID)
    }
  }

  @_alwaysEmitIntoClient
  public func fchownat(
    path: FilePath,
    userID: CInterop.UserID,
    groupID: CInterop.GroupID,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _fchownat(
      path: path,
      userID: userID,
      groupID: groupID,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fchownat(
    path: FilePath,
    userID: CInterop.UserID,
    groupID: CInterop.GroupID,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    path.withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_fchownat(self.rawValue, ptr, userID, groupID, fcntrl.rawValue)
      }
    }
  }
}

// MARK: - chflags

// [x] int chflags(const char *, __uint32_t)
// [x] int lchflags(const char *, __uint32_t)
// [x] int fchflags(int, __uint32_t)
// [ ] int chflagsat(int, const char *, __uint32_t, int) (FreeBSD)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func chflags(
    flags: FileFlags,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _chflags(
      flags: flags,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _chflags(
    flags: FileFlags,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let _chflags = followSymlinks ? system_lchflags : system_chflags
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chflags(ptr, flags.rawValue)
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  internal func fchflags(
    flags: FileFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _fchflags(
      flags: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _fchflags(
    flags: FileFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fchflags(self.rawValue, flags.rawValue)
    }
  }
}

// MARK: - umask

// FIXME: umask document, shape
/// The umask() routine sets the process's file mode creation mask to newMask
/// and returns the previous value of the mask. The bits of newMask are used by
/// system calls, including open(2), mkdir(2), mkfifo(2), and mknod(2) to turn
/// off corresponding bits requested in file mode. (See chmod(2)). This clearing
/// allows each user to restrict the default access to their files.
///
/// The default mask value is `S_IWGRP` | `S_IWOTH` (022, write access for the
/// owner only). Child processes inherit the mask of the calling process.
// @_alwaysEmitIntoClient
// public func umask(newMask: FilePermissions) -> FilePermissions {
//   let oldMode = system_umask(newMask.rawValue)
//   return FileMode(rawValue: oldMode).permissions
// }

// [x] mode_t umask(mode_t)

// MARK: - mkfifo

// [x] int mkfifo(const char *, mode_t)
// [ ] int mkfifox_np(const char *, filesec_t)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func mkfifo(
    permissions: FilePermissions, retryOnInterrupt: Bool = true) throws {
    try _mkfifo(
      permissions: permissions,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _mkfifo(
    permissions: FilePermissions,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkfifo(ptr, permissions.rawValue)
      }
    }
  }
}

// MARK: - mknod

// [x] int mknod(const char *, mode_t, dev_t)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func mknod(
    permissions: FilePermissions,
    device: CInterop.DeviceID,
    retryOnInterrupt: Bool = true
  ) throws {
    try _mknod(
      permissions: permissions,
      device: device,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _mknod(
    permissions: FilePermissions,
    device: CInterop.DeviceID,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mknod(ptr, permissions.rawValue, device)
      }
    }
  }
}

// MARK: - mkdir

// [x] int mkdir(const char *, mode_t)
// [x] int mkdirat(int, const char *, mode_t)
// [ ] int mkdirx_np(const char *, filesec_t)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func mkdir(
    permissions: FilePermissions,
    retryOnInterrupt: Bool = true
  ) throws {
    try _mkdir(
      permissions: permissions,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _mkdir(
    permissions: FilePermissions,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkdir(ptr, permissions.rawValue)
      }
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  public func mkdirat(
    path: FilePath,
    permissions: FilePermissions,
    retryOnInterrupt: Bool = true
  ) throws {
    try _mkdirat(
      path: path,
      permissions: permissions,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  internal func _mkdirat(
    path: FilePath,
    permissions: FilePermissions,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    path.withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_mkdirat(self.rawValue, ptr, permissions.rawValue)
      }
    }
  }
}

// MARK: - utimens

// [x] int futimens(int, const struct timespec[2])
// [x] int utimensat(int, const char *, const struct timespec[2], int)

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
@available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func futimens(
    accessTime: TimeSpecification,
    modificationTime: TimeSpecification,
    retryOnInterrupt: Bool = true
  ) throws {
    try _futimens(
      accessTime: accessTime,
      modificationTime: modificationTime,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _futimens(
    accessTime: TimeSpecification,
    modificationTime: TimeSpecification,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let times = [accessTime.rawValue, modificationTime.rawValue]
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_futimens(self.rawValue, times)
    }
  }

  @_alwaysEmitIntoClient
  public func utimensat(
    path: FilePath,
    accessTime: TimeSpecification,
    modificationTime: TimeSpecification,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _utimensat(
      path: path,
      accessTime: accessTime,
      modificationTime: modificationTime,
      fcntrl: fcntrl,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _utimensat(
    path: FilePath,
    accessTime: TimeSpecification,
    modificationTime: TimeSpecification,
    fcntrl: FileDescriptor.ControlFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let times = [accessTime.rawValue, modificationTime.rawValue]
    return path.withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_utimensat(self.rawValue, ptr, times, fcntrl.rawValue)
      }
    }
  }
}

#endif
