/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if os(Windows)

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

import WinSDK

@available(iOS 8, *)
final class FileOperationsTestWindows: XCTestCase {
  private let r = ACCESS_MASK(
    FILE_READ_ATTRIBUTES
      | FILE_READ_DATA
      | FILE_READ_EA
      | STANDARD_RIGHTS_READ
      | SYNCHRONIZE
  )
  private let w = ACCESS_MASK(
    FILE_APPEND_DATA
      | FILE_WRITE_ATTRIBUTES
      | FILE_WRITE_DATA
      | FILE_WRITE_EA
      | STANDARD_RIGHTS_WRITE
      | SYNCHRONIZE
  )
  private let x = ACCESS_MASK(
    FILE_EXECUTE
      | FILE_READ_ATTRIBUTES
      | STANDARD_RIGHTS_EXECUTE
      | SYNCHRONIZE
  )

  private struct Test {
    var permissions: CModeT
    var ownerAccess: ACCESS_MASK
    var groupAccess: ACCESS_MASK
    var otherAccess: ACCESS_MASK

    init(_ permissions: CModeT,
         _ ownerAccess: ACCESS_MASK,
         _ groupAccess: ACCESS_MASK,
         _ otherAccess: ACCESS_MASK) {
      self.permissions = permissions
      self.ownerAccess = ownerAccess
      self.groupAccess = groupAccess
      self.otherAccess = otherAccess
    }
  }

  /// Retrieve the owner, group and other access masks for a given file.
  ///
  /// - Parameters:
  ///   - path: The path to the file to inspect
  /// - Returns: A tuple of ACCESS_MASK values.
  func getAccessMasks(
    path: FilePath
  ) -> (ACCESS_MASK, ACCESS_MASK, ACCESS_MASK) {
    var SIDAuthWorld = SID_IDENTIFIER_AUTHORITY(Value: (0, 0, 0, 0, 0, 1))
    var psidEveryone: PSID? = nil

    XCTAssert(AllocateAndInitializeSid(&SIDAuthWorld, 1,
                                       DWORD(SECURITY_WORLD_RID),
                                       0, 0, 0, 0, 0, 0, 0,
                                       &psidEveryone))
    defer {
      FreeSid(psidEveryone)
    }

    var everyone = TRUSTEE_W(
      pMultipleTrustee: nil,
      MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
      TrusteeForm: TRUSTEE_IS_SID,
      TrusteeType: TRUSTEE_IS_GROUP,
      ptstrName:
        psidEveryone!.assumingMemoryBound(to: CInterop.PlatformChar.self)
    )

    return path.withPlatformString { objectName in
      var psidOwner: PSID? = nil
      var psidGroup: PSID? = nil
      var pDacl: PACL? = nil
      var pSD: PSECURITY_DESCRIPTOR? = nil

      XCTAssertEqual(GetNamedSecurityInfoW(
                       objectName,
                       SE_FILE_OBJECT,
                       SECURITY_INFORMATION(
                         DACL_SECURITY_INFORMATION
                           | GROUP_SECURITY_INFORMATION
                           | OWNER_SECURITY_INFORMATION
                       ),
                       &psidOwner,
                       &psidGroup,
                       &pDacl,
                       nil,
                       &pSD), DWORD(ERROR_SUCCESS))
      defer {
        LocalFree(pSD)
      }

      var owner = TRUSTEE_W(
        pMultipleTrustee: nil,
        MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
        TrusteeForm: TRUSTEE_IS_SID,
        TrusteeType: TRUSTEE_IS_USER,
        ptstrName:
          psidOwner!.assumingMemoryBound(to: CInterop.PlatformChar.self)
      )
      var group = TRUSTEE_W(
        pMultipleTrustee: nil,
        MultipleTrusteeOperation: NO_MULTIPLE_TRUSTEE,
        TrusteeForm: TRUSTEE_IS_SID,
        TrusteeType: TRUSTEE_IS_GROUP,
        ptstrName:
          psidGroup!.assumingMemoryBound(to: CInterop.PlatformChar.self)
      )

      var ownerAccess = ACCESS_MASK(0)
      var groupAccess = ACCESS_MASK(0)
      var otherAccess = ACCESS_MASK(0)

      XCTAssertEqual(GetEffectiveRightsFromAclW(
                       pDacl,
                       &owner,
                       &ownerAccess), DWORD(ERROR_SUCCESS))
      XCTAssertEqual(GetEffectiveRightsFromAclW(
                       pDacl,
                       &group,
                       &groupAccess), DWORD(ERROR_SUCCESS))
      XCTAssertEqual(GetEffectiveRightsFromAclW(
                       pDacl,
                       &everyone,
                       &otherAccess), DWORD(ERROR_SUCCESS))

      return (ownerAccess, groupAccess, otherAccess)
    }
  }

