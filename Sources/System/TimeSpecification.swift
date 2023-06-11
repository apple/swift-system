/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin

// FIXME: Document
@frozen
public struct TimeSpecification: RawRepresentable {
  /// The raw C time spec type.
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.TimeSpec

  /// Create a strongly-typed time specification from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.TimeSpec) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  private init(_ raw: CInterop.TimeSpec) { self.init(rawValue: raw) }

  /// seconds since 1970
  @_alwaysEmitIntoClient
  public var seconds: Int {
    get { rawValue.tv_sec }
    set { rawValue.tv_sec = newValue }
  }

  /// nanoseconds
  @_alwaysEmitIntoClient
  public var nanoseconds: Int {
    get { rawValue.tv_nsec }
    set { rawValue.tv_nsec = newValue }
  }
}

#endif
