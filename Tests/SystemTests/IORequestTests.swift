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
        let req = IORing.Request.nop().makeRawRequest()
        let sourceBytes = requestBytes(req)
        // convenient property of nop: it's all zeros!
        // for some unknown reason, liburing sets the fd field to -1.
        // we're not trying to be bug-compatible with it, so 0 *should* work.
        XCTAssertEqual(sourceBytes, .init(repeating: 0, count: 64))
    }

    func testOpenAndReadFixedFile() throws {
        mkdir("/tmp/IORingTests/", 0o777)
        let path: FilePath = "/tmp/IORingTests/test.txt"
        let fd = try FileDescriptor.open(
            path, .readWrite, options: .create, permissions: .ownerReadWrite)
        try fd.writeAll("Hello, World!".utf8)
        try fd.close()
        var ring = try IORing(queueDepth: 3)
        let parent = try FileDescriptor.open("/tmp/IORingTests/", .readOnly)
        let fileSlot = try ring.registerFileSlots(count: 1)[0]
        let rawBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 64, alignment: 16)
        let buffer = try ring.registerBuffers([rawBuffer])[0]
        try ring.submit(linkedRequests:
            .open(path, in: parent, into: fileSlot, mode: .readOnly),
            .read(fileSlot, into: buffer),
            .close(fileSlot)
        )
        _ = try ring.blockingConsumeCompletion() //open
        _ = try ring.blockingConsumeCompletion() //read
        _ = try ring.blockingConsumeCompletion() //close

        let result = String(cString: rawBuffer.assumingMemoryBound(to: CChar.self).baseAddress!)
        XCTAssertEqual(result, "Hello, World!")
   
        rmdir("/tmp/IORingTests/")
    }
}
