/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if defined(__FreeBSD__)
#define __BSD_VISIBLE
#endif
#if defined(__FreeBSD__) || defined(__OpenBSD__)
#include <unistd.h>
#endif

#if defined(__FreeBSD__)
#include <CSystemFreeBSD.h>
#endif

#ifdef __linux__

// The `ST_*` mount-flag constants in <sys/statvfs.h> require _GNU_SOURCE.
// Define it here, in a dedicated translation unit, not in CSystemLinux.h,
// since defining it there changes libc types like `fd_set` for every file
// that imports CSystem and conflicts with SwiftGlibc.
#define _GNU_SOURCE
#include <sys/statvfs.h>
#include <stdint.h>

uint64_t _system_get_ST_RDONLY(void) { return ST_RDONLY; }
uint64_t _system_get_ST_NOSUID(void) { return ST_NOSUID; }
uint64_t _system_get_ST_NODEV(void) { return ST_NODEV; }
uint64_t _system_get_ST_NOEXEC(void) { return ST_NOEXEC; }
uint64_t _system_get_ST_SYNCHRONOUS(void) { return ST_SYNCHRONOUS; }
uint64_t _system_get_ST_MANDLOCK(void) { return ST_MANDLOCK; }
uint64_t _system_get_ST_NOATIME(void) { return ST_NOATIME; }
uint64_t _system_get_ST_NODIRATIME(void) { return ST_NODIRATIME; }
uint64_t _system_get_ST_RELATIME(void) { return ST_RELATIME; }

// ST_NOSYMFOLLOW was added to glibc's <sys/statvfs.h> in Linux 5.10. For
// older versions, fall back to the fixed kernel UAPI bit (<linux/statfs.h>),
// which is the same value a newer glibc header defines.
#ifndef ST_NOSYMFOLLOW
#define ST_NOSYMFOLLOW 0x2000
#endif
uint64_t _system_get_ST_NOSYMFOLLOW(void) { return ST_NOSYMFOLLOW; }

#if !defined(__ANDROID__)
uint64_t _system_get_ST_WRITE(void) { return ST_WRITE; }
uint64_t _system_get_ST_APPEND(void) { return ST_APPEND; }
uint64_t _system_get_ST_IMMUTABLE(void) { return ST_IMMUTABLE; }
#endif

#include <CSystemLinux.h>
#endif

#if defined(_WIN32)
#include <CSystemWindows.h>
#endif

#include <errno.h>

#if !defined(_WIN32) && !defined(__wasi__) && !defined(__APPLE__)
#define HAVE_PIPE2_DUP3
#endif

// Wrappers are required because _GNU_SOURCE causes a conflict with other imports when defined in CSystemLinux.h

#if !defined(_WIN32)
extern int csystem_posix_pipe2(int fildes[2], int flag) {
    #ifdef HAVE_PIPE2_DUP3
    return pipe2(fildes, flag);
    #else
    errno = ENOSYS;
    return -1;
    #endif
}
#endif // !defined(_WIN32)

extern int csystem_posix_dup3(int fildes, int fildes2, int flag) {
    #ifdef HAVE_PIPE2_DUP3
    return dup3(fildes, fildes2, flag);
    #else
    errno = ENOSYS;
    return -1;
    #endif
}
