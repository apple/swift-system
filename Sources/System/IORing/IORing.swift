#if compiler(>=6.2)
#if os(Linux)

import CSystem
// needed for mmap
#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif
import Synchronization

//This was #defines in older headers, so we redeclare it to get a consistent import
internal enum RegistrationOps: UInt32 {
	case registerBuffers		= 0
	case unregisterBuffers		= 1
	case registerFiles			= 2
	case unregisterFiles		= 3
	case registerEventFD		= 4
	case unregisterEventFD		= 5
	case registerFilesUpdate	= 6
	case registerEventFDAsync	= 7
	case registerProbe			= 8
	case registerPersonality	= 9
	case unregisterPersonality	= 10
}

extension UnsafeMutableRawPointer {
    func advanced(by offset: UInt32) -> UnsafeMutableRawPointer {
        return advanced(by: Int(offset))
    }
}

extension UnsafeMutableRawBufferPointer {
    func to_iovec() -> iovec {
        iovec(iov_base: baseAddress, iov_len: count)
    }
}

// all pointers in this struct reference kernel-visible memory
@usableFromInline struct SQRing: ~Copyable {
    @usableFromInline let kernelHead: UnsafePointer<Atomic<UInt32>>
    @usableFromInline let kernelTail: UnsafePointer<Atomic<UInt32>>
    @usableFromInline var userTail: UInt32

    // from liburing: the kernel should never change these
    // might change in the future with resizable rings?
    @usableFromInline let ringMask: UInt32
    // let ringEntries: UInt32 - absorbed into array.count

    // ring flags bitfield
    // currently used by the kernel only in SQPOLL mode to indicate
    // when the polling thread needs to be woken up
    @usableFromInline let flags: UnsafePointer<Atomic<UInt32>>

    // ring array
    // maps indexes between the actual ring and the submissionQueueEntries list,
    // allowing the latter to be used as a kind of freelist with enough work?
    // currently, just 1:1 mapping (0..<n)
    @usableFromInline let array: UnsafeMutableBufferPointer<UInt32>
}

@usableFromInline struct CQRing: ~Copyable {
    @usableFromInline let kernelHead: UnsafePointer<Atomic<UInt32>>
    @usableFromInline let kernelTail: UnsafePointer<Atomic<UInt32>>

    @usableFromInline let ringMask: UInt32

    @usableFromInline let cqes: UnsafeBufferPointer<io_uring_cqe>
}

@inline(__always) @inlinable
internal func _tryWriteRequest(
    _ request: __owned RawIORequest, ring: inout SQRing,
    submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>
)
    -> Bool
{
    if let entry = _getSubmissionEntry(
        ring: &ring, submissionQueueEntries: submissionQueueEntries) {
        entry.pointee = request.rawValue
        return true
    }
    return false
}

//TODO: omitting signal mask for now
//Tell the kernel that we've submitted requests and/or are waiting for completions
@inlinable
internal func _enter(
    ring: borrowing SQRing,
    ringDescriptor: Int32,
    numEvents: UInt32,
    minCompletions: UInt32,
    flags: UInt32
) throws(Errno) -> Int32 {
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
            throw(Errno(rawValue: -ret))
        } else if _getSubmissionQueueCount(ring: ring) > 0 {
            // See https://github.com/axboe/liburing/issues/309, in some cases not all pending requests are submitted
            continue
        } else {
            return ret
        }
    }
}

@inlinable
internal func _submitRequests(ring: borrowing SQRing, ringDescriptor: Int32) throws(Errno) {
    let flushedEvents = _flushQueue(ring: ring)
    _ = try _enter(
        ring: ring, ringDescriptor: ringDescriptor, numEvents: flushedEvents, minCompletions: 0, flags: 0)
}

@inlinable
internal func _getSubmissionQueueCount(ring: borrowing SQRing) -> UInt32 {
    return ring.userTail - ring.kernelHead.pointee.load(ordering: .acquiring)
}

@inlinable
internal func _getRemainingSubmissionQueueCapacity(ring: borrowing SQRing) -> UInt32 {
    return UInt32(truncatingIfNeeded: ring.array.count) - _getSubmissionQueueCount(ring: ring) 
}

