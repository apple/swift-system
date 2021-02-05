/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import CSystem

// Internal wrappers and typedefs which help reduce #if littering in System's
// code base.

// TODO: Should CSystem just include all the header files we need?

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#elseif os(Windows)
import ucrt
#else
#error("Unsupported Platform")
#endif

public typealias COffT = off_t

#if os(Windows)
public typealias CModeT = CInt
#else
public typealias CModeT = mode_t
#endif

// MARK: syscalls and variables

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
public var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#elseif os(Windows)
public var system_errno: CInt {
  get {
    var value: CInt = 0
    // TODO(compnerd) handle the error?
    _ = ucrt._get_errno(&value)
    return value
  }
  set {
    _ = ucrt._set_errno(newValue)
  }
}
#else
public var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#endif

// MARK: C stdlib decls

// Convention: `system_foo` is system's wrapper for `foo`.

public func system_strerror(_ __errnum: Int32) -> UnsafeMutablePointer<Int8>! {
  strerror(__errnum)
}

public func system_strlen(_ s: UnsafePointer<Int8>) -> Int {
  strlen(s)
}

#if os(Windows)
public typealias _PlatformChar = UInt16
#else
public typealias _PlatformChar = CChar
#endif
#if os(Windows)
public typealias _PlatformUnicodeEncoding = UTF16
#else
public typealias _PlatformUnicodeEncoding = UTF8
#endif


// Convention: `system_platform_foo` is a
// platform-representation-abstracted wrapper around `foo`-like functionality.
// Type and layout differences such as the `char` vs `wchar` are abstracted.
//

// strlen for the platform string
public func system_platform_strlen(_ s: UnsafePointer<_PlatformChar>) -> Int {
  #if os(Windows)
  return wcslen(s)
  #else
  return strlen(s)
  #endif
}

// Interop between String and platfrom string
extension String {
  public func _withPlatformString<Result>(
    _ body: (UnsafePointer<_PlatformChar>) throws -> Result
  ) rethrows -> Result {
    // Need to #if because CChar may be signed
    #if os(Windows)
    return try withCString(encodedAs: _PlatformUnicodeEncoding.self, body)
    #else
    return try withCString(body)
    #endif
  }

  public init?(_platformString platformString: UnsafePointer<_PlatformChar>) {
    // Need to #if because CChar may be signed
    #if os(Windows)
    guard let strRes = String.decodeCString(
      platformString,
      as: _PlatformUnicodeEncoding.self,
      repairingInvalidCodeUnits: false
    ) else { return nil }
    assert(strRes.repairsMade == false)
    self = strRes.result
    return

    #else
    self.init(validatingUTF8: platformString)
    #endif
  }

  public init(
    _errorCorrectingPlatformString platformString: UnsafePointer<_PlatformChar>
  ) {
    // Need to #if because CChar may be signed
    #if os(Windows)
    let strRes = String.decodeCString(
      platformString,
      as: _PlatformUnicodeEncoding.self,
      repairingInvalidCodeUnits: true)
    self = strRes!.result
    return
    #else
    self.init(cString: platformString)
    #endif
  }


}
