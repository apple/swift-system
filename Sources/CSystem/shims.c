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
#define _GNU_SOURCE
#include <signal.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <CSystemLinux.h>
#endif

#include <errno.h>

#if !defined(_WIN32) && !defined(__wasi__) && !defined(__APPLE__)
#define HAVE_PIPE2_DUP3
#endif

#if defined(__APPLE__)
#include <Availability.h>
#if defined(__MAC_27_0)
#include <unistd.h>
#define HAVE_PIPE2_DUP3
#endif
#endif // defined(__APPLE__)

// Wrappers are required because _GNU_SOURCE causes a conflict with other imports when defined in CSystemLinux.h

#if !defined(_WIN32)
extern int csystem_posix_pipe2(int fildes[2], int flag) {
  #if defined(__APPLE__) && defined(HAVE_PIPE2_DUP3)
  if (__builtin_available(macOS 27, iOS 27, tvOS 27, watchOS 27, visionOS 27, *))
    return pipe2(fildes, flag);
  __builtin_trap();
  #elif defined(HAVE_PIPE2_DUP3)
  return pipe2(fildes, flag);
  #else
  errno = ENOSYS;
  return -1;
  #endif
}
#endif // !defined(_WIN32)

extern int csystem_posix_dup3(int fildes, int fildes2, int flag) {
  #if defined(__APPLE__) && defined(HAVE_PIPE2_DUP3)
  if (__builtin_available(macOS 27, iOS 27, tvOS 27, watchOS 27, visionOS 27, *))
    return dup3(fildes, fildes2, flag);
  __builtin_trap();
  #elif defined(HAVE_PIPE2_DUP3)
  return dup3(fildes, fildes2, flag);
  #else
  errno = ENOSYS;
  return -1;
  #endif
}

#if defined(__linux__) && !defined(__ANDROID__)
# ifndef __NR_io_uring_setup
#  define __NR_io_uring_setup		425
# endif
# ifndef __NR_io_uring_enter
#  define __NR_io_uring_enter		426
# endif
# ifndef __NR_io_uring_register
#  define __NR_io_uring_register	427
# endif

extern int csystem_io_uring_setup(unsigned int entries,
                                  struct io_uring_params *p) {
  return syscall(__NR_io_uring_setup, entries, p);
}

extern int csystem_io_uring_enter2(int fd, unsigned int to_submit,
                                   unsigned int min_complete,
                                   unsigned int flags, void *args, size_t sz) {
  return syscall(__NR_io_uring_enter, fd, to_submit, min_complete, flags,
                 args, sz);
}

extern int csystem_io_uring_enter(int fd, unsigned int to_submit,
                                  unsigned int min_complete,
                                  unsigned int flags, void *sig) {
  return csystem_io_uring_enter2(fd, to_submit, min_complete, flags, sig,
                                 _NSIG / 8);
}

extern int csystem_io_uring_register(int fd, unsigned int opcode, void *arg,
                                     unsigned int nr_args) {
  return syscall(__NR_io_uring_register, fd, opcode, arg, nr_args);
}
#endif // defined(__linux__) && !defined(__ANDROID__)
