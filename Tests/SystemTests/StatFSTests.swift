//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !os(Windows)

import Testing

#if canImport(Foundation)
import Foundation
#endif

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

@Suite("StatFS")
private struct StatFSTests {

  // On WASI, statvfs/fstatvfs are unconditional stubs that set ENOSYS and
  // return -1, so every StatFS initializer throws Errno.noFunction. Skip the
  // behavioral tests there.
  #if !os(WASI)

  @available(System 199, *)
  @Test func initializersAgree() async throws {
    try withTemporaryFilePath(basename: "StatFS_initializersAgree") { tempDir in
      let fromFilePath = try StatFS(tempDir)
      let fromCString = try tempDir.withPlatformString { try StatFS($0) }
      let fromFilePathExt = try tempDir.statfs()

      let dirFD = try FileDescriptor.open(tempDir, .readOnly)
      defer { try? dirFD.close() }
      let fromFD = try StatFS(dirFD)
      let fromFDExt = try dirFD.statfs()

      // All construction paths describe the same file system.
      #expect(fromFilePath.fileSystemID == fromCString.fileSystemID)
      #expect(fromFilePath.fileSystemID == fromFilePathExt.fileSystemID)
      #expect(fromFilePath.fileSystemID == fromFD.fileSystemID)
      #expect(fromFilePath.fileSystemID == fromFDExt.fileSystemID)

      #expect(fromFilePath.blockSize == fromFD.blockSize)
      #expect(fromFilePath.totalBlocks == fromFD.totalBlocks)
      #expect(fromFilePath.mountFlags == fromFD.mountFlags)
    }
  }

  @available(System 199, *)
  @Test func spaceAndBlocks() async throws {
    try withTemporaryFilePath(basename: "StatFS_spaceAndBlocks") { tempDir in
      let statfs = try StatFS(tempDir)

      #expect(statfs.blockSize > 0)
      #expect(statfs.totalBlocks > 0)

      // Free space cannot exceed the total, and available (non-superuser)
      // cannot exceed the total free.
      #expect(statfs.freeBlocks <= statfs.totalBlocks)
      #expect(statfs.availableBlocks <= statfs.freeBlocks)

      // Computed sizes are the block count times the block-count unit.
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      let unit = UInt64(statfs.blockSize)
      #else
      let unit = UInt64(statfs.fragmentSize)
      #endif
      #expect(statfs.totalSpace == statfs.totalBlocks * unit)
      #expect(statfs.freeSpace == statfs.freeBlocks * unit)
      #expect(statfs.availableSpace == statfs.availableBlocks * unit)

      #expect(statfs.totalSpace >= statfs.freeSpace)
      #expect(statfs.freeSpace >= statfs.availableSpace)
    }
  }

  @available(System 199, *)
  @Test func spaceSaturatesOnOverflow() async throws {
    try withTemporaryFilePath(basename: "StatFS_saturates") { tempDir in
      var statfs = try StatFS(tempDir)
      statfs.totalBlocks = .max
      #expect(statfs.blockSize > 1)
      // Max blocks times a >1 unit overflows UInt64 and must saturate.
      #expect(statfs.totalSpace == .max)
    }
  }

  @available(System 199, *)
  @Test func inodes() async throws {
    try withTemporaryFilePath(basename: "StatFS_inodes") { tempDir in
      let statfs = try StatFS(tempDir)
      // totalInodes can legitimately be 0 on file systems with dynamic inode
      // allocation, so only assert the ordering when it is nonzero.
      #expect(statfs.freeInodes <= statfs.totalInodes || statfs.totalInodes == 0)
      #if !SYSTEM_PACKAGE_DARWIN && !os(FreeBSD)
      #expect(statfs.availableInodes <= statfs.freeInodes)
      #endif
    }
  }

