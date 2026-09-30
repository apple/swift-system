/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#pragma once

// Unlike the Musl and Android modules, Glibc doesn't export <sys/vfs.h>,
// which declares `struct statfs` and `statfs()`/`fstatfs()`. SystemPackage
// re-exports this module on glibc platforms so that clients can use the
// raw `CInterop.StatFS` value under MemberImportVisibility.
#if defined(__linux__) && !defined(__ANDROID__)
#include <sys/vfs.h>
#endif
