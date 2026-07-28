#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import XCTest
import CSystem //for eventfd
#if canImport(Glibc)
import Glibc // for errno
#elseif canImport(Musl)
import Musl  // for errno
#endif

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

// Cache `isUringEnabled()`. The probe is complex and the answer doesn't change
// during a test run.
let uringEnabled: Bool = {
    do {
        return try isUringEnabled()
    } catch {
        return false
    }
}()

let failureMessage = "Runtime environment does not support IORing."

func isUringEnabled() throws -> Bool {
    // Even if the kernel supports io_uring, the SystemPackage build may have
    // been compiled against older kernel headers that lack features it needs
    // (gated on IORING_TIMEOUT_BOOTTIME in CSystem); in that configuration
    // IORing.init throws ENOTSUP. Treat that as disabled so tests skip cleanly
    // instead of failing.
    do throws(Errno) {
        _ = try IORing(queueDepth: 1, flags: [])
    } catch {
        switch error {
        case .notSupported, .noFunction, .invalidArgument,
             .notPermitted, .permissionDenied:
            return false
        default:
            throw error
        }
    }

    // The ideal test uses /proc/sys/kernel/io_uring_disabled (Linux >= 6.6).
    if let fd = try? FileDescriptor.open(
        "/proc/sys/kernel/io_uring_disabled", .readOnly)
    {
        defer { try? fd.close() }
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1, alignment: 1)
        defer { buffer.deallocate() }
        let n = try fd.read(into: buffer)
        return n == 1 && (buffer.load(as: UInt8.self) == UInt8(ascii: "0"))
    }

    // Fallback for older kernels: simply attempt io_uring_setup.
    //   - ENOSYS  -> syscall doesn't exist (Linux < 5.1) -> disabled.
    //   - EPERM or EACCES -> treat as disabled
    //   - propagate any other error.
    var params = io_uring_params()
    let raw = io_uring_setup(1, &params)
    if raw < 0 {
        let err = Errno(rawValue: errno)
        switch err {
        case .noFunction, .notPermitted, .permissionDenied:
            return false
        default:
            throw err
        }
    }
    try? FileDescriptor(rawValue: raw).close()
    return true
}

final class IORingTests: XCTestCase {
    func testIsUringEnabled() throws {
        // If `isUringEnabled()` throws, it is incomplete in some way.
        let enabled = try isUringEnabled()
        if !enabled {
            print("IORing tests will be skipped.")
        }
    }

