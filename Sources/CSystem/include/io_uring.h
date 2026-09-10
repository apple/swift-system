/*
 * This source file is part of the Swift System open source project
 * Copyright (c) 2026 Apple Inc. and the Swift System project authors
 * Licensed under Apache License v2.0 with Runtime Library Exception
 * See https://swift.org/LICENSE.txt for license information
 */

#ifndef SWIFT_IORING_C_WRAPPER
#define SWIFT_IORING_C_WRAPPER

#include <unistd.h>
#include <sys/syscall.h>
#include <sys/uio.h>
#include <signal.h>

// Preserve the existing support policy independently of the vendored types.
// Builds with headers older than Linux 5.15, or without linux/io_uring.h,
// still throw ENOTSUP when an IORing is initialized.
#if __has_include(<linux/io_uring.h>)
#include <linux/io_uring.h>
#endif
#if __has_include(<linux/io_uring.h>) && defined(IORING_TIMEOUT_BOOTTIME)
#define __SWIFT_IORING_SUPPORTED 1
#else
#define __SWIFT_IORING_SUPPORTED 0
#endif

// Use a consistent UAPI layout even when the system headers are older or absent.
// The vendored identifiers are prefixed so both headers can coexist.
#include "liburing/io_uring.h"
typedef struct swift_io_uring_sqe swift_io_uring_sqe;

# ifndef __NR_io_uring_setup
#  define __NR_io_uring_setup		425
# endif
# ifndef __NR_io_uring_enter
#  define __NR_io_uring_enter		426
# endif
# ifndef __NR_io_uring_register
#  define __NR_io_uring_register	427
# endif

static inline int io_uring_register(int fd, unsigned int opcode, void *arg,
		      unsigned int nr_args)
{
	return syscall(__NR_io_uring_register, fd, opcode, arg, nr_args);
}

static inline int io_uring_setup(unsigned int entries, struct swift_io_uring_params *p)
{
	return syscall(__NR_io_uring_setup, entries, p);
}

static inline int io_uring_enter2(int fd, unsigned int to_submit, unsigned int min_complete,
		   unsigned int flags, void *args, size_t sz)
{
	return syscall(__NR_io_uring_enter, fd, to_submit, min_complete,
			flags, args, sz);
}

static inline int io_uring_enter(int fd, unsigned int to_submit, unsigned int min_complete,
		   unsigned int flags, sigset_t *sig)
{
	return io_uring_enter2(fd, to_submit, min_complete, flags, sig, _NSIG / 8);
}

#endif
