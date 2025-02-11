@_implementationOnly import CSystem
import Glibc  // needed for mmap
import Synchronization

import struct CSystem.io_uring_sqe

// XXX: this *really* shouldn't be here. oh well.
extension UnsafeMutableRawPointer {
    func advanced(by offset: UInt32) -> UnsafeMutableRawPointer {
        return advanced(by: Int(offset))
    }
}

// all pointers in this struct reference kernel-visible memory
@usableFromInline struct SQRing: ~Copyable {
    let kernelHead: UnsafePointer<Atomic<UInt32>>
    let kernelTail: UnsafePointer<Atomic<UInt32>>
    var userTail: UInt32

    // from liburing: the kernel should never change these
    // might change in the future with resizable rings?
    let ringMask: UInt32
    // let ringEntries: UInt32 - absorbed into array.count

    // ring flags bitfield
    // currently used by the kernel only in SQPOLL mode to indicate
    // when the polling thread needs to be woken up
    let flags: UnsafePointer<Atomic<UInt32>>

    // ring array
    // maps indexes between the actual ring and the submissionQueueEntries list,
    // allowing the latter to be used as a kind of freelist with enough work?
    // currently, just 1:1 mapping (0..<n)
    let array: UnsafeMutableBufferPointer<UInt32>
}

struct CQRing: ~Copyable {
    let kernelHead: UnsafePointer<Atomic<UInt32>>
    let kernelTail: UnsafePointer<Atomic<UInt32>>

    // TODO: determine if this is actually used
    var userHead: UInt32

    let ringMask: UInt32

    let cqes: UnsafeBufferPointer<io_uring_cqe>
}

internal final class ResourceManager<T>: @unchecked Sendable {
    typealias Resource = T

    struct Resources {
        let resourceList: UnsafeMutableBufferPointer<T>
        var freeList: [Int]  //TODO: bitvector?
    }

    let mutex: Mutex<Resources>

    init(_ res: UnsafeMutableBufferPointer<T>) {
        mutex = Mutex(
            Resources(
                resourceList: res,
                freeList: [Int](res.indices)
            ))
    }

    func getResource() -> IOResource<T>? {
        mutex.withLock { resources in
            if let index = resources.freeList.popLast() {
                return IOResource(
                    resource: resources.resourceList[index],
                    index: index,
                    manager: self
                )
            } else {
                return nil
            }
        }
    }

    func releaseResource(index: Int) {
        mutex.withLock { resources in
            resources.freeList.append(index)
        }
    }
}

public class IOResource<T> {
    typealias Resource = T
    @usableFromInline let resource: T
    @usableFromInline let index: Int
    let manager: ResourceManager<T>

    internal init(
        resource: T,
        index: Int,
        manager: ResourceManager<T>
    ) {
        self.resource = resource
        self.index = index
        self.manager = manager
    }

    func withResource() {

    }

    deinit {
        manager.releaseResource(index: self.index)
    }
}

public typealias IORingFileSlot = IOResource<UInt32>
public typealias IORingBuffer = IOResource<iovec>

extension IORingFileSlot {
    public var unsafeFileSlot: Int {
        return index
    }
}
extension IORingBuffer {
    public var unsafeBuffer: UnsafeMutableRawBufferPointer {
        return .init(start: resource.iov_base, count: resource.iov_len)
    }
}

@inlinable @inline(__always)
internal func _writeRequest(
    _ request: __owned RawIORequest, ring: inout SQRing,
    submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>
)
    -> Bool
{
    let entry = _blockingGetSubmissionEntry(
        ring: &ring, submissionQueueEntries: submissionQueueEntries)
    entry.pointee = request.rawValue
    return true
}

@inlinable @inline(__always)
internal func _blockingGetSubmissionEntry(
    ring: inout SQRing, submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>
) -> UnsafeMutablePointer<
    io_uring_sqe
> {
    while true {
        if let entry = _getSubmissionEntry(
            ring: &ring,
            submissionQueueEntries: submissionQueueEntries
        ) {
            return entry
        }
        // TODO: actually block here instead of spinning
    }

}

//TODO: omitting signal mask for now
//Tell the kernel that we've submitted requests and/or are waiting for completions
internal func _enter(
    ringDescriptor: Int32,
    numEvents: UInt32,
    minCompletions: UInt32,
    flags: UInt32
) throws -> Int32 {
    // Ring always needs enter right now;
    // TODO: support SQPOLL here
    while true {
        let ret = io_uring_enter(ringDescriptor, numEvents, minCompletions, flags, nil)
        // error handling:
        //     EAGAIN / EINTR (try again),
        //     EBADF / EBADFD / EOPNOTSUPP / ENXIO
        //     (failure in ring lifetime management, fatal),
        //     EINVAL (bad constant flag?, fatal),
        //     EFAULT (bad address for argument from library, fatal)
        if ret == -EAGAIN || ret == -EINTR {
            //TODO: should we wait a bit on AGAIN?
            continue
        } else if ret < 0 {
            fatalError(
                "fatal error in submitting requests: " + Errno(rawValue: -ret).debugDescription
            )
        } else {
            return ret
        }
    }
}

