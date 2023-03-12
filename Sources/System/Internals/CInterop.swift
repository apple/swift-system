/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(OpenBSD) || os(Android)
@_implementationOnly import CSystem
import Glibc
#elseif os(Windows)
import CSystem
import ucrt
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
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
public typealias CModeT = mode_t
#endif

/// A namespace for C and platform types
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
public enum CInterop {
#if os(Windows)
  public typealias Mode = CInt
#else
  public typealias Mode = mode_t
#endif

  /// The C `char` type
  public typealias Char = CChar

  /// The C `short` type
  public typealias CShort = Int16

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

#if !os(Windows)
  /// The C `struct flock` type
  public typealias FileLock = flock

  /// The C `pid_t` type
  public typealias PID = pid_t

  /// The C `off_t` type.
  ///
  /// Note System generally standardizes on `Int64` where `off_t`
  /// might otherwise appear. This typealias allows conversion code to be
  /// emitted into client.
  public typealias Offset = off_t

  #if !os(Linux)
  /// The C `fstore` type
  public typealias FStore = fstore

  /// The C `fpunchhole` type
  public typealias FPunchhole = fpunchhole

  /// The C `radvisory` type
  public typealias RAdvisory = radvisory

  /// The C `radvisory` type
  public typealias Log2Phys = log2phys
  #endif

#endif // !os(Windows)

}


