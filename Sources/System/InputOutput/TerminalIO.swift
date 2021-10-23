/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(Linux) || os(FreeBSD) || os(Android)
/// Terminal `ioctl` definitions
@frozen
public struct TerminalIO: IOControlID, Equatable, Hashable {
    
    public let rawValue: CUnsignedLong
    
    public init(rawValue: CUnsignedLong) {
        self.rawValue = rawValue
    }
    
    @_alwaysEmitIntoClient
    private init(_ rawValue: CUnsignedLong) {
        self.init(rawValue: rawValue)
    }
}

public extension TerminalIO {
    
    /// Turn break on, that is, start sending zero bits.
    @_alwaysEmitIntoClient
    static var setBreakBit: TerminalIO { TerminalIO(_TIOCSBRK) }
    
    /// Turn break off, that is, stop sending zero bits.
    @_alwaysEmitIntoClient
    static var clearBreakBit: TerminalIO { TerminalIO(_TIOCCBRK) }
    
    /// Put the terminal into exclusive mode.
    @_alwaysEmitIntoClient
    static var setExclusiveMode: TerminalIO { TerminalIO(_TIOCEXCL) }
    
    /// Reset exclusive use of tty.
    @_alwaysEmitIntoClient
    static var resetExclusiveMode: TerminalIO { TerminalIO(_TIOCNXCL) }
    
    /// Get the line discipline of the terminal.
    @_alwaysEmitIntoClient
    static var getLineDiscipline: TerminalIO { TerminalIO(_TIOCGETD) }
    
    /// Set the line discipline of the terminal.
    @_alwaysEmitIntoClient
    static var setLineDiscipline: TerminalIO { TerminalIO(_TIOCSETD) }
}

public extension TerminalIO {
    
    /// Get the line discipline of the terminal.
    @frozen
    struct GetLineDiscipline: Equatable, Hashable, IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: TerminalIO { .getLineDiscipline }
        
        public private(set) var lineDiscipline: Int
        
        public init() {
            self.lineDiscipline = 0
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            // Argument: int *argp
            var value: CInt = numericCast(self.lineDiscipline)
            let result = try Swift.withUnsafeMutableBytes(of: &value) { buffer in
                try body(buffer.baseAddress!)
            }
            self.lineDiscipline = numericCast(value)
            return result
        }
    }
    
    /// Set the line discipline of the terminal.
    @frozen
    struct SetLineDiscipline: Equatable, Hashable, IOControlValue {
        
        @_alwaysEmitIntoClient
        public static var id: TerminalIO { .setLineDiscipline }
        
        public let lineDiscipline: Int
        
        public init(lineDiscipline: Int) {
            self.lineDiscipline = lineDiscipline
        }
        
        public mutating func withUnsafeMutablePointer<Result>(_ body: (UnsafeMutableRawPointer) throws -> (Result)) rethrows -> Result {
            // Argument: const int *argp
            var value: CInt = numericCast(self.lineDiscipline)
            let result = try Swift.withUnsafeMutableBytes(of: &value) { buffer in
                try body(buffer.baseAddress!)
            }
            assert(numericCast(value) == self.lineDiscipline, "Value changed")
            return result
        }
    }
}

#endif
