@_implementationOnly import CSystem


public final class AsyncFileDescriptor {    
    @usableFromInline var open: Bool = true
    @usableFromInline let fileSlot: IORingFileSlot
    @usableFromInline let ring: ManagedIORing
    
    public static func openat(
        atDirectory: FileDescriptor = FileDescriptor(rawValue: -100), 
        path: FilePath,
        _ mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        onRing ring: ManagedIORing
    ) async throws -> AsyncFileDescriptor {
        // todo; real error type
        guard let fileSlot = ring.getFileSlot() else {
            throw IORingError.missingRequiredFeatures
        }
        let cstr = path.withCString {
            return $0 // bad
        }
        let res = await ring.submitAndWait(.openat(
            atDirectory: atDirectory, 
            path: cstr,
            mode,
            options: options,
            permissions: permissions,
            intoSlot: fileSlot
        ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        }
        
        return AsyncFileDescriptor(
            fileSlot, ring: ring
        )
    }

    internal init(_ fileSlot: IORingFileSlot, ring: ManagedIORing) {
        self.fileSlot = fileSlot
        self.ring = ring
    }

    @inlinable @inline(__always) @_unsafeInheritExecutor
    public func close() async throws {
        let res = await ring.submitAndWait(.close(
            .registered(self.fileSlot)
        ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        }
        self.open = false
    }

    @inlinable @inline(__always) @_unsafeInheritExecutor
    public func read(
        into buffer: IORequest.Buffer,
        atAbsoluteOffset offset: UInt64 = UInt64.max
    ) async throws -> UInt32 {
        let res = await ring.submitAndWait(.read(
            file: .registered(self.fileSlot),
            buffer: buffer,
            offset: offset
        ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        } else {
            return UInt32(bitPattern: res.result)
        }
    }

    deinit {
        if (self.open) {
            // TODO: close or error? TBD
        }
    }
}

extension AsyncFileDescriptor: AsyncSequence {
    public func makeAsyncIterator() -> FileIterator {
        return .init(self)
    }

    public typealias AsyncIterator = FileIterator
    public typealias Element = UInt8
}

public struct FileIterator: AsyncIteratorProtocol {
    @usableFromInline let file: AsyncFileDescriptor
    @usableFromInline var buffer: IORingBuffer
    @usableFromInline var done: Bool

    @usableFromInline internal var currentByte: UnsafeRawPointer?
    @usableFromInline internal var lastByte: UnsafeRawPointer?

    init(_ file: AsyncFileDescriptor) {
        self.file = file
        self.buffer = file.ring.getBuffer()!
        self.done = false
    }

    @inlinable @inline(__always)
    public mutating func nextBuffer() async throws {
        let buffer = self.buffer

        let bytesRead = try await file.read(into: .registered(buffer))
        if _fastPath(bytesRead != 0) {
            let bufPointer = buffer.unsafeBuffer.baseAddress.unsafelyUnwrapped
            self.currentByte = UnsafeRawPointer(bufPointer)
            self.lastByte = UnsafeRawPointer(bufPointer.advanced(by: Int(bytesRead)))
        } else {
            self.done = true
        }
    }

    @inlinable @inline(__always) @_unsafeInheritExecutor
    public mutating func next() async throws -> UInt8? {
        if _fastPath(currentByte != lastByte) {
            // SAFETY: both pointers should be non-nil if they're not equal
            let byte = currentByte.unsafelyUnwrapped.load(as: UInt8.self)
            currentByte = currentByte.unsafelyUnwrapped + 1
            return byte
        } else if done {
            return nil
        }
        try await nextBuffer()
        return try await next()
    }
}
