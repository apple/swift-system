/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

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

  // FIXME: This isn't right
  /// seconds since 1970
  @_alwaysEmitIntoClient
  public var seconds: Int { Int(rawValue.tv_sec) }

  /// nanoseconds
  @_alwaysEmitIntoClient
  public var nanoseconds: Int { rawValue.tv_nsec }

  // FIXME: This isn't right
  // (-1)
  static var now: TimeSpecification {
    .init(rawValue: CInterop.TimeSpec(tv_sec: .min, tv_nsec: _UTIME_NOW))
  }

  // FIXME: This isn't right
  // (-2)
  static var omit: TimeSpecification {
    .init(rawValue: CInterop.TimeSpec(tv_sec: .min, tv_nsec: _UTIME_OMIT))
  }
}

#endif