internal func _submitRequests(ring: borrowing SQRing, ringDescriptor: Int32) throws {
    let flushedEvents = _flushQueue(ring: ring)
    _ = try _enter(
        ringDescriptor: ringDescriptor, numEvents: flushedEvents, minCompletions: 0, flags: 0)
}

internal func _getUnconsumedSubmissionCount(ring: borrowing SQRing) -> UInt32 {
    return ring.userTail - ring.kernelHead.pointee.load(ordering: .acquiring)
}

internal func _getUnconsumedCompletionCount(ring: borrowing CQRing) -> UInt32 {
    return ring.kernelTail.pointee.load(ordering: .acquiring)
        - ring.kernelHead.pointee.load(ordering: .acquiring)
}

//TODO: pretty sure this is supposed to do more than it does
internal func _flushQueue(ring: borrowing SQRing) -> UInt32 {
    ring.kernelTail.pointee.store(
        ring.userTail, ordering: .releasing
    )
    return _getUnconsumedSubmissionCount(ring: ring)
}

@usableFromInline @inline(__always)
internal func _getSubmissionEntry(
    ring: inout SQRing, submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>
) -> UnsafeMutablePointer<
    io_uring_sqe
>? {
    let next = ring.userTail &+ 1  //this is expected to wrap

    // FEAT: smp load when SQPOLL in use (not in MVP)
    let kernelHead = ring.kernelHead.pointee.load(ordering: .acquiring)

    // FEAT: 128-bit event support (not in MVP)
    if next - kernelHead <= ring.array.count {
        // let sqe =  &sq->sqes[(sq->sqe_tail & sq->ring_mask) << shift];
        let sqeIndex = Int(
            ring.userTail & ring.ringMask
        )

        let sqe = submissionQueueEntries
            .baseAddress.unsafelyUnwrapped
            .advanced(by: sqeIndex)

        ring.userTail = next
        return sqe
    }
    return nil
}

public struct IORing: ~Copyable {
    let ringFlags: UInt32
    let ringDescriptor: Int32

    @usableFromInline var submissionRing: SQRing
    // FEAT: set this eventually
    let submissionPolling: Bool = false

    let completionRing: CQRing

    @usableFromInline let submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>

    // kept around for unmap / cleanup
    let ringSize: Int
    let ringPtr: UnsafeMutableRawPointer

    var registeredFiles: ResourceManager<UInt32>?
    var registeredBuffers: ResourceManager<iovec>?

