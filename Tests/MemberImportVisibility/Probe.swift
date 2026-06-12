/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Compile-only canary for MemberImportVisibility regressions: this file fails
// to build if a C member of a type SystemPackage vends is attributed to the
// private CSystem module.
//
// For new type wrappers introduced to System, access their C members here:
//  - Import the platform overlay (Glibc/Musl), as consumers do.
//  - Access raw C members of vended types (e.g. CInterop.Stat) as a downstream
//    consumer would. Don't go through the Swift (e.g. Stat) wrapper since its
//    accesses happen inside System, where importing CSystem is fine.
//  - Touch every direct member the public API exposes. One field is not always
//    a safe proxy for the rest.

#if canImport(Glibc) || canImport(Musl)
#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
import SystemPackage

func _mivProbe(_ s: CInterop.Stat) {
  _ = s.st_dev
  _ = s.st_ino
  _ = s.st_mode
  _ = s.st_nlink
  _ = s.st_uid
  _ = s.st_gid
  _ = s.st_rdev
  _ = s.st_size
  _ = s.st_blksize
  _ = s.st_blocks
  _ = s.st_atim
  _ = s.st_mtim
  _ = s.st_ctim
}
#endif
