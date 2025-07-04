#if os(Linux)
import CSystem

public extension IORing {
    struct Completion: ~Copyable {
        @inlinable init(rawValue inRawValue: io_uring_cqe) {
            rawValue = inRawValue
        }
        @usableFromInline let rawValue: io_uring_cqe
    }
}

public extension IORing.Completion {
    struct Flags: OptionSet, Hashable, Codable {
        public let rawValue: UInt32

        @inlinable public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let allocatedBuffer = Flags(rawValue: 1 << 0)
        public static let moreCompletions = Flags(rawValue: 1 << 1)
        public static let socketNotEmpty = Flags(rawValue: 1 << 2)
        public static let isNotificationEvent = Flags(rawValue: 1 << 3)
    }
}

public extension IORing.Completion {
    @inlinable var context: UInt64 {
        get {
            rawValue.user_data
        }
    }

    @inlinable var userPointer: UnsafeRawPointer? {
        get {
            UnsafeRawPointer(bitPattern: UInt(rawValue.user_data))
        }
    }

    @inlinable var result: Int32 {
        get {
            rawValue.res
        }
    }

    @inlinable var flags: IORing.Completion.Flags {
        get {
            Flags(rawValue: rawValue.flags & 0x0000FFFF)
        }
    }

    @inlinable var bufferIndex: UInt16? {
        get {
            if self.flags.contains(.allocatedBuffer) {
                return UInt16(rawValue.flags >> 16)
            } else {
                return nil
            }
        }
    }
}
#endif
