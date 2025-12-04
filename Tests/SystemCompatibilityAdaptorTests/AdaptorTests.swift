#if canImport(System) && canImport(SystemPackage)

import XCTest

import SystemPackage
import System

import SystemCompatibilityAdaptors

final class SystemCompatibilityAdaptorTests: XCTestCase {

  func testFilePathAdaptor() {
    let fp = SystemPackage.FilePath("/bar")

    let sfp = System.FilePath(converting: fp)

    // If we had access to the underlying array as API, this would look less silly
    XCTAssertEqual(fp, SystemPackage.FilePath(converting: sfp))
  }

  func testFileDescriptorAdaptor() throws {
    let fd = try SystemPackage.FileDescriptor.standardInput.duplicate()

    let sfd: System.FileDescriptor = System.FileDescriptor(converting: fd)

    print(fd.rawValue)
    XCTAssertEqual(fd.rawValue, sfd.rawValue)
  }
}
#endif // canImport(System) && canImport(SystemPackage)
