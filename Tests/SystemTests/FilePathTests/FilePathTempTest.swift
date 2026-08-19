/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import Foundation

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

#if os(Windows)
import WinSDK
#endif

final class TemporaryPathTest: XCTestCase {
  #if SYSTEM_PACKAGE_DARWIN
  func testNotInSlashTmp() throws {
    try withTemporaryFilePath(basename: "NotInSlashTmp") { path in
      // We shouldn't be using "/tmp" on Darwin
      XCTAssertNotEqual(path.components.first!, "tmp")
    }
  }
  #endif

  func testUnique() throws {
    try withTemporaryFilePath(basename: "test") { path in
      let strPath = String(decoding: path)
      XCTAssert(strPath.contains("test"))
      try withTemporaryFilePath(basename: "test") { path2 in
        let strPath2 = String(decoding: path2)
        XCTAssertNotEqual(strPath, strPath2)
      }
    }
  }

  func testCleanup() throws {
    var thePath: FilePath? = nil

    try withTemporaryFilePath(basename: "test") { path in
      thePath = path.appending("foo.txt")
      let fd = try FileDescriptor.open(thePath!, .readWrite,
                                       options: [.create, .truncate],
                                       permissions: .ownerReadWrite)
      _ = try fd.closeAfter {
        try fd.writeAll("Hello World".utf8)
      }
    }

    XCTAssertThrowsError(try FileDescriptor.open(thePath!, .readOnly)) {
      error in

      XCTAssertEqual(error as! Errno, Errno.noSuchFileOrDirectory)
    }
  }

  #if os(Windows)
  /// Recursive removal must not follow directory reparse points (junctions or
  /// directory symlinks). Enumerating one traverses into its *target*, so a
  /// naive recursion would delete files that live outside the tree being
  /// removed.
  func testCleanupDoesNotFollowReparsePoints() throws {
    func createDirectory(_ path: FilePath) throws {
      try path.withPlatformString {
        if CreateDirectoryW($0, nil) == false {
          throw Errno(windowsError: GetLastError())
        }
      }
    }

    let tmp = try _getTemporaryDirectory()
    let victim = tmp.appending("ss-reparse-victim")
    let container = tmp.appending("ss-reparse-container")
    // Start from a clean slate and always clean up afterwards.
    try? _recursiveRemove(at: victim)
    try? _recursiveRemove(at: container)
    defer {
      try? _recursiveRemove(at: victim)
      try? _recursiveRemove(at: container)
    }

    // A file that lives outside the tree we are about to remove, and so must
    // survive it.
    try createDirectory(victim)
    let victimFile = victim.appending("keep.txt")
    let vfd = try FileDescriptor.open(victimFile, .readWrite,
                                      options: [.create, .truncate],
                                      permissions: .ownerReadWrite)
    try vfd.closeAfter { try vfd.writeAll("keep".utf8) }

    // A directory junction inside the container, pointing at the victim.
    // A junction (mklink /J) is a reparse point that, unlike a symlink, needs
    // no special privilege, so this exercises the reparse-point path in CI too.
    try createDirectory(container)
    let link = container.appending("link")
    let mklink = Process()
    mklink.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\cmd.exe")
    mklink.arguments = ["/c", "mklink", "/J",
                        String(decoding: link), String(decoding: victim)]
    mklink.standardOutput = nil
    mklink.standardError = nil
    try mklink.run()
    mklink.waitUntilExit()
    try XCTSkipUnless(mklink.terminationStatus == 0,
                      "could not create a directory junction")

    // Removing the container must delete the link, not what it points at.
    try _recursiveRemove(at: container)

    let reopened = try FileDescriptor.open(victimFile, .readOnly)
    try reopened.close()
  }
  #endif
}
