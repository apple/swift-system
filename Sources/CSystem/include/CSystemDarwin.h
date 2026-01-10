/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if defined(__APPLE__)

#include <sys/ioctl.h>
#include <termios.h>

// Terminal ioctl shims
int _system_ioctl_TIOCGWINSZ(int fd, struct winsize *ws);
int _system_ioctl_TIOCSWINSZ(int fd, const struct winsize *ws);

#endif
