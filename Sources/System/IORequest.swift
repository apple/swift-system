@_implementationOnly import struct CSystem.io_uring_sqe

@usableFromInline
internal enum IORequestCore: ~Copyable {
    case nop  // nothing here
    case openat(
        atDirectory: FileDescriptor,
        path: UnsafePointer<CChar>,
        FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    )
    case openatSlot(
        atDirectory: FileDescriptor,
        path: UnsafePointer<CChar>,
        FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        intoSlot: IORingFileSlot
    )
    case read(
        file: FileDescriptor,
        buffer: IORingBuffer,
        offset: UInt64 = 0
    )
    case readUnregistered(
        file: FileDescriptor,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0
    )
    case readSlot(
        file: IORingFileSlot,
        buffer: IORingBuffer,
        offset: UInt64 = 0
    )
    case readUnregisteredSlot(
        file: IORingFileSlot,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0
    )
    case write(
        file: FileDescriptor,
        buffer: IORingBuffer,
        offset: UInt64 = 0
    )
    case writeUnregistered(
        file: FileDescriptor,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0
    )
    case writeSlot(
        file: IORingFileSlot,
        buffer: IORingBuffer,
        offset: UInt64 = 0
    )
    case writeUnregisteredSlot(
        file: IORingFileSlot,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0
    )
    case close(FileDescriptor)
    case closeSlot(IORingFileSlot)
}

@inline(__always)
internal func makeRawRequest_readWrite_registered(
    file: FileDescriptor,
    buffer: IORingBuffer,
    offset: UInt64,
    request: consuming RawIORequest
) -> RawIORequest {
    request.fileDescriptor = file
    request.buffer = buffer.unsafeBuffer
    request.rawValue.buf_index = UInt16(exactly: buffer.index)!
    request.offset = offset
    return request
}

@inline(__always)
internal func makeRawRequest_readWrite_registered_slot(
    file: IORingFileSlot,
    buffer: IORingBuffer,
    offset: UInt64,
    request: consuming RawIORequest
) -> RawIORequest {
    request.rawValue.fd = Int32(exactly: file.index)!
    request.flags = .fixedFile
    request.buffer = buffer.unsafeBuffer
    request.rawValue.buf_index = UInt16(exactly: buffer.index)!
    request.offset = offset
    return request
}

@inlinable @inline(__always)
internal func makeRawRequest_readWrite_unregistered(
    file: FileDescriptor,
    buffer: UnsafeMutableRawBufferPointer,
    offset: UInt64,
    request: consuming RawIORequest
) -> RawIORequest {
    request.fileDescriptor = file
    request.buffer = buffer
    request.offset = offset
    return request
}

@inline(__always)
internal func makeRawRequest_readWrite_unregistered_slot(
    file: IORingFileSlot,
    buffer: UnsafeMutableRawBufferPointer,
    offset: UInt64,
    request: consuming RawIORequest
) -> RawIORequest {
    request.rawValue.fd = Int32(exactly: file.index)!
    request.flags = .fixedFile
    request.buffer = buffer
    request.offset = offset
    return request
}

public struct IORequest : ~Copyable {
    @usableFromInline var core: IORequestCore

    @inlinable internal consuming func extractCore() -> IORequestCore {
        return core
    }
}

extension IORequest {
    public init() { //TODO: why do we have nop?
        core = .nop
    }

    public init(
        reading file: IORingFileSlot,
        into buffer: IORingBuffer,
        at offset: UInt64 = 0
    ) {
        core = .readSlot(file: file, buffer: buffer, offset: offset)
    }

    public init(
        reading file: FileDescriptor,
        into buffer: IORingBuffer,
        at offset: UInt64 = 0
    ) {
        core = .read(file: file, buffer: buffer, offset: offset)
    }

    public init(
        reading file: IORingFileSlot,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0
    ) {
        core = .readUnregisteredSlot(file: file, buffer: buffer, offset: offset)
    }

    public init(
        reading file: FileDescriptor,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0
    ) {
        core = .readUnregistered(file: file, buffer: buffer, offset: offset)
    }

    public init(
        writing buffer: IORingBuffer,
        into file: IORingFileSlot,
        at offset: UInt64 = 0
    ) {
        core = .writeSlot(file: file, buffer: buffer, offset: offset)
    }

