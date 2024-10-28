@_implementationOnly import CSystem

//TODO: should be ~Copyable, but requires UnsafeContinuation add ~Copyable support
public struct IOCompletion {
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
    public var userData: UInt64 {
        get {
            return rawValue.user_data
        }
    }

    public var result: Int32 {
        get {
            return rawValue.res
        }
    }

    public var flags: IOCompletion.Flags {
        get {
            return Flags(rawValue: rawValue.flags & 0x0000FFFF)
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
