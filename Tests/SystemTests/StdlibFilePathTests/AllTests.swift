/*
 This source file is part of the SE-0529 reference implementation

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// These suites historically ran under `@Suite(.serialized)` so the runner
// never interleaved tests that mutated a shared mutable platform global.
// That global is gone — platform selection is now compile-time
// (see FilePathParsing.swift `_isWindows` / `_isDarwin` / `_isLinux`,
// and TestSupport.swift `_builtPlatform`) — so serialization is no
// longer strictly required. Kept as harmless and to preserve a stable
// run order.
@Suite(.serialized)
struct AllTests {
  struct DecompositionTests {}
  struct ComponentViewTests {}
  struct ValidationTests {}
  // New coverage (see TestSupport.swift for the framework/platform seam).
  struct EqualityTests {}
  struct StringBridgingTests {}
  struct ReconstructionTests {}
}
