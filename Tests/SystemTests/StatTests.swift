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
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif canImport(WASILibc)
import CSystem
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

@Suite("Stat")
private struct StatTests {

  @available(System 99, *)
  @Test func basics() async throws {
    try withTemporaryFilePath(basename: "Stat_basics") { tempDir in
      let dirStatFromFilePath = try tempDir.stat()
      #expect(dirStatFromFilePath.type == .directory)

      let dirFD = try FileDescriptor.open(tempDir, .readOnly)
      defer {
        try? dirFD.close()
      }
      let dirStatFromFD = try dirFD.stat()
      #expect(dirStatFromFD.type == .directory)

      let dirStatFromCString = try tempDir.withPlatformString { try Stat($0) }
      #expect(dirStatFromCString.type == .directory)

      #expect(dirStatFromFilePath == dirStatFromFD)
      #expect(dirStatFromFD == dirStatFromCString)

      let tempFile = tempDir.appending("test.txt")
      let fileFD = try FileDescriptor.open(tempFile, .readWrite, options: .create, permissions: [.ownerReadWrite, .groupRead, .otherRead])
      defer {
        try? fileFD.close()
      }
      try fileFD.writeAll("Hello, world!".utf8)

      let fileStatFromFD = try fileFD.stat()
      #expect(fileStatFromFD.type == .regular)
      #expect(fileStatFromFD.permissions == [.ownerReadWrite, .groupRead, .otherRead])
      #expect(fileStatFromFD.size == "Hello, world!".utf8.count)

      let fileStatFromFilePath = try tempFile.stat()
      #expect(fileStatFromFilePath.type == .regular)
      
      let fileStatFromCString = try tempFile.withPlatformString { try Stat($0) }
      #expect(fileStatFromCString.type == .regular)

      #expect(fileStatFromFD == fileStatFromFilePath)
      #expect(fileStatFromFilePath == fileStatFromCString)
    }
  }

  @available(System 99, *)
  @Test func followSymlinkInits() async throws {
    try withTemporaryFilePath(basename: "Stat_followSymlinkInits") { tempDir in
      let targetFilePath = tempDir.appending("target.txt")
      let symlinkPath = tempDir.appending("symlink")
      let targetFD = try FileDescriptor.open(targetFilePath, .readWrite, options: .create, permissions: .ownerReadWrite)
      defer {
        try? targetFD.close()
      }
      try targetFD.writeAll(Array(repeating: UInt8(ascii: "A"), count: 1025))

      try targetFilePath.withPlatformString { targetPtr in
        try symlinkPath.withPlatformString { symlinkPtr in
          try #require(symlink(targetPtr, symlinkPtr) == 0, "\(Errno.current)")
        }
      }

      // Can't open an fd to a symlink on WASI (no O_PATH)
      // On non-Darwin, we need O_PATH | O_NOFOLLOW to open the symlink
      // directly, but O_PATH requires _GNU_SOURCE be defined (TODO).
      #if SYSTEM_PACKAGE_DARWIN
      let symlinkFD = try FileDescriptor.open(symlinkPath, .readOnly, options: .symlink)
      defer {
        try? symlinkFD.close()
      }
      #endif

      let targetStat = try targetFilePath.stat()
      let originalTargetAccessTime = targetStat.st_atim

      let symlinkStat = try symlinkPath.stat(followTargetSymlink: false)
      let originalSymlinkAccessTime = symlinkStat.st_atim

      #expect(targetStat != symlinkStat)
      #expect(targetStat.type == .regular)
      #expect(symlinkStat.type == .symbolicLink)
      #expect(symlinkStat.size < targetStat.size)
      #if os(FreeBSD)
      #expect(symlinkStat.sizeAllocated <= targetStat.sizeAllocated)
      #else
      #expect(symlinkStat.sizeAllocated < targetStat.sizeAllocated)
      #endif

      // Set each .st_atim back to its original value for comparison

      // FileDescriptor Extensions

      var stat = try targetFD.stat()
      stat.st_atim = originalTargetAccessTime
      #expect(stat == targetStat)

      #if SYSTEM_PACKAGE_DARWIN
      stat = try symlinkFD.stat()
      stat.st_atim = originalSymlinkAccessTime
      #expect(stat == symlinkStat)
      #endif

      // Initializing Stat with FileDescriptor

      stat = try Stat(targetFD)
      stat.st_atim = originalTargetAccessTime
      #expect(stat == targetStat)

      #if SYSTEM_PACKAGE_DARWIN
      stat = try Stat(symlinkFD)
      stat.st_atim = originalSymlinkAccessTime
      #expect(stat == symlinkStat)
      #endif

      // FilePath Extensions

      stat = try symlinkPath.stat(followTargetSymlink: true)
      stat.st_atim = originalTargetAccessTime
      #expect(stat == targetStat)

      stat = try symlinkPath.stat(followTargetSymlink: false)
      stat.st_atim = originalSymlinkAccessTime
      #expect(stat == symlinkStat)

      // Initializing Stat with UnsafePointer<CChar>

      try symlinkPath.withPlatformString { pathPtr in
        stat = try Stat(pathPtr, followTargetSymlink: true)
        stat.st_atim = originalTargetAccessTime
        #expect(stat == targetStat)

        stat = try Stat(pathPtr, followTargetSymlink: false)
        stat.st_atim = originalSymlinkAccessTime
        #expect(stat == symlinkStat)
      }

      // Initializing Stat with FilePath

      stat = try Stat(symlinkPath, followTargetSymlink: true)
      stat.st_atim = originalTargetAccessTime
      #expect(stat == targetStat)

      stat = try Stat(symlinkPath, followTargetSymlink: false)
      stat.st_atim = originalSymlinkAccessTime
      #expect(stat == symlinkStat)

      // Initializing Stat with String

      stat = try Stat(symlinkPath.string, followTargetSymlink: true)
      stat.st_atim = originalTargetAccessTime
      #expect(stat == targetStat)

      stat = try Stat(symlinkPath.string, followTargetSymlink: false)
      stat.st_atim = originalSymlinkAccessTime
      #expect(stat == symlinkStat)
    }
  }

