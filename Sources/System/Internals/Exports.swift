/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Internal wrappers and typedefs which help reduce #if littering in System's
// code base.

// TODO: Should CSystem just include all the header files we need?

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
@_implementationOnly import CSystem
import Glibc
#elseif os(Windows)
import CSystem
import ucrt
#else
#error("Unsupported Platform")
#endif

internal typealias _COffT = off_t

// MARK: syscalls and variables

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
internal var system_errno: CInt {
  get { Darwin.errno }
  set { Darwin.errno = newValue }
}
#elseif os(Windows)
internal var system_errno: CInt {
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
internal var system_errno: CInt {
  get { Glibc.errno }
  set { Glibc.errno = newValue }
}
#endif

// MARK: C stdlib decls

// Convention: `system_foo` is system's wrapper for `foo`.

internal func system_strerror(_ __errnum: Int32) -> UnsafeMutablePointer<Int8>! {
  strerror(__errnum)
}

internal func system_strlen(_ s: UnsafePointer<Int8>) -> Int {
  strlen(s)
}

// Convention: `system_platform_foo` is a
// platform-representation-abstracted wrapper around `foo`-like functionality.
// Type and layout differences such as the `char` vs `wchar` are abstracted.
//

// strlen for the platform string
internal func system_platform_strlen(_ s: UnsafePointer<CInterop.PlatformChar>) -> Int {
  #if os(Windows)
  return wcslen(s)
  #else
  return strlen(s)
  #endif
}

// Interop between String and platfrom string
extension String {
  internal func _withPlatformString<Result>(
    _ body: (UnsafePointer<CInterop.PlatformChar>) throws -> Result
  ) rethrows -> Result {
    // Need to #if because CChar may be signed
    #if os(Windows)
    return try withCString(encodedAs: CInterop.PlatformUnicodeEncoding.self, body)
    #else
    return try withCString(body)
    #endif
  }

  internal init?(_platformString platformString: UnsafePointer<CInterop.PlatformChar>) {
    // Need to #if because CChar may be signed
    #if os(Windows)
    guard let strRes = String.decodeCString(
      platformString,
      as: CInterop.PlatformUnicodeEncoding.self,
      repairingInvalidCodeUnits: false
    ) else { return nil }
    assert(strRes.repairsMade == false)
    self = strRes.result
    return

    #else
    self.init(validatingUTF8: platformString)
    #endif
  }

  internal init(
    _errorCorrectingPlatformString platformString: UnsafePointer<CInterop.PlatformChar>
  ) {
    // Need to #if because CChar may be signed
    #if os(Windows)
    let strRes = String.decodeCString(
      platformString,
      as: CInterop.PlatformUnicodeEncoding.self,
      repairingInvalidCodeUnits: true)
    self = strRes!.result
    return
    #else
    self.init(cString: platformString)
    #endif
  }
}

// TLS
#if os(Windows)
internal typealias _PlatformTLSKey = DWORD
#else
internal typealias _PlatformTLSKey = pthread_key_t
#endif

internal func makeTLSKey() -> _PlatformTLSKey {
  #if os(Windows)
  let raw: DWORD = FlsAlloc(nil)
  if raw == FLS_OUT_OF_INDEXES {
    fatalError("Unable to create key")
  }
  return raw
  #else
  var raw = pthread_key_t()
  guard 0 == pthread_key_create(&raw, nil) else {
    fatalError("Unable to create key")
  }
  return raw
  #endif
}
internal func setTLS(_ key: _PlatformTLSKey, _ p: UnsafeMutableRawPointer?) {
  #if os(Windows)
  guard FlsSetValue(key, p) else {
    fatalError("Unable to set TLS")
  }
  #else
  guard 0 == pthread_setspecific(key, p) else {
    fatalError("Unable to set TLS")
  }
  #endif
}
internal func getTLS(_ key: _PlatformTLSKey) -> UnsafeMutableRawPointer? {
  #if os(Windows)
  return FlsGetValue(key)
  #else
  return pthread_getspecific(key)
  #endif
}
