/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

extension FileDescriptor {
  internal func fileSize(
    retryOnInterrupt: Bool = true
  ) throws -> Int64 {
    let current = try seek(offset: 0, from: .current)
    let size = try seek(offset: 0, from: .end)
    try seek(offset: current, from: .start)
    return size
  }
}
