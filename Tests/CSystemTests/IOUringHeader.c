/*
 * This source file is part of the Swift System open source project
 * Copyright (c) 2026 Apple Inc. and the Swift System project authors
 * Licensed under Apache License v2.0 with Runtime Library Exception
 * See https://swift.org/LICENSE.txt for license information
 */

#if defined(INCLUDE_SYSTEM_FIRST) && __has_include(<linux/io_uring.h>)
#include <linux/io_uring.h>
#endif
#include "io_uring.h"
#include "io_uring.h"
#if defined(INCLUDE_SYSTEM_LAST) && __has_include(<linux/io_uring.h>)
#include <linux/io_uring.h>
#endif

_Static_assert(SWIFT_IORING_ENTER_EXT_ARG == (1U << 3), "extended argument flag");
_Static_assert(sizeof(struct swift_io_uring_sqe) == 64, "SQE size");
_Static_assert(sizeof(struct swift_io_uring_cqe) == 16, "CQE size");
_Static_assert(sizeof(struct swift_io_uring_params) == 120, "setup parameters size");
_Static_assert(sizeof(struct swift_io_uring_getevents_arg) == 24, "extended argument size");
_Static_assert(__builtin_offsetof(struct swift_io_uring_sqe, file_index) == 44, "direct descriptor offset");
_Static_assert(__builtin_offsetof(struct swift_io_uring_getevents_arg, ts) == 16, "timeout offset");
_Static_assert(_Alignof(struct swift_io_uring_files_update) == 8, "aligned UAPI addresses");

#ifdef EXPECT_SUPPORTED
_Static_assert(__SWIFT_IORING_SUPPORTED == EXPECT_SUPPORTED, "header support gate");
#elif defined(IORING_TIMEOUT_BOOTTIME)
_Static_assert(__SWIFT_IORING_SUPPORTED == 1, "supported system headers");
#else
_Static_assert(__SWIFT_IORING_SUPPORTED == 0, "unsupported system headers");
#endif
