fileprivate func handleCompletionError(
    _ result: Int32, 
    for continuation: UnsafeContinuation<IOCompletion, any Error>) {
    var error: IORingError = .unknown
    switch result {
        case -(_ECANCELED):
            error = .operationCanceled
        default:
            error = .unknown
    }
    continuation.resume(throwing: error)
}

final public class ManagedIORing: @unchecked Sendable {
    var internalRing: IORing

    public init(queueDepth: UInt32) throws {
        self.internalRing = try IORing(queueDepth: queueDepth)
        self.internalRing.registerBuffers(bufSize: 655336, count: 4)
        self.internalRing.registerFiles(count: 32)
        self.startWaiter()
    }

    private func startWaiter() {
        Task.detached {
            while !Task.isCancelled {
                //TODO: should timeout handling be sunk into IORing?
                let cqe = self.internalRing.blockingConsumeCompletion()

                if cqe.userData == 0 {
                    continue
                }
                let cont = unsafeBitCast(
                cqe.userData, to: UnsafeContinuation<IOCompletion, any Error>.self)
                
                if cqe.result < 0 {
                    var err = system_strerror(cqe.result * -1)
                    let len = system_strlen(err!)
                    err!.withMemoryRebound(to: UInt8.self, capacity: len) {
                        let errStr = String(decoding: UnsafeBufferPointer(start: $0, count: len), as: UTF8.self)
                        print("\(errStr)")
                    }
                    handleCompletionError(cqe.result, for: cont)
                } else {
                    cont.resume(returning: cqe)
                }
            }
        }
    }

    public func submit(
        request: __owned IORequest,
        timeout: Duration? = nil,
        isolation actor: isolated (any Actor)? = #isolation
    ) async throws -> IOCompletion {
        var consumeOnceWorkaround: IORequest? = request
        return try await withUnsafeThrowingContinuation { cont in
            do {
                try internalRing.submissionMutex.withLock { ring in
                    let request = consumeOnceWorkaround.take()!
                    let entry = _blockingGetSubmissionEntry(
                        ring: &ring, submissionQueueEntries: internalRing.submissionQueueEntries)
                    entry.pointee = request.makeRawRequest().rawValue
                    entry.pointee.user_data = unsafeBitCast(cont, to: UInt64.self)
                    if let timeout {
                        //TODO: if IORING_FEAT_MIN_TIMEOUT is supported we can do this more efficiently
                        let timeoutEntry = _blockingGetSubmissionEntry(
                            ring: &ring, 
                            submissionQueueEntries: internalRing.submissionQueueEntries
                        )
                        try RawIORequest.withTimeoutRequest(
                            linkedTo: entry,
                            in: timeoutEntry,
                            duration: timeout, 
                            flags: .relativeTime
                        ) {
                            try _submitRequests(ring: &ring, ringDescriptor: internalRing.ringDescriptor)
                        }
                    } else {
                        try _submitRequests(ring: &ring, ringDescriptor: internalRing.ringDescriptor)
                    }
                }
            } catch (let e) {
                cont.resume(throwing: e)
            }
        }

    }

    internal func getFileSlot() -> IORingFileSlot? {
        internalRing.getFile()
    }

    internal func getBuffer() -> IORingBuffer? {
        internalRing.getBuffer()
    }

}
