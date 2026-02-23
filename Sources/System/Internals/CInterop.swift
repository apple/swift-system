/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif os(Windows)
import CSystem
import ucrt
#elseif canImport(Glibc)
@_implementationOnly import CSystem
import Glibc
#elseif canImport(Musl)
@_implementationOnly import CSystem
import Musl
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Bionic)
import CSystem
import Bionic
#else
#error("Unsupported Platform")
#endif

// MARK: - Public typealiases

// FIXME: `CModeT` ought to be deprecated and replaced with `CInterop.Mode`
//        if/when the compiler becomes less strict about availability checking
//        of "namespaced" typealiases. (rdar://81722893)
#if os(Windows)
/// The C `mode_t` type.
public typealias CModeT = CInt
#else
/// The C `mode_t` type.
@available(System 0.0.1, *)
public typealias CModeT = mode_t
#endif

/// A namespace for C and platform types
@available(System 0.0.2, *)
public enum CInterop {
#if os(Windows)
  public typealias Mode = CInt
#else
  public typealias Mode = mode_t
#endif

  /// The C `char` type
  public typealias Char = CChar

  #if os(Windows)
  /// The platform's preferred character type. On Unix, this is an 8-bit C
  /// `char` (which may be signed or unsigned, depending on platform). On
  /// Windows, this is `UInt16` (a "wide" character).
  public typealias PlatformChar = UInt16
  #else
  /// The platform's preferred character type. On Unix, this is an 8-bit C
  /// `char` (which may be signed or unsigned, depending on platform). On
  /// Windows, this is `UInt16` (a "wide" character).
  public typealias PlatformChar = CInterop.Char
  #endif

  #if os(Windows)
  /// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
  /// Windows it is UTF-16. Native strings may contain invalid Unicode,
  /// which will be handled by either error-correction or failing, depending
  /// on API.
  public typealias PlatformUnicodeEncoding = UTF16
  #else
  /// The platform's preferred Unicode encoding. On Unix this is UTF-8 and on
  /// Windows it is UTF-16. Native strings may contain invalid Unicode,
  /// which will be handled by either error-correction or failing, depending
  /// on API.
  public typealias PlatformUnicodeEncoding = UTF8
  #endif
}

#if !os(Windows)
@available(System 0.0.2, *) // Original availability of CInterop
extension CInterop {
  /// The C `stat` struct.
  public typealias Stat = stat

  /// Calls the C `stat()` function.
  ///
  /// This is a direct wrapper around the C `stat()` system call.
  /// For a more ergonomic Swift API, use `Stat` instead.
  ///
  /// - Warning: This API is primarily intended for migration purposes when
  ///   supporting older deployment targets. If your deployment target supports
  ///   it, prefer using the `Stat` API introduced in SYS-0006, which provides
  ///   type-safe, ergonomic access to file metadata in Swift.
  ///
  /// - Parameters:
  ///   - path: A null-terminated C string representing the file path.
  ///   - s: An `inout` reference to a `CInterop.Stat` struct to populate.
  /// - Returns: 0 on success, -1 on error (check `Errno.current`).
  @_alwaysEmitIntoClient
  public static func stat(_ path: UnsafePointer<CChar>, _ s: inout CInterop.Stat) -> Int32 {
    system_stat(path, &s)
  }
}

@available(System 99, *)
extension CInterop {
  public typealias DeviceID = dev_t
  public typealias Inode = ino_t
  public typealias UserID = uid_t
  public typealias GroupID = gid_t
  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  public typealias FileFlags = UInt32
  #endif
}
#endif
