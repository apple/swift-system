/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#pragma once

#if __wasi__

#include <errno.h>
#include <fcntl.h>

// wasi-libc defines the following constants in a way that Clang Importer can't
// understand, so we need to expose them manually.
static inline int32_t _getConst_O_ACCMODE(void) { return O_ACCMODE; }
static inline int32_t _getConst_O_APPEND(void) { return O_APPEND; }
static inline int32_t _getConst_O_CREAT(void) { return O_CREAT; }
static inline int32_t _getConst_O_DIRECTORY(void) { return O_DIRECTORY; }
static inline int32_t _getConst_O_EXCL(void) { return O_EXCL; }
static inline int32_t _getConst_O_NONBLOCK(void) { return O_NONBLOCK; }
static inline int32_t _getConst_O_TRUNC(void) { return O_TRUNC; }
static inline int32_t _getConst_O_WRONLY(void) { return O_WRONLY; }

static inline int32_t _getConst_EWOULDBLOCK(void) { return EWOULDBLOCK; }
static inline int32_t _getConst_EOPNOTSUPP(void) { return EOPNOTSUPP; }

#endif
