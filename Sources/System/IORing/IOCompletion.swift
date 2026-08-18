/*
 This source file is part of the Swift System open source project

 Copyright (c) 2023 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if compiler(>=6.2) && $Lifetimes
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
        
        ///`IORING_CQE_F_BUFFER` Indicates the buffer ID is stored in the upper 16 bits
        @inlinable public static var allocatedBuffer: Flags { Flags(rawValue: 1 << 0) }
        ///`IORING_CQE_F_MORE`  Indicates more completions will be generated from the request that generated this
        @inlinable public static var moreCompletions: Flags { Flags(rawValue: 1 << 1) }
        //`IORING_CQE_F_SOCK_NONEMPTY`, but currently unused
        //@inlinable public static var socketNotEmpty: Flags { Flags(rawValue: 1 << 2) }
        //`IORING_CQE_F_NOTIF`, but currently unused
        //@inlinable public static var isNotificationEvent: Flags { Flags(rawValue: 1 << 3) }
        //IORING_CQE_F_BUF_MORE  will eventually be  (1U << 4) if we add IOU_PBUF_RING_INC support
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

    /// The result of the completed operation.
    ///
    /// A non-negative value is the operation's success result: a byte count
    /// for a read or a write, an event mask for a poll, and so on.
    ///
    /// A negative value is an `errno` code multiplied by -1. Recover the error
    /// by negating it again: `Errno(rawValue: -completion.result)`.
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
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
