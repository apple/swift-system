/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

public extension FileDescriptor {
    
    /// Set of file descriptors
    @frozen
    struct Set {
        
        @_alwaysEmitIntoClient
        internal private(set) var bytes: CInterop.FileDescriptorSet
                
        @_alwaysEmitIntoClient
        public init(_ bytes: CInterop.FileDescriptorSet) {
            self.bytes = bytes
        }
        
        @_alwaysEmitIntoClient
        public init() {
            self.init(CInterop.FileDescriptorSet())
        }
    }
}

public extension FileDescriptor.Set {
    
    @_alwaysEmitIntoClient
    init<S>(_ sequence: S) where S: Sequence, S.Element == FileDescriptor {
        self.init()
        for element in sequence {
            bytes.set(element.rawValue)
        }
    }
    
    @_alwaysEmitIntoClient
    mutating func append(_ element: FileDescriptor) {
        bytes.set(element.rawValue)
    }
    
    @_alwaysEmitIntoClient
    mutating func remove(_ element: FileDescriptor) {
        bytes.clear(element.rawValue)
    }
    
    @_alwaysEmitIntoClient
    mutating func contains(_ element: FileDescriptor) -> Bool {
        bytes.isSet(element.rawValue)
    }
    
    @_alwaysEmitIntoClient
    mutating func removeAll() {
        self.bytes.zero()
    }
    
    #if os(Windows)
    @_alwaysEmitIntoClient
    var count: Int {
        return numericCast(bytes.fd_count)
    }
    #endif
}

extension FileDescriptor.Set: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: FileDescriptor...) {
        assert(elements.count <= _fd_set_count,
               "FileDescriptor.Set can only contain \(_fd_set_count) elements")
        self.init(elements)
    }
}

extension FileDescriptor.Set: CustomStringConvertible, CustomDebugStringConvertible {
    
    @inline(never)
    public var description: String {
        return "FileDescriptor.Set()"
    }
    
    public var debugDescription: String {
        return description
    }
}

public extension FileDescriptor.Set {
    
    @_alwaysEmitIntoClient
    mutating func withUnsafeMutablePointer<T>(_ body: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
        return try bytes.withUnsafeMutablePointer(body)
    }
}

internal extension CInterop.FileDescriptorSet {
    
    @usableFromInline
    mutating func zero() {
        withUnsafeMutablePointer {
            $0.initialize(repeating: 0, count: _fd_set_count)
        }
    }
    
    ///
    /// Set an fd in an fd_set
    ///
    /// - Parameter fd:    The fd to add to the fd_set
    ///
    @usableFromInline
    mutating func set(_ fd: Int32) {
        let (index, mask) = Self.address(for: fd)
        withUnsafeMutablePointer { $0[index] |= mask }
    }
    
    ///
    /// Clear an fd from an fd_set
    ///
    /// - Parameter fd:    The fd to clear from the fd_set
    ///
    @usableFromInline
    mutating func clear(_ fd: Int32) {
        let (index, mask) = Self.address(for: fd)
        withUnsafeMutablePointer { $0[index] &= ~mask }
    }
    
    ///
    /// Check if an fd is present in an fd_set
    ///
    /// - Parameter fd:    The fd to check
    ///
    ///    - Returns:    `True` if present, `false` otherwise.
    ///
    @usableFromInline
    mutating func isSet(_ fd: Int32) -> Bool {
        let (index, mask) = Self.address(for: fd)
        return withUnsafeMutablePointer { $0[index] & mask != 0 }
    }
    
    @usableFromInline
    static func address(for fd: Int32) -> (Int, Int32) {
        var intOffset = Int(fd) / _fd_set_count
        #if _endian(big)
        if intOffset % 2 == 0 {
            intOffset += 1
        } else {
            intOffset -= 1
        }
        #endif
        let bitOffset = Int(fd) % _fd_set_count
        let mask = Int32(bitPattern: UInt32(1 << bitOffset))
        return (intOffset, mask)
    }
    
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    @usableFromInline
    mutating func withUnsafeMutablePointer<T>(_ body: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
        return try Swift.withUnsafeMutablePointer(to: &fds_bits) {
            try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Int32.self))
        }
    }
#elseif os(Linux) || os(FreeBSD) || os(Android)
    @usableFromInline
    mutating func withUnsafeMutablePointer<T>(_ body: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
        return try Swift.withUnsafeMutablePointer(to: &__fds_bits) {
            try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Int32.self))
        }
    }
#elseif os(Windows)
    @usableFromInline
    mutating func withUnsafeMutablePointer<T>(_ body: (UnsafeMutablePointer<Int32>) throws -> T) rethrows -> T {
        return try Swift.withUnsafeMutablePointer(to: &fds_bits) {
            try body(UnsafeMutableRawPointer($0).assumingMemoryBound(to: Int32.self))
        }
    }
#endif
}
