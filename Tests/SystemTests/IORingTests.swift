import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class IORingTests: XCTestCase {
    func testInit() throws {
        _ = try IORing(queueDepth: 32)
    }

    func testNop() throws {
        var ring = try IORing(queueDepth: 32)
        ring.writeRequest(IORequest())
        try ring.submitRequests()
        let completion = ring.blockingConsumeCompletion()
        XCTAssertEqual(completion.result, 0)
    }
}
