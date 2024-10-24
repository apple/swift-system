@_implementationOnly import CSystem
import struct CSystem.io_uring_sqe

@_implementationOnly import Synchronization
import Glibc // needed for mmap

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

internal class ResourceManager<T>: @unchecked Sendable {
    typealias Resource = T
    let resourceList: UnsafeMutableBufferPointer<T>
    var freeList: [Int]
    let mutex: Mutex

    init(_ res: UnsafeMutableBufferPointer<T>) {
        self.resourceList = res
        self.freeList = [Int](resourceList.indices)
        self.mutex = Mutex()
    }

    func getResource() -> IOResource<T>? {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        if let index = freeList.popLast() {
            return IOResource(
                rescource: resourceList[index],
                index: index,
                manager: self
            )
        } else {
            return nil
        }
    }

    func releaseResource(index: Int) {
        self.mutex.lock()
        defer { self.mutex.unlock() }
        self.freeList.append(index)
    }
}

public struct IOResource<T>: ~Copyable {
    typealias Resource = T
    @usableFromInline let resource: T
    @usableFromInline let index: Int
    let manager: ResourceManager<T>

    internal init(
        rescource: T,
        index: Int,
        manager: ResourceManager<T>
    ) {
        self.resource = rescource
        self.index = index
        self.manager = manager
    }

    func withResource() {

    }

    deinit {
        self.manager.releaseResource(index: self.index)
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
        get {
            return .init(start: resource.iov_base, count: resource.iov_len)
        }
    }
}



// XXX: This should be a non-copyable type (?)
// demo only runs on Swift 5.8.1
public struct IORing: @unchecked Sendable, ~Copyable {
    let ringFlags: UInt32
    let ringDescriptor: Int32

    @usableFromInline var submissionRing: SQRing
    @usableFromInline var submissionMutex: Mutex
    // FEAT: set this eventually
    let submissionPolling: Bool = false

    var completionRing: CQRing
    var completionMutex: Mutex

    let submissionQueueEntries: UnsafeMutableBufferPointer<io_uring_sqe>

    // kept around for unmap / cleanup
    let ringSize: Int
    let ringPtr: UnsafeMutableRawPointer

    var registeredFiles: ResourceManager<UInt32>?
    var registeredBuffers: ResourceManager<iovec>?

    public init(queueDepth: UInt32) throws {
        var params = io_uring_params()

        ringDescriptor = withUnsafeMutablePointer(to: &params) {
            return io_uring_setup(queueDepth, $0);
        }

        if (params.features & IORING_FEAT_SINGLE_MMAP == 0
            || params.features & IORING_FEAT_NODROP == 0) {
            close(ringDescriptor)
            // TODO: error handling
            throw IORingError.missingRequiredFeatures
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
            fatalError("mmap failed in ring setup")
        }

        submissionRing = SQRing(
            kernelHead: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.sq_off.head)
                .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            kernelTail: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.sq_off.tail)
                .assumingMemoryBound(to: Atomic<UInt32>.self)
            ),
            userTail: 0, // no requests yet
            ringMask: ringPtr.advanced(by: params.sq_off.ring_mask)
                .assumingMemoryBound(to: UInt32.self).pointee,
            flags: UnsafePointer<Atomic<UInt32>>(
                ringPtr.advanced(by: params.sq_off.flags)
                .assumingMemoryBound(to: Atomic<UInt32>.self)
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
            fatalError("sqe mmap failed in ring setup")
        }

        submissionQueueEntries = UnsafeMutableBufferPointer(
            start: sqes!.assumingMemoryBound(to: io_uring_sqe.self),
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

    public func blockingConsumeCompletion() -> IOCompletion {
        self.completionMutex.lock()
        defer { self.completionMutex.unlock() }
        
        if let completion = _tryConsumeCompletion() {
            return completion
        } else {
            while true {
                let res = io_uring_enter(ringDescriptor, 0, 1, IORING_ENTER_GETEVENTS, nil)
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
                fatalError("fatal error in receiving requests: " +
                    Errno(rawValue: -res).debugDescription
                )
            }
            return _tryConsumeCompletion().unsafelyUnwrapped
        }
    }

    public func tryConsumeCompletion() -> IOCompletion? {
        self.completionMutex.lock()
        defer { self.completionMutex.unlock() }
        return _tryConsumeCompletion()
    }

    func _tryConsumeCompletion() -> IOCompletion? {
        let tail = completionRing.kernelTail.pointee.load(ordering: .acquiring)
        let head = completionRing.kernelHead.pointee.load(ordering: .relaxed)
        
        if tail != head {
            // 32 byte copy - oh well
            let res = completionRing.cqes[Int(head & completionRing.ringMask)]
            completionRing.kernelHead.pointee.store(head + 1, ordering: .relaxed)
            return IOCompletion(rawValue: res)
        }

        return nil
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
            let buf = UnsafeMutableRawBufferPointer.allocate(byteCount: intBufSize, alignment: 16384)
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

    public func submitRequests() {
        self.submissionMutex.lock()
        defer { self.submissionMutex.unlock() }
        self._submitRequests()
    }

    internal func _submitRequests() {
        let flushedEvents = _flushQueue()
        
        // Ring always needs enter right now;
        // TODO: support SQPOLL here
        while true {
            let ret = io_uring_enter(ringDescriptor, flushedEvents, 0, 0, nil)
            // error handling:
            //     EAGAIN / EINTR (try again),
            //     EBADF / EBADFD / EOPNOTSUPP / ENXIO
            //     (failure in ring lifetime management, fatal),
            //     EINVAL (bad constant flag?, fatal),
            //     EFAULT (bad address for argument from library, fatal)
            if ret == -EAGAIN || ret == -EINTR {
                continue
            } else if ret < 0 {
                fatalError("fatal error in submitting requests: " +
                    Errno(rawValue: -ret).debugDescription
                )
            } else {
                break
            }
        }
    }

    internal func _flushQueue() -> UInt32 {
        self.submissionRing.kernelTail.pointee.store(
            self.submissionRing.userTail, ordering: .relaxed
        )
        return self.submissionRing.userTail - 
            self.submissionRing.kernelHead.pointee.load(ordering: .relaxed)
    }


    @inlinable @inline(__always)
    public mutating func writeRequest(_ request: __owned IORequest) -> Bool {
        self.submissionMutex.lock()
        defer { self.submissionMutex.unlock() }
        return _writeRequest(request.makeRawRequest())
    }

    @inlinable @inline(__always)
    internal mutating func _writeRequest(_ request: __owned RawIORequest) -> Bool {
        let entry = _blockingGetSubmissionEntry()
        entry.pointee = request.rawValue
        return true
    }

    @inlinable @inline(__always)
    internal mutating func _blockingGetSubmissionEntry() -> UnsafeMutablePointer<io_uring_sqe> {
        while true {
            if let entry = _getSubmissionEntry() {
                return entry
            }
            // TODO: actually block here instead of spinning
        }

    }

    @usableFromInline @inline(__always)
    internal mutating func _getSubmissionEntry() -> UnsafeMutablePointer<io_uring_sqe>? {
        let next = self.submissionRing.userTail + 1

        // FEAT: smp load when SQPOLL in use (not in MVP)
        let kernelHead = self.submissionRing.kernelHead.pointee.load(ordering: .relaxed)

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