  @available(System 199, *)
  @Test func readOnlyFlagReflectsWritableFileSystem() async throws {
    try withTemporaryFilePath(basename: "StatFS_readOnly") { tempDir in
      let statfs = try StatFS(tempDir)

      // Create and write a file in the temp dir. If this succeeds,
      // the file system is not read-only...
      let probe = tempDir.appending("probe")
      let fd = try FileDescriptor.open(
        probe, .readWrite, options: .create, permissions: .ownerReadWrite)
      defer { try? fd.close() }
      try fd.writeAll("probe".utf8)

      // ...so the read-only mount flag must be clear.
      #expect(!statfs.mountFlags.contains(.readOnly))
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  @available(System 199, *)
  @Test func darwinAndBSDFields() async throws {
    try withTemporaryFilePath(basename: "StatFS_darwinBSD") { tempDir in
      let statfs = try StatFS(tempDir)
      #expect(statfs.preferredIOBlockSize > 0)

      // `typeName` is a non-empty, readable file system name.
      #expect(!statfs.typeName.isEmpty)

      // `mountPoint` is some absolute path, and `mountSource` is a non-empty
      // device path. Note that on Darwin, firmlinks mean the temp dir path is
      // not necessarily a lexical prefix of its mount point, so don't assert
      // that relationship.
      #expect(statfs.mountPoint.isAbsolute)
      #expect(!statfs.mountSource.string.isEmpty)

      // statfs of the mount point itself reports that same mount point.
      let mountStatFS = try StatFS(statfs.mountPoint)
      #expect(mountStatFS.mountPoint == statfs.mountPoint)
      #expect(mountStatFS.typeName == statfs.typeName)
    }
  }
  #endif

  #if SYSTEM_PACKAGE_DARWIN
  @available(System 199, *)
  @Test func typeAndSubtypeRoundTrip() throws {
    // On Darwin, `type` and `subtype` are opaque kernel indices with no stable
    // public constants, so we can only assert that mutation round-trips.
    var statfs = StatFS(rawValue: CInterop.StatFS())
    statfs.type = FileSystemType(rawValue: 42)
    #expect(statfs.type == FileSystemType(42))
    statfs.subtype = FileSystemSubtype(rawValue: 7)
    #expect(statfs.subtype == FileSystemSubtype(7))
  }
  #endif

  @available(System 199, *)
  @Test func nonexistentPathThrows() async throws {
    #expect(throws: Errno.noSuchFileOrDirectory) {
      _ = try StatFS("/var/empty/definitely/does/not/exist")
    }
    #expect(throws: Errno.noSuchFileOrDirectory) {
      _ = try StatFS(FilePath("/var/empty/definitely/does/not/exist"))
    }
    #expect(throws: Errno.noSuchFileOrDirectory) {
      _ = try FilePath("/var/empty/definitely/does/not/exist").statfs()
    }
  }

  @available(System 199, *)
  @Test func badFileDescriptorThrows() async throws {
    let badFD = FileDescriptor(rawValue: -1)
    #expect(throws: Errno.badFileDescriptor) {
      _ = try StatFS(badFD)
    }
    #expect(throws: Errno.badFileDescriptor) {
      _ = try badFD.statfs()
    }
  }

  @available(System 199, *)
  @Test func propertiesMatchRawFields() async throws {
    // Verify property mappings from the raw C struct
    try withTemporaryFilePath(basename: "StatFS_diff") { tempDir in
      var raw = CInterop.StatFS()
      try tempDir.withPlatformString {
        #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
        try #require(statfs($0, &raw) == 0, "\(Errno.current)")
        #else
        try #require(statvfs($0, &raw) == 0, "\(Errno.current)")
        #endif
      }
      let s = StatFS(rawValue: raw)

      #expect(s.blockSize == Int(raw.f_bsize))
      #expect(s.totalBlocks == UInt64(clamping: raw.f_blocks))
      #expect(s.freeBlocks == UInt64(clamping: raw.f_bfree))
      #expect(s.availableBlocks == UInt64(clamping: raw.f_bavail))
      #expect(s.totalInodes == UInt64(clamping: raw.f_files))
      #expect(s.freeInodes == UInt64(clamping: raw.f_ffree))

      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      #expect(s.preferredIOBlockSize == Int(raw.f_iosize))
      #expect(s.owner.rawValue == raw.f_owner)
      #expect(s.mountFlags.rawValue == raw.f_flags)
      // Decode independently with `String(cString:)`, not the implementation's
      // own helper, so this checks the decode rather than restating it.
      #expect(s.typeName == withUnsafeBytes(of: raw.f_fstypename) {
        $0.withMemoryRebound(to: CChar.self) { String(cString: $0.baseAddress!) }
      })
      #expect(s.mountPoint.string == withUnsafeBytes(of: raw.f_mntonname) {
        $0.withMemoryRebound(to: CChar.self) { String(cString: $0.baseAddress!) }
      })
      #expect(s.mountSource.string == withUnsafeBytes(of: raw.f_mntfromname) {
        $0.withMemoryRebound(to: CChar.self) { String(cString: $0.baseAddress!) }
      })
      #else
      #expect(s.fragmentSize == Int(raw.f_frsize))
      #expect(s.availableInodes == UInt64(clamping: raw.f_favail))
      #expect(s.maximumNameLength == Int(raw.f_namemax))
      #expect(s.mountFlags.rawValue == raw.f_flag)
      #endif
    }
  }

  #endif // !os(WASI)

  @available(System 199, *)
  @Test func propertiesAndRawValueRoundTrip() throws {
    var raw = CInterop.StatFS()
    raw.f_bsize = 4096
    var statfs = StatFS(rawValue: raw)
    #expect(statfs.blockSize == 4096)

    statfs.blockSize = 8192
    #expect(statfs.blockSize == 8192)
    #expect(statfs.rawValue.f_bsize == 8192)

    statfs.totalBlocks = 123456
    #expect(statfs.totalBlocks == 123456)
    #expect(statfs.rawValue.f_blocks == 123456)

    statfs.mountFlags.insert(.readOnly)
    #expect(statfs.mountFlags.contains(.readOnly))
  }

  // Setters clamp to the field's range instead of trapping. If the field is
  // 64-bit the write round-trips; if it's narrower the value clamps to the
  // field's max. Either way, setting `UInt64.max` should never trap or wrap
  // to a small value.
  @available(System 199, *)
  @Test func settersClamp() throws {
    var statfs = StatFS(rawValue: CInterop.StatFS())

    statfs.totalBlocks = .max
    #expect(statfs.totalBlocks >= UInt64(UInt32.max))

    statfs.blockSize = .max
    #expect(statfs.blockSize > 0)

    // Writing 0 always fits and reads back exactly.
    statfs.freeBlocks = 0
    #expect(statfs.freeBlocks == 0)
  }

  @available(System 199, *)
  @Test func craftedStructComputesSpace() throws {
    var raw = CInterop.StatFS()
    // The block-count unit is f_bsize on Darwin/BSD, f_frsize on statvfs.
    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    raw.f_bsize = 512
    #else
    raw.f_bsize = 4096 // Should not be used in calculations
    raw.f_frsize = 512
    #endif
    raw.f_blocks = 1000
    raw.f_bfree = 400
    raw.f_bavail = 100

    let s = StatFS(rawValue: raw)
    #expect(s.totalSpace == 1000 * 512)
    #expect(s.freeSpace == 400 * 512)
    #expect(s.availableSpace == 100 * 512)
  }

  #if os(FreeBSD) || os(OpenBSD)
  // The block/inode-count fields are signed here; negatives clamp to 0.
  @available(System 199, *)
  @Test func negativeCountsClampToZero() throws {
    var raw = CInterop.StatFS()
    raw.f_bsize = 512
    raw.f_bavail = -1
    raw.f_ffree = -1

    let s = StatFS(rawValue: raw)
    #expect(s.availableBlocks == 0)
    #expect(s.availableSpace == 0)
    #expect(s.freeInodes == 0)
  }
  #endif

  #if os(Linux)
  // /proc files report size 0 via stat, so read until EOF instead of getting
  // the size up front.
  private func _readEntireFile(_ path: String) throws -> String {
    let fd = try FileDescriptor.open(FilePath(path), .readOnly)
    defer { try? fd.close() }
    var result = [UInt8]()
    var chunk = [UInt8](repeating: 0, count: 64 * 1024)
    while true {
      let n = try chunk.withUnsafeMutableBytes { try fd.read(into: $0) }
      if n == 0 { break }
      result.append(contentsOf: chunk[..<n])
    }
    return String(decoding: result, as: UTF8.self)
  }

  // Cross-check mountFlags against /proc/self/mounts, the kernel's textual view
  // of the same flags produced by a different code path.
  @available(System 199, *)
  @Test func mountFlagsMatchProcMounts() throws {
    let contents = try _readEntireFile("/proc/self/mounts")

    // Fields: device, mountPoint, fsType, options, dump, pass. A later entry
    // shadows an earlier one at the same mount point, as statvfs also sees, so
    // key on mount point to keep the effective options.
    var mounts: [String: Set<String>] = [:]
    for line in contents.split(separator: "\n") {
      let fields = line.split(separator: " ")
      guard fields.count >= 4 else { continue }
      let mountPoint = String(fields[1])
      // Skip octal-escaped paths (spaces, tabs, etc.).
      if mountPoint.contains(where: { $0 == "\\" }) { continue }
      mounts[mountPoint] = Set(fields[3].split(separator: ",").map(String.init))
    }

    // Match whole options, so "errors=remount-ro" doesn't look like "ro".
    let checks: [(option: String, flag: MountFlags)] = [
      ("ro", .readOnly),
      ("noexec", .noExecution),
      ("nosuid", .noSetUserID),
      ("nodev", .noDevices),
      ("noatime", .noAccessTime),
    ]

    var verified = 0
    for (mountPoint, options) in mounts {
      guard let statfs = try? StatFS(FilePath(mountPoint)) else { continue }
      for (option, flag) in checks {
        #expect(
          statfs.mountFlags.contains(flag) == options.contains(option),
          "\(mountPoint): flag \(flag) disagrees with options \(options)"
        )
      }
      verified += 1
    }

    // Guard against a parser that silently matched nothing: "/" always works.
    #expect(verified > 0)
  }
  #endif

  #if os(WASI)
  @available(System 199, *)
  @Test func wasiThrowsNoFunction() async throws {
    // wasi-libc's statvfs is a stub that always fails with ENOSYS.
    #expect(throws: Errno.noFunction) {
      _ = try StatFS("/")
    }
  }
  #endif

  @available(System 199, *)
  @Test func fileSystemIDConformances() throws {
    let a = FileSystemID(rawValue: CInterop.FileSystemID())
    let b = FileSystemID(rawValue: CInterop.FileSystemID())
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)

    // Codable round-trips, including the manual fsid_t implementation on
    // Darwin and BSD.
    #if canImport(Foundation)
    let statfs = try? StatFS(FilePath("/"))
    if let id = statfs?.fileSystemID {
      let data = try JSONEncoder().encode(id)
      let decoded = try JSONDecoder().decode(FileSystemID.self, from: data)
      #expect(decoded == id)
      #expect(decoded.hashValue == id.hashValue)
    }
    #endif
  }

  @available(System 199, *)
  @Test func mountFlagsIsOptionSet() throws {
    var flags: MountFlags = [.readOnly, .noExecution]
    #expect(flags.contains(.readOnly))
    #expect(flags.contains(.noExecution))
    #expect(!flags.contains(.synchronous))

    flags.remove(.readOnly)
    #expect(!flags.contains(.readOnly))

    let empty = MountFlags(rawValue: 0)
    #expect(empty.isEmpty)
  }

  #if !os(WASI)
  @available(System 199, *)
  @Test func equalityAndHashing() throws {
    try withTemporaryFilePath(basename: "StatFS_equality") { tempDir in
      let statfs = try StatFS(tempDir)
      let copy = statfs
      #expect(statfs == copy)
      #expect(statfs.hashValue == copy.hashValue)
      #expect(Set([statfs, copy]).count == 1)

      var mutated = statfs
      mutated.totalBlocks &+= 1
      #expect(statfs != mutated)

      // Reserved fields are not part of the value.
      #if SYSTEM_PACKAGE_DARWIN
      var reserved = statfs
      reserved.rawValue.f_reserved.0 &+= 1
      #expect(statfs == reserved)
      #expect(statfs.hashValue == reserved.hashValue)
      #endif

      // Name buffers are read only up to their NUL terminator, so bytes past
      // it don't affect the value.
      #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
      var trailing = statfs
      try withUnsafeMutableBytes(of: &trailing.rawValue.f_mntonname) { buffer in
        // The kernel always NUL-terminates the name buffers.
        let terminator = try #require(buffer.firstIndex(of: 0))
        if terminator + 1 < buffer.count {
          buffer[terminator + 1] &+= 1
        }
      }
      #expect(statfs == trailing)
      #expect(statfs.hashValue == trailing.hashValue)
      #endif
    }
  }
  #endif

}

#endif
