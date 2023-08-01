@_implementationOnly import CSystem

public class AsyncFileDescriptor {    
    var open: Bool = true
    @usableFromInline let fileSlot: IORingFileSlot
    @usableFromInline let ring: ManagedIORing
    
    static func openat(
        atDirectory: FileDescriptor = FileDescriptor(rawValue: AT_FDCWD), 
        path: FilePath,
        _ mode: FileDescriptor.AccessMode,
        options: FileDescriptor.OpenOptions = FileDescriptor.OpenOptions(),
        permissions: FilePermissions? = nil,
        onRing ring: ManagedIORing
    ) async throws -> AsyncFileDescriptor {
        // todo; real error type
        guard let fileSlot = ring.getFileSlot() else {
            throw IORingError.missingRequiredFeatures
        }
        let cstr = path.withCString {
            return $0 // bad
        }
        let res = await ring.submitAndWait(.openat(
            atDirectory: atDirectory, 
            path: cstr,
            mode,
            options: options,
            permissions: permissions, intoSlot: fileSlot
        ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        }
        
        return AsyncFileDescriptor(
            fileSlot, ring: ring
        )
    }

    internal init(_ fileSlot: IORingFileSlot, ring: ManagedIORing) {
        self.fileSlot = fileSlot
        self.ring = ring
    }

    func close() async throws {
        self.open = false
        fatalError()
    }

    @inlinable @inline(__always) @_unsafeInheritExecutor
    func read(
        into buffer: IORequest.Buffer,
        atAbsoluteOffset offset: UInt64 = UInt64.max
    ) async throws -> UInt32 {
        let res = await ring.submitAndWait(.read(
            file: .registered(self.fileSlot),
            buffer: buffer,
            offset: offset
        ))
        if res.result < 0 {
            throw Errno(rawValue: -res.result)
        } else {
            return UInt32(bitPattern: res.result)
        }
    }

    deinit {
        if (self.open) {
            // TODO: close
        }
    }
}
