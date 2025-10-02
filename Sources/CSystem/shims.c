/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if defined(__FreeBSD__) || defined(__OpenBSD__)
#define __BSD_VISIBLE
#include <unistd.h>
#endif

#ifdef __linux__
#define _GNU_SOURCE
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
extern int csystem_posix_pipe2(int fildes[2], int flag) {
    #ifdef HAVE_PIPE2_DUP3
    return pipe2(fildes, flag);
    #else
    errno = ENOSYS;
    return -1;
    #endif
}
extern int csystem_posix_dup3(int fildes, int fildes2, int flag) {
    #ifdef HAVE_PIPE2_DUP3
    return dup3(fildes, fildes2, flag);
    #else
    errno = ENOSYS;
    return -1;
    #endif
}
