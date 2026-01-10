/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Internal wrappers and typedefs for socket operations

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
@_implementationOnly import CSystem
import Glibc
#elseif canImport(Musl)
@_implementationOnly import CSystem
import Musl
#elseif canImport(Android)
@_implementationOnly import CSystem
import Android
#else
#error("Unsupported Platform")
#endif

import SystemPackage

// MARK: - errno access

#if SYSTEM_PACKAGE_DARWIN
internal var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#elseif canImport(Glibc)
internal var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#elseif canImport(Musl)
internal var system_errno: CInt {
  get { Musl.errno }
  set { Musl.errno = newValue }
}
#elseif canImport(Android)
internal var system_errno: CInt {
  get { Android.errno }
  set { Android.errno = newValue }
}
#endif

// MARK: - C stdlib functions

@usableFromInline
internal func system_strlen(_ s: UnsafePointer<CChar>) -> Int {
  strlen(s)
}

@usableFromInline
internal func system_strlen(_ s: UnsafeMutablePointer<CChar>) -> Int {
  strlen(s)
}

internal func system_memset(
  _ buffer: UnsafeMutableRawBufferPointer,
  to byte: UInt8
) {
  guard buffer.count > 0 else { return }
  memset(buffer.baseAddress!, CInt(byte), buffer.count)
}
