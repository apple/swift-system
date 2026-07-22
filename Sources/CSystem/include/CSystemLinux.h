/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#ifdef __linux__

#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <sys/socket.h>
#include <sys/sysinfo.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <errno.h>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>
#include "io_uring.h"

// The `ST_*` mount-flag constants in <sys/statvfs.h> require _GNU_SOURCE.
// Rather than define _GNU_SOURCE module-wide, which clashes with SwiftGlibc,
// expose them through these getters, defined in shims.c under _GNU_SOURCE.
#include <stdint.h>
uint64_t _system_get_ST_RDONLY(void);
uint64_t _system_get_ST_NOSUID(void);
uint64_t _system_get_ST_NODEV(void);
uint64_t _system_get_ST_NOEXEC(void);
uint64_t _system_get_ST_SYNCHRONOUS(void);
uint64_t _system_get_ST_MANDLOCK(void);
uint64_t _system_get_ST_NOATIME(void);
uint64_t _system_get_ST_NODIRATIME(void);
uint64_t _system_get_ST_RELATIME(void);
uint64_t _system_get_ST_NOSYMFOLLOW(void);
#if !defined(__ANDROID__)
uint64_t _system_get_ST_WRITE(void);
uint64_t _system_get_ST_APPEND(void);
uint64_t _system_get_ST_IMMUTABLE(void);
#endif
#endif