    public init(queueDepth: UInt32) throws {
        var params = io_uring_params()

        ringDescriptor = withUnsafeMutablePointer(to: &params) {
            return io_uring_setup(queueDepth, $0)
        }

        if params.features & IORING_FEAT_SINGLE_MMAP == 0
            || params.features & IORING_FEAT_NODROP == 0
        {
            close(ringDescriptor)
            // TODO: error handling
            throw IORingError.missingRequiredFeatures
        }

        if ringDescriptor < 0 {
            // TODO: error handling
        }

        let submitRingSize =
            params.sq_off.array
            + params.sq_entries * UInt32(MemoryLayout<UInt32>.size)

        let completionRingSize =
            params.cq_off.cqes
            + params.cq_entries * UInt32(MemoryLayout<io_uring_cqe>.size)

        ringSize = Int(max(submitRingSize, completionRingSize))

        ringPtr = mmap(
            /* addr: */ nil,
            /* len: */ ringSize,
            /* prot: */ PROT_READ | PROT_WRITE,
            /* flags: */ MAP_SHARED | MAP_POPULATE,
            /* fd: */ ringDescriptor,
            /* offset: */ __off_t(IORING_OFF_SQ_RING)
        )

        if ringPtr == MAP_FAILED {
            perror("mmap")
            // TODO: error handling
            fatalError("mmap failed in ring setup")
        }

        let submissionRing = SQRing(
            kernelHead: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.sq_off.head)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            kernelTail: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.sq_off.tail)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            userTail: 0,  // no requests yet
            ringMask: ringPtr.advanced(by: params.sq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            flags: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.sq_off.flags)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            array: UnsafeMutableBufferPointer(
                start: ringPtr.advanced(by: params.sq_off.array)
                    .assumingMemoryBound(to: UInt32.self),
                count: Int(
                    ringPtr.advanced(by: params.sq_off.ring_entries)
                        .assumingMemoryBound(to: UInt32.self).pointee)
            )
        )

        // fill submission ring array with 1:1 map to underlying SQEs
        for i in 0..<submissionRing.array.count {
            submissionRing.array[i] = UInt32(i)
        }

        // map the submission queue
        let sqes = mmap(
            /* addr: */ nil,
            /* len: */ Int(params.sq_entries) * MemoryLayout<io_uring_sqe>.size,
            /* prot: */ PROT_READ | PROT_WRITE,
            /* flags: */ MAP_SHARED | MAP_POPULATE,
            /* fd: */ ringDescriptor,
            /* offset: */ __off_t(IORING_OFF_SQES)
        )

        if sqes == MAP_FAILED {
            perror("mmap")
            // TODO: error handling
            fatalError("sqe mmap failed in ring setup")
        }

        submissionQueueEntries = UnsafeMutableBufferPointer(
            start: sqes!.assumingMemoryBound(to: io_uring_sqe.self),
            count: Int(params.sq_entries)
        )

        let completionRing = CQRing(
            kernelHead: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.cq_off.head)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            kernelTail: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.cq_off.tail)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            userHead: 0,  // no completions yet
            ringMask: ringPtr.advanced(by: params.cq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            cqes: UnsafeBufferPointer(
                start: ringPtr.advanced(by: params.cq_off.cqes)
                    .assumingMemoryBound(to: io_uring_cqe.self),
                count: Int(
                    ringPtr.advanced(by: params.cq_off.ring_entries)
                        .assumingMemoryBound(to: UInt32.self).pointee)
            )
        )

        self.submissionRing = submissionRing
        self.completionRing = completionRing

        self.ringFlags = params.flags
    }

    private func _blockingConsumeCompletionGuts(
        minimumCount: UInt32,
        extraArgs: UnsafeMutablePointer<io_uring_getevents_arg>? = nil,
        consumer: (IOCompletion?, IORingError?, Bool) throws -> Void
    ) rethrows {
        var count = 0
        while let completion = _tryConsumeCompletion(ring: completionRing) {
            count += 1
            try consumer(completion, nil, false)
        }

        if count < minimumCount {
            while count < minimumCount {
                var sz = 0
                if extraArgs != nil {
                    sz = MemoryLayout<io_uring_getevents_arg>.size
                }
                let res = io_uring_enter2(
                    ringDescriptor,
                    0,
                    minimumCount,
                    IORING_ENTER_GETEVENTS,
                    extraArgs,
                    sz
                )
                // error handling:
                //     EAGAIN / EINTR (try again),
                //     EBADF / EBADFD / EOPNOTSUPP / ENXIO
                //     (failure in ring lifetime management, fatal),
                //     EINVAL (bad constant flag?, fatal),
                //     EFAULT (bad address for argument from library, fatal)
                //     EBUSY (not enough space for events; implies events filled
                //            by kernel between kernelTail load and now)
                if res >= 0 || res == -EBUSY {
                    break
                } else if res == -EAGAIN || res == -EINTR {
                    continue
                }
                fatalError(
                    "fatal error in receiving requests: "
                        + Errno(rawValue: -res).debugDescription
                )
                while let completion = _tryConsumeCompletion(ring: completionRing) {
                    try consumer(completion, nil, false)
                }
            }
            try consumer(nil, nil, true)
        }
    }

    internal func _blockingConsumeOneCompletion(
        extraArgs: UnsafeMutablePointer<io_uring_getevents_arg>? = nil
    ) throws -> IOCompletion {
        var result: IOCompletion? = nil
        try _blockingConsumeCompletionGuts(minimumCount: 1, extraArgs: extraArgs) {
            (completion, error, done) in
            if let error {
                throw error
            }
            if let completion {
                result = completion
            }
        }
        return result.unsafelyUnwrapped
    }

    public func blockingConsumeCompletion(
        timeout: Duration? = nil
    ) throws -> IOCompletion {
        if let timeout {
            var ts = __kernel_timespec(
                tv_sec: timeout.components.seconds,
                tv_nsec: timeout.components.attoseconds / 1_000_000_000
            )
            return try withUnsafePointer(to: &ts) { tsPtr in
                var args = io_uring_getevents_arg(
                    sigmask: 0,
                    sigmask_sz: 0,
                    pad: 0,
                    ts: UInt64(UInt(bitPattern: tsPtr))
                )
                return try _blockingConsumeOneCompletion(extraArgs: &args)
            }
        } else {
            return try _blockingConsumeOneCompletion()
        }
    }

    public func blockingConsumeCompletions(
        minimumCount: UInt32 = 1,
        timeout: Duration? = nil,
        consumer: (IOCompletion?, IORingError?, Bool) throws -> Void
    ) throws {
        if let timeout {
            var ts = __kernel_timespec(
                tv_sec: timeout.components.seconds,
                tv_nsec: timeout.components.attoseconds / 1_000_000_000
            )
            return try withUnsafePointer(to: &ts) { tsPtr in
                var args = io_uring_getevents_arg(
                    sigmask: 0,
                    sigmask_sz: 0,
                    pad: 0,
                    ts: UInt64(UInt(bitPattern: tsPtr))
                )
                try _blockingConsumeCompletionGuts(
                    minimumCount: minimumCount, extraArgs: &args, consumer: consumer)
            }
        } else {
            try _blockingConsumeCompletionGuts(minimumCount: minimumCount, consumer: consumer)
        }
    }

    // public func peekNextCompletion() -> IOCompletion {

    // }

    public func tryConsumeCompletion() -> IOCompletion? {
        return _tryConsumeCompletion(ring: completionRing)
    }

    func _tryConsumeCompletion(ring: borrowing CQRing) -> IOCompletion? {
        let tail = ring.kernelTail.pointee.load(ordering: .acquiring)
        let head = ring.kernelHead.pointee.load(ordering: .acquiring)

        if tail != head {
            // 32 byte copy - oh well
            let res = ring.cqes[Int(head & ring.ringMask)]
            ring.kernelHead.pointee.store(head &+ 1, ordering: .releasing)
            return IOCompletion(rawValue: res)
        }

        return nil
    }

    internal func handleRegistrationResult(_ result: Int32) throws {
        //TODO: error handling
    }

    public mutating func registerEventFD(ring: inout IORing, _ descriptor: FileDescriptor) throws {
        var rawfd = descriptor.rawValue
        let result = withUnsafePointer(to: &rawfd) { fdptr in
            return io_uring_register(
                ring.ringDescriptor,
                IORING_REGISTER_EVENTFD,
                UnsafeMutableRawPointer(mutating: fdptr),
                1
            )
        }
        try handleRegistrationResult(result)
    }

    public mutating func unregisterEventFD(ring: inout IORing) throws {
        let result = io_uring_register(
            ring.ringDescriptor,
            IORING_UNREGISTER_EVENTFD,
            nil,
            0
        )
        try handleRegistrationResult(result)
    }

    public mutating func registerFiles(count: UInt32) {
        guard self.registeredFiles == nil else { fatalError() }
        let fileBuf = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: Int(count))
        fileBuf.initialize(repeating: UInt32.max)
        io_uring_register(
            self.ringDescriptor,
            IORING_REGISTER_FILES,
            fileBuf.baseAddress!,
            count
        )
        // TODO: error handling
        self.registeredFiles = ResourceManager(fileBuf)
    }

    public func unregisterFiles() {
        fatalError("failed to unregister files")
    }

    public func getFile() -> IORingFileSlot? {
        return self.registeredFiles?.getResource()
    }

    public mutating func registerBuffers(bufSize: UInt32, count: UInt32) {
        let iovecs = UnsafeMutableBufferPointer<iovec>.allocate(capacity: Int(count))
        let intBufSize = Int(bufSize)
        for i in 0..<iovecs.count {
            // TODO: mmap instead of allocate here, because there are
            // certain restrictions about buffer memory behavior
            let buf = UnsafeMutableRawBufferPointer.allocate(
                byteCount: intBufSize, alignment: 16384)
            iovecs[i] = iovec(iov_base: buf.baseAddress!, iov_len: buf.count)
        }
        io_uring_register(
            self.ringDescriptor,
            IORING_REGISTER_BUFFERS,
            iovecs.baseAddress!,
            count
        )
        // TODO: error handling
        self.registeredBuffers = ResourceManager(iovecs)
    }

    public func getBuffer() -> IORingBuffer? {
        return self.registeredBuffers?.getResource()
    }

    public func unregisterBuffers() {
        fatalError("failed to unregister buffers: TODO")
    }

    public func submitRequests() throws {
        try _submitRequests(ring: submissionRing, ringDescriptor: ringDescriptor)
    }

    @inlinable @inline(__always)
    public mutating func writeRequest(_ request: __owned IORequest) -> Bool {
        var raw: RawIORequest? = request.makeRawRequest()
        return _writeRequest(
            raw.take()!, ring: &submissionRing, submissionQueueEntries: submissionQueueEntries)
    }

    deinit {
        munmap(ringPtr, ringSize)
        munmap(
            UnsafeMutableRawPointer(submissionQueueEntries.baseAddress!),
            submissionQueueEntries.count * MemoryLayout<io_uring_sqe>.size
        )
        close(ringDescriptor)
    }
}
