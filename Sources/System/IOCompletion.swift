@_implementationOnly import CSystem

public extension IORing {
    struct Completion: ~Copyable {
        let rawValue: io_uring_cqe
    }
}

public extension IORing.Completion {
    struct Flags: OptionSet, Hashable, Codable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static let allocatedBuffer = Flags(rawValue: 1 << 0)
        public static let moreCompletions = Flags(rawValue: 1 << 1)
        public static let socketNotEmpty = Flags(rawValue: 1 << 2)
        public static let isNotificationEvent = Flags(rawValue: 1 << 3)
    }
}

public extension IORing.Completion {
    var context: UInt64 {
        get {
            rawValue.user_data
        }
    }

    var userPointer: UnsafeRawPointer? {
        get {
            UnsafeRawPointer(bitPattern: UInt(rawValue.user_data))
        }
    }

    var result: Int32 {
        get {
            rawValue.res
        }
    }

    var flags: IORing.Completion.Flags {
        get {
            Flags(rawValue: rawValue.flags & 0x0000FFFF)
        }
    }

    var bufferIndex: UInt16? {
        get {
            if self.flags.contains(.allocatedBuffer) {
                return UInt16(rawValue.flags >> 16)
            } else {
                return nil
            }
        }
    }
}
