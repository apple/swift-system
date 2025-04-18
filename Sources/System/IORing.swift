@_implementationOnly import CSystem
import Glibc  // needed for mmap
import Synchronization

@_implementationOnly import struct CSystem.io_uring_sqe

// XXX: this *really* shouldn't be here. oh well.
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

public struct IOResource<T> {
    public typealias Resource = T
    @usableFromInline let resource: T
    @usableFromInline let index: Int

    internal init(
        resource: T,
        index: Int
    ) {
        self.resource = resource
        self.index = index
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

@inline(__always)
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

@inline(__always)
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
        } else {
            return ret
        }
    }
}

internal func _submitRequests(ring: borrowing SQRing, ringDescriptor: Int32) throws(Errno) {
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

@inline(__always)
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

private func setUpRing(
    queueDepth: UInt32, flags: IORing.SetupFlags, submissionRing: inout SQRing
) throws(Errno) -> 
    (params: io_uring_params, ringDescriptor: Int32, ringPtr: UnsafeMutableRawPointer, ringSize: Int, sqes: UnsafeMutableRawPointer) {
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

    if params.features & IORING_FEAT_SINGLE_MMAP == 0
        || params.features & IORING_FEAT_NODROP == 0
    {
        close(ringDescriptor)
        // TODO: error handling
        throw Errno.invalidArgument
    }

    let submitRingSize =
        params.sq_off.array
        + params.sq_entries * UInt32(MemoryLayout<UInt32>.size)

    let completionRingSize =
        params.cq_off.cqes
        + params.cq_entries * UInt32(MemoryLayout<io_uring_cqe>.size)

    let ringSize = Int(max(submitRingSize, completionRingSize))

    let ringPtr: UnsafeMutableRawPointer! = mmap(
        /* addr: */ nil,
        /* len: */ ringSize,
        /* prot: */ PROT_READ | PROT_WRITE,
        /* flags: */ MAP_SHARED | MAP_POPULATE,
        /* fd: */ ringDescriptor,
        /* offset: */ __off_t(IORING_OFF_SQ_RING)
    )

    if ringPtr == MAP_FAILED {
        let errno = Errno.current
        perror("mmap")
        close(ringDescriptor)
        throw errno
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
        let errno = Errno.current
        perror("mmap")
        munmap(ringPtr, ringSize)
        close(ringDescriptor)
        throw errno
    }

    return (params: params, ringDescriptor: ringDescriptor, ringPtr: ringPtr!, ringSize: ringSize, sqes: sqes!)
}

public struct IORing: ~Copyable {
    let ringFlags: UInt32
    let ringDescriptor: Int32

    @usableFromInline var submissionRing: SQRing!
    // FEAT: set this eventually
    let submissionPolling: Bool = false

    let completionRing: CQRing

    let submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>

    // kept around for unmap / cleanup
    let ringSize: Int
    let ringPtr: UnsafeMutableRawPointer

    var _registeredFiles: [UInt32]
    var _registeredBuffers: [iovec]

    var features = Features(rawValue: 0)

    @frozen
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
        internal static var use128ByteSQEs: SetupFlags { .init(rawValue: UInt32(1) << 10) } //IORING_SETUP_SQE128
        internal static var use32ByteCQEs: SetupFlags { .init(rawValue: UInt32(1) << 11) } //IORING_SETUP_CQE32
        @inlinable public static var singleSubmissionThread: SetupFlags { .init(rawValue: UInt32(1) << 12) } //IORING_SETUP_SINGLE_ISSUER
        @inlinable public static var deferRunningTasks: SetupFlags { .init(rawValue: UInt32(1) << 13) } //IORING_SETUP_DEFER_TASKRUN
        //pretty sure we don't want to expose IORING_SETUP_NO_MMAP or IORING_SETUP_REGISTERED_FD_ONLY currently
        //TODO: should IORING_SETUP_NO_SQARRAY be the default? do we need to adapt anything to it?
    }

    public init(queueDepth: UInt32, flags: SetupFlags) throws(Errno) {
        let (params, tmpRingDescriptor, tmpRingPtr, tmpRingSize, sqes) = try setUpRing(queueDepth: queueDepth, flags: flags, submissionRing: &submissionRing)
        // All throws need to be before initializing ivars here to avoid 
        // "error: conditional initialization or destruction of noncopyable types is not supported; 
        // this variable must be consistently in an initialized or uninitialized state through every code path"
        features = Features(rawValue: params.features)
        ringDescriptor = tmpRingDescriptor
        ringPtr = tmpRingPtr
        ringSize = tmpRingSize
        _registeredFiles = []
        _registeredBuffers = []

        submissionQueueEntries = UnsafeMutableBufferPointer(
            start: sqes.assumingMemoryBound(to: io_uring_sqe.self),
            count: Int(params.sq_entries)
        )

        completionRing = CQRing(
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
        self.ringFlags = params.flags
    }

    private func _blockingConsumeCompletionGuts<Err: Error>(
        minimumCount: UInt32,
        maximumCount: UInt32,
        extraArgs: UnsafeMutablePointer<io_uring_getevents_arg>? = nil,
        consumer: (consuming IOCompletion?, Errno?, Bool) throws(Err) -> Void
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

    internal func _blockingConsumeOneCompletion(
        extraArgs: UnsafeMutablePointer<io_uring_getevents_arg>? = nil
    ) throws(Errno) -> IOCompletion {
        var result: IOCompletion? = nil
        try _blockingConsumeCompletionGuts(minimumCount: 1, maximumCount: 1, extraArgs: extraArgs) {
            (completion: consuming IOCompletion?, error, done) throws(Errno) in
            if let error {
                throw error
            }
            if let completion {
                result = consume completion
            }
        }
        return result.take()!
    }

    public func blockingConsumeCompletion(
        timeout: Duration? = nil
    ) throws(Errno) -> IOCompletion {
        if let timeout {
            var ts = __kernel_timespec(
                tv_sec: timeout.components.seconds,
                tv_nsec: timeout.components.attoseconds / 1_000_000_000
            )
            return try withUnsafePointer(to: &ts) { (tsPtr) throws(Errno) -> IOCompletion in
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

    public func blockingConsumeCompletions<Err: Error>(
        minimumCount: UInt32 = 1,
        timeout: Duration? = nil,
        consumer: (consuming IOCompletion?, Errno?, Bool) throws(Err) -> Void
    ) throws(Err) {
        if let timeout {
            var ts = __kernel_timespec(
                tv_sec: timeout.components.seconds,
                tv_nsec: timeout.components.attoseconds / 1_000_000_000
            )
            try withUnsafePointer(to: &ts) { (tsPtr) throws(Err) in
                var args = io_uring_getevents_arg(
                    sigmask: 0,
                    sigmask_sz: 0,
                    pad: 0,
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

    public mutating func registerEventFD(_ descriptor: FileDescriptor) throws(Errno) {
        var rawfd = descriptor.rawValue
        let result = withUnsafePointer(to: &rawfd) { fdptr in
            let result = io_uring_register(
                ringDescriptor,
                IORING_REGISTER_EVENTFD,
                UnsafeMutableRawPointer(mutating: fdptr),
                1
            )
            return result >= 0 ? nil : Errno(rawValue: -result)
        }
        if let result {
            throw result
        }
    }

    public mutating func unregisterEventFD() throws(Errno) {
        let result = io_uring_register(
            ringDescriptor,
            IORING_UNREGISTER_EVENTFD,
            nil,
            0
        )
        if result < 0 {
            throw Errno(rawValue: -result)
        }
    }

    public mutating func registerFileSlots(count: Int) throws(Errno) -> RegisteredResources<
        IORingFileSlot.Resource
    > {
        precondition(_registeredFiles.isEmpty)
        precondition(count < UInt32.max)
        let files = [UInt32](repeating: UInt32.max, count: count)

        let regResult = files.withUnsafeBufferPointer { bPtr in
            let result = io_uring_register(
                self.ringDescriptor,
                IORING_REGISTER_FILES,
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

    public func unregisterFiles() {
        fatalError("failed to unregister files")
    }

    public var registeredFileSlots: RegisteredResources<IORingFileSlot.Resource> {
        RegisteredResources(resources: _registeredFiles)
    }

    public mutating func registerBuffers(_ buffers: some Collection<UnsafeMutableRawBufferPointer>) throws(Errno)
        -> RegisteredResources<IORingBuffer.Resource>
    {
        precondition(buffers.count < UInt32.max)
        precondition(_registeredBuffers.isEmpty)
        //TODO: check if io_uring has preconditions it needs for the buffers (e.g. alignment)
        let iovecs = buffers.map { $0.to_iovec() }
        let regResult = iovecs.withUnsafeBufferPointer { bPtr in
            let result = io_uring_register(
                self.ringDescriptor,
                IORING_REGISTER_BUFFERS,
                UnsafeMutableRawPointer(mutating: bPtr.baseAddress!),
                UInt32(truncatingIfNeeded: buffers.count)
            )
            return result >= 0 ? nil : Errno(rawValue: -result)
        }

        if let regResult {
            throw regResult
        }

        // TODO: error handling
        _registeredBuffers = iovecs
        return registeredBuffers
    }

    public mutating func registerBuffers(_ buffers: UnsafeMutableRawBufferPointer...) throws(Errno)
        -> RegisteredResources<IORingBuffer.Resource>
    {
        try registerBuffers(buffers)
    }

    public struct RegisteredResources<T>: RandomAccessCollection {
        let resources: [T]

        public var startIndex: Int { 0 }
        public var endIndex: Int { resources.endIndex }
        init(resources: [T]) {
            self.resources = resources
        }
        public subscript(position: Int) -> IOResource<T> {
            IOResource(resource: resources[position], index: position)
        }
        public subscript(position: UInt16) -> IOResource<T> {
            IOResource(resource: resources[Int(position)], index: Int(position))
        }
    }

    public var registeredBuffers: RegisteredResources<IORingBuffer.Resource> {
        RegisteredResources(resources: _registeredBuffers)
    }

    public func unregisterBuffers() {
        fatalError("failed to unregister buffers: TODO")
    }

    public func submitPreparedRequests() throws(Errno) {
        switch submissionRing {
        case .some(let submissionRing):
            try _submitRequests(ring: submissionRing, ringDescriptor: ringDescriptor)
        case .none:
            fatalError()
        }
    }

    public func submitPreparedRequestsAndConsumeCompletions<Err: Error>(
        minimumCount: UInt32 = 1,
        timeout: Duration? = nil,
        consumer: (consuming IOCompletion?, Errno?, Bool) throws(Err) -> Void
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

    public mutating func prepare(request: __owned IORequest) -> Bool {
        var raw: RawIORequest? = request.makeRawRequest()
        return _writeRequest(
            raw.take()!, ring: &submissionRing, submissionQueueEntries: submissionQueueEntries)
    }

    mutating func prepare(linkedRequests: some BidirectionalCollection<IORequest>) {
        guard linkedRequests.count > 0 else {
            return
        }
        let last = linkedRequests.last!
        for req in linkedRequests.dropLast() {
            var raw = req.makeRawRequest()
            raw.linkToNextRequest()
            _ = _writeRequest(
                raw, ring: &submissionRing, submissionQueueEntries: submissionQueueEntries)
        }
        _ = _writeRequest(
            last.makeRawRequest(), ring: &submissionRing,
            submissionQueueEntries: submissionQueueEntries)
    }

    //@inlinable //TODO: make sure the array allocation gets optimized out...
    public mutating func prepare(linkedRequests: IORequest...) {
        prepare(linkedRequests: linkedRequests)
    }

    public mutating func submit(linkedRequests: IORequest...) throws(Errno) {
        prepare(linkedRequests: linkedRequests)
        try submitPreparedRequests()
    }

    @frozen
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
	public var supportedFeatures: Features {
        return features
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
