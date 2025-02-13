@_implementationOnly import struct CSystem.io_uring_sqe

@usableFromInline
internal enum IORequestCore {
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
    case unlinkAt(   
        atDirectory: FileDescriptor,
        path: UnsafePointer<CChar>
    )
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

public struct IORequest {
    @usableFromInline var core: IORequestCore

    @inlinable internal consuming func extractCore() -> IORequestCore {
        return core
    }
}

extension IORequest {
    public static func nop() -> IORequest {
        IORequest(core: .nop)
    }

    public static func reading(_ file: IORingFileSlot,
        into buffer: IORingBuffer,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .readSlot(file: file, buffer: buffer, offset: offset))
    }

    public static func reading(_ file: FileDescriptor,
        into buffer: IORingBuffer,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .read(file: file, buffer: buffer, offset: offset))
    }

    public static func reading(_ file: IORingFileSlot,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .readUnregisteredSlot(file: file, buffer: buffer, offset: offset))
    }

    public static func reading(_ file: FileDescriptor,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .readUnregistered(file: file, buffer: buffer, offset: offset))
    }

    public static func writing(_ buffer: IORingBuffer,
        into file: IORingFileSlot,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .writeSlot(file: file, buffer: buffer, offset: offset))
    }

    public static func writing(_ buffer: IORingBuffer,
        into file: FileDescriptor,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .write(file: file, buffer: buffer, offset: offset))
    }

    public static func writing(_ buffer: UnsafeMutableRawBufferPointer,
        into file: IORingFileSlot,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .writeUnregisteredSlot(file: file, buffer: buffer, offset: offset))
    }

    public static func writing(_ buffer: UnsafeMutableRawBufferPointer,
        into file: FileDescriptor,
        at offset: UInt64 = 0
    ) -> IORequest {
        IORequest(core: .writeUnregistered(file: file, buffer: buffer, offset: offset))
    }

    public static func closing(_ file: FileDescriptor) -> IORequest {
        IORequest(core: .close(file))
    }

    public static func closing(_ file: IORingFileSlot) -> IORequest {
        IORequest(core: .closeSlot(file))
    }


    public static func opening(_ path: UnsafePointer<CChar>,
        in directory: FileDescriptor,
        into slot: IORingFileSlot,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) -> IORequest {
        IORequest(core :.openatSlot(atDirectory: directory, path: path, mode, options: options, permissions: permissions, intoSlot: slot))
    }

    public static func opening(_ path: UnsafePointer<CChar>,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) -> IORequest {
        IORequest(core:  .openat(atDirectory: directory, path: path, mode, options: options, permissions: permissions))
    }


    public static func opening(_ path: FilePath,
        in directory: FileDescriptor,
        into slot: IORingFileSlot,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) -> IORequest {
        fatalError("Implement me")
    }

    public static func opening(_ path: FilePath,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil
    ) -> IORequest {
        fatalError("Implement me")
    }

    public static func unlinking(_ path: UnsafePointer<CChar>,
        in directory: FileDescriptor
    ) -> IORequest {
        IORequest(core: .unlinkAt(atDirectory: directory, path: path))
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
        case .unlinkAt(let atDirectory, let path):
            request.operation = .unlinkAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = UInt64(UInt(bitPattern: path))
        }
        return request
    }
}
