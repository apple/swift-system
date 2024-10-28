import struct CSystem.io_uring_sqe

public enum IORequest: ~Copyable {
    case nop // nothing here
    case openat(
        atDirectory: FileDescriptor,
        path: UnsafePointer<CChar>,
        FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        intoSlot: IORingFileSlot? = nil
    )
    case read(
        file: File,
        buffer: Buffer,
        offset: UInt64 = 0
    )
    case write(
        file: File,
        buffer: Buffer,
        offset: UInt64 = 0
    )
    case close(File)

    public enum Buffer: ~Copyable {
        case registered(IORingBuffer)
        case unregistered(UnsafeMutableRawBufferPointer)
    }

    public enum File: ~Copyable {
        case registered(IORingFileSlot)
        case unregistered(FileDescriptor)
    }
}

@inlinable @inline(__always)
internal func makeRawRequest_readWrite_registered(
    file: consuming IORequest.File,
    buffer: consuming IORingBuffer,
    offset: UInt64,
    request: consuming RawIORequest
) -> RawIORequest {
    switch file {
    case .registered(let regFile):
        request.rawValue.fd = Int32(exactly: regFile.index)!
        request.flags = .fixedFile
    case .unregistered(let fd):
        request.fileDescriptor = fd
    }
    request.buffer = buffer.unsafeBuffer
    request.rawValue.buf_index = UInt16(exactly: buffer.index)!
    request.offset = offset
    return request
}

@inlinable @inline(__always)
internal func makeRawRequest_readWrite_unregistered(
    file: consuming IORequest.File,
    buffer: UnsafeMutableRawBufferPointer,
    offset: UInt64,
    request: consuming RawIORequest
) -> RawIORequest {
    switch file {
    case .registered(let regFile):
        request.rawValue.fd = Int32(exactly: regFile.index)!
        request.flags = .fixedFile
    case .unregistered(let fd):
        request.fileDescriptor = fd
    }
    request.buffer = buffer
    request.offset = offset
    return request
}

extension IORequest {
    @inlinable @inline(__always)
    public consuming func makeRawRequest() -> RawIORequest {
        var request = RawIORequest()
        switch consume self {
        case .nop:
            request.operation = .nop
        case .openat(let atDirectory, let path, let mode, let options, let permissions, let slot):
            // TODO: use rawValue less
            request.operation = .openAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = unsafeBitCast(path, to: UInt64.self)
            request.rawValue.open_flags = UInt32(bitPattern: options.rawValue | mode.rawValue)
            request.rawValue.len = permissions?.rawValue ?? 0
            if let fileSlot = slot {
                request.rawValue.file_index = UInt32(fileSlot.index + 1)
            }
        case .write(let file, let buffer, let offset):
            switch consume buffer {
            case .registered(let buffer):
                request.operation = .writeFixed
                return makeRawRequest_readWrite_registered(
                    file: file, buffer: buffer, offset: offset, request: request)

            case .unregistered(let buffer):
                request.operation = .write
                return makeRawRequest_readWrite_unregistered(
                    file: file, buffer: buffer, offset: offset, request: request)
            }
        case .read(let file, let buffer, let offset):

            switch consume buffer {
            case .registered(let buffer):
                request.operation = .readFixed
                return makeRawRequest_readWrite_registered(
                    file: file, buffer: buffer, offset: offset, request: request)

            case .unregistered(let buffer):
                request.operation = .read
                return makeRawRequest_readWrite_unregistered(
                    file: file, buffer: buffer, offset: offset, request: request)
            }
        case .close(let file):
            request.operation = .close
            switch file {
            case .registered(let regFile):
                request.rawValue.file_index = UInt32(regFile.index + 1)
            case .unregistered(let normalFile):
                request.fileDescriptor = normalFile
            }
        }
        return request
    }
}
