/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

extension FixedWidthInteger {
  internal var _networkOrder: Self {
    bigEndian
  }

  internal init(_networkOrder value: Self) {
    self.init(bigEndian: value)
  }
}
