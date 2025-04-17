@_implementationOnly import CSystem

public struct IOCompletion: ~Copyable {
    let rawValue: io_uring_cqe
}

extension IOCompletion {
    public struct Flags: OptionSet, Hashable, Codable {
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

extension IOCompletion {
    public var context: UInt64 {
        get {
            rawValue.user_data
        }
    }

    public var userPointer: UnsafeRawPointer? {
        get {
            UnsafeRawPointer(bitPattern: UInt(rawValue.user_data))
        }
    }

    public var result: Int32 {
        get {
            rawValue.res
        }
    }

    public var flags: IOCompletion.Flags {
        get {
            Flags(rawValue: rawValue.flags & 0x0000FFFF)
        }
    }

    public var bufferIndex: UInt16? {
        get {
            if self.flags.contains(.allocatedBuffer) {
                return UInt16(rawValue.flags >> 16)
            } else {
                return nil
            }
        }
    }
}
