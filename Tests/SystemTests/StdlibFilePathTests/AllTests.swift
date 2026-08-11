/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// `.serialized` fixes the run order across the nested suites. Nothing here
// shares mutable state to protect: the platform is selected at compile time
// (`_isWindows` / `_isDarwin` / `_isLinux` in FilePathParsing.swift,
// `_builtPlatform` in TestSupport.swift).
@Suite(.serialized)
struct AllTests {
  struct DecompositionTests {}
  struct ComponentViewTests {}
  struct ValidationTests {}
  struct EqualityTests {}
  struct StringBridgingTests {}
  struct ReconstructionTests {}
}
