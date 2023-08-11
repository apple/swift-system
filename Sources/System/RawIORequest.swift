// TODO: investigate @usableFromInline / @_implementationOnly dichotomy
@_implementationOnly import CSystem
import struct CSystem.io_uring_sqe
    
public struct RawIORequest {
    @usableFromInline var rawValue: io_uring_sqe 

    public init() {
        self.rawValue = io_uring_sqe()
    }
}

extension RawIORequest {
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

    public enum RequestFlags {
        case readWriteFlags(ReadWriteFlags)
        // case fsyncFlags(FsyncFlags?)
        // poll_events
        // poll32_events
        // sync_range_flags
        // msg_flags
        // timeout_flags
        // accept_flags
        // cancel_flags
        case openFlags(FileDescriptor.OpenOptions)
        // statx_flags
        // fadvise_advice
        // splice_flags
    }

    public struct ReadWriteFlags: OptionSet, Hashable, Codable {
        public var rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let highPriority = ReadWriteFlags(rawValue: 1 << 0)

        // sync with only data integrity
        public static let dataSync = ReadWriteFlags(rawValue: 1 << 1)

        // sync with full data + file integrity
        public static let fileSync = ReadWriteFlags(rawValue: 1 << 2)

        // return -EAGAIN if operation blocks
        public static let noWait = ReadWriteFlags(rawValue: 1 << 3)

        // append to end of the file
        public static let append = ReadWriteFlags(rawValue: 1 << 4)
    }
}

extension RawIORequest {
    static func nop() -> RawIORequest {
        var req = RawIORequest()
        req.operation = .nop
        return req
    }
}