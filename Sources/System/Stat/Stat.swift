/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - stat
// int stat(const char *, struct stat *)
// int lstat(const char *, struct stat *)
// FilePath.fileStatus(followSymlinks:) throws Errno -> FileStatus

// int fstatat(int, const char *, struct stat *, int)
// FilePath.fileStatus(relativeTo:controlFlags:) throws Errno -> FileStatus

// int fstat(int, struct stat *)
// FileDescriptor.fileStatus() throws Errno -> FileStatus


// MARK: - chmod
// int chmod(const char *, mode_t)
// int lchmod(const char *, mode_t)
// FilePath.changeFileMode(to:followSymlinks) throws Errno -> Void

// int fchmodat(int, const char *, mode_t, int)
// FilePath.changeFileMode(to:relativeTo:controlFlags:) throws Errno -> Void

// int fchmod(int, mode_t)
// FileDescriptor.changeFileMode(to:) throws Errno -> Void


// MARK: - chown
// int chown(const char *, uid_t, gid_t)
// int lchown(const char *, uid_t, gid_t)
// FilePath.changeFileOwner(to:followSymlinks:) throws Errno -> Void

// int fchownat(int, const char *, uid_t, gid_t, int)
// FilePath.changeFileOwner(to:relativeTo:controlFlags:) throws Errno -> Void

// int fchown(int, uid_t, gid_t)
// FileDescriptor.changeFileOwner(to:) throws Errno -> Void


// MARK: - chflags
// int chflags(const char *, uint32_t)
// int lchflags(const char *, uint32_t)
// FilePath.changeFileFlags(to:followSymlinks:) throws Errno -> Void

// int chflagsat(int, const char *, uint32_t, int) (FreeBSD)
// FilePath.changeFileFlags(to:relativeTo:controlFlags:) throws Errno -> Void

// int fchflags(int, uint32_t)
// FileDescriptor.changeFileFlags(to:) throws Errno -> Void


// MARK: - umask
// mode_t umask(mode_t)
// FileMode.updateProcessMask() -> FileMode


// MARK: - mkfifo
// int mkfifo(const char *, mode_t)
// FilePath.makeFIFO(withMode:) throws Errno -> Void

// int mkfifoat(int, const char *, mode_t)
// FilePath.makeFIFO(withMode:relativeTo:) throws Errno -> Void


// MARK: - mknod
// int mknod(const char *, mode_t, dev_t)
// FilePath.makeNode(withMode:andDeviceID:) throws Errno -> Void

// int mknodat(int, const char *, mode_t, dev_t)
// FilePath.makeNode(withMode:andDeviceID:relativeTo:) throws Errno -> Void


// MARK: - mkdir
// int mkdir(const char *, mode_t)
// FilePath.makeDirectory(withMode:) throws Errno -> Void

// int mkdirat(int, const char *, mode_t)
// FilePath.makeDirectory(withMode:relativeTo:) throws Errno -> Void


// MARK: - utimens
// int utimens(const char *, const struct timespec[2])
// int lutimens(const char *, const struct timespec[2])
// FilePath.changeFileTimes(to:followSymlinks:) throws Errno -> Void

// int utimensat(int, const char *, const struct timespec[2], int)
// FilePath.changeFileTimes(to:relativeTo:controlFlags:) throws Errno -> Void

// int futimens(int, const struct timespec[2])
// FileDescriptor.changeFileTimes(to:) throws Errno -> Void
