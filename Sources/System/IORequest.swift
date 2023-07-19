@_implementationOnly import CSystem

public struct IORequest {
    internal var rawValue: io_uring_sqe 

    public init() {
        self.rawValue = io_uring_sqe()
    }
}

extension IORequest {
    public enum Operation: UInt8 {
        case nop = 0
        case readv = 1
        case writev = 2
        case fsync = 3
        case readFixed = 4
        case writeFixed = 5
        case pollAdd = 6
        case pollRemove = 7
        case syncFileRange = 8
        case sendMessage = 9
        case receiveMessage = 10
        // ...
        case openAt = 18
        case read = 22
        case write = 23
        case openAt2 = 28

    }

    public struct Flags: OptionSet, Hashable, Codable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let fixedFile = Flags(rawValue: 1 << 0)
        public static let drainQueue = Flags(rawValue: 1 << 1)
        public static let linkRequest = Flags(rawValue: 1 << 2)
        public static let hardlinkRequest = Flags(rawValue: 1 << 3)
        public static let asynchronous = Flags(rawValue: 1 << 4)
        public static let selectBuffer = Flags(rawValue: 1 << 5)
        public static let skipSuccess = Flags(rawValue: 1 << 6)
    }

    public var operation: Operation {
        get { Operation(rawValue: rawValue.opcode)! }
        set { rawValue.opcode = newValue.rawValue }
    }

    public var flags: Flags {
        get { Flags(rawValue: rawValue.flags) }
        set { rawValue.flags = newValue.rawValue }
    }

    public var fileDescriptor: FileDescriptor {
        get { FileDescriptor(rawValue: rawValue.fd) }
        set { rawValue.fd = newValue.rawValue }
    }

    public var offset: UInt64? {
        get { 
            if (rawValue.off == UInt64.max) {
                return nil
            } else {
                return rawValue.off
            }
        }
        set {
            if let val = newValue {
                rawValue.off = val
            } else {
                rawValue.off = UInt64.max
            }
        }
    }

    public var buffer: UnsafeMutableRawBufferPointer {
        get {
            let ptr = UnsafeMutableRawPointer(bitPattern: UInt(exactly: rawValue.addr)!)
            return UnsafeMutableRawBufferPointer(start: ptr, count: Int(rawValue.len))
        }

        set {
            // TODO: cleanup?
            rawValue.addr = UInt64(Int(bitPattern: newValue.baseAddress!))
            rawValue.len = UInt32(exactly: newValue.count)!
        }
    }
}

extension IORequest {
    static func nop() -> IORequest {
        var req = IORequest()
        req.operation = .nop
        return req
    }

    static func read(
        from fileDescriptor: FileDescriptor,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64? = nil
    ) -> IORequest {
        var req = IORequest.readWrite(
            op: Operation.read,
            fd: fileDescriptor,
            buffer: buffer,
            offset: offset
        )
        fatalError()
    }

    static func read(
        fixedFile: Int // TODO: AsyncFileDescriptor
    ) -> IORequest {
        fatalError()
    }

    static func write(
    
    ) -> IORequest {
        fatalError()
    }

    internal static func readWrite(
        op: Operation,
        fd: FileDescriptor,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64? = nil
    ) -> IORequest {
        var req = IORequest()
        req.operation = op
        req.fileDescriptor = fd
        req.offset = offset
        req.buffer = buffer
        return req
    }
}