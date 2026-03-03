#if canImport(System) && canImport(SystemPackage)

import Testing

import SystemPackage
import System

import SystemCompatibilityAdaptors

@Suite("CompatibilityAdaptors")
private struct CompatibilityAdaptorTests {

  @available(System 0.0.2, *)
  @Test
  func filePathAdaptor() throws {
    let fp = SystemPackage.FilePath("/bar")

    let sfp = System.FilePath(converting: fp)

    // If we had access to the underlying array as API, this would look less silly
    #expect(fp == SystemPackage.FilePath(converting: sfp))
  }

  @available(System 0.0.1, *)
  @Test
  func fileDescriptorAdaptor() throws {
    let fd = try SystemPackage.FileDescriptor.standardInput.duplicate()

    let sfd: System.FileDescriptor = System.FileDescriptor(converting: fd)

    #expect(fd.rawValue == sfd.rawValue)
  }
}
#endif // canImport(System) && canImport(SystemPackage)
