/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Windows)

import WinSDK

extension Errno {
  internal init(windowsError: DWORD) {
    self.init(rawValue: _mapWindowsErrorToErrno(windowsError))
  }
}

@available(System 199, *)
extension Errno {
  /// Creates the closest POSIX ``Errno`` for a Windows system error.
  ///
  /// This mapping is lossy. It approximates the C runtime's `_dosmaperr`,
  /// folding Windows' several thousand system error codes onto a small set
  /// of ``Errno`` values. Unrecognized codes become ``Errno/invalidArgument``.
  /// Prefer handling ``Win32Error`` directly.
  public init(approximating error: Win32Error) {
    self.init(windowsError: error.rawValue)
  }
}

#endif
