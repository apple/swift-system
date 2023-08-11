import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class ManagedIORingTests: XCTestCase {
    func testInit() throws {
        let ring = try ManagedIORing(queueDepth: 32)
    }

    func testNop() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let completion = await ring.submitAndWait(.nop)
        XCTAssertEqual(completion.result, 0)
    }
}
