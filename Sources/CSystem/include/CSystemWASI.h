/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#pragma once

#if __wasi__

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h> // For NAME_MAX

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

static inline uint8_t _getConst_DT_DIR(void) { return DT_DIR; }

// Modified dirent struct that can be imported to Swift
struct _system_dirent {
  ino_t d_ino;
  unsigned char d_type;
  // char d_name[] cannot be imported to Swift
  char d_name[NAME_MAX + 1];
};

// Convert WASI dirent with d_name[] to _system_dirent
static inline
struct _system_dirent *
_system_dirent_from_wasi_dirent(const struct dirent *wasi_dirent) {

  // Match readdir behavior and use thread-local storage for the converted dirent
  static __thread struct _system_dirent _converted_dirent;

  if (wasi_dirent == NULL) {
    return NULL;
  }

  memset(&_converted_dirent, 0, sizeof(struct _system_dirent));

  _converted_dirent.d_ino = wasi_dirent->d_ino;
  _converted_dirent.d_type = wasi_dirent->d_type;

  strncpy(_converted_dirent.d_name, wasi_dirent->d_name, NAME_MAX);
  _converted_dirent.d_name[NAME_MAX] = '\0';

  return &_converted_dirent;
}

#endif
