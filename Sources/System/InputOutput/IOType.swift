/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Linux)

/// `ioctl` Device driver identifier code
@frozen
public struct IOType: RawRepresentable, Equatable, Hashable {
    
    @_alwaysEmitIntoClient
    public let rawValue: CInt
    
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByUnicodeScalarLiteral

extension IOType: ExpressibleByUnicodeScalarLiteral {
    
    @_alwaysEmitIntoClient
    public init(unicodeScalarLiteral character: Unicode.Scalar) {
        self.init(rawValue: CInt(character.value))
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension IOType: ExpressibleByIntegerLiteral {
    
    @_alwaysEmitIntoClient
    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)
    }
}

// MARK: - Definitions

// https://01.org/linuxgraphics/gfx-docs/drm/ioctl/ioctl-number.html
public extension IOType {
    
    /// Floppy Disk
    @_alwaysEmitIntoClient
    static var floppyDisk: IOType { 0x02 } // linux/fd.h
    
    /// InfiniBand Subsystem
    @_alwaysEmitIntoClient
    static var infiniBand: IOType { 0x1b }
    
    /// IEEE 1394 Subsystem Block for the entire subsystem
    @_alwaysEmitIntoClient
    static var ieee1394: IOType { "#" }
    
    /// Performance counter
    @_alwaysEmitIntoClient
    static var performance: IOType { "$" } // linux/perf_counter.h, linux/perf_event.h
    
    /// System Trace Module subsystem
    @_alwaysEmitIntoClient
    static var systemTrace: IOType { "%" } // include/uapi/linux/stm.h
    
    /// Kernel-based Virtual Machine
    @_alwaysEmitIntoClient
    static var kvm: IOType { 0xAF }  // linux/kvm.h
    
    /// Freescale hypervisor
    @_alwaysEmitIntoClient
    static var freescaleHypervisor: IOType { 0xAF }  // linux/fsl_hypervisor.h
    
    /// GPIO
    @_alwaysEmitIntoClient
    static var gpio: IOType { 0xB4 }  // linux/gpio.h
    
    /// Linux FUSE
    @_alwaysEmitIntoClient
    static var fuse: IOType { 0xE5 }  // linux/fuse.h
    
    /// ChromeOS EC driver
    @_alwaysEmitIntoClient
    static var chromeEC: IOType { 0xEC } // drivers/platform/chrome/cros_ec_dev.h
}

#endif
