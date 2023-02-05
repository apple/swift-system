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
@_alwaysEmitIntoClient
internal var _ITIMER_REAL: CInterop.IntervalTimer { ITIMER_REAL }
@_alwaysEmitIntoClient
internal var _ITIMER_VIRTUAL: CInterop.IntervalTimer { ITIMER_VIRTUAL }
@_alwaysEmitIntoClient
internal var _ITIMER_PROF: CInterop.IntervalTimer { ITIMER_PROF }
#endif
