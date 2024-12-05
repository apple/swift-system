@_implementationOnly import CSystem

public struct AsyncFileDescriptor: ~Copyable {
    @usableFromInline var open: Bool = true
    @usableFromInline let fileSlot: IORingFileSlot
    @usableFromInline let ring: ManagedIORing

    public static func open(
        path: FilePath,
        in directory: FileDescriptor = FileDescriptor(rawValue: -100),
        on ring: ManagedIORing,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) async throws -> AsyncFileDescriptor {
        // todo; real error type
        guard let fileSlot = ring.getFileSlot() else {
            throw IORingError.missingRequiredFeatures
        }
        //TODO: need an async-friendly withCString
        let cstr = path.withCString {
            return $0  // bad
        }
        let res = await ring.submitAndWait(
            IORequest(
                opening: cstr, 
                in: directory, 
                into: fileSlot, 
                mode: mode, 
                options: options, 
                permissions: permissions
            ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        }

        return AsyncFileDescriptor(
            fileSlot, ring: ring
        )
    }

    internal init(_ fileSlot: consuming IORingFileSlot, ring: ManagedIORing) {
        self.fileSlot = consume fileSlot
        self.ring = ring
    }

    @inlinable @inline(__always)
    public consuming func close(isolation actor: isolated (any Actor)? = #isolation) async throws {
        let res = await ring.submitAndWait(IORequest(closing: fileSlot))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        }
        self.open = false
    }

    @inlinable @inline(__always)
    public func read(
        into buffer: inout UnsafeMutableRawBufferPointer,
        atAbsoluteOffset offset: UInt64 = UInt64.max,
        isolation actor: isolated (any Actor)? = #isolation
    ) async throws -> UInt32 {
        let res = await ring.submitAndWait(
            IORequest(
                reading: fileSlot, 
                into: buffer, 
                at: offset
            ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        } else {
            return UInt32(bitPattern: res.result)
        }
    }

    @inlinable @inline(__always)
    public func read(
        into buffer: IORingBuffer, //TODO: should be inout?
        atAbsoluteOffset offset: UInt64 = UInt64.max,
        isolation actor: isolated (any Actor)? = #isolation
    ) async throws -> UInt32 {
        let res = await ring.submitAndWait(
            IORequest(
                reading: fileSlot,
                into: buffer,
                at: offset
            ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        } else {
            return UInt32(bitPattern: res.result)
        }
    }

    //TODO: temporary workaround until AsyncSequence supports ~Copyable
    public consuming func toBytes() -> AsyncFileDescriptorSequence {
        AsyncFileDescriptorSequence(self)
    }

    //TODO: can we do the linear types thing and error if they don't consume it manually?
    // deinit {
    //     if self.open {
    //         close()
    //         // TODO: close or error? TBD
    //     }
    // }
}

public class AsyncFileDescriptorSequence: AsyncSequence {
    var descriptor: AsyncFileDescriptor?

    public func makeAsyncIterator() -> FileIterator {
        return .init(descriptor.take()!)
    }

    internal init(_ descriptor: consuming AsyncFileDescriptor) {
        self.descriptor = consume descriptor
    }

    public typealias AsyncIterator = FileIterator
    public typealias Element = UInt8
}

//TODO: only a class due to ~Copyable limitations
public class FileIterator: AsyncIteratorProtocol {
    @usableFromInline let file: AsyncFileDescriptor
    @usableFromInline var buffer: IORingBuffer
    @usableFromInline var done: Bool

    @usableFromInline internal var currentByte: UnsafeRawPointer?
    @usableFromInline internal var lastByte: UnsafeRawPointer?

    init(_ file: consuming AsyncFileDescriptor) {
        self.buffer = file.ring.getBuffer()!
        self.file = file
        self.done = false
    }

    @inlinable @inline(__always)
    public func nextBuffer() async throws {
        let bytesRead = Int(try await file.read(into: buffer))
        if _fastPath(bytesRead != 0) {
            let unsafeBuffer = buffer.unsafeBuffer
            let bufPointer = unsafeBuffer.baseAddress.unsafelyUnwrapped
            self.currentByte = UnsafeRawPointer(bufPointer)
            self.lastByte = UnsafeRawPointer(bufPointer.advanced(by: bytesRead))
        } else {
            done = true
        }
    }

    @inlinable @inline(__always)
    public func next() async throws -> UInt8? {
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
