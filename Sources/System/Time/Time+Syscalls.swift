/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// getitimer
internal func system_getitimer(
  _ timer: CInt,
  _ currentValue: UnsafeMutablePointer<itimerval>
) -> CInt {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(timer, currentValue) }
#endif
  return getitimer(timer, currentValue)
}

// setitimer
internal func system_setitimer(
  _ timer: CInt,
  _ newValue: UnsafePointer<itimerval>,
  _ oldValue: UnsafeMutablePointer<itimerval>?
) -> Int32 {
#if ENABLE_MOCKING
  if mockingEnabled { return _mock(timer, newValue, oldValue) }
#endif
  return setitimer(timer, newValue, oldValue)
}
#endif