  private func runTests(_ tests: [Test], at path: FilePath) throws {
    for test in tests {
      let octal = String(test.permissions, radix: 8)
      let testPath = path.appending("test-\(octal).txt")
      let fd = try FileDescriptor.open(
        testPath,
        .readWrite,
        options: [.create, .truncate],
        permissions: FilePermissions(rawValue: test.permissions)
      )
      _ = try fd.closeAfter {
        try fd.writeAll("Hello World".utf8)
      }

      let (ownerAccess, groupAccess, otherAccess)
        = getAccessMasks(path: testPath)

      XCTAssertEqual(ownerAccess, test.ownerAccess)
      XCTAssertEqual(groupAccess, test.groupAccess)
      XCTAssertEqual(otherAccess, test.otherAccess)
    }
  }

  /// Test that the umask works properly
  func testUmask() throws {
    // See https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/persistent-storage#permissions
    try XCTSkipIf(NSUserName() == "ContainerAdministrator", "containers use a different permission model")
    
    // Default mask should be 0o022
    XCTAssertEqual(FilePermissions.creationMask, [.groupWrite, .otherWrite])

    try withTemporaryFilePath(basename: "testUmask") { path in
      let tests = [
        Test(0o000, 0, 0, 0),
        Test(0o700, r|w|x, 0, 0),
        Test(0o770, r|w|x, r|x, 0),
        Test(0o777, r|w|x, r|x, r|x)
      ]

      try runTests(tests, at: path)
    }

    try FilePermissions.withCreationMask([.groupWrite, .groupExecute,
                                          .otherWrite, .otherExecute]) {
      try withTemporaryFilePath(basename: "testUmask") { path in
        let tests = [
          Test(0o000, 0, 0, 0),
          Test(0o700, r|w|x, 0, 0),
          Test(0o770, r|w|x, r, 0),
          Test(0o777, r|w|x, r, r)
        ]

        try runTests(tests, at: path)
      }
    }
  }

  /// Test that setting permissions on a file works as expected
  func testPermissions() throws {
    // See https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/persistent-storage#permissions
    try XCTSkipIf(NSUserName() == "ContainerAdministrator", "containers use a different permission model")

    try FilePermissions.withCreationMask([]) {
      try withTemporaryFilePath(basename: "testPermissions") { path in
        let tests = [
          Test(0o000, 0, 0, 0),

          Test(0o400, r, 0, 0),
          Test(0o200, w, 0, 0),
          Test(0o100, x, 0, 0),
          Test(0o040, 0, r, 0),
          Test(0o020, 0, w, 0),
          Test(0o010, 0, x, 0),
          Test(0o004, 0, 0, r),
          Test(0o002, 0, 0, w),
          Test(0o001, 0, 0, x),

          Test(0o700, r|w|x, 0, 0),
          Test(0o770, r|w|x, r|w|x, 0),
          Test(0o777, r|w|x, r|w|x, r|w|x),

          Test(0o755, r|w|x, r|x, r|x),
          Test(0o644, r|w, r, r),

          Test(0o007, 0, 0, r|w|x),
          Test(0o070, 0, r|w|x, 0),
          Test(0o077, 0, r|w|x, r|w|x),
        ]

        try runTests(tests, at: path)
      }
    }
  }
}

#endif // os(Windows)
