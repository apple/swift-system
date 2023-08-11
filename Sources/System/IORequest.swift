import struct CSystem.io_uring_sqe

public enum IORequest {
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

    public enum Buffer {
        case registered(IORingBuffer)
        case unregistered(UnsafeMutableRawBufferPointer)
    }

    public enum File {
        case registered(IORingFileSlot)
        case unregistered(FileDescriptor)
    }
}

extension IORequest {
    @inlinable @inline(__always)
    public func makeRawRequest() -> RawIORequest {
        var request = RawIORequest()
        switch self {
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
            case .read(let file, let buffer, let offset), .write(let file, let buffer, let offset):
                if case .read = self {
                    if case .registered = buffer {
                        request.operation = .readFixed
                    } else {
                        request.operation = .read
                    }
                } else {
                    if case .registered = buffer {
                        request.operation = .writeFixed
                    } else {
                        request.operation = .write
                    }
                }
                switch file {
                    case .registered(let regFile):
                        request.rawValue.fd = Int32(exactly: regFile.index)!
                        request.flags = .fixedFile
                    case .unregistered(let fd):
                        request.fileDescriptor = fd
                }
                switch buffer {
                    case .registered(let regBuf):
                        request.buffer = regBuf.unsafeBuffer
                        request.rawValue.buf_index = UInt16(exactly: regBuf.index)!
                    case .unregistered(let buf):
                        request.buffer = buf
                }
                request.offset = offset
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
