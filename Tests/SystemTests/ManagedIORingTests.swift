import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

final class ManagedIORingTests: XCTestCase {
    func testInit() throws {
        _ = try ManagedIORing(queueDepth: 32)
    }

    func testNop() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        let completion = try await ring.submit(request: IORequest())
        XCTAssertEqual(completion.result, 0)
    }

    func testSubmitTimeout() async throws {
        let ring = try ManagedIORing(queueDepth: 32)
        var pipes: (Int32, Int32) = (0, 0)
        withUnsafeMutableBytes(of: &pipes) { ptr in
            ptr.withMemoryRebound(to: UInt32.self) { tptr in 
                let res = pipe(tptr.baseAddress!)
                XCTAssertEqual(res, 0)
            }
        }
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 128, alignment: 16)
        do {
            let completion = try await ring.submit(
                request: IORequest(reading: FileDescriptor(rawValue: pipes.0), into: buffer), 
                timeout: .seconds(0.1)
            )
            print("\(completion)")
            XCTFail("An error should be thrown")
        } catch (let e) {
            if let err  = e as? IORingError {
                XCTAssertEqual(err, .operationCanceled)
            } else {
                XCTFail()
            }
            buffer.deallocate()
            close(pipes.0)
            close(pipes.1)
        }
    }
}
