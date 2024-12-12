import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class AsyncFileDescriptorTests: XCTestCase {
    func testOpen() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        _ = try await AsyncFileDescriptor.open(
            path: "/dev/zero",
            on: ring,
            mode: .readOnly
        )
    }

    func testOpenClose() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let file = try await AsyncFileDescriptor.open(
            path: "/dev/zero",
            on: ring,
            mode: .readOnly
        )
        try await file.close()
    }

    func testDevNullEmpty() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let file = try await AsyncFileDescriptor.open(
            path: "/dev/null",
            on: ring,
            mode: .readOnly
        )
        for try await _ in file.toBytes() {
            XCTFail("/dev/null should be empty")
        }
    }

    func testRead() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let file = try await AsyncFileDescriptor.open(
            path: "/dev/zero",
            on: ring,
            mode: .readOnly
        )
        let bytes = file.toBytes()
        var counter = 0
        for try await byte in bytes {
            XCTAssert(byte == 0)
            counter &+= 1
            if counter > 16384 {
                break
            }
        }
    }
}
