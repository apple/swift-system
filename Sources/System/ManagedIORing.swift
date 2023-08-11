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
            while (!Task.isCancelled) {
                let cqe = self.internalRing.blockingConsumeCompletion()

                let cont = unsafeBitCast(cqe.userData, to: UnsafeContinuation<IOCompletion, Never>.self)
                cont.resume(returning: cqe)
            }
        }
    }

    @_unsafeInheritExecutor
    public func submitAndWait(_ request: __owned IORequest) async -> IOCompletion {
        self.internalRing.submissionMutex.lock()
        return await withUnsafeContinuation { cont in
            let entry = internalRing._blockingGetSubmissionEntry()
            entry.pointee = request.makeRawRequest().rawValue
            entry.pointee.user_data = unsafeBitCast(cont, to: UInt64.self)
            self.internalRing._submitRequests()
            self.internalRing.submissionMutex.unlock()
        }
    }

    internal func getFileSlot() -> IORingFileSlot? {
        self.internalRing.getFile()
    }

    internal func getBuffer() -> IORingBuffer? {
        self.internalRing.getBuffer()
    }

}