#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import CSystem

@usableFromInline
internal enum IORequestCore {
    case nop  // nothing here
    case openat(
        atDirectory: FileDescriptor,
        path: FilePath,
        FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    )
    case openatSlot(
        atDirectory: FileDescriptor,
        path: FilePath,
        FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        intoSlot: IORing.RegisteredFile,
        context: UInt64 = 0
    )
    case pollAdd(
        file: FileDescriptor,
        pollEvents: IORing.Request.PollEvents,
        isMultiShot: Bool = true,
        context: UInt64 = 0
    )
    case read(
        file: FileDescriptor,
        buffer: IORing.RegisteredBuffer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case readUnregistered(
        file: FileDescriptor,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case readSlot(
        file: IORing.RegisteredFile,
        buffer: IORing.RegisteredBuffer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case readUnregisteredSlot(
        file: IORing.RegisteredFile,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case write(
        file: FileDescriptor,
        buffer: IORing.RegisteredBuffer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case writeUnregistered(
        file: FileDescriptor,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case writeSlot(
        file: IORing.RegisteredFile,
        buffer: IORing.RegisteredBuffer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case writeUnregisteredSlot(
        file: IORing.RegisteredFile,
        buffer: UnsafeMutableRawBufferPointer,
        offset: UInt64 = 0,
        context: UInt64 = 0
    )
    case close(
        FileDescriptor,
        context: UInt64 = 0
    )
    case closeSlot(
        IORing.RegisteredFile,
        context: UInt64 = 0
    )
    case unlinkAt(
        atDirectory: FileDescriptor,
        path: FilePath,
        context: UInt64 = 0
    )
    case cancel(
        flags:UInt32
    )
    case cancelContext(
        flags: UInt32,
        targetContext: UInt64
    )
    case cancelFD(
        flags: UInt32,
        targetFD: FileDescriptor
    )
    case cancelFDSlot(
        flags: UInt32,
        target: IORing.RegisteredFile
    )

}

@inline(__always) @inlinable
internal func makeRawRequest_readWrite_registered(
    file: FileDescriptor,
    buffer: IORing.RegisteredBuffer,
    offset: UInt64,
    context: UInt64 = 0,
    request: consuming RawIORequest
) -> RawIORequest {
    request.fileDescriptor = file
    request.buffer = buffer.unsafeBuffer
    request.rawValue.buf_index = UInt16(exactly: buffer.index)!
    request.offset = offset
    request.rawValue.user_data = context
    return request
}

@inline(__always) @inlinable
internal func makeRawRequest_readWrite_registered_slot(
    file: IORing.RegisteredFile,
    buffer: IORing.RegisteredBuffer,
    offset: UInt64,
    context: UInt64 = 0,
    request: consuming RawIORequest
) -> RawIORequest {
    request.rawValue.fd = Int32(exactly: file.index)!
    request.flags = .fixedFile
    request.buffer = buffer.unsafeBuffer
    request.rawValue.buf_index = UInt16(exactly: buffer.index)!
    request.offset = offset
    request.rawValue.user_data = context
    return request
}

@inline(__always) @inlinable
internal func makeRawRequest_readWrite_unregistered(
    file: FileDescriptor,
    buffer: UnsafeMutableRawBufferPointer,
    offset: UInt64,
    context: UInt64 = 0,
    request: consuming RawIORequest
) -> RawIORequest {
    request.fileDescriptor = file
    request.buffer = buffer
    request.offset = offset
    request.rawValue.user_data = context
    return request
}

@inline(__always) @inlinable
internal func makeRawRequest_readWrite_unregistered_slot(
    file: IORing.RegisteredFile,
    buffer: UnsafeMutableRawBufferPointer,
    offset: UInt64,
    context: UInt64 = 0,
    request: consuming RawIORequest
) -> RawIORequest {
    request.rawValue.fd = Int32(exactly: file.index)!
    request.flags = .fixedFile
    request.buffer = buffer
    request.offset = offset
    request.rawValue.user_data = context
    return request
}

extension IORing {
    public struct Request {
        @usableFromInline var core: IORequestCore

        @inlinable internal init(core inCore: IORequestCore) {
            core = inCore
        }

        @inlinable internal consuming func extractCore() -> IORequestCore {
            return core
        }
    }
}



extension IORing.Request {
    @inlinable public static func nop(context: UInt64 = 0) -> IORing.Request {
        .init(core: .nop)
    }

    /// Adds a poll operation to monitor a file descriptor for specific I/O events.
    ///
    /// This method creates an io_uring poll operation that monitors the specified file descriptor
    /// for I/O readiness events. The operation completes when any of the requested events become
    /// active on the file descriptor, such as data becoming available for reading or the descriptor
    /// becoming ready for writing.
    ///
    /// Poll operations are useful for implementing efficient I/O multiplexing, allowing you to
    /// monitor multiple file descriptors concurrently within a single io_uring instance. When used
    /// with multishot mode, a single poll operation can deliver multiple completion events without
    /// needing to be resubmitted.
    ///
    /// ## Multishot Behavior
    ///
    /// When `isMultiShot` is `true`, the poll operation automatically rearms after each completion
    /// event, continuing to monitor the file descriptor for subsequent events. This reduces
    /// submission overhead for long-lived monitoring operations. The operation continues until
    /// explicitly cancelled or the file descriptor is closed.
    ///
    /// When `isMultiShot` is `false`, the poll operation completes once after the first matching
    /// event occurs, requiring resubmission to continue monitoring.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// // Monitor a socket for incoming connections
    /// let pollRequest = IORing.Request.pollAdd(
    ///     listenSocket,
    ///     pollEvents: .pollin,
    ///     isMultiShot: true,
    ///     context: 1
    /// )
    /// try ring.submit(pollRequest)
    ///
    /// // Process completions
    /// for completion in try ring.completions() {
    ///     if completion.context == 1 {
    ///         // Handle incoming connection
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - file: The file descriptor to monitor for I/O events.
    ///   - pollEvents: The I/O events to monitor on the file descriptor.
    ///   - isMultiShot: If `true`, the poll operation automatically rearms after each event,
    ///     continuing to monitor the file descriptor. If `false`, the operation completes after
    ///     the first matching event. Defaults to `false`.
    ///   - context: An application-specific value passed through to the completion event,
    ///     allowing you to identify which operation completed. Defaults to `0`.
    ///
    /// - Returns: An I/O ring request that monitors the file descriptor for the specified events.
    ///
    /// ## See Also
    ///
    /// - ``PollEvents``: The events that can be monitored.
    /// - ``IORing/Request/cancel(_:matching:)``: Cancelling poll operations.
    @inlinable public static func pollAdd(
        _ file: FileDescriptor,
        pollEvents: PollEvents,
        isMultiShot: Bool = false,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .pollAdd(file: file, pollEvents: pollEvents, context: context))
    }
    
    @inlinable public static func read(
        _ file: IORing.RegisteredFile,
        into buffer: IORing.RegisteredBuffer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .readSlot(file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func read(
        _ file: FileDescriptor,
        into buffer: IORing.RegisteredBuffer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .read(file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func read(
        _ file: IORing.RegisteredFile,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .readUnregisteredSlot(file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func read(
        _ file: FileDescriptor,
        into buffer: UnsafeMutableRawBufferPointer,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .readUnregistered(file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func write(
        _ buffer: IORing.RegisteredBuffer,
        into file: IORing.RegisteredFile,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .writeSlot(file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func write(
        _ buffer: IORing.RegisteredBuffer,
        into file: FileDescriptor,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .write(file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func write(
        _ buffer: UnsafeMutableRawBufferPointer,
        into file: IORing.RegisteredFile,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .writeUnregisteredSlot(
                file: file, buffer: buffer, offset: offset, context: context))
    }

    @inlinable public static func write(
        _ buffer: UnsafeMutableRawBufferPointer,
        into file: FileDescriptor,
        at offset: UInt64 = 0,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(
            core: .writeUnregistered(file: file, buffer: buffer, offset: offset, context: context)
        )
    }

    @inlinable public static func close(
        _ file: FileDescriptor,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .close(file, context: context))
    }

    @inlinable public static func close(
        _ file: IORing.RegisteredFile,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .closeSlot(file, context: context))
    }

    @inlinable public static func open(
        _ path: FilePath,
        in directory: FileDescriptor,
        into slot: IORing.RegisteredFile,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(
            core: .openatSlot(
                atDirectory: directory, path: path, mode, options: options,
                permissions: permissions, intoSlot: slot, context: context))
    }

    @inlinable public static func open(
        _ path: FilePath,
        in directory: FileDescriptor,
        mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(
            core: .openat(
                atDirectory: directory, path: path, mode, options: options,
                permissions: permissions, context: context
            ))
    }

    @inlinable public static func unlink(
        _ path: FilePath,
        in directory: FileDescriptor,
        context: UInt64 = 0
    ) -> IORing.Request {
        .init(core: .unlinkAt(atDirectory: directory, path: path, context: context))
    }

    // Cancel

    /*
    * ASYNC_CANCEL flags.
    *
    * IORING_ASYNC_CANCEL_ALL	Cancel all requests that match the given key
    * IORING_ASYNC_CANCEL_FD	Key off 'fd' for cancellation rather than the
    *				request 'user_data'
    * IORING_ASYNC_CANCEL_ANY	Match any request
    * IORING_ASYNC_CANCEL_FD_FIXED	'fd' passed in is a fixed descriptor
    * IORING_ASYNC_CANCEL_USERDATA	Match on user_data, default for no other key
    * IORING_ASYNC_CANCEL_OP	Match request based on opcode
    */

@inlinable internal static var SWIFT_IORING_ASYNC_CANCEL_ALL: UInt32 { 1 << 0 }
@inlinable internal static var SWIFT_IORING_ASYNC_CANCEL_FD: UInt32 { 1 << 1 }
@inlinable internal static var SWIFT_IORING_ASYNC_CANCEL_ANY: UInt32 { 1 << 2 }
@inlinable internal static var SWIFT_IORING_ASYNC_CANCEL_FD_FIXED: UInt32 { 1 << 3 }
@inlinable internal static var SWIFT_IORING_ASYNC_CANCEL_USERDATA: UInt32 { 1 << 4 }
@inlinable internal static var SWIFT_IORING_ASYNC_CANCEL_OP: UInt32 { 1 << 5 }

    public enum CancellationMatch {
    	case all
    	case first
    }
    
    @inlinable public static func cancel(
    	_ matchAll: CancellationMatch,
    	matchingContext: UInt64
    ) -> IORing.Request {
        switch matchAll {
            case .all:
                .init(core: .cancelContext(flags: SWIFT_IORING_ASYNC_CANCEL_ALL | SWIFT_IORING_ASYNC_CANCEL_USERDATA, targetContext: matchingContext))
            case .first:
                .init(core: .cancelContext(flags: SWIFT_IORING_ASYNC_CANCEL_USERDATA, targetContext: matchingContext))
        }
    }
    
    @inlinable public static func cancel(
    	_ matchAll: CancellationMatch,
    	matching: FileDescriptor
    ) -> IORing.Request {
        switch matchAll {
            case .all:
                .init(core: .cancelFD(flags: SWIFT_IORING_ASYNC_CANCEL_ALL | SWIFT_IORING_ASYNC_CANCEL_FD, targetFD: matching))
            case .first:
                .init(core: .cancelFD(flags: SWIFT_IORING_ASYNC_CANCEL_FD, targetFD: matching))
        }
    }
    
    @inlinable public static func cancel(
    	_ matchAll: CancellationMatch,
    	matching: IORing.RegisteredFile
    ) -> IORing.Request {
        switch matchAll {
            case .all:
                .init(core: .cancelFDSlot(flags: SWIFT_IORING_ASYNC_CANCEL_ALL | SWIFT_IORING_ASYNC_CANCEL_FD_FIXED, target: matching))
            case .first:
                .init(core: .cancelFDSlot(flags: SWIFT_IORING_ASYNC_CANCEL_FD_FIXED, target: matching))
        }
    }

    @inlinable public static func cancel(
    	_ matchAll: CancellationMatch,
    ) -> IORing.Request {
        switch matchAll {
            case .all:
                .init(core: .cancel(flags: SWIFT_IORING_ASYNC_CANCEL_ALL))
            case .first:
                .init(core: .cancel(flags: SWIFT_IORING_ASYNC_CANCEL_ANY))
        }
    }

    @inline(__always) @inlinable
    internal consuming func makeRawRequest() -> RawIORequest {
        var request = RawIORequest()
        switch extractCore() {
        case .nop:
            request.operation = .nop
        case .openatSlot(
            let atDirectory, let path, let mode, let options, let permissions, let fileSlot,
            let context):
            // TODO: use rawValue less
            request.operation = .openAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = UInt64(
                UInt(
                    bitPattern: path.withPlatformString { ptr in
                        ptr  //this is unsavory, but we keep it alive by storing path alongside it in the request
                    }))
            request.rawValue.open_flags = UInt32(bitPattern: options.rawValue | mode.rawValue)
            request.rawValue.len = permissions?.rawValue ?? 0
            request.rawValue.file_index = UInt32(fileSlot.index + 1)
            request.path = path
            request.rawValue.user_data = context
        case .openat(
            let atDirectory, let path, let mode, let options, let permissions, let context):
            request.operation = .openAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = UInt64(
                UInt(
                    bitPattern: path.withPlatformString { ptr in
                        ptr  //this is unsavory, but we keep it alive by storing path alongside it in the request
                    }))
            request.rawValue.open_flags = UInt32(bitPattern: options.rawValue | mode.rawValue)
            request.rawValue.len = permissions?.rawValue ?? 0
            request.path = path
            request.rawValue.user_data = context
        case .write(let file, let buffer, let offset, let context):
            request.operation = .writeFixed
            return makeRawRequest_readWrite_registered(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .writeSlot(let file, let buffer, let offset, let context):
            request.operation = .writeFixed
            return makeRawRequest_readWrite_registered_slot(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .writeUnregistered(let file, let buffer, let offset, let context):
            request.operation = .write
            return makeRawRequest_readWrite_unregistered(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .writeUnregisteredSlot(let file, let buffer, let offset, let context):
            request.operation = .write
            return makeRawRequest_readWrite_unregistered_slot(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .read(let file, let buffer, let offset, let context):
            request.operation = .readFixed
            return makeRawRequest_readWrite_registered(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .readSlot(let file, let buffer, let offset, let context):
            request.operation = .readFixed
            return makeRawRequest_readWrite_registered_slot(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .readUnregistered(let file, let buffer, let offset, let context):
            request.operation = .read
            return makeRawRequest_readWrite_unregistered(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .readUnregisteredSlot(let file, let buffer, let offset, let context):
            request.operation = .read
            return makeRawRequest_readWrite_unregistered_slot(
                file: file, buffer: buffer, offset: offset, context: context, request: request)
        case .close(let file, let context):
            request.operation = .close
            request.fileDescriptor = file
            request.rawValue.user_data = context
        case .closeSlot(let file, let context):
            request.operation = .close
            request.rawValue.file_index = UInt32(file.index + 1)
            request.rawValue.user_data = context
        case .unlinkAt(let atDirectory, let path, let context):
            request.operation = .unlinkAt
            request.fileDescriptor = atDirectory
            request.rawValue.addr = UInt64(
                UInt(
                    bitPattern: path.withPlatformString { ptr in
                        ptr  //this is unsavory, but we keep it alive by storing path alongside it in the request
                    })
            )
            request.path = path
            request.rawValue.user_data = context
        case .cancelContext(let flags, let targetContext):
            request.operation = .asyncCancel
            request.cancel_flags = flags
            request.addr = targetContext
        case .cancelFD(let flags, let targetFD):
            request.operation = .asyncCancel
            request.cancel_flags = flags
            request.fileDescriptor = targetFD
        case .cancelFDSlot(let flags, let target):
            request.operation = .asyncCancel
            request.cancel_flags = flags
            request.rawValue.fd = Int32(target.index)
        case .cancel(let flags):
            request.operation = .asyncCancel
            request.cancel_flags = flags
        case .pollAdd(let file, let pollEvents, let isMultiShot, let context):
            request.operation = .pollAdd
            request.fileDescriptor = file
            request.rawValue.user_data = context
            if isMultiShot {
                request.rawValue.len = IORING_POLL_ADD_MULTI
            }
            request.rawValue.poll32_events = pollEvents.rawValue
        }

        return request
    }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
