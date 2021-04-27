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

  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  /// The C `stat` type.
  public typealias Stat = stat

  /// The C `uid_t` type.
  public typealias UserID = uid_t

  /// The C `gid_t` type.
  public typealias GroupID = gid_t

  /// The C `dev_t` type.
  public typealias DeviceID = dev_t

  /// The C `nlink_t` type.
  public typealias NumberOfLinks = nlink_t

  /// The C `ino_t` type.
  public typealias INodeNumber = ino_t

  /// The C `timespec` type.
  public typealias TimeSpec = timespec

  /// The C `off_t` type.
  public typealias Offset = off_t

  /// The C `blkcnt_t` type.
  public typealias BlockCount = blkcnt_t

  /// The C `blksize_t` type.
  public typealias BlockSize = blksize_t

  /// The C `UInt32` type.
  public typealias GenerationID = UInt32

  /// The C `UInt32` type.
  public typealias FileFlags = UInt32
  #endif
}
