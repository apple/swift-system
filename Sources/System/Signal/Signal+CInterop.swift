/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

extension CInterop {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
  /// The C `int` type
  public typealias Signal = CInt
#endif
}
