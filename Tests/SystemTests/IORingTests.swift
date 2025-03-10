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
        try ring.submit(linkedRequests: IORequest.nop())
        let completion = try ring.blockingConsumeCompletion()
        XCTAssertEqual(completion.result, 0)
    }
}
