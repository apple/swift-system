/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - umask
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileMode {
  @_alwaysEmitIntoClient
  func updateProcessMask() -> Self {
    _updateProcessMask()
  }

  @usableFromInline
  func _updateProcessMask() -> Self {
    Self(rawValue: system_umask(self.rawValue))
  }
}
#endif
