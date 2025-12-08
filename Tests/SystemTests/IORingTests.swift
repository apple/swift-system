#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import XCTest
import CSystem //for eventfd

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

func uringEnabled() throws -> Bool {
    do {
        let procPath = FilePath("/proc/sys/kernel/io_uring_disabled")
        let fd = try FileDescriptor.open(procPath, .readOnly)
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1024, alignment: 0)
        _ = try fd.read(into: buffer)
        if buffer.load(fromByteOffset: 0, as: Int.self) == 0 {
            return true
        }
    } catch (_) {
        return false
    }
    return false
}

final class IORingTests: XCTestCase {
    func testInit() throws {
        guard try uringEnabled() else { return }
        _ = try IORing(queueDepth: 32, flags: [])
    }

    func testNop() throws {
        guard try uringEnabled() else { return }
        var ring = try IORing(queueDepth: 32, flags: [])
        _ = try ring.submit(linkedRequests: .nop())
        let completion = try ring.blockingConsumeCompletion()
        XCTAssertEqual(completion.result, 0)
    }

    func makeHelloWorldFile() throws -> (dir: FileDescriptor, file: FilePath) {
        mkdir("/tmp/IORingTests/", 0o777)
        let path: FilePath = "/tmp/IORingTests/test.txt"
        let fd = try FileDescriptor.open(
            path, 
            .readWrite, 
            options: .create, 
            permissions: .ownerReadWrite
        )
        try fd.writeAll("Hello, World!".utf8)
        try fd.close()
        let parent = try FileDescriptor.open("/tmp/IORingTests/", .readOnly)

        return (parent, path)
    }

    func cleanUpHelloWorldFile(_ parent: FileDescriptor) throws {
        try parent.close()
        rmdir("/tmp/IORingTests/")
    }

    func setupTestRing(depth: Int, fileSlots: Int, buffers: [UnsafeMutableRawBufferPointer]) throws -> IORing {
        var ring: IORing = try IORing(queueDepth: UInt32(depth))
        _ = try ring.registerFileSlots(count: 1)
        _ = try ring.registerBuffers(buffers)
        return ring
    }

    func testUndersizedSubmissionQueue() throws {
        guard try uringEnabled() else { return }
        var ring: IORing = try IORing(queueDepth: 1)
        let enqueued = ring.prepare(linkedRequests: .nop(), .nop())
        XCTAssertFalse(enqueued)
    }

    // Exercises opening, reading, closing, registered files, registered buffers, and eventfd
    func testOpenReadAndWriteFixedFile() throws {
        guard try uringEnabled() else { return }
        let (parent, path) = try makeHelloWorldFile()
        let rawBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 13, alignment: 16)
        var ring = try setupTestRing(depth: 6, fileSlots: 1, buffers: [rawBuffer])
        let eventFD = FileDescriptor(rawValue: eventfd(0, Int32(EFD_SEMAPHORE)))
        try ring.registerEventFD(eventFD)

        //Part 1: read the file we just created, and make sure the eventfd fires
        let enqueued = try ring.submit(linkedRequests:
            .open(path, in: parent, into: ring.registeredFileSlots[0], mode: .readOnly),
            .read(ring.registeredFileSlots[0], into: ring.registeredBuffers[0]),
            .close(ring.registeredFileSlots[0]))
        XCTAssert(enqueued)
        let efdBuf = UnsafeMutableRawBufferPointer.allocate(byteCount: 8, alignment: 0)
        _ = try eventFD.read(into: efdBuf)
        _ = try ring.blockingConsumeCompletion() //open
        _ = try eventFD.read(into: efdBuf)
        _ = try ring.blockingConsumeCompletion() //read
        _ = try eventFD.read(into: efdBuf)
        _ = try ring.blockingConsumeCompletion() //close
        let result = String(cString: rawBuffer.assumingMemoryBound(to: CChar.self).baseAddress!)
        XCTAssertEqual(result, "Hello, World!")

