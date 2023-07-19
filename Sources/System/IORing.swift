@_implementationOnly import CSystem
import Glibc
import Atomics

// XXX: this *really* shouldn't be here. oh well.
extension UnsafeMutableRawPointer {
    func advanced(by offset: UInt32) -> UnsafeMutableRawPointer {
        return advanced(by: Int(offset))
    }
}

// all pointers in this struct reference kernel-visible memory
struct SQRing {
    let kernelHead: UnsafeAtomic<UInt32>
    let kernelTail: UnsafeAtomic<UInt32>
    var userTail: UInt32

    // from liburing: the kernel should never change these
    // might change in the future with resizable rings?
    let ringMask: UInt32
    // let ringEntries: UInt32 - absorbed into array.count

    // ring flags bitfield
    // currently used by the kernel only in SQPOLL mode to indicate
    // when the polling thread needs to be woken up
    let flags: UnsafeAtomic<UInt32>
    
    // ring array
    // maps indexes between the actual ring and the submissionQueueEntries list,
    // allowing the latter to be used as a kind of freelist with enough work?
    // currently, just 1:1 mapping (0..<n)
    let array: UnsafeMutableBufferPointer<UInt32>
}

struct CQRing {
    let kernelHead: UnsafeAtomic<UInt32>
    let kernelTail: UnsafeAtomic<UInt32>

    // TODO: determine if this is actually used
    var userHead: UInt32

    let ringMask: UInt32

    let cqes: UnsafeBufferPointer<io_uring_cqe>
}

// XXX: This should be a non-copyable type (?)
// demo only runs on Swift 5.8.1
public final class IORing: Sendable {
    let ringFlags: UInt32
    let ringDescriptor: Int32

    var submissionRing: SQRing
    var submissionMutex: Mutex
    // FEAT: set this eventually
    let submissionPolling: Bool = false

    var completionRing: CQRing
    var completionMutex: Mutex

    let submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>
    
    var registeredFiles: UnsafeMutableBufferPointer<UInt32>?

    // kept around for unmap / cleanup
    let ringSize: Int
    let ringPtr: UnsafeMutableRawPointer

