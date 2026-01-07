/*
 This source file is part of the Swift System open source project

 Copyright (c) 2025 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if canImport(System) && canImport(SystemPackage)
import System
import SystemPackage

extension SystemPackage.FilePath {
  @available(System 0.0.2, *)
  public init(converting path: System.FilePath) {
    self = path.withPlatformString(Self.init(platformString:))
  }
}

@available(System 0.0.1, *)
extension System.FilePath {
  @available(System 0.0.2, *)
  public init(converting path: SystemPackage.FilePath) {
    self = path.withPlatformString(Self.init(platformString:))
  }
}

extension SystemPackage.FileDescriptor {
  @available(System 0.0.1, *)
  public init(converting descriptor: System.FileDescriptor) {
    self.init(rawValue: descriptor.rawValue)
  }
}

@available(System 0.0.1, *)
extension System.FileDescriptor {
  @available(System 0.0.1, *)
  public init(converting descriptor: SystemPackage.FileDescriptor) {
    self.init(rawValue: descriptor.rawValue)
  }
}
#endif // canImport(System) && canImport(SystemPackage)
