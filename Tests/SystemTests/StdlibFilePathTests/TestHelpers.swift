/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

struct Expected {
  var anchor: String?
  var components: [String]
  var hasTrailingSeparator: Bool = false
  var isResourceFork: Bool = false

  var printed: String
  var isAbsolute: Bool
  var isRooted: Bool? = nil
  var driveLetter: Unicode.Scalar? = nil
  var kinds: [_StdlibFilePath.Component.Kind]? = nil
}

// Test-only helpers for integer-offset indexing into ComponentView.
extension _StdlibFilePath.ComponentView {
  func idx(_ offset: Int) -> Index {
    index(startIndex, offsetBy: offset)
  }

  func range(_ r: Range<Int>) -> Range<Index> {
    idx(r.lowerBound) ..< idx(r.upperBound)
  }
}

struct PathTestCase {
  var input: String
  var linux: Expected
  var darwin: Expected
  var windows: Expected

  init(
    input: String, unix: Expected, windows: Expected
  ) {
    self.input = input
    self.linux = unix
    self.darwin = unix
    self.windows = windows
  }

  init(
    input: String, linux: Expected, darwin: Expected, windows: Expected
  ) {
    self.input = input
    self.linux = linux
    self.darwin = darwin
    self.windows = windows
  }
}