    public init(queueDepth: UInt32) throws {
        var params = io_uring_params()

        ringDescriptor = withUnsafeMutablePointer(to: &params) {
            return io_uring_setup(queueDepth, $0);
        }

        if (params.features & IORING_FEAT_SINGLE_MMAP == 0
            || params.features & IORING_FEAT_NODROP == 0) {
            close(ringDescriptor)
            // TODO: error handling
            fatalError("kernel not new enough")
        }
        
        if (ringDescriptor < 0) {
            // TODO: error handling
        }

        let submitRingSize = params.sq_off.array
            + params.sq_entries * UInt32(MemoryLayout<UInt32>.size)
        
        let completionRingSize = params.cq_off.cqes
            + params.cq_entries * UInt32(MemoryLayout<io_uring_cqe>.size)

        ringSize = Int(max(submitRingSize, completionRingSize))
        
        ringPtr = mmap(
            /* addr: */ nil,
            /* len: */ ringSize,
            /* prot: */ PROT_READ | PROT_WRITE,
            /* flags: */ MAP_SHARED | MAP_POPULATE,
            /* fd: */ ringDescriptor,
            /* offset: */ __off_t(IORING_OFF_SQ_RING)
        );

        if (ringPtr == MAP_FAILED) {
            perror("mmap");
            // TODO: error handling
            fatalError()
        }

        let kernelHead = UnsafeAtomic<UInt32>(at: 
            ringPtr.advanced(by: params.sq_off.head)
            .assumingMemoryBound(to: UInt32.AtomicRepresentation.self)
        )

        submissionRing = SQRing(
            kernelHead: UnsafeAtomic<UInt32>(
                at: ringPtr.advanced(by: params.sq_off.head)
                .assumingMemoryBound(to: UInt32.AtomicRepresentation.self)
            ),
            kernelTail: UnsafeAtomic<UInt32>(
                at: ringPtr.advanced(by: params.sq_off.tail)
                .assumingMemoryBound(to: UInt32.AtomicRepresentation.self)
            ),
            userTail: 0, // no requests yet
            ringMask: ringPtr.advanced(by: params.sq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            flags: UnsafeAtomic<UInt32>(
                at: ringPtr.advanced(by: params.sq_off.flags)
                .assumingMemoryBound(to: UInt32.AtomicRepresentation.self)
            ),
            array: UnsafeMutableBufferPointer(
                start: ringPtr.advanced(by: params.sq_off.array)
                    .assumingMemoryBound(to: UInt32.self),
                count: Int(ringPtr.advanced(by: params.sq_off.ring_entries)
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
        );

        if (sqes == MAP_FAILED) {
            perror("mmap");
            // TODO: error handling
            fatalError()
        }

        submissionQueueEntries = UnsafeMutableBufferPointer(
            start: sqes!.assumingMemoryBound(to: io_uring_sqe.self),
            count: Int(params.sq_entries)
        )

        completionRing = CQRing(
            kernelHead: UnsafeAtomic<UInt32>(
                at: ringPtr.advanced(by: params.cq_off.head)
                .assumingMemoryBound(to: UInt32.AtomicRepresentation.self)
            ),
            kernelTail: UnsafeAtomic<UInt32>(
                at: ringPtr.advanced(by: params.cq_off.tail)
                .assumingMemoryBound(to: UInt32.AtomicRepresentation.self)
            ),
            userHead: 0, // no completions yet
            ringMask: ringPtr.advanced(by: params.cq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            cqes: UnsafeBufferPointer(
                start: ringPtr.advanced(by: params.cq_off.cqes)
                    .assumingMemoryBound(to: io_uring_cqe.self),
                count: Int(ringPtr.advanced(by: params.cq_off.ring_entries)
                    .assumingMemoryBound(to: UInt32.self).pointee)
            )
        )

        self.submissionMutex = Mutex()
        self.completionMutex = Mutex()

        self.ringFlags = params.flags
    }

    func blockingConsumeCompletion() -> IOCompletion {
        self.completionMutex.lock()
        defer { self.completionMutex.unlock() }
        
        if let completion = _tryConsumeCompletion() {
            return completion
        } else {
            _waitForCompletion()
            return _tryConsumeCompletion().unsafelyUnwrapped
        }
    }

    func _waitForCompletion() {
        // TODO: error handling
        io_uring_enter(ringDescriptor, 0, 1, IORING_ENTER_GETEVENTS, nil)
    }

    func tryConsumeCompletion() -> IOCompletion? {
        self.completionMutex.lock()
        defer { self.completionMutex.unlock() }
        return _tryConsumeCompletion()
    }

    func _tryConsumeCompletion() -> IOCompletion? {
        let tail = completionRing.kernelTail.load(ordering: .acquiring)
        var head = completionRing.kernelHead.load(ordering: .relaxed)
        
        if tail != head {
            // 32 byte copy - oh well
            let res = completionRing.cqes[Int(head & completionRing.ringMask)]
            completionRing.kernelHead.store(head + 1, ordering: .relaxed)
            return IOCompletion(rawValue: res)
        }

        return nil
    }


    func registerFiles(count: UInt32) {
        // TODO: implement
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
        self.registeredFiles = fileBuf
    }

    func unregisterFiles() {
        if self.registeredFiles != nil {
            io_uring_register(
                self.ringDescriptor,
                IORING_UNREGISTER_FILES,
                self.registeredFiles!.baseAddress!,
                UInt32(self.registeredFiles!.count)
            )
            // TODO: error handling
            self.registeredFiles!.deallocate()
            self.registeredFiles = nil
        }
    }

    // register a group of buffers
    func registerBuffers(bufSize: UInt32, count: UInt32) {
        //

    }

    func getBuffer() -> (index: Int, buf: UnsafeRawBufferPointer) {
        fatalError()
    }

    // TODO: types
    func submitRequests() {
        self.submissionMutex.lock()
        defer { self.submissionMutex.unlock() }
        self._submitRequests()
    }

    func _submitRequests() {
        let flushedEvents = _flushQueue()
        
        // Ring always needs enter right now;
        // TODO: support SQPOLL here

        let ret = io_uring_enter(ringDescriptor, flushedEvents, 0, 0, nil)
        // TODO: handle errors
    }

    internal func _flushQueue() -> UInt32 {
        self.submissionRing.kernelTail.store(
            self.submissionRing.userTail, ordering: .relaxed
        )
        return self.submissionRing.userTail - 
            self.submissionRing.kernelHead.load(ordering: .relaxed)
    }


    func writeRequest(_ request: __owned IORequest) -> Bool {
        self.submissionMutex.lock()
        defer { self.submissionMutex.unlock() }
        return _writeRequest(request)
    }

    internal func _writeRequest(_ request: __owned IORequest) -> Bool {
        if let entry = _getSubmissionEntry() {
            entry.pointee = request.rawValue
            return true
        }
        return false
    }

    internal func _blockingGetSubmissionEntry() -> UnsafeMutablePointer<io_uring_sqe> {
        while true {
            if let entry = _getSubmissionEntry() {
                return entry
            }
            // TODO: actually block here instead of spinning
        }

    }

    internal func _getSubmissionEntry() -> UnsafeMutablePointer<io_uring_sqe>? {
        let next = self.submissionRing.userTail + 1

        // FEAT: smp load when SQPOLL in use (not in MVP)
        let kernelHead = self.submissionRing.kernelHead.load(ordering: .relaxed)

        // FEAT: 128-bit event support (not in MVP)
    	if (next - kernelHead <= self.submissionRing.array.count) {
		    // let sqe =  &sq->sqes[(sq->sqe_tail & sq->ring_mask) << shift];
            let sqeIndex = Int(
                self.submissionRing.userTail & self.submissionRing.ringMask
            )
		    
            let sqe = self.submissionQueueEntries
                .baseAddress.unsafelyUnwrapped
                .advanced(by: sqeIndex)
            
            self.submissionRing.userTail = next;
		    return sqe
	    }
        return nil
    }

    deinit {
        munmap(ringPtr, ringSize);
        munmap(
            UnsafeMutableRawPointer(submissionQueueEntries.baseAddress!),
            submissionQueueEntries.count * MemoryLayout<io_uring_sqe>.size
        )
        close(ringDescriptor)
    }
};