  @available(System 99, *)
  @Test func permissions() async throws {
    try withTemporaryFilePath(basename: "Stat_permissions") { tempDir in
      let testFile = tempDir.appending("test.txt")
      let fd = try FileDescriptor.open(testFile, .writeOnly, options: .create, permissions: [.ownerReadWrite, .groupRead, .otherRead])
      try fd.close()

      let stat = try testFile.stat()
      #expect(stat.type == .regular)
      #expect(stat.permissions == [.ownerReadWrite, .groupRead, .otherRead])

      var newMode = stat.mode
      newMode.permissions.insert(.ownerExecute)
      try testFile.withPlatformString { pathPtr in
        try #require(chmod(pathPtr, newMode.permissions.rawValue) == 0, "\(Errno.current)")
      }

      let updatedStat = try testFile.stat()
      #expect(updatedStat.permissions == newMode.permissions)

      newMode.permissions.remove(.ownerWriteExecute)
      try testFile.withPlatformString { pathPtr in
        try #require(chmod(pathPtr, newMode.permissions.rawValue) == 0, "\(Errno.current)")
      }

      let readOnlyStat = try testFile.stat()
      #expect(readOnlyStat.permissions == newMode.permissions)
    }
  }

  @available(System 99, *)
  @Test func times() async throws {
    var start = timespec()
    try #require(clock_gettime(CLOCK_REALTIME, &start) == 0, "\(Errno.current)")
    start.tv_sec -= 1 // A little wiggle room
    try withTemporaryFilePath(basename: "Stat_times") { tempDir in
      var dirStat = try tempDir.stat()
      let dirAccessTime0 = dirStat.st_atim
      let dirModificationTime0 = dirStat.st_mtim
      let dirChangeTime0 = dirStat.st_ctim
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      let dirCreationTime0 = dirStat.st_birthtim
      #endif

      var startUpperBound = start
      startUpperBound.tv_sec += 5
      #expect(dirAccessTime0 >= start)
      #expect(dirAccessTime0 < startUpperBound)
      #expect(dirModificationTime0 >= start)
      #expect(dirModificationTime0 < startUpperBound)
      #expect(dirChangeTime0 >= start)
      #expect(dirChangeTime0 < startUpperBound)
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      #expect(dirCreationTime0 >= start)
      #expect(dirCreationTime0 < startUpperBound)
      #endif

      // Fails intermittently if less than 5ms
      usleep(10000)

      let file1 = tempDir.appending("test1.txt")
      let fd1 = try FileDescriptor.open(file1, .writeOnly, options: .create, permissions: .ownerReadWrite)
      defer {
        try? fd1.close()
      }

      dirStat = try tempDir.stat()
      let dirAccessTime1 = dirStat.st_atim
      let dirModificationTime1 = dirStat.st_mtim
      let dirChangeTime1 = dirStat.st_ctim
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      let dirCreationTime1 = dirStat.st_birthtim
      #endif

      // Creating a file updates directory modification and change time.
      // Access time may not be updated depending on mount options like NOATIME.

      #expect(dirModificationTime1 > dirModificationTime0)
      #expect(dirChangeTime1 > dirChangeTime0)
      #expect(dirAccessTime1 >= dirAccessTime0)
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      #expect(dirCreationTime1 == dirCreationTime0)
      #endif

      usleep(10000)

      // Changing permissions only updates directory change time

      try tempDir.withPlatformString { pathPtr in
        var newMode = dirStat.mode
        // tempDir only starts with .ownerReadWriteExecute
        newMode.permissions.insert(.groupReadWriteExecute)
        try #require(chmod(pathPtr, newMode.rawValue) == 0, "\(Errno.current)")
      }

      dirStat = try tempDir.stat()
      let dirChangeTime2 = dirStat.st_ctim
      #expect(dirChangeTime2 > dirChangeTime1)
      #expect(dirStat.st_atim == dirAccessTime1)
      #expect(dirStat.st_mtim == dirModificationTime1)
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      #expect(dirStat.st_birthtim == dirCreationTime1)
      #endif

      var stat1 = try file1.stat()
      let file1AccessTime1 = stat1.st_atim
      let file1ModificationTime1 = stat1.st_mtim
      let file1ChangeTime1 = stat1.st_ctim
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      let file1CreationTime1 = stat1.st_birthtim
      #endif

      usleep(10000)

      try fd1.writeAll("Hello, world!".utf8)
      stat1 = try file1.stat()
      let file1AccessTime2 = stat1.st_atim
      let file1ModificationTime2 = stat1.st_mtim
      let file1ChangeTime2 = stat1.st_ctim
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      let file1CreationTime2 = stat1.st_birthtim
      #endif

      #expect(file1AccessTime2 >= file1AccessTime1)
      #expect(file1ModificationTime2 > file1ModificationTime1)
      #expect(file1ChangeTime2 > file1ChangeTime1)
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      #expect(file1CreationTime2 == file1CreationTime1)
      #endif

      // Changing file metadata or content does not update directory times

      dirStat = try tempDir.stat()
      #expect(dirStat.st_ctim == dirChangeTime2)
      #expect(dirStat.st_atim == dirAccessTime1)
      #expect(dirStat.st_mtim == dirModificationTime1)
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      #expect(dirStat.st_birthtim == dirCreationTime1)
      #endif

      usleep(10000)

      let file2 = tempDir.appending("test2.txt")
      let fd2 = try FileDescriptor.open(file2, .writeOnly, options: .create, permissions: .ownerReadWrite)
      defer {
        try? fd2.close()
      }

      let stat2 = try file2.stat()
      #expect(stat2.st_atim > file1AccessTime2)
      #expect(stat2.st_mtim > file1ModificationTime2)
      #expect(stat2.st_ctim > file1ChangeTime2)
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
      #expect(stat2.st_birthtim > file1CreationTime2)
      #endif
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  @available(System 99, *)
  @Test func flags() async throws {
    try withTemporaryFilePath(basename: "Stat_flags") { tempDir in
      let filePath = tempDir.appending("test.txt")
      let fd = try FileDescriptor.open(filePath, .writeOnly, options: .create, permissions: .ownerReadWrite)
      defer {
        try? fd.close()
      }
      var stat = try fd.stat()
      var flags = stat.flags

      #if SYSTEM_PACKAGE_DARWIN
      let userSettableFlags: FileFlags = [
        .noDump, .userImmutable, .userAppend,
        .opaque, .tracked, .hidden,
        /* .dataVault (throws EPERM when testing) */
      ]
      #elseif os(FreeBSD)
      let userSettableFlags: FileFlags = [
        .noDump, .hidden, .offline,
        .readOnly, .sparse, .system
        // The following flags throw EPERM on ZFS.
        // .userImmutable, .userAppend, .opaque,
        // .userNoUnlink, .reparse,
      ]
      #else // os(OpenBSD)
      let userSettableFlags: FileFlags = [
        .noDump, .userImmutable, .userAppend
      ]
      #endif

      flags.insert(userSettableFlags)
      try #require(fchflags(fd.rawValue, UInt(flags.rawValue)) == 0, "\(Errno.current)")

      stat = try fd.stat()
      #expect(stat.flags == flags)

      flags.remove(userSettableFlags)
      try #require(fchflags(fd.rawValue, UInt(flags.rawValue)) == 0, "\(Errno.current)")

      stat = try fd.stat()
      #expect(stat.flags == flags)
    }
  }
  #endif

}

// Comparison operators for timespec until UTCClock.Instant properties are available
private func >= (lhs: timespec, rhs: timespec) -> Bool {
  (lhs.tv_sec, lhs.tv_nsec) >= (rhs.tv_sec, rhs.tv_nsec)
}

private func < (lhs: timespec, rhs: timespec) -> Bool {
  (lhs.tv_sec, lhs.tv_nsec) < (rhs.tv_sec, rhs.tv_nsec)
}

private func > (lhs: timespec, rhs: timespec) -> Bool {
  (lhs.tv_sec, lhs.tv_nsec) > (rhs.tv_sec, rhs.tv_nsec)
}

private func == (lhs: timespec, rhs: timespec) -> Bool {
  lhs.tv_sec == rhs.tv_sec && lhs.tv_nsec == rhs.tv_nsec
}

#endif
