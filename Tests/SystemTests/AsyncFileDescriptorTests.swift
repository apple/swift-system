import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class AsyncFileDescriptorTests: XCTestCase {
    func testOpen() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let file = try await AsyncFileDescriptor.openat(
            path: "/dev/zero",
            .readOnly,
            onRing: ring
        )
    }

    func testOpenClose() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let file = try await AsyncFileDescriptor.openat(
            path: "/dev/zero",
            .readOnly,
            onRing: ring
        )
        await try file.close()
    }

    func testDevNullEmpty() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let file = try await AsyncFileDescriptor.openat(
            path: "/dev/null",
            .readOnly,
            onRing: ring
        )
        for try await _ in file {
            XCTFail("/dev/null should be empty")
        }
    }
}
