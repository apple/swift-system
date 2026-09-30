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

#if !os(Windows) && !os(WASI)

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
#elseif canImport(Android)
import CSystem
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
      #expect(statfs.freeBlocks <= statfs.totalBlocks)
      #expect(statfs.availableBlocks <= statfs.freeBlocks)
    }
  }

  @available(System 199, *)
  @Test func readOnlyFlagReflectsWritableFileSystem() async throws {
    try withTemporaryFilePath(basename: "StatFS_readOnly") { tempDir in
      let statfs = try StatFS(tempDir)
      #expect(!statfs.mountFlags.contains(.readOnly))
    }
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  @available(System 199, *)
  @Test func darwinAndBSDFields() async throws {
    try withTemporaryFilePath(basename: "StatFS_darwinBSD") { tempDir in
      let statfs = try StatFS(tempDir)
      #expect(statfs.preferredIOBlockSize > 0)
      #expect(!statfs.typeName.isEmpty)
      #expect(statfs.mountPoint.isAbsolute)
      #expect(!statfs.mountSource.string.isEmpty)

      let mountStatFS = try StatFS(statfs.mountPoint)
      #expect(mountStatFS.mountPoint == statfs.mountPoint)
      #expect(mountStatFS.typeName == statfs.typeName)
    }
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
    try withTemporaryFilePath(basename: "StatFS_diff") { tempDir in
      var raw = CInterop.StatFS()
      try tempDir.withPlatformString {
        try #require(statfs($0, &raw) == 0, "\(Errno.current)")
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
      #expect(s.typeName == withUnsafeBytes(of: raw.f_fstypename) {
        $0.withMemoryRebound(to: CChar.self) { String(cString: $0.baseAddress!) }
      })
      #expect(s.mountPoint.string == withUnsafeBytes(of: raw.f_mntonname) {
        $0.withMemoryRebound(to: CChar.self) { String(cString: $0.baseAddress!) }
      })
      #expect(s.mountSource.string == withUnsafeBytes(of: raw.f_mntfromname) {
        $0.withMemoryRebound(to: CChar.self) { String(cString: $0.baseAddress!) }
      })
      #if SYSTEM_PACKAGE_DARWIN
      #expect(s.type.rawValue == raw.f_type)
      #expect(s.subtype.rawValue == raw.f_fssubtype)
      #elseif os(FreeBSD)
      #expect(s.type.rawValue == raw.f_type)
      #expect(s.maximumNameLength == Int(raw.f_namemax))
      #else // os(OpenBSD)
      #expect(s.maximumNameLength == Int(raw.f_namemax))
      #expect(s.availableInodes == UInt64(clamping: raw.f_favail))
      #endif
      #else
      #expect(s.fragmentSize == Int(raw.f_frsize))
      #expect(s.maximumNameLength == Int(raw.f_namelen))
      #expect(s.type.rawValue == UInt32(truncatingIfNeeded: raw.f_type))
      // `mountFlags` omits the kernel's ST_VALID (0x20) bookkeeping bit.
      #expect(s.mountFlags.rawValue == CInterop.MountFlags(truncatingIfNeeded: raw.f_flags) & ~0x20)
      #endif
    }
  }

  // Each setter writes its own field, and clamps instead of trapping.
  @available(System 199, *)
  @Test func settersWriteRawFields() throws {
    var s = StatFS(rawValue: CInterop.StatFS())
    s.blockSize = 1
    s.totalBlocks = 2
    s.freeBlocks = 3
    s.availableBlocks = 4
    s.totalInodes = 5
    s.freeInodes = 6
    #expect(s.rawValue.f_bsize == 1)
    #expect(s.rawValue.f_blocks == 2)
    #expect(s.rawValue.f_bfree == 3)
    #expect(s.rawValue.f_bavail == 4)
    #expect(s.rawValue.f_files == 5)
    #expect(s.rawValue.f_ffree == 6)
    #if SYSTEM_PACKAGE_DARWIN
    s.type = FileSystemType(7)
    s.subtype = FileSystemSubtype(8)
    #expect(s.rawValue.f_type == 7)
    #expect(s.rawValue.f_fssubtype == 8)
    #endif

    s.mountFlags.insert(.readOnly)
    #expect(s.mountFlags.contains(.readOnly))

    s.blockSize = .max
    #expect(s.blockSize == Int(clamping: type(of: s.rawValue.f_bsize).max))
  }

  @available(System 199, *)
  @Test func craftedStructComputesSpace() throws {
    var raw = CInterop.StatFS()
    // The block-count unit is f_bsize on Darwin/BSD, f_frsize elsewhere.
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

  @available(System 199, *)
  @Test func spaceSaturatesOnOverflow() throws {
    var raw = CInterop.StatFS()
    #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
    raw.f_bsize = 512
    #else
    raw.f_frsize = 512
    #endif
    raw.f_blocks = .max

    let s = StatFS(rawValue: raw)
    if MemoryLayout.size(ofValue: raw.f_blocks) == MemoryLayout<UInt64>.size {
      #expect(s.totalSpace == .max)
    } else {
      #expect(s.totalSpace == UInt64(raw.f_blocks) * 512)
    }
  }

  #if os(FreeBSD) || os(OpenBSD)
  @available(System 199, *)
  @Test func negativeCountsClampToZero() throws {
    var raw = CInterop.StatFS()
    raw.f_bsize = 512
    raw.f_bavail = -1
    #if os(FreeBSD)
    raw.f_ffree = -1
    #else
    raw.f_favail = -1
    #endif

    let s = StatFS(rawValue: raw)
    #expect(s.availableBlocks == 0)
    #expect(s.availableSpace == 0)
    #if os(FreeBSD)
    #expect(s.freeInodes == 0)
    #else
    #expect(s.availableInodes == 0)
    #endif

    // Distinct negative counts read the same through the clamped property,
    // but they're still different values.
    var other = raw
    other.f_bavail = -2
    #expect(StatFS(rawValue: other).availableBlocks == s.availableBlocks)
    #expect(StatFS(rawValue: other) != s)
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

  @available(System 199, *)
  @Test func mountFlagsMatchProcMounts() throws {
    let contents = try _readEntireFile("/proc/self/mounts")

    // Fields: device, mountPoint, fsType, options, dump, pass.
    var mounts: [String: Set<String>] = [:]
    for line in contents.split(separator: "\n") {
      let fields = line.split(separator: " ")
      guard fields.count >= 4 else { continue }
      let mountPoint = String(fields[1])
      // Skip octal-escaped paths (spaces, tabs, etc.).
      if mountPoint.contains(where: { $0 == "\\" }) { continue }
      mounts[mountPoint] = Set(fields[3].split(separator: ",").map(String.init))
    }

    let checks: [(option: String, flag: MountFlags)] = [
      ("ro", .readOnly),
      ("noexec", .noExecution),
      ("nosuid", .noSetUserID),
      ("nodev", .noDevices),
      ("noatime", .noAccessTime),
    ]

    // Only probe well-known local mounts. statfs on an arbitrary host mount
    // can hang (e.g. a stale NFS mount).
    let candidates: Set<String> = ["/", "/proc", "/sys", "/dev", "/dev/shm", "/run"]

    var verified = 0
    for (mountPoint, options) in mounts where candidates.contains(mountPoint) {
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

  #if os(Linux) || os(Android)
  @available(System 199, *)
  @Test func typeIsMagicNumber() throws {
    // PROC_SUPER_MAGIC from <linux/magic.h>.
    #expect(try StatFS("/proc").type == FileSystemType(0x9FA0))

    // Magic numbers from 0x80000000 up should round-trip correctly even
    // on platforms where they're signed.
    var statfs = StatFS(rawValue: CInterop.StatFS())
    statfs.type = FileSystemType(0x9123_683E) // BTRFS_SUPER_MAGIC
    #expect(statfs.type == FileSystemType(0x9123_683E))
  }

  // The kernel sets ST_VALID (0x20) in every `f_flags` to mark the field as
  // filled in, though Bionic's `statfs()` clears it.
  @available(System 199, *)
  @Test func mountFlagsOmitValidBit() throws {
    var raw = CInterop.StatFS()
    raw.f_flags = 0x20 | 0x01 // ST_VALID | ST_RDONLY
    var statfs = StatFS(rawValue: raw)
    #expect(statfs.mountFlags == .readOnly)

    statfs.mountFlags = .noExecution
    #expect(statfs.rawValue.f_flags == 0x20 | 0x08) // ST_VALID | ST_NOEXEC

    let root = try StatFS("/")
    #if os(Linux)
    #expect(root.rawValue.f_flags & 0x20 != 0)
    #endif
    #expect(root.mountFlags.rawValue & 0x20 == 0)
  }
  #endif

  #if os(Linux) || os(Android)
  @available(System 199, *)
  @Test func mountFlagBitsMatchLibc() throws {
    let expected: [(name: String, literal: CInterop.MountFlags, libc: UInt64)] = [
      ("ST_RDONLY", _ST_RDONLY_BIT, _system_get_ST_RDONLY()),
      ("ST_NOSUID", _ST_NOSUID_BIT, _system_get_ST_NOSUID()),
      ("ST_NODEV", _ST_NODEV_BIT, _system_get_ST_NODEV()),
      ("ST_NOEXEC", _ST_NOEXEC_BIT, _system_get_ST_NOEXEC()),
      ("ST_SYNCHRONOUS", _ST_SYNCHRONOUS_BIT, _system_get_ST_SYNCHRONOUS()),
      ("ST_MANDLOCK", _ST_MANDLOCK_BIT, _system_get_ST_MANDLOCK()),
      ("ST_NOATIME", _ST_NOATIME_BIT, _system_get_ST_NOATIME()),
      ("ST_NODIRATIME", _ST_NODIRATIME_BIT, _system_get_ST_NODIRATIME()),
      ("ST_RELATIME", _ST_RELATIME_BIT, _system_get_ST_RELATIME()),
      ("ST_NOSYMFOLLOW", _ST_NOSYMFOLLOW_BIT, _system_get_ST_NOSYMFOLLOW()),
    ]

    for (name, literal, libc) in expected {
      #expect(
        UInt64(literal) == libc,
        "\(name): literal \(literal) disagrees with libc value \(libc)"
      )
    }
  }
  #endif

  @available(System 199, *)
  @Test func fileSystemIDConformances() throws {
    let id = FileSystemID(_words: (1, 2))
    #expect(id == FileSystemID(_words: (1, 2)))
    #expect(id != FileSystemID(_words: (1, 3)))
    #expect(id != FileSystemID(_words: (3, 2)))
    #expect(id.hashValue != FileSystemID(_words: (1, 3)).hashValue)

    #if canImport(Foundation)
    let data = try JSONEncoder().encode(id)
    #expect(String(decoding: data, as: UTF8.self) == "[1,2]")
    #expect(try JSONDecoder().decode(FileSystemID.self, from: data) == id)
    #endif
  }

  @available(System 199, *)
  @Test func descriptions() throws {
    #expect(MountFlags.readOnly.description == "[.readOnly]")
    let flags: MountFlags = [.readOnly, .noExecution]
    #expect(flags.description == "[.readOnly, .noExecution]")
    #expect(flags.debugDescription == flags.description)
    #expect(MountFlags(rawValue: 0).description == "[]")

    #expect(FileSystemID(_words: (1, 2)).description == "FileSystemID(1, 2)")
  }

  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  // A name buffer with no NUL terminator (malformed) is read in full.
  @available(System 199, *)
  @Test func unterminatedNameBuffers() throws {
    var raw = CInterop.StatFS()
    withUnsafeMutableBytes(of: &raw.f_fstypename) { buffer in
      for i in buffer.indices { buffer[i] = UInt8(ascii: "a") }
    }
    withUnsafeMutableBytes(of: &raw.f_mntonname) { buffer in
      for i in buffer.indices { buffer[i] = UInt8(ascii: "b") }
    }

    let s = StatFS(rawValue: raw)
    let typeNameLength = MemoryLayout.size(ofValue: raw.f_fstypename)
    let mountPointLength = MemoryLayout.size(ofValue: raw.f_mntonname)
    #expect(s.typeName == String(repeating: "a", count: typeNameLength))
    #expect(s.mountPoint.string == String(repeating: "b", count: mountPointLength))
  }
  #endif

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

      // Fields without a property, like `f_flags_ext`, are.
      var extended = statfs
      extended.rawValue.f_flags_ext ^= 1
      #expect(statfs != extended)
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

}

#endif
