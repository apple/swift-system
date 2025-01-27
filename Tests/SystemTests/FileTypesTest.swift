/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
final class FileDescriptorTest: XCTestCase {
  func testStandardDescriptors() {
    XCTAssertEqual(FileDescriptor.standardInput.rawValue, 0)
    XCTAssertEqual(FileDescriptor.standardOutput.rawValue, 1)
    XCTAssertEqual(FileDescriptor.standardError.rawValue, 2)
  }

  // Test the constants match the C header values. For various reasons,
  func testConstants() {
    XCTAssertEqual(O_RDONLY, FileDescriptor.AccessMode.readOnly.rawValue)
    XCTAssertEqual(O_WRONLY, FileDescriptor.AccessMode.writeOnly.rawValue)
    XCTAssertEqual(O_RDWR, FileDescriptor.AccessMode.readWrite.rawValue)

#if !os(Windows)
    XCTAssertEqual(O_NONBLOCK, FileDescriptor.OpenOptions.nonBlocking.rawValue)
#endif
    XCTAssertEqual(O_APPEND, FileDescriptor.OpenOptions.append.rawValue)
    XCTAssertEqual(O_CREAT, FileDescriptor.OpenOptions.create.rawValue)
    XCTAssertEqual(O_TRUNC, FileDescriptor.OpenOptions.truncate.rawValue)
    XCTAssertEqual(O_EXCL, FileDescriptor.OpenOptions.exclusiveCreate.rawValue)
#if !os(Windows)
    XCTAssertEqual(O_NOFOLLOW, FileDescriptor.OpenOptions.noFollow.rawValue)
    XCTAssertEqual(O_CLOEXEC, FileDescriptor.OpenOptions.closeOnExec.rawValue)
#endif

    // BSD only
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    XCTAssertEqual(O_SHLOCK, FileDescriptor.OpenOptions.sharedLock.rawValue)
    XCTAssertEqual(O_EXLOCK, FileDescriptor.OpenOptions.exclusiveLock.rawValue)
#endif

#if SYSTEM_PACKAGE_DARWIN
    XCTAssertEqual(O_SYMLINK, FileDescriptor.OpenOptions.symlink.rawValue)
    XCTAssertEqual(O_EVTONLY, FileDescriptor.OpenOptions.eventOnly.rawValue)
#endif

#if os(FreeBSD)
    XCTAssertEqual(O_SYNC, FileDescriptor.OpenOptions.sync.rawValue)
#endif

    XCTAssertEqual(SEEK_SET, FileDescriptor.SeekOrigin.start.rawValue)
    XCTAssertEqual(SEEK_CUR, FileDescriptor.SeekOrigin.current.rawValue)
    XCTAssertEqual(SEEK_END, FileDescriptor.SeekOrigin.end.rawValue)

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    XCTAssertEqual(SEEK_HOLE, FileDescriptor.SeekOrigin.nextHole.rawValue)
    XCTAssertEqual(SEEK_DATA, FileDescriptor.SeekOrigin.nextData.rawValue)
#endif
  }

  // TODO: test string conversion
  // TODO: test option set string conversion

}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
final class FilePermissionsTest: XCTestCase {

  func testPermissions() {
    // TODO: exhaustive tests

    XCTAssert(FilePermissions(rawValue: 0o664) == [.ownerReadWrite, .groupReadWrite, .otherRead])
    XCTAssert(FilePermissions(rawValue: 0o644) == [.ownerReadWrite, .groupRead, .otherRead])
    XCTAssert(FilePermissions(rawValue: 0o777) == [.otherReadWriteExecute, .groupReadWriteExecute, .ownerReadWriteExecute])

    // From the docs for FilePermissions
    do {
      let perms = FilePermissions(rawValue: 0o644)
      XCTAssert(perms == [.ownerReadWrite, .groupRead, .otherRead])
      XCTAssert(perms.contains(.ownerRead))
    }
  }
}
