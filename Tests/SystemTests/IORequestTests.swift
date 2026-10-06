#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import XCTest
import CSystem

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
    func testWriteUnregisteredImmutableBuffer() {
        let bytes: [UInt8] = [1, 2, 3]
        bytes.withUnsafeBytes { buffer in
            let request = IORing.Request.write(
                buffer, into: FileDescriptor(rawValue: 7), at: 17, context: 42
            ).makeRawRequest(pathBuffers: PendingPathBuffers(reservedCapacity: 0))
            XCTAssertEqual(request.rawValue.opcode, 23)
            XCTAssertEqual(request.rawValue.fd, 7)
            XCTAssertEqual(request.rawValue.flags, 0)
            XCTAssertEqual(request.rawValue.addr, UInt64(UInt(bitPattern: buffer.baseAddress)))
            XCTAssertEqual(request.rawValue.len, 3)
            XCTAssertEqual(request.rawValue.off, 17)
            XCTAssertEqual(request.rawValue.user_data, 42)
        }
    }

    func testWriteUnregisteredImmutableBufferToRegisteredFile() {
        let bytes: [UInt8] = [1, 2, 3]
        bytes.withUnsafeBytes { buffer in
            let file = IORing.RegisteredFile(resource: 7, index: 3)
            let request = IORing.Request.write(
                buffer, into: file, at: 17, context: 42
            ).makeRawRequest(pathBuffers: PendingPathBuffers(reservedCapacity: 0))
            XCTAssertEqual(request.rawValue.opcode, 23)
            XCTAssertEqual(request.rawValue.fd, 3)
            XCTAssertEqual(request.rawValue.flags, 1)
            XCTAssertEqual(request.rawValue.addr, UInt64(UInt(bitPattern: buffer.baseAddress)))
            XCTAssertEqual(request.rawValue.len, 3)
            XCTAssertEqual(request.rawValue.off, 17)
            XCTAssertEqual(request.rawValue.user_data, 42)
        }
    }

    func testMutableWriteFunctionReferences() {
        let write: (UnsafeMutableRawBufferPointer, FileDescriptor, UInt64, UInt64) -> IORing.Request =
            IORing.Request.write
        let writeRegistered: (UnsafeMutableRawBufferPointer, IORing.RegisteredFile, UInt64, UInt64) -> IORing.Request =
            IORing.Request.write
        var bytes: [UInt8] = [1, 2, 3]
        bytes.withUnsafeMutableBytes { buffer in
            let request = write(buffer, FileDescriptor(rawValue: 7), 17, 42)
                .makeRawRequest(pathBuffers: PendingPathBuffers(reservedCapacity: 0))
            let registered = writeRegistered(buffer, IORing.RegisteredFile(resource: 7, index: 3), 17, 42)
                .makeRawRequest(pathBuffers: PendingPathBuffers(reservedCapacity: 0))
            XCTAssertEqual(request.rawValue.fd, 7)
            XCTAssertEqual(request.rawValue.len, 3)
            XCTAssertEqual(registered.rawValue.fd, 3)
            XCTAssertEqual(registered.rawValue.flags, 1)
        }
    }

    func testNop() {
        let req = IORing.Request.nop().makeRawRequest(
            pathBuffers: PendingPathBuffers(reservedCapacity: 0))
        let sourceBytes = requestBytes(req)
        // convenient property of nop: it's all zeros!
        // for some unknown reason, liburing sets the fd field to -1.
        // we're not trying to be bug-compatible with it, so 0 *should* work.
        XCTAssertEqual(sourceBytes, .init(repeating: 0, count: 64))
    }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
