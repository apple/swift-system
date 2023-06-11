/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

// MARK: - Mode Masks
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// mode_t: type ugs rwx rwx rwx
@_alwaysEmitIntoClient
internal var _MODE_PERMISSIONS: CInterop.Mode { 0b0000_111_111_111_111 }

@_alwaysEmitIntoClient
internal var _MODE_TYPE: CInterop.Mode { 0b1111_000_000_000_000 }
#endif

// MARK: - File Type
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _S_IFIFO: CInterop.Mode { S_IFIFO }

@_alwaysEmitIntoClient
internal var _S_IFCHR: CInterop.Mode { S_IFCHR }

@_alwaysEmitIntoClient
internal var _S_IFDIR: CInterop.Mode { S_IFDIR }

@_alwaysEmitIntoClient
internal var _S_IFBLK: CInterop.Mode { S_IFBLK }

@_alwaysEmitIntoClient
internal var _S_IFREG: CInterop.Mode { S_IFREG }

@_alwaysEmitIntoClient
internal var _S_IFLNK: CInterop.Mode { S_IFLNK }

@_alwaysEmitIntoClient
internal var _S_IFSOCK: CInterop.Mode { S_IFSOCK }

@_alwaysEmitIntoClient
internal var _S_IFWHT: CInterop.Mode { S_IFWHT }
#endif

// MARK: - File Flags
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _UF_NODUMP: CInterop.FileFlags { UInt32(bitPattern: UF_NODUMP) }

@_alwaysEmitIntoClient
internal var _UF_IMMUTABLE: CInterop.FileFlags { UInt32(bitPattern: UF_IMMUTABLE) }

@_alwaysEmitIntoClient
internal var _UF_APPEND: CInterop.FileFlags { UInt32(bitPattern: UF_APPEND) }

@_alwaysEmitIntoClient
internal var _UF_OPAQUE: CInterop.FileFlags { UInt32(bitPattern: UF_OPAQUE) }

#if os(FreeBSD)
@_alwaysEmitIntoClient
internal var _UF_NOUNLINK: CInterop.FileFlags { UInt32(bitPattern: UF_NOUNLINK) }
#endif

@_alwaysEmitIntoClient
internal var _UF_COMPRESSED: CInterop.FileFlags { UInt32(bitPattern: UF_COMPRESSED) }

@_alwaysEmitIntoClient
internal var _UF_TRACKED: CInterop.FileFlags { UInt32(bitPattern: UF_TRACKED) }

@_alwaysEmitIntoClient
internal var _UF_DATAVAULT: CInterop.FileFlags { UInt32(bitPattern: UF_DATAVAULT) }

@_alwaysEmitIntoClient
internal var _UF_HIDDEN: CInterop.FileFlags { UInt32(bitPattern: UF_HIDDEN) }

@_alwaysEmitIntoClient
internal var _SF_ARCHIVED: CInterop.FileFlags { UInt32(bitPattern: SF_ARCHIVED) }

@_alwaysEmitIntoClient
internal var _SF_IMMUTABLE: CInterop.FileFlags { UInt32(bitPattern: SF_IMMUTABLE) }

@_alwaysEmitIntoClient
internal var _SF_APPEND: CInterop.FileFlags { UInt32(bitPattern: SF_APPEND) }

@_alwaysEmitIntoClient
internal var _SF_RESTRICTED: CInterop.FileFlags { UInt32(bitPattern: SF_RESTRICTED) }

@_alwaysEmitIntoClient
internal var _SF_NOUNLINK: CInterop.FileFlags { UInt32(bitPattern: SF_NOUNLINK) }

#if os(FreeBSD)
@_alwaysEmitIntoClient
internal var _SF_SNAPSHOT: CInterop.FileFlags { UInt32(bitPattern: SF_SNAPSHOT) }
#endif

@_alwaysEmitIntoClient
internal var _SF_FIRMLINK: CInterop.FileFlags { UInt32(bitPattern: SF_FIRMLINK) }

@_alwaysEmitIntoClient
internal var _SF_DATALESS: CInterop.FileFlags { UInt32(bitPattern: SF_DATALESS) }
#endif

// MARK: - Time Specification
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _UTIME_NOW: Int { Int(UTIME_NOW) }

@_alwaysEmitIntoClient
internal var _UTIME_OMIT: Int { Int(UTIME_OMIT) }
#endif
