/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if defined(__APPLE__)

#include <fcntl.h>

#ifdef O_CLOFORK
#define COMPATIBILITY_O_CLOFORK O_CLOFORK
#else
#define COMPATIBILITY_O_CLOFORK 0
#endif

#endif // defined(__APPLE__)
