/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if !defined(_WIN32)
extern int csystem_posix_pipe2(int fildes[2], int flag);
#endif

extern int csystem_posix_dup3(int fildes, int fildes2, int flag);

#include <stddef.h>

// Thread-safe replacement for strerror(3).
//
// Writes the message for `errnum` into `buf`, which holds `buflen` bytes, and
// always NUL-terminates it if `buflen` is not zero. Returns 0 on success, or an
// error number (e.g. EINVAL for an unknown `errnum`, ERANGE if the message was
// truncated). A message that exactly fills the buffer is also reported as
// ERANGE, because not every C library can tell that apart from truncation.
// Even on failure, `buf` may contain a message such as "Unknown error 1234".
//
// This hides the differences between the XSI and GNU variants of strerror_r,
// and uses strerror_s on Windows.
extern int csystem_strerror_r(int errnum, char *buf, size_t buflen);