@inlinable
internal func _getUnconsumedCompletionCount(ring: borrowing CQRing) -> UInt32 {
    return ring.kernelTail.pointee.load(ordering: .acquiring)
        - ring.kernelHead.pointee.load(ordering: .acquiring)
}

@inlinable
internal func _flushQueue(ring: borrowing SQRing) -> UInt32 {
    ring.kernelTail.pointee.store(
        ring.userTail, ordering: .releasing
    )
    return _getSubmissionQueueCount(ring: ring)
}

@inlinable
internal func _getSubmissionEntry(
    ring: inout SQRing, submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>
) -> UnsafeMutablePointer<
    io_uring_sqe
>? {
    let next = ring.userTail &+ 1  //this is expected to wrap

    let kernelHead: UInt32 = ring.kernelHead.pointee.load(ordering: .acquiring)

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

private func setUpRing(
    queueDepth: UInt32, flags: IORing.SetupFlags
) throws(Errno) -> 
    (params: io_uring_params, ringDescriptor: Int32, ringPtr: UnsafeMutableRawPointer?, ringSize: Int, submissionRingPtr: UnsafeMutableRawPointer?, submissionRingSize: Int, completionRingPtr: UnsafeMutableRawPointer?, completionRingSize: Int, sqes: UnsafeMutableRawPointer) {
    var params = io_uring_params()
    params.flags = flags.rawValue

    var err: Errno? = nil
    let ringDescriptor = withUnsafeMutablePointer(to: &params) {
        let result = io_uring_setup(queueDepth, $0)
        if result < 0 {
            err = Errno.current
        }
        return result
    }

    if let err {
        throw err
    }

    if params.features & IORING_FEAT_NODROP == 0
    {
        close(ringDescriptor)
        throw Errno.invalidArgument
    }

    let submitRingSize =
        params.sq_off.array
        + params.sq_entries * UInt32(MemoryLayout<UInt32>.size)

    let completionRingSize =
        params.cq_off.cqes
        + params.cq_entries * UInt32(MemoryLayout<io_uring_cqe>.size)

    let ringSize = Int(max(submitRingSize, completionRingSize))

    var ringPtr: UnsafeMutableRawPointer!
    var sqPtr: UnsafeMutableRawPointer!
    var cqPtr: UnsafeMutableRawPointer!

    if params.features & IORING_FEAT_SINGLE_MMAP != 0{
        ringPtr = mmap(
            /* addr: */ nil,
            /* len: */ ringSize,
            /* prot: */ PROT_READ | PROT_WRITE,
            /* flags: */ MAP_SHARED | MAP_POPULATE,
            /* fd: */ ringDescriptor,
            /* offset: */ __off_t(IORING_OFF_SQ_RING)
        )

        if ringPtr == MAP_FAILED {
            let errno = Errno.current
            close(ringDescriptor)
            throw errno
        }
    } else {
        sqPtr = mmap(
            /* addr: */ nil,
            /* len: */ Int(submitRingSize),
            /* prot: */ PROT_READ | PROT_WRITE,
            /* flags: */ MAP_SHARED | MAP_POPULATE,
            /* fd: */ ringDescriptor,
            /* offset: */ __off_t(IORING_OFF_SQ_RING)
        )

        if sqPtr == MAP_FAILED {
            let errno = Errno.current
            close(ringDescriptor)
            throw errno
        }

        cqPtr = mmap(
            /* addr: */ nil,
            /* len: */ Int(completionRingSize),
            /* prot: */ PROT_READ | PROT_WRITE,
            /* flags: */ MAP_SHARED | MAP_POPULATE,
            /* fd: */ ringDescriptor,
            /* offset: */ __off_t(IORING_OFF_CQ_RING)
        )

        if cqPtr == MAP_FAILED {
            let errno: Errno = Errno.current
            close(ringDescriptor)
            throw errno
        }
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
        let errno = Errno.current
        if ringPtr != nil {
            munmap(ringPtr, ringSize)
        } else {
            if sqPtr != nil {
                munmap(sqPtr, Int(submitRingSize))
            }
            if cqPtr != nil {
                munmap(cqPtr, Int(completionRingSize))
            }
        }
        close(ringDescriptor)
        throw errno
    }

    return (params: params, ringDescriptor: ringDescriptor, ringPtr: ringPtr, ringSize: ringSize, submissionRingPtr: sqPtr, submissionRingSize: Int(submitRingSize), completionRingPtr: cqPtr, completionRingSize: Int(completionRingSize), sqes: sqes!)
}

///IORing provides facilities for
/// * Registering and unregistering resources (files and buffers), an `io_uring` specific variation on Unix file IOdescriptors that improves their efficiency
/// * Registering and unregistering eventfds, which allow asynchronous waiting for completions
/// * Enqueueing IO requests
/// * Dequeueing IO completions
public struct IORing: ~Copyable {
    let ringFlags: UInt32
    @usableFromInline let ringDescriptor: Int32

    @usableFromInline var submissionRing: SQRing
    // FEAT: set this eventually
    let submissionPolling: Bool = false

    @usableFromInline let completionRing: CQRing

    @usableFromInline let submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>

    // kept around for unmap / cleanup. TODO: we can save a few words of memory by figuring out how to handle cleanup for non-IORING_FEAT_SINGLE_MMAP better
    let ringSize: Int
    let ringPtr: UnsafeMutableRawPointer?
    let submissionRingSize: Int
    let submissionRingPtr: UnsafeMutableRawPointer?
    let completionRingSize: Int
    let completionRingPtr: UnsafeMutableRawPointer?

    @usableFromInline var _registeredFiles: [UInt32]
    @usableFromInline var _registeredBuffers: [iovec]

    var features = Features(rawValue: 0)
    
    /// RegisteredResource is used via its typealiases, RegisteredFile and RegisteredBuffer. Registering file descriptors and buffers with the IORing allows for more efficient access to them.
    public struct RegisteredResource<T> {
        public typealias Resource = T
        @usableFromInline let resource: T
        public let index: Int

        @inlinable internal init(
            resource: T,
            index: Int
        ) {
            self.resource = resource
            self.index = index
        }
    }

    public typealias RegisteredFile = RegisteredResource<UInt32>
    public typealias RegisteredBuffer = RegisteredResource<iovec>

    /// SetupFlags represents configuration options to an IORing as it's being created
    public struct SetupFlags: OptionSet, RawRepresentable, Hashable {
        public var rawValue: UInt32

        @inlinable public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        @inlinable public static var pollCompletions: SetupFlags { .init(rawValue: UInt32(1) << 0) } //IORING_SETUP_IOPOLL
        @inlinable public static var pollSubmissions: SetupFlags { .init(rawValue: UInt32(1) << 1) } //IORING_SETUP_SQPOLL
        //TODO: figure out how to expose IORING_SETUP_SQ_AFF, IORING_SETUP_CQSIZE, IORING_SETUP_ATTACH_WQ
        @inlinable public static var clampMaxEntries: SetupFlags { .init(rawValue: UInt32(1) << 4) } //IORING_SETUP_CLAMP
        @inlinable public static var startDisabled: SetupFlags { .init(rawValue: UInt32(1) << 6) } //IORING_SETUP_R_DISABLED
        @inlinable public static var continueSubmittingOnError: SetupFlags { .init(rawValue: UInt32(1) << 7) } //IORING_SETUP_SUBMIT_ALL
        //TODO: do we want to expose IORING_SETUP_COOP_TASKRUN and IORING_SETUP_TASKRUN_FLAG?
        //public static var runTasksCooperatively: SetupFlags { .init(rawValue: UInt32(1) << 8) } //IORING_SETUP_COOP_TASKRUN
        //TODO: can we even do different size sqe/cqe? It requires a kernel feature, but how do we convince swift to let the types be different sizes?
        //internal static var use128ByteSQEs: SetupFlags { .init(rawValue: UInt32(1) << 10) } //IORING_SETUP_SQE128
        //internal static var use32ByteCQEs: SetupFlags { .init(rawValue: UInt32(1) << 11) } //IORING_SETUP_CQE32
        @inlinable public static var singleSubmissionThread: SetupFlags { .init(rawValue: UInt32(1) << 12) } //IORING_SETUP_SINGLE_ISSUER
        @inlinable public static var deferRunningTasks: SetupFlags { .init(rawValue: UInt32(1) << 13) } //IORING_SETUP_DEFER_TASKRUN
        //pretty sure we don't want to expose IORING_SETUP_NO_MMAP or IORING_SETUP_REGISTERED_FD_ONLY currently
        //TODO: should IORING_SETUP_NO_SQARRAY be the default? do we need to adapt anything to it?
    }

    /// Initializes an IORing with enough space for `queueDepth` prepared requests and completed operations
    public init(queueDepth: UInt32, flags: SetupFlags = []) throws(Errno) {
        let (params, tmpRingDescriptor, tmpRingPtr, tmpRingSize, tmpSQPtr, tmpSQSize, tmpCQPtr, tmpCQSize, sqes) = try setUpRing(queueDepth: queueDepth, flags: flags)
        // All throws need to be before initializing ivars here to avoid 
        // "error: conditional initialization or destruction of noncopyable types is not supported; 
        // this variable must be consistently in an initialized or uninitialized state through every code path"
        features = Features(rawValue: params.features)
        ringDescriptor = tmpRingDescriptor
        ringPtr = tmpRingPtr
        ringSize = tmpRingSize
        submissionRingPtr = tmpSQPtr
        submissionRingSize = tmpSQSize
        completionRingPtr = tmpCQPtr
        completionRingSize = tmpCQSize

        _registeredFiles = []
        _registeredBuffers = []
        submissionRing = SQRing(
            kernelHead: UnsafePointer<Atomic<UInt32>>(
                (ringPtr ?? submissionRingPtr!).advanced(by: params.sq_off.head)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            kernelTail: UnsafePointer<Atomic<UInt32>>(
                (ringPtr ?? submissionRingPtr!).advanced(by: params.sq_off.tail)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            userTail: 0,  // no requests yet
            ringMask: (ringPtr ?? submissionRingPtr!).advanced(by: params.sq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            flags: UnsafePointer<Atomic<UInt32>>(
                (ringPtr ?? submissionRingPtr!).advanced(by: params.sq_off.flags)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            array: UnsafeMutableBufferPointer(
                start: (ringPtr ?? submissionRingPtr!).advanced(by: params.sq_off.array)
                    .assumingMemoryBound(to: UInt32.self),
                count: Int(
                    (ringPtr ?? submissionRingPtr!).advanced(by: params.sq_off.ring_entries)
                        .assumingMemoryBound(to: UInt32.self).pointee)
            )
        )

        // fill submission ring array with 1:1 map to underlying SQEs
        for i in 0 ..< submissionRing.array.count {
            submissionRing.array[i] = UInt32(i)
        }

        submissionQueueEntries = UnsafeMutableBufferPointer(
            start: sqes.assumingMemoryBound(to: io_uring_sqe.self),
            count: Int(params.sq_entries)
        )

        completionRing = CQRing(
            kernelHead: UnsafePointer<Atomic<UInt32>>(
                (ringPtr ?? completionRingPtr!).advanced(by: params.cq_off.head)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            kernelTail: UnsafePointer<Atomic<UInt32>>(
                (ringPtr ?? completionRingPtr!).advanced(by: params.cq_off.tail)
                    .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            ringMask: (ringPtr ?? completionRingPtr!).advanced(by: params.cq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            cqes: UnsafeBufferPointer(
                start: (ringPtr ?? completionRingPtr!).advanced(by: params.cq_off.cqes)
                    .assumingMemoryBound(to: io_uring_cqe.self),
                count: Int(
                    (ringPtr ?? completionRingPtr!).advanced(by: params.cq_off.ring_entries)
                        .assumingMemoryBound(to: UInt32.self).pointee)
            )
        )
        self.ringFlags = params.flags
    }

    @inlinable
    internal func _blockingConsumeCompletionGuts<Err: Error>(
        minimumCount: UInt32,
        maximumCount: UInt32,
        extraArgs: UnsafeMutablePointer<swift_io_uring_getevents_arg>? = nil,
        consumer: (consuming IORing.Completion?, Errno?, Bool) throws(Err) -> Void
    ) throws(Err) {
        var count = 0
        while let completion = _tryConsumeCompletion(ring: completionRing) {
            count += 1
            if completion.result < 0 {
                try consumer(nil, Errno(rawValue: -completion.result), false)
            } else {
                try consumer(completion, nil, false)
            }
            if count == maximumCount {
                try consumer(nil, nil, true)
                return
            }
        }

        if count < minimumCount {
            while count < minimumCount {
                var sz = 0
                if extraArgs != nil {
                    sz = MemoryLayout<swift_io_uring_getevents_arg>.size
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
            }
            var count = 0
            while let completion = _tryConsumeCompletion(ring: completionRing) {
                count += 1
                if completion.result < 0 {
                    try consumer(nil, Errno(rawValue: -completion.result), false)
                } else {
                    try consumer(completion, nil, false)
                }
                if count == maximumCount {
                    break
                }
            }
            try consumer(nil, nil, true)
        }
    }

    @inlinable
    internal func _blockingConsumeOneCompletion(
        extraArgs: UnsafeMutablePointer<swift_io_uring_getevents_arg>? = nil
    ) throws(Errno) -> Completion {
        var result: Completion? = nil
        try _blockingConsumeCompletionGuts(minimumCount: 1, maximumCount: 1, extraArgs: extraArgs) {
            (completion: consuming Completion?, error, done) throws(Errno) in
            if let error {
                throw error
            }
            if let completion {
                result = consume completion
            }
        }
        return result.take()!
    }

    /// Synchronously waits for an operation to complete for up to `timeout` (or forever if not specified)
    @inlinable
    public func blockingConsumeCompletion(
        timeout: Duration? = nil
    ) throws(Errno) -> Completion {
        if let timeout {
            var ts = timespec(
                tv_sec: Int(timeout.components.seconds),
                tv_nsec: Int(timeout.components.attoseconds / 1_000_000_000)
            )
            return try withUnsafePointer(to: &ts) { (tsPtr) throws(Errno) -> Completion in
                var args = swift_io_uring_getevents_arg(
                    sigmask: 0,
                    sigmask_sz: 0,
                    min_wait_usec: 0,
                    ts: UInt64(UInt(bitPattern: tsPtr))
                )
                return try _blockingConsumeOneCompletion(extraArgs: &args)
            }
        } else {
            return try _blockingConsumeOneCompletion()
        }
    }

    /// Synchronously waits for `minimumCount` or more operations to complete for up to `timeout` (or forever if not specified). For each completed operation found, `consumer` is called to handle processing it
    @inlinable
    public func blockingConsumeCompletions<Err: Error>(
        minimumCount: UInt32 = 1,
        timeout: Duration? = nil,
        consumer: (consuming Completion?, Errno?, Bool) throws(Err) -> Void
    ) throws(Err) {
        if let timeout {
            var ts = timespec(
                tv_sec: Int(timeout.components.seconds),
                tv_nsec: Int(timeout.components.attoseconds / 1_000_000_000)
            )
            try withUnsafePointer(to: &ts) { (tsPtr) throws(Err) in
                var args = swift_io_uring_getevents_arg(
                    sigmask: 0,
                    sigmask_sz: 0,
                    min_wait_usec: 0,
                    ts: UInt64(UInt(bitPattern: tsPtr))
                )
                try _blockingConsumeCompletionGuts(
                    minimumCount: minimumCount, maximumCount: UInt32.max, extraArgs: &args,
                    consumer: consumer)
            }
        } else {
            try _blockingConsumeCompletionGuts(
                minimumCount: minimumCount, maximumCount: UInt32.max, consumer: consumer)
        }
    }

    // public func peekNextCompletion() -> IOCompletion {

    // }

    /// Takes a completed operation from the ring and returns it, if one is ready. Otherwise, returns nil.
    @inlinable
    public func tryConsumeCompletion() -> Completion? {
        return _tryConsumeCompletion(ring: completionRing)
    }

    @inlinable
    func _tryConsumeCompletion(ring: borrowing CQRing) -> Completion? {
        let tail = ring.kernelTail.pointee.load(ordering: .acquiring)
        let head = ring.kernelHead.pointee.load(ordering: .acquiring)

        if tail != head {
            // 32 byte copy - oh well
            let res = ring.cqes[Int(head & ring.ringMask)]
            ring.kernelHead.pointee.store(head &+ 1, ordering: .releasing)
            return Completion(rawValue: res)
        }

        return nil
    }

    /// Registers an event monitoring file descriptor with the ring. The file descriptor becomes readable whenever completions are ready to be dequeued. See `man eventfd(2)` for additional information.
    public mutating func registerEventFD(_ descriptor: FileDescriptor) throws(Errno) {
        var rawfd = descriptor.rawValue
        let result = withUnsafePointer(to: &rawfd) { fdptr in
            let result = io_uring_register(
                ringDescriptor,
                RegistrationOps.registerEventFD.rawValue,
                UnsafeMutableRawPointer(mutating: fdptr),
                1
            )
            return result >= 0 ? nil : Errno(rawValue: -result)
        }
        if let result {
            throw result
        }
    }

    /// Removes a registered event file descriptor from the ring
    public mutating func unregisterEventFD() throws(Errno) {
        let result = io_uring_register(
            ringDescriptor,
            RegistrationOps.unregisterEventFD.rawValue,
            nil,
            0
        )
        if result < 0 {
            throw Errno(rawValue: -result)
        }
    }

    /// Registers `count` files with the ring for later use in IO operations
    public mutating func registerFileSlots(count: Int) throws(Errno) -> RegisteredResources<RegisteredFile.Resource> {
        precondition(_registeredFiles.isEmpty)
        precondition(count < UInt32.max)
        let files = [UInt32](repeating: UInt32.max, count: count)

        let regResult = files.withUnsafeBufferPointer { bPtr in
            let result = io_uring_register(
                self.ringDescriptor,
                RegistrationOps.registerFiles.rawValue,
                UnsafeMutableRawPointer(mutating: bPtr.baseAddress!),
                UInt32(truncatingIfNeeded: count)
            )
            return result >= 0 ? nil : Errno(rawValue: -result)
        } 

        if let regResult {
            throw regResult
        }

        _registeredFiles = files
        return registeredFileSlots
    }

    /// Removes registered files from the ring
    public func unregisterFiles() throws {
            let result = io_uring_register(
            ringDescriptor,
            RegistrationOps.unregisterFiles.rawValue,
            nil,
            0
        )
        if result < 0 {
            throw Errno(rawValue: -result)
        }
    }

    /// Allows access to registered files by index
    @inlinable
    public var registeredFileSlots: RegisteredResources<RegisteredFile.Resource> {
        RegisteredResources(resources: _registeredFiles)
    }

    /// Registers buffers with the ring for later use in IO operations
    public mutating func registerBuffers(_ buffers: some Collection<UnsafeMutableRawBufferPointer>) throws(Errno)
        -> RegisteredResources<RegisteredBuffer.Resource>
    {
        precondition(buffers.count < UInt32.max)
        precondition(_registeredBuffers.isEmpty)
        let iovecs = buffers.map { $0.to_iovec() }
        let regResult = iovecs.withUnsafeBufferPointer { bPtr in
            let result = io_uring_register(
                self.ringDescriptor,
                RegistrationOps.registerBuffers.rawValue,
                UnsafeMutableRawPointer(mutating: bPtr.baseAddress!),
                UInt32(truncatingIfNeeded: buffers.count)
            )
            return result >= 0 ? nil : Errno(rawValue: -result)
        }

        if let regResult {
            throw regResult
        }

        _registeredBuffers = iovecs
        return registeredBuffers
    }

    /// Registers buffers with the ring for later use in IO operations
    @inlinable
    public mutating func registerBuffers(_ buffers: UnsafeMutableRawBufferPointer...) throws(Errno)
        -> RegisteredResources<RegisteredBuffer.Resource>
    {
        try registerBuffers(buffers)
    }

    /// A view of the registered files or buffers in a ring
    public struct RegisteredResources<T>: RandomAccessCollection {
        @usableFromInline let resources: [T]

        @inlinable public var startIndex: Int { 0 }
        @inlinable public var endIndex: Int { resources.endIndex }
        @inlinable init(resources: [T]) {
            self.resources = resources
        }
        @inlinable public subscript(position: Int) -> RegisteredResource<T> {
            RegisteredResource(resource: resources[position], index: position)
        }
        @inlinable public subscript(position: UInt16) -> RegisteredResource<T> {
            RegisteredResource(resource: resources[Int(position)], index: Int(position))
        }
    }

    /// Allows access to registered files by index
    @inlinable
    public var registeredBuffers: RegisteredResources<RegisteredBuffer.Resource> {
        RegisteredResources(resources: _registeredBuffers)
    }

    public func unregisterBuffers() throws {
        let result = io_uring_register(
            self.ringDescriptor,
            RegistrationOps.unregisterBuffers.rawValue,
            nil,
            0
        )
        guard result >= 0 else {
            throw Errno(rawValue: -result)
        }
    }

    /// Sends all prepared requests to the kernel for processing. Results will be delivered as completions, which can be dequeued from the ring.
    @inlinable
    public func submitPreparedRequests() throws(Errno) {
        try _submitRequests(ring: submissionRing, ringDescriptor: ringDescriptor)
    }

    /// Sends all prepared requests to the kernel for processing, and then dequeues at least `minimumCount` completions, waiting up to `timeout` for them to become available. `consumer` is called to process each completed IO operation as it becomes available.
    @inlinable
    public func submitPreparedRequestsAndConsumeCompletions<Err: Error>(
        minimumCount: UInt32 = 1,
        timeout: Duration? = nil,
        consumer: (consuming Completion?, Errno?, Bool) throws(Err) -> Void
    ) throws(Err) {
        //TODO: optimize this to one uring_enter
        do {
            try submitPreparedRequests()
        } catch (let e) {
            try consumer(nil, e, true)
        }
        try blockingConsumeCompletions(
            minimumCount: minimumCount,
            timeout: timeout,
            consumer: consumer
        )
    }

    /// Attempts to prepare an IO request for submission to the kernel. Returns false if no space is available to enqueue the request
    @inlinable
    public mutating func prepare(request: __owned Request) -> Bool {
        var raw: RawIORequest? = request.makeRawRequest()
        return _tryWriteRequest(
            raw.take()!, ring: &submissionRing, submissionQueueEntries: submissionQueueEntries)
    }

    /// Attempts to prepare a chain of linked IO requests for submission to the kernel. Returns false if not enough space is available to enqueue the request. If any linked operation fails, subsequent operations will be canceled. Linked operations always execute in order.
    @inlinable
    mutating func prepare(linkedRequests: some BidirectionalCollection<Request>) -> Bool {
        guard linkedRequests.count > 0 else {
            return true
        }
        let freeSQECount = _getRemainingSubmissionQueueCapacity(ring: submissionRing)
        guard freeSQECount >= linkedRequests.count else {
            return false
        }
        let last = linkedRequests.last!
        for req in linkedRequests.dropLast() {
            var raw = req.makeRawRequest()
            raw.linkToNextRequest()
            let successfullyAdded = _tryWriteRequest(
                raw, ring: &submissionRing, submissionQueueEntries: submissionQueueEntries)
            assert(successfullyAdded)
        }
        let successfullyAdded = _tryWriteRequest(
            last.makeRawRequest(), ring: &submissionRing,
            submissionQueueEntries: submissionQueueEntries)
        assert(successfullyAdded)
        return true
    }

    /// Prepares a sequence of requests for submission to the ring. Returns false if the submission queue doesn't have enough available space.
    @inlinable 
    public mutating func prepare(linkedRequests: Request...) -> Bool {
        prepare(linkedRequests: linkedRequests)
    }

    /// Prepares and submits a sequence of requests to the ring. Returns false if the submission queue doesn't have enough available space.
    @inlinable
    public mutating func submit(linkedRequests: Request...) throws(Errno) -> Bool {
        if !prepare(linkedRequests: linkedRequests) {
            return false
        }
        try submitPreparedRequests()
        return true
    }

    /// Describes which io_uring features are supported by the kernel this program is running on
    public struct Features: OptionSet, RawRepresentable, Hashable {
		public let rawValue: UInt32
		
		@inlinable public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
		
		//IORING_FEAT_SINGLE_MMAP is handled internally
		@inlinable public static var nonDroppingCompletions: Features { .init(rawValue: UInt32(1) << 1) } //IORING_FEAT_NODROP
		@inlinable public static var stableSubmissions: Features { .init(rawValue: UInt32(1) << 2) } //IORING_FEAT_SUBMIT_STABLE
		@inlinable public static var currentFilePosition: Features { .init(rawValue: UInt32(1) << 3) } //IORING_FEAT_RW_CUR_POS
		@inlinable public static var assumingTaskCredentials: Features { .init(rawValue: UInt32(1) << 4) } //IORING_FEAT_CUR_PERSONALITY
		@inlinable public static var fastPolling: Features { .init(rawValue: UInt32(1) << 5) } //IORING_FEAT_FAST_POLL
		@inlinable public static var epoll32BitFlags: Features { .init(rawValue: UInt32(1) << 6) } //IORING_FEAT_POLL_32BITS
		@inlinable public static var pollNonFixedFiles: Features { .init(rawValue: UInt32(1) << 7) } //IORING_FEAT_SQPOLL_NONFIXED
		@inlinable public static var extendedArguments: Features { .init(rawValue: UInt32(1) << 8) } //IORING_FEAT_EXT_ARG
		@inlinable public static var nativeWorkers: Features { .init(rawValue: UInt32(1) << 9) } //IORING_FEAT_NATIVE_WORKERS
		@inlinable public static var resourceTags: Features { .init(rawValue: UInt32(1) << 10) } //IORING_FEAT_RSRC_TAGS
		@inlinable public static var allowsSkippingSuccessfulCompletions: Features { .init(rawValue: UInt32(1) << 11) } //IORING_FEAT_CQE_SKIP
		@inlinable public static var improvedLinkedFiles: Features { .init(rawValue: UInt32(1) << 12) } //IORING_FEAT_LINKED_FILE
		@inlinable public static var registerRegisteredRings: Features { .init(rawValue: UInt32(1) << 13) } //IORING_FEAT_REG_REG_RING
		@inlinable public static var minimumTimeout: Features { .init(rawValue: UInt32(1) << 15) } //IORING_FEAT_MIN_TIMEOUT
		@inlinable public static var bundledSendReceive: Features { .init(rawValue: UInt32(1) << 14) } //IORING_FEAT_RECVSEND_BUNDLE
	}

    /// Describes which io_uring features are supported by the kernel this program is running on
	public var supportedFeatures: Features {
        return features
    }

    deinit {
        if let ringPtr {
            munmap(ringPtr, ringSize)
        } else if let submissionRingPtr, let completionRingPtr {
            munmap(submissionRingPtr, submissionRingSize)
            munmap(completionRingPtr, completionRingSize)
        }
        munmap(
            UnsafeMutableRawPointer(submissionQueueEntries.baseAddress!),
            submissionQueueEntries.count * MemoryLayout<io_uring_sqe>.size
        )
        close(ringDescriptor)
    }
}

extension IORing.RegisteredBuffer {
    @unsafe @inlinable public var unsafeBuffer: UnsafeMutableRawBufferPointer {
        return .init(start: resource.iov_base, count: resource.iov_len)
    }

    @inlinable public var mutableBytes: MutableRawSpan {
        @_lifetime(&self)
        mutating get {
            let span = MutableRawSpan(_unsafeBytes: unsafeBuffer)
            return unsafe _overrideLifetime(span, mutating: &self)
        }
    }

    @inlinable public var bytes: RawSpan {
        let span = RawSpan(_unsafeBytes: UnsafeRawBufferPointer(unsafeBuffer))
        return unsafe _overrideLifetime(span, borrowing: self)
    }
}
#endif
#endif
