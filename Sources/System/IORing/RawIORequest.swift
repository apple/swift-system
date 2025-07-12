#if compiler(>=6.2)
#if os(Linux)

import CSystem
    
@usableFromInline
internal struct RawIORequest: ~Copyable {
    @usableFromInline var rawValue: io_uring_sqe
    @usableFromInline var path: FilePath? //buffer owner for the path pointer that the sqe may have

    @inlinable public init() {
        self.rawValue = io_uring_sqe()
    }
}

extension RawIORequest {
    @usableFromInline
    enum Operation: UInt8 {
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
        case asyncCancel = 14
        case link_timeout = 15
        // ...
        case openAt = 18
        case close = 19
        case filesUpdate = 20
        case statx = 21
        case read = 22
        case write = 23
        // ...
        case openAt2 = 28
        // ...
        case unlinkAt = 36
    }

    public struct Flags: OptionSet, Hashable, Codable {
        public let rawValue: UInt8

        @inlinable public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        @inlinable public static var fixedFile: RawIORequest.Flags { Flags(rawValue: 1 << 0) }
        @inlinable public static var drainQueue: RawIORequest.Flags { Flags(rawValue: 1 << 1) }
        @inlinable public static var linkRequest: RawIORequest.Flags { Flags(rawValue: 1 << 2) }
        @inlinable public static var hardlinkRequest: RawIORequest.Flags { Flags(rawValue: 1 << 3) }
        @inlinable public static var asynchronous: RawIORequest.Flags { Flags(rawValue: 1 << 4) }
        @inlinable public static var selectBuffer: RawIORequest.Flags { Flags(rawValue: 1 << 5) }
        @inlinable public static var skipSuccess: RawIORequest.Flags { Flags(rawValue: 1 << 6) }
    }

    @inlinable var operation: Operation {
        get { Operation(rawValue: rawValue.opcode)! }
        set { rawValue.opcode = newValue.rawValue }
    }

    @inlinable var cancel_flags: UInt32 {
        get { rawValue.cancel_flags }
        set { rawValue.cancel_flags = newValue }
    }

    @inlinable var addr: UInt64 {
        get { rawValue.addr }
        set { rawValue.addr = newValue }
    }

    @inlinable public var flags: Flags {
        get { Flags(rawValue: rawValue.flags) }
        set { rawValue.flags = newValue.rawValue }
    }

    @inlinable public mutating func linkToNextRequest() {
        flags = Flags(rawValue: flags.rawValue | Flags.linkRequest.rawValue)
    }

    @inlinable public var fileDescriptor: FileDescriptor {
        get { FileDescriptor(rawValue: rawValue.fd) }
        set { rawValue.fd = newValue.rawValue }
    }

    @inlinable public var offset: UInt64? {
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

    @inlinable public var buffer: UnsafeMutableRawBufferPointer {
        get {
            let ptr = UnsafeMutableRawPointer(bitPattern: UInt(exactly: rawValue.addr)!)
            return UnsafeMutableRawBufferPointer(start: ptr, count: Int(rawValue.len))
        }

        set {
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
        case timeoutFlags(TimeOutFlags)
        // accept_flags
        // cancel_flags
        case openFlags(FileDescriptor.OpenOptions)
        // statx_flags
        // fadvise_advice
        // splice_flags
    }

    public struct ReadWriteFlags: OptionSet, Hashable, Codable {
        public var rawValue: UInt32
        @inlinable public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        @inlinable public static var highPriority: RawIORequest.ReadWriteFlags { ReadWriteFlags(rawValue: 1 << 0) }

        // sync with only data integrity
        @inlinable public static var dataSync: RawIORequest.ReadWriteFlags { ReadWriteFlags(rawValue: 1 << 1) }

        // sync with full data + file integrity
        @inlinable public static var fileSync: RawIORequest.ReadWriteFlags { ReadWriteFlags(rawValue: 1 << 2) }

        // return -EAGAIN if operation blocks
        @inlinable public static var noWait: RawIORequest.ReadWriteFlags { ReadWriteFlags(rawValue: 1 << 3) }

        // append to end of the file
        @inlinable public static var append: RawIORequest.ReadWriteFlags { ReadWriteFlags(rawValue: 1 << 4) }
    }

    public struct TimeOutFlags: OptionSet, Hashable, Codable {
        public var rawValue: UInt32

        @inlinable public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        @inlinable public static var relativeTime: RawIORequest.TimeOutFlags { TimeOutFlags(rawValue: 0) }
        @inlinable public static var absoluteTime: RawIORequest.TimeOutFlags { TimeOutFlags(rawValue: 1 << 0) }
    }
}

extension RawIORequest {
    @inlinable
    static func nop() -> RawIORequest {
        var req: RawIORequest = RawIORequest()
        req.operation = .nop
        return req
    }

    @inlinable
    static func withTimeoutRequest<R>(
        linkedTo opEntry: UnsafeMutablePointer<io_uring_sqe>,
        in timeoutEntry: UnsafeMutablePointer<io_uring_sqe>,
        duration: Duration, 
        flags: TimeOutFlags, 
        work: () throws -> R) rethrows -> R {

        opEntry.pointee.flags |= Flags.linkRequest.rawValue
        opEntry.pointee.off = 1
        var ts = timespec(
            tv_sec: Int(duration.components.seconds), 
            tv_nsec: Int(duration.components.attoseconds / 1_000_000_000)
        )
        return try withUnsafePointer(to: &ts) { tsPtr in
            var req: RawIORequest = RawIORequest()
            req.operation = .link_timeout
            req.rawValue.timeout_flags = flags.rawValue
            req.rawValue.len = 1
            req.rawValue.addr = UInt64(UInt(bitPattern: tsPtr))
            timeoutEntry.pointee = req.rawValue
            return try work()
        }
    }
}
#endif
#endif
