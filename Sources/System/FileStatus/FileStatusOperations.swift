/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// FIXME: this is wrong and should be done with wrapping fcntrl
// FIXME: go through and figure out the right way to express `at` methods
// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  public struct ControlFlags {
    let rawValue: Int32
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

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FilePath {
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
    let _stat = followSymlinks ? SystemPackage._stat : _lstat
    return  withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _stat(ptr, &result)
      }.map { FileStatus(rawValue: result) }
    }
  }

  //  @_alwaysEmitIntoClient
  //  public func stat(relativeTo fd: FileDescriptor, flags: FileDescriptor.ControlFlags) throws -> FileStatus {
  //
  //  }
}

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  internal func fstat(retryOnInterrupt: Bool = true) throws -> FileStatus {
    var result = CInterop.Stat()
    try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      _fstat(self.rawValue, &result)
    }.get()
    return FileStatus(rawValue: result)
  }

  internal func fstatat(path: FilePath, fcntrl: FileDescriptor.ControlFlags, retryOnInterrupt: Bool = true) throws -> FileStatus {
    var result = CInterop.Stat()
    try path.withPlatformString { ptr in
      try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _fstatat(self.rawValue, ptr, &result, fcntrl.rawValue)
      }.get()
    }
    return FileStatus(rawValue: result)
  }
}

// MARK: - chmod

// [x] int chmod(const char *, mode_t)
// [x] int lchmod(const char *, mode_t)
// [x] int fchmod(int, mode_t)
// [x] int fchmodat(int, const char *, mode_t, int)
// [ ] int chmodx_np(const char *, filesec_t)
// [ ] int fchmodx_np(int, filesec_t)

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
    let _chmod = followSymlinks ? SystemPackage._chmod : _lchmod
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chmod(ptr, permissions.rawValue)
      }
    }
  }
}

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  internal func fchmod(permissions: FilePermissions, retryOnInterrupt: Bool = true) throws {
    try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      _fchmod(self.rawValue, permissions.rawValue)
    }.get()
  }

  // valid flags: AT_SYMLINK_NOFOLLOW | AT_REALDEV | AT_FDONLY
  internal func fchmodat(path: FilePath, permissions: FilePermissions, fcntrl: FileDescriptor.ControlFlags, retryOnInterrupt: Bool = true) throws {
    try path.withPlatformString { ptr in
      try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _fchmodat(self.rawValue, ptr, permissions.rawValue, fcntrl.rawValue)
      }.get()
    }
  }
}

// MARK: - chown

// [x] int chown(const char *, uid_t, gid_t)
// [x] int lchown(const char *, uid_t, gid_t)
// [x] int fchown(int, uid_t, gid_t)
// [x] int fchownat(int, const char *, uid_t, gid_t, int)

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FilePath {
  @_alwaysEmitIntoClient
  public func chown(
    userId: CInterop.UserId,
    groupId: CInterop.GroupId,
    followSymlinks: Bool = true,
    retryOnInterrupt: Bool = true
  ) throws {
    try _chown(
      userId: userId,
      groupId: groupId,
      followSymlinks: followSymlinks,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _chown(
    userId: CInterop.UserId,
    groupId: CInterop.GroupId,
    followSymlinks: Bool,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    let _chown = followSymlinks ? SystemPackage._chown : _lchown
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chown(ptr, userId, groupId)
      }
    }
  }
}

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  internal func fchown(userId: CInterop.UserId, groupId: CInterop.GroupId, retryOnInterrupt: Bool = true) throws {
    try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      _fchown(self.rawValue, userId, groupId)
    }.get()
  }

  internal func fchownat(path: FilePath, userId: CInterop.UserId, groupId: CInterop.GroupId, fcntrl: FileDescriptor.ControlFlags, retryOnInterrupt: Bool = true) throws {
    try path.withPlatformString { ptr in
      try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _fchownat(self.rawValue, ptr, userId, groupId, fcntrl.rawValue)
      }.get()
    }
  }
}

// MARK: - chflags

// [x] int chflags(const char *, __uint32_t)
// [x] int lchflags(const char *, __uint32_t)
// [x] int fchflags(int, __uint32_t)
// [x] int chflagsat(int, const char *, __uint32_t, int)

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
    let _chflags = followSymlinks ? SystemPackage._chflags : _lchflags
    return withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chflags(ptr, flags.rawValue)
      }
    }
  }
}

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  internal func fchflags(flags: FileFlags, retryOnInterrupt: Bool = true) throws {
    try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      _fchflags(self.rawValue, flags.rawValue)
    }.get()
  }

#if os(FreeBSD)
  internal func chflagsat(path: FilePath, flags: FileFlags, fcntrl: FileDescriptorControlFlags, retryOnInterrupt: Bool = true) throws {
    try path.withPlatformString { ptr in
      try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _chflagsat(self.rawValue, ptr, flags.rawValue, fcntrl.rawValue)
      }.get()
    }
  }
#endif
}

// MARK: - umask

// FIXME: document, shape
/// The umask() routine sets the process's file mode creation mask to cmask and
/// returns the previous value of the mask.  The 9 low-order access permission
/// bits of cmask are used by system calls, including open(2), mkdir(2),
/// mkfifo(2), and mknod(2) to turn off corresponding bits requested in file
/// mode.  (See chmod(2)).  This clearing allows each user to restrict the
/// default access to his files.
///
/// The default mask value is `S_IWGRP` | `S_IWOTH` (022, write access for the
/// owner only).  Child processes inherit the mask of the calling process.
@_alwaysEmitIntoClient
public func umask(newMask: FilePermissions) -> FilePermissions {
  let mode = _umask(newMask.rawValue)
  return FileMode(rawValue: mode).permissions
}

// [ ] mode_t umask(mode_t)

// MARK: - mkfifo, mknod, mkdir

// [x] int mkfifo(const char *, mode_t)
// [x] int mknod(const char *, mode_t, dev_t)
// [x] int mkdir(const char *, mode_t)
// [x] int mkdirat(int, const char *, mode_t)
// [ ] int mkfifox_np(const char *, filesec_t)
// [ ] int mkdirx_np(const char *, filesec_t)

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
        SystemPackage._mkfifo(ptr, permissions.rawValue)
      }
    }
  }

  @_alwaysEmitIntoClient
  public func mknod(
    permissions: FilePermissions,
    device: CInterop.DeviceId,
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
    device: CInterop.DeviceId,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    withPlatformString { ptr in
      nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        SystemPackage._mknod(ptr, permissions.rawValue, device)
      }
    }
  }

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
        SystemPackage._mkdir(ptr, permissions.rawValue)
      }
    }
  }
}

extension FileDescriptor {
  internal func mkdirat(path: FilePath, permissions: FilePermissions, retryOnInterrupt: Bool = true) throws {
    try path.withPlatformString { ptr in
      try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _mkdirat(self.rawValue, ptr, permissions.rawValue)
      }.get()
    }
  }
}

// MARK: - utimens

// [x] int futimens(int, const struct timespec[2])
// [x] int utimensat(int, const char *, const struct timespec[2], int)

// @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension FileDescriptor {
  @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  internal func futimens(accessTime: TimeSpecification, modificationTime: TimeSpecification, retryOnInterrupt: Bool = true) throws {
    let times = [accessTime.rawValue, modificationTime.rawValue]
    try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      _futimens(self.rawValue, times)
    }.get()
  }

  @available(macOS 12, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
  internal func utimensat(path: FilePath, accessTime: TimeSpecification, modificationTime: TimeSpecification, fcntrl: FileDescriptor.ControlFlags, retryOnInterrupt: Bool = true) throws {
    let times = [accessTime.rawValue, modificationTime.rawValue]
    try path.withPlatformString { ptr in
      try nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        _utimensat(self.rawValue, ptr, times, fcntrl.rawValue)
      }.get()
    }
  }
}

#endif