        //Part 2: delete that file, then use the ring to write out a new one
        let rmResult = path.withPlatformString {
            remove($0)
        }
        XCTAssertEqual(rmResult, 0)
        let enqueued2 = try ring.submit(linkedRequests:
            .open(path, in: parent, into: ring.registeredFileSlots[0], mode: .readWrite, options: .create, permissions: .ownerReadWrite),
            .write(ring.registeredBuffers[0], into: ring.registeredFileSlots[0]),
            .close(ring.registeredFileSlots[0]))
        XCTAssert(enqueued2)
        _ = try eventFD.read(into: efdBuf)
        _ = try ring.blockingConsumeCompletion() //open
        _ = try eventFD.read(into: efdBuf)
        _ = try ring.blockingConsumeCompletion() //write
        _ = try eventFD.read(into: efdBuf)
        _ = try ring.blockingConsumeCompletion() //close
        memset(rawBuffer.baseAddress!, 0, rawBuffer.count)
        //Verify using a non-ring IO method that what we wrote matches our expectations
        print("about to open")
        let nonRingFD = try FileDescriptor.open(path, .readOnly)
        let bytesRead = try nonRingFD.read(into: rawBuffer)
        XCTAssert(bytesRead == 13)
        let result2 = String(cString: rawBuffer.assumingMemoryBound(to: CChar.self).baseAddress!)
        XCTAssertEqual(result2, "Hello, World!")
        try cleanUpHelloWorldFile(parent)
        efdBuf.deallocate()
        rawBuffer.deallocate()
    }

    func testPollAddPollIn() throws {
        guard try uringEnabled() else { return }
        var ring = try IORing(queueDepth: 32, flags: [])

        // Test POLLIN: Create an eventfd to monitor for read readiness
        let testEventFD = FileDescriptor(rawValue: eventfd(0, 0))
        defer {
            // Clean up
            try! testEventFD.close()
        }
        let pollInContext: UInt64 = 42

        // Submit a pollAdd request to monitor for POLLIN events (data available for reading)
        let enqueued = try ring.submit(linkedRequests:
            .pollAdd(testEventFD, pollEvents: .pollin, isMultiShot: false, context: pollInContext))
        XCTAssert(enqueued)

        // Write to the eventfd to trigger the POLLIN event
        var value: UInt64 = 1
        withUnsafeBytes(of: &value) { bufferPtr in
            _ = try? testEventFD.write(bufferPtr)
        }

        // Consume the completion from the poll operation
        let completion = try ring.blockingConsumeCompletion()
        XCTAssertEqual(completion.context, pollInContext)
        XCTAssertGreaterThan(completion.result, 0) // Poll should return mask of ready events
    }

    func testPollAddPollOut() throws {
        guard try uringEnabled() else { return }
        var ring = try IORing(queueDepth: 32, flags: [])

        // Test POLLOUT: Create a pipe to monitor for write readiness
        var pipeFDs: [Int32] = [0, 0]
        let pipeResult = pipe(&pipeFDs)
        XCTAssertEqual(pipeResult, 0)
        let writeFD = FileDescriptor(rawValue: pipeFDs[1])
        let readFD = FileDescriptor(rawValue: pipeFDs[0])
        defer {
            // Clean up
            try! writeFD.close()
            try! readFD.close()
        }
        let pollOutContext: UInt64 = 43

        // Submit a pollAdd request to monitor for POLLOUT events (ready for writing)
        // Pipes are typically ready for writing when empty
        let enqueuedOut = try ring.submit(linkedRequests:
            .pollAdd(writeFD, pollEvents: .pollout, isMultiShot: false, context: pollOutContext))
        XCTAssert(enqueuedOut)

        // Consume the completion from the poll operation
        let completionOut = try ring.blockingConsumeCompletion()
        XCTAssertEqual(completionOut.context, pollOutContext)
        XCTAssertGreaterThan(completionOut.result, 0) // Poll should return mask of ready events
    }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
