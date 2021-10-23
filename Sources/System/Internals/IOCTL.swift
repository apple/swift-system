/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Linux)

/// #define _IOC(dir,type,nr,size) \
/// (((dir)  << _IOC_DIRSHIFT) | \
/// ((type) << _IOC_TYPESHIFT) | \
/// ((nr)   << _IOC_NRSHIFT) | \
/// ((size) << _IOC_SIZESHIFT))
@usableFromInline
internal func _IOC(
    _ direction: IODirection,
    _ type: IOType,
    _ nr: CInt,
    _ size: CInt
) -> CUnsignedLong {
    
    let dir = CInt(direction.rawValue)
    let dirValue = dir << _DIRSHIFT
    let typeValue = type.rawValue << _TYPESHIFT
    let nrValue = nr << _NRSHIFT
    let sizeValue = size << _SIZESHIFT
    let value = CLong(dirValue | typeValue | nrValue | sizeValue)
    return CUnsignedLong(bitPattern: value)
}

@_alwaysEmitIntoClient
internal var _NRBITS: CInt       { CInt(8) }

@_alwaysEmitIntoClient
internal var _TYPEBITS: CInt     { CInt(8) }

@_alwaysEmitIntoClient
internal var _SIZEBITS: CInt     { CInt(14) }

@_alwaysEmitIntoClient
internal var _DIRBITS: CInt      { CInt(2) }

@_alwaysEmitIntoClient
internal var _NRMASK: CInt       { CInt((1 << _NRBITS)-1) }

@_alwaysEmitIntoClient
internal var _TYPEMASK: CInt     { CInt((1 << _TYPEBITS)-1) }

@_alwaysEmitIntoClient
internal var _SIZEMASK: CInt     { CInt((1 << _SIZEBITS)-1) }

@_alwaysEmitIntoClient
internal var _DIRMASK: CInt      { CInt((1 << _DIRBITS)-1) }

@_alwaysEmitIntoClient
internal var _NRSHIFT: CInt      { CInt(0) }

@_alwaysEmitIntoClient
internal var _TYPESHIFT: CInt    { CInt(_NRSHIFT+_NRBITS) }

@_alwaysEmitIntoClient
internal var _SIZESHIFT: CInt    { CInt(_TYPESHIFT+_TYPEBITS) }

@_alwaysEmitIntoClient
internal var _DIRSHIFT: CInt     { CInt(_SIZESHIFT+_SIZEBITS) }
#endif
