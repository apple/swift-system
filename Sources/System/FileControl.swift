/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

// Strongly typed, Swifty interfaces to the most common and useful `fcntl`
// commands.

extension FileDescriptor {
  @usableFromInline
  internal func _fcntl(
    _ cmd: Control.Command, _ lock: inout FileDescriptor.FileLock,
    retryOnInterrupt: Bool
  ) -> Result<(), Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      withUnsafeMutablePointer(to: &lock) {
        system_fcntl(self.rawValue, cmd.rawValue, $0)
      }
    }
  }
}
