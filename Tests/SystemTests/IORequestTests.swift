import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
import System
#endif

func requestBytes(_ request: consuming RawIORequest) -> [UInt8] {
    return withUnsafePointer(to: request) {
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
        let req = IORequest.nop().makeRawRequest()
        let sourceBytes = requestBytes(req)
        // convenient property of nop: it's all zeros!
        // for some unknown reason, liburing sets the fd field to -1.
        // we're not trying to be bug-compatible with it, so 0 *should* work.
        XCTAssertEqual(sourceBytes, .init(repeating: 0, count: 64))
    }

    func testOpenatFixedFile() throws {
        let pathPtr = UnsafePointer<CChar>(bitPattern: 0x414141410badf00d)!
        let fileSlot: IORingFileSlot = IORingFileSlot(resource: UInt32.max, index: 0)
        let req = IORequest.open(FilePath(platformString: pathPtr),
            in: FileDescriptor(rawValue: -100),
            into: fileSlot,
            mode: .readOnly,
            options: [],
            permissions: nil
        )

        let expectedRequest: [UInt8] = {
            var bin = [UInt8].init(repeating: 0, count: 64)
            bin[0] = 0x12 // opcode for the request
            // bin[1] = 0 - no request flags
            // bin[2...3] = 0 - padding
            bin[4...7] = [0x9c, 0xff, 0xff, 0xff] // -100 in UInt32 - dirfd
            // bin[8...15] = 0 - zeroes
            withUnsafeBytes(of: pathPtr) {
                // path pointer
                bin[16...23] = ArraySlice($0)
            }
            // bin[24...43] = 0 - zeroes
            withUnsafeBytes(of: UInt32(fileSlot.index + 1)) {
                // file index + 1 - yes, unfortunately
                bin[44...47] = ArraySlice($0)
            }
            return bin
        }()

        let actualRequest = requestBytes(req.makeRawRequest())
        XCTAssertEqual(expectedRequest, actualRequest)
    }
}
