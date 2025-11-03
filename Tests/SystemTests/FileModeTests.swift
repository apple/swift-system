//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !os(Windows)

import Testing

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

@Suite("FileMode")
private struct FileModeTests {

  @available(System 99, *)
  @Test func basics() async throws {
    var mode = FileMode(rawValue: S_IFREG | 0o644) // Regular file, rw-r--r--
    #expect(mode.type == .regular)
    #expect(mode.permissions == [.ownerReadWrite, .groupRead, .otherRead])

    mode.type = .directory // Directory, rw-r--r--
    #expect(mode.type == .directory)
    #expect(mode.permissions == [.ownerReadWrite, .groupRead, .otherRead])

    mode.permissions.insert([.ownerExecute, .groupExecute, .otherExecute]) // Directory, rwxr-xr-x
    #expect(mode.type == .directory)
    #expect(mode.permissions == [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute])

    mode.type = .symbolicLink // Symbolic link, rwxr-xr-x
    #expect(mode.type == .symbolicLink)
    #expect(mode.permissions == [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute])

    let mode1 = FileMode(rawValue: S_IFLNK | 0o755) // Symbolic link, rwxr-xr-x
    let mode2 = FileMode(type: .symbolicLink, permissions: [.ownerReadWriteExecute, .groupReadExecute, .otherReadExecute])
    #expect(mode == mode1)
    #expect(mode1 == mode2)

    mode.permissions.remove([.otherReadExecute]) // Symbolic link, rwxr-x---
    #expect(mode.permissions == [.ownerReadWriteExecute, .groupReadExecute])
    #expect(mode != mode1)
    #expect(mode != mode2)
    #expect(mode.type == mode1.type)
    #expect(mode.type == mode2.type)
  }

  @available(System 99, *)
  @Test func invalidInput() async throws {
    // No permissions, all other bits set
    var invalidMode = FileMode(rawValue: ~0o7777)
    #expect(invalidMode.permissions.isEmpty)
    #expect(invalidMode.type != .directory)
    #expect(invalidMode.type != .characterSpecial)
    #expect(invalidMode.type != .blockSpecial)
    #expect(invalidMode.type != .regular)
    #expect(invalidMode.type != .fifo)
    #expect(invalidMode.type != .symbolicLink)
    #expect(invalidMode.type != .socket)
    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    #expect(invalidMode.type != .whiteout)
    #endif

    // All file-type bits set
    invalidMode = FileMode(rawValue: S_IFMT)
    #expect(invalidMode.type != .directory)
    #expect(invalidMode.type != .characterSpecial)
    #expect(invalidMode.type != .blockSpecial)
    #expect(invalidMode.type != .regular)
    #expect(invalidMode.type != .fifo)
    #expect(invalidMode.type != .symbolicLink)
    #expect(invalidMode.type != .socket)
    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    #expect(invalidMode.type != .whiteout)
    #endif

    // FileMode(type:permissions:) masks its inputs so
    // they don't accidentally modify the other bits.
    let emptyPermissions = FileMode(type: FileType(rawValue: ~0), permissions: [])
    #expect(emptyPermissions.permissions.isEmpty)
    #expect(emptyPermissions.type == FileType(rawValue: S_IFMT))
    #expect(emptyPermissions == invalidMode)

    let regularFile = FileMode(type: .regular, permissions: FilePermissions(rawValue: ~0))
    #expect(regularFile.type == .regular)
    #expect(regularFile.permissions == FilePermissions(rawValue: 0o7777))
    #expect(regularFile.permissions == [
      .ownerReadWriteExecute,
      .groupReadWriteExecute,
      .otherReadWriteExecute,
      .setUserID, .setGroupID, .saveText
    ])

    // Setting properties should not modify the other bits, either.
    var mode = FileMode(rawValue: 0)
    mode.type = FileType(rawValue: ~0)
    #expect(mode.type == FileType(rawValue: S_IFMT))
    #expect(mode.permissions.isEmpty)

    mode.type.rawValue = 0
    #expect(mode.type == FileType(rawValue: 0))
    #expect(mode.permissions.isEmpty)

    mode.permissions = FilePermissions(rawValue: ~0)
    #expect(mode.permissions == FilePermissions(rawValue: 0o7777))
    #expect(mode.type == FileType(rawValue: 0))

    mode.permissions = []
    #expect(mode.permissions.isEmpty)
    #expect(mode.type == FileType(rawValue: 0))
  }

}
#endif
