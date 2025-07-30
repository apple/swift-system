#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import XCTest

#if SYSTEM_PACKAGE
    @testable import SystemPackage
#else
    import System
#endif

func requestBytes(_ request: consuming RawIORequest) -> [UInt8] {
    return withUnsafePointer(to: request.rawValue) {
        let requestBuf = UnsafeBufferPointer(start: $0, count: 1)
        let rawBytes = UnsafeRawBufferPointer(requestBuf)
        return .init(rawBytes)
    }
}

// This test suite compares various IORequests bit-for-bit to IORequests
// that were generated with liburing or manually written out,
// which are known to work correctly.
final class IORequestTests: XCTestCase {
    func testNop() {
        let req = IORing.Request.nop().makeRawRequest()
        let sourceBytes = requestBytes(req)
        // convenient property of nop: it's all zeros!
        // for some unknown reason, liburing sets the fd field to -1.
        // we're not trying to be bug-compatible with it, so 0 *should* work.
        XCTAssertEqual(sourceBytes, .init(repeating: 0, count: 64))
    }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
