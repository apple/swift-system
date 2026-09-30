/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#ifdef __linux__

// Glibc doesn't export eventfd, which the tests use.
#include <sys/eventfd.h>

#if !defined(__ANDROID__)
#include <stddef.h>
#include "io_uring.h"

// Defined in shims.c, which can include the libc headers they need.
extern int csystem_io_uring_setup(unsigned int entries,
                                  struct io_uring_params *p);
extern int csystem_io_uring_enter(int fd, unsigned int to_submit,
                                  unsigned int min_complete,
                                  unsigned int flags, void *sig);
extern int csystem_io_uring_enter2(int fd, unsigned int to_submit,
                                   unsigned int min_complete,
                                   unsigned int flags, void *args, size_t sz);
extern int csystem_io_uring_register(int fd, unsigned int opcode, void *arg,
                                     unsigned int nr_args);
#endif // !defined(__ANDROID__)

#endif // __linux__
