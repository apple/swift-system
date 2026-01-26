/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#ifdef __linux__

#include <CSystemLinux.h>

// Terminal ioctl shims for Linux
int _system_ioctl_TIOCGWINSZ(int fd, struct winsize *ws) {
  return ioctl(fd, TIOCGWINSZ, ws);
}

int _system_ioctl_TIOCSWINSZ(int fd, const struct winsize *ws) {
  return ioctl(fd, TIOCSWINSZ, ws);
}

#endif

#if defined(__APPLE__)

#include <CSystemDarwin.h>

// Terminal ioctl shims for Darwin
int _system_ioctl_TIOCGWINSZ(int fd, struct winsize *ws) {
  return ioctl(fd, TIOCGWINSZ, ws);
}

int _system_ioctl_TIOCSWINSZ(int fd, const struct winsize *ws) {
  return ioctl(fd, TIOCSWINSZ, ws);
}

#endif

#if defined(_WIN32)
#include <CSystemWindows.h>
#endif
