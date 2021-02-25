/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

@_implementationOnly import SystemInternals


// Public typealiases that can't be reexported from SystemInternals

/// The C `mode_t` type.
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(*, deprecated, renamed: "CInterop.Mode")
public typealias CModeT =  CInterop.Mode

/// A namespace for C and platform types
public enum CInterop {
  #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  /// The C `mode_t` type.
  public typealias Mode = UInt16
  #elseif os(Windows)
  /// The C `mode_t` type.
  public typealias Mode = Int32
  #else
  /// The C `mode_t` type.
  public typealias Mode = UInt32
  #endif

  /// The C `char` type
  public typealias Char = CChar
}