    public init(
        writing buffer: IORingBuffer,
        into file: FileDescriptor,
        at offset: UInt64 = 0
    ) {
        core = .write(file: file, buffer: buffer, offset: offset)
    }

    public init(
        writing buffer: UnsafeMutableRawBufferPointer,
        into file: IORingFileSlot,
        at offset: UInt64 = 0
    ) {
        core = .writeUnregisteredSlot(file: file, buffer: buffer, offset: offset)
    }

    public init(
        writing buffer: UnsafeMutableRawBufferPointer,
        into file: FileDescriptor,
        at offset: UInt64 = 0
    ) {
        core = .writeUnregistered(file: file, buffer: buffer, offset: offset)
    }

    public init(
        closing file: FileDescriptor
    ) {
        core = .close(file)
    }

    public init(
        closing file: IORingFileSlot
    ) {
        core = .closeSlot(file)
    }


    public init(
        opening path: UnsafePointer<CChar>,
        in directory: FileDescriptor,
        into slot: IORingFileSlot,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) {
        core = .openatSlot(atDirectory: directory, path: path, mode, options: options, permissions: permissions, intoSlot: slot)
    }

    public init(
        opening path: UnsafePointer<CChar>,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) {
        core = .openat(atDirectory: directory, path: path, mode, options: options, permissions: permissions)
    }


    public init(
        opening path: FilePath,
        in directory: FileDescriptor,
        into slot: IORingFileSlot,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) {
        fatalError("Implement me")
    }

    public init(
        opening path: FilePath,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) {
        fatalError("Implement me")
    }

    @inline(__always)
    public consuming func makeRawRequest() -> RawIORequest {
        var request = RawIORequest()
        switch extractCore() {
        case .nop:
            request.operation = .nop
        case .openatSlot(let atDirectory, let path, let mode, let options, let permissions, let fileSlot):
            // TODO: use rawValue less
            request.operation = .openAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = UInt64(UInt(bitPattern: path))
            request.rawValue.open_flags = UInt32(bitPattern: options.rawValue | mode.rawValue)
            request.rawValue.len = permissions?.rawValue ?? 0
            request.rawValue.file_index = UInt32(fileSlot.index + 1)
        case .openat(let atDirectory, let path, let mode, let options, let permissions):
            request.operation = .openAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = UInt64(UInt(bitPattern: path))
            request.rawValue.open_flags = UInt32(bitPattern: options.rawValue | mode.rawValue)
            request.rawValue.len = permissions?.rawValue ?? 0
        case .write(let file, let buffer, let offset):
            request.operation = .writeFixed
            return makeRawRequest_readWrite_registered(
                file: file, buffer: buffer, offset: offset, request: request)
        case .writeSlot(let file, let buffer, let offset):
            request.operation = .writeFixed
            return makeRawRequest_readWrite_registered_slot(
                file: file, buffer: buffer, offset: offset, request: request)
        case .writeUnregistered(let file, let buffer, let offset):
            request.operation = .write
            return makeRawRequest_readWrite_unregistered(
                file: file, buffer: buffer, offset: offset, request: request)
        case .writeUnregisteredSlot(let file, let buffer, let offset):
            request.operation = .write
            return makeRawRequest_readWrite_unregistered_slot(
                file: file, buffer: buffer, offset: offset, request: request)
        case .read(let file, let buffer, let offset):
            request.operation = .readFixed
            return makeRawRequest_readWrite_registered(
                file: file, buffer: buffer, offset: offset, request: request)
        case .readSlot(let file, let buffer, let offset):
            request.operation = .readFixed
            return makeRawRequest_readWrite_registered_slot(
                file: file, buffer: buffer, offset: offset, request: request)
        case .readUnregistered(let file, let buffer, let offset):
            request.operation = .read
            return makeRawRequest_readWrite_unregistered(
                file: file, buffer: buffer, offset: offset, request: request)
        case .readUnregisteredSlot(let file, let buffer, let offset):
            request.operation = .read
            return makeRawRequest_readWrite_unregistered_slot(
                file: file, buffer: buffer, offset: offset, request: request)
        case .close(let file):
            request.operation = .close
            request.fileDescriptor = file
        case .closeSlot(let file):
            request.operation = .close
            request.rawValue.file_index = UInt32(file.index + 1)
        }
        return request
    }
}