    func testInit() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        _ = try IORing(queueDepth: 32, flags: [])
    }

    func testNop() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
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
        try XCTSkipIf(!uringEnabled, failureMessage)
        var ring: IORing = try IORing(queueDepth: 1)
        let enqueued = ring.prepare(linkedRequests: .nop(), .nop())
        XCTAssertFalse(enqueued)
    }

    // Exercises opening, reading, closing, registered files, registered buffers, and eventfd
    func testOpenReadAndWriteFixedFile() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
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
        let nonRingFD = try FileDescriptor.open(path, .readOnly)
        let bytesRead = try nonRingFD.read(into: rawBuffer)
        XCTAssert(bytesRead == 13)
        let result2 = String(cString: rawBuffer.assumingMemoryBound(to: CChar.self).baseAddress!)
        XCTAssertEqual(result2, "Hello, World!")
        try cleanUpHelloWorldFile(parent)
        efdBuf.deallocate()
        rawBuffer.deallocate()
    }

    // Prior to the fix this is testing, prepare() escaped a pointer obtained
    // inside `path.withPlatformString { ... }` into the SQE and dropped the
    // owning FilePath before submit, so io_uring_enter handed the kernel a
    // dangling pointer. Here we deliberately let the FilePath go out of scope
    // between prepare and submit, then churn the heap to make UAFs observable.
    func testPathBufferLifetimeAcrossPrepareSubmit() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        let (parent, _) = try makeHelloWorldFile()
        var ring = try IORing(queueDepth: 6)

        func enqueueOpen() {
            let path: FilePath = "/tmp/IORingTests/test.txt"
            let ok = ring.prepare(request: .open(path, in: parent, mode: .readOnly))
            XCTAssertTrue(ok)
        }
        enqueueOpen()

        var churn: [UnsafeMutableRawBufferPointer] = []
        for _ in 0..<256 {
            let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: 64, alignment: 1)
            memset(buf.baseAddress!, 0x41, 64)
            churn.append(buf)
        }
        for buf in churn { buf.deallocate() }
        churn.removeAll()

        try ring.submitPreparedRequests()
        let completion = try ring.blockingConsumeCompletion()
        XCTAssertGreaterThanOrEqual(
            completion.result, 0,
            "open should succeed; got \(completion.result)")

        if completion.result >= 0 {
            let fd = FileDescriptor(rawValue: Int32(completion.result))
            try fd.close()
        }
        try cleanUpHelloWorldFile(parent)
    }
  
    func testPathBufferLifetimeAcrossLinkedRequests() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        let (parent, _) = try makeHelloWorldFile()
        let rawBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 13, alignment: 16)
        var ring = try setupTestRing(depth: 6, fileSlots: 1, buffers: [rawBuffer])

        func enqueueLinkedReadback() {
            let path: FilePath = "/tmp/IORingTests/test.txt"
            let ok = ring.prepare(linkedRequests:
                .open(path, in: parent, into: ring.registeredFileSlots[0], mode: .readOnly),
                .read(ring.registeredFileSlots[0], into: ring.registeredBuffers[0]),
                .close(ring.registeredFileSlots[0]))
            XCTAssertTrue(ok)
        }
        enqueueLinkedReadback()

        var churn: [UnsafeMutableRawBufferPointer] = []
        for _ in 0..<256 {
            let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: 64, alignment: 1)
            memset(buf.baseAddress!, 0x41, 64)
            churn.append(buf)
        }
        for buf in churn { buf.deallocate() }

        try ring.submitPreparedRequests()
        _ = try ring.blockingConsumeCompletion() // open
        _ = try ring.blockingConsumeCompletion() // read
        _ = try ring.blockingConsumeCompletion() // close

        let result = String(cString: rawBuffer.assumingMemoryBound(to: CChar.self).baseAddress!)
        XCTAssertEqual(result, "Hello, World!")

        try cleanUpHelloWorldFile(parent)
        rawBuffer.deallocate()
    }

    // Timeout test for `blockingConsumeCompletion(timeout:)`:
    func testBlockingConsumeCompletionWithTimeoutOnIdleRing() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        let ring = try IORing(queueDepth: 4, flags: [])
        try XCTSkipIf(
            !ring.supportedFeatures.contains(.extendedArguments),
            "Kernel < 5.11: timeouts in io_uring_enter aren't supported."
        )

        let clock = ContinuousClock()
        let start = clock.now

        var thrown: Errno? = nil
        do throws(Errno) {
            _ = try ring.blockingConsumeCompletion(timeout: .milliseconds(100))
            XCTFail("expected timeout, got a completion on an idle ring")
        } catch {
            thrown = error
        }

        let elapsed = start.duration(to: clock.now)

        XCTAssertEqual(thrown, .timeout)
        XCTAssertGreaterThanOrEqual(elapsed, .milliseconds(50))
    }

    func testRegisterEventFDTwiceThrows() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        var ring = try IORing(queueDepth: 4)
        let efd = FileDescriptor(rawValue: eventfd(0, Int32(EFD_SEMAPHORE)))
        defer { try? efd.close() }

        try ring.registerEventFD(efd)
        do throws(Errno) {
            try ring.registerEventFD(efd) // second registration -> EBUSY
            XCTFail("expected second registerEventFD to throw")
        } catch {
            XCTAssertEqual(error, .resourceBusy)
        }
    }

    func testSubmitOnDisabledRingThrows() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        var ring = try IORing(queueDepth: 4, flags: [.startDisabled])

        do throws(Errno) {
            _ = try ring.submit(linkedRequests: .nop())
            XCTFail("expected submit on a disabled ring to throw")
        } catch {
            XCTAssertEqual(error, Errno(rawValue: EBADFD))
        }
    }

    func testPollAddPollIn() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
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
            .pollAdd(testEventFD, pollEvents: .pollIn, isMultiShot: false, context: pollInContext))
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
        try XCTSkipIf(!uringEnabled, failureMessage)
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
            .pollAdd(writeFD, pollEvents: .pollOut, isMultiShot: false, context: pollOutContext))
        XCTAssert(enqueuedOut)

        // Consume the completion from the poll operation
        let completionOut = try ring.blockingConsumeCompletion()
        XCTAssertEqual(completionOut.context, pollOutContext)
        XCTAssertGreaterThan(completionOut.result, 0) // Poll should return mask of ready events
    }

    // Similar to the multishot example in the documentation for
    // `pollAdd(_:pollEvents:isMultiShot:context:)`: arm a multishot poll,
    // then consume completions for as long as they carry `.moreCompletions`.
    func testPollAddMultiShotRearmsAcrossEvents() throws {
        try XCTSkipIf(!uringEnabled, failureMessage)
        var ring = try IORing(queueDepth: 32, flags: [])

        // Every wait below has a timeout, so that a poll that fails to fire
        // causes a test failure.
        try XCTSkipIf(
            !ring.supportedFeatures.contains(.extendedArguments),
            "Kernel < 5.11: timeouts in io_uring_enter aren't supported."
        )

        var pipeFDs: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&pipeFDs), 0)
        let readFD = FileDescriptor(rawValue: pipeFDs[0])
        let writeFD = FileDescriptor(rawValue: pipeFDs[1])
        defer {
            try? readFD.close()
            try? writeFD.close()
        }

        func writeByte() throws {
            var byte: UInt8 = 1
            try withUnsafeBytes(of: &byte) {
                try XCTAssertEqual(writeFD.write($0), 1)
            }
        }

        func readByte() throws {
            var scratch: UInt8 = 0
            try withUnsafeMutableBytes(of: &scratch) {
                try XCTAssertEqual(readFD.read(into: $0), 1)
            }
        }

        let context: UInt64 = 44
        let pollIn = Int32(IORing.Request.PollEvents.pollIn.rawValue)

        let pollRequest = IORing.Request.pollAdd(
            readFD, pollEvents: .pollIn, isMultiShot: true, context: context
        )
        let enqueued = try ring.submit(linkedRequests: pollRequest)
        XCTAssert(enqueued)

        try writeByte()
        let first = try ring.blockingConsumeCompletion(timeout: .seconds(1))
        // Kernels before 5.13 reject IORING_POLL_ADD_MULTI
        try XCTSkipIf(
            first.result == -EINVAL,
            "Kernel < 5.13: multishot poll is unsupported."
        )
        XCTAssertEqual(first.context, context)
        XCTAssertNotEqual(
            first.result & pollIn, 0, "expected POLLIN in the result mask"
        )
        XCTAssert(first.flags.contains(.moreCompletions))

        // Drain the pipe, then any extra completions.
        try readByte()
        while ring.tryConsumeCompletion() != nil {}

        try writeByte()
        // This written byte will only be reported by a re-armed poll.
        let second = try ring.blockingConsumeCompletion(timeout: .seconds(1))
        XCTAssertEqual(second.context, context)
        XCTAssertNotEqual(
            second.result & pollIn, 0, "expected POLLIN in the result mask"
        )

        // Drain again
        try readByte()
        while ring.tryConsumeCompletion() != nil {}

        // Cancel to end the multishot poll.
        try XCTAssert(
            ring.submit(linkedRequests: .cancel(.all, matchingContext: context))
        )
        var terminal: (result: Int32, flags: IORing.Completion.Flags)? = nil
        var observed: [(context: UInt64, result: Int32, flags: UInt32)] = []
        // The cancel posts a completion of its own under a different context,
        // and the two may land a moment apart, so retry briefly rather than
        // draining exactly once.
        for _ in 0..<100 where terminal == nil {
            while let completion = ring.tryConsumeCompletion() {
                observed.append(
                    (
                        completion.context,
                        completion.result,
                        completion.flags.rawValue
                    )
                )
                if completion.context == context {
                    terminal = (completion.result, completion.flags)
                }
            }
            if terminal == nil { usleep(1000) }
        }
        XCTAssertNotNil(
            terminal,
            "no terminal completion for the cancelled poll; "
                + "completions seen: \(observed)"
        )
        if let terminal {
            XCTAssertEqual(terminal.result, -ECANCELED)
            XCTAssertFalse(
                terminal.flags.contains(.moreCompletions),
                "poll kept its armed state after being cancelled"
            )
        }
    }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
