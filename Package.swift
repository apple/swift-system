// swift-tools-version:6.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription

/// The availability floor every `System` macro maps to in the SwiftPM build.
let systemSourceAvailability =
  "macOS 10.10, iOS 8.0, watchOS 2.0, tvOS 9.0, visionOS 1.0"

struct Available {
  var name: String
  var version: String
  var osAvailability: String
  var sourceAvailability: String

  init(
    _ version: String,
    _ osAvailability: String
  ) {
    self.name = "System"
    self.version = version
    self.osAvailability = osAvailability
    self.sourceAvailability = systemSourceAvailability
  }

  var swiftSetting: SwiftSetting {
    #if SYSTEM_ABI_STABLE
    // Use availability matching Darwin API.
    let availability = self.osAvailability
    #else
    // Use availability matching SwiftPM default.
    let availability = self.sourceAvailability
    #endif
    return .enableExperimentalFeature(
      "AvailabilityMacro=\(self.name) \(version):\(availability)")
  }
}

let availability: [Available] = [
  Available("0.0.1", "macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0"),

  Available("0.0.2", "macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0"),

  Available("0.0.3", "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4"),
  Available("1.1.0", "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4"),

  Available("1.1.1", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),
  Available("1.2.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),

  Available("1.2.1", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),
  Available("1.3.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),

  Available("1.3.1", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.0"),
  Available("1.3.2", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.0"),
  Available("1.4.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.0"),

  Available("1.7.0", "macOS 27.0, iOS 27.0, watchOS 27.0, tvOS 27.0, visionOS 27.0"),

  Available("199", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
]

let swiftSettingsAvailability = availability.map(\.swiftSetting)

#if SYSTEM_CI
let swiftSettingsCI: [SwiftSetting] = [
  .unsafeFlags(["-require-explicit-availability=error"]),
]
#else
let swiftSettingsCI: [SwiftSetting] = []
#endif

let swiftSettings = swiftSettingsAvailability + swiftSettingsCI + [
  .define(
    "SYSTEM_PACKAGE_DARWIN",
    .when(platforms: [.macOS, .macCatalyst, .iOS, .watchOS, .tvOS, .visionOS])),
  .define("SYSTEM_PACKAGE"),
  .define("ENABLE_MOCKING", .when(configuration: .debug)),
  .enableExperimentalFeature("Lifetimes"),

  // MARK: - Dual-backing FilePath (testing branch)
  //
  // FilePath is a wrapper over two backings: the classic swift-system
  // implementation (_SwiftSystemFilePath, the default) and the SE-0529 one
  // (_StdlibFilePath), selected by _SWIFT_SYSTEM_NEW_FILEPATH. The settings
  // below are what that transplanted code was validated with.

  // The SE-0529 core carries @available(SwiftStdlib 9999, *) throughout. That
  // is a stdlib-build spelling for "a future release". Map it to 26, the floor
  // where `Span` (which the core's code-unit views vend) became available.
  //
  // Deliberately NOT mapped to 9999 with -disable-availability-checking, which
  // is how the prototype built it: that flag also folds `#available` queries to
  // true, so runtime-gated tests (the macOS 27 dup3/pipe2 skips in
  // FileOperationsTest) would stop skipping and fail with ENOSYS. 26 is also
  // strictly below those 27 gates, so they still skip.
  .enableExperimentalFeature(
    "AvailabilityMacro=SwiftStdlib 9999:macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26"),
  // Selects the package flavor of the SE-0529 core: its own
  // _internalInvariant, and a libc resolve() instead of the SwiftShims one.
  .define("FILEPATH_PACKAGE"),
  // The transplanted code was validated in the Swift 5 language mode; match it
  // so Swift 6 concurrency diagnostics do not masquerade as real errors.
  .swiftLanguageMode(.v5),
]

let cSettings: [CSetting] = [
  .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
]

#if SYSTEM_ABI_STABLE
let platforms: [SupportedPlatform] = [
  .macOS("26"),
  .iOS("26"),
  .watchOS("26"),
  .tvOS("26"),
  .visionOS("26"),
]
#else
// Dual-backing FilePath (testing branch): the SE-0529 core vends `Span`, which
// needs a 26 floor, and its `@available(SwiftStdlib 9999, *)` is mapped to 26
// above. A nil (SwiftPM-default, 10.13-era) deployment target would make every
// use of those decls "only available in macOS 26 or newer". Upstream this is
// nil; the 27 runtime gates in FileOperationsTest still evaluate normally
// because 26 is below them.
let platforms: [SupportedPlatform]? = [
  .macOS("26"),
  .iOS("26"),
  .watchOS("26"),
  .tvOS("26"),
  .visionOS("26"),
]
#endif

#if os(Linux)
let filesToExclude = ["CMakeLists.txt"]
#else
let filesToExclude = ["CMakeLists.txt", "IORing"]
#endif

#if os(Linux)
let testsToExclude:[String] = []
#else
let testsToExclude = ["IORequestTests.swift", "IORingTests.swift"]
#endif

let package = Package(
  name: "swift-system",
  platforms: platforms,
  products: [
    .library(name: "SystemPackage", targets: ["SystemPackage"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "CSystem",
      dependencies: [],
      exclude: ["CMakeLists.txt"],
      cSettings: cSettings),
    .target(
      name: "SystemPackage",
      dependencies: ["CSystem"],
      path: "Sources/System",
      exclude: filesToExclude,
      cSettings: cSettings,
      swiftSettings: swiftSettings),
    .testTarget(
      name: "SystemTests",
      dependencies: ["SystemPackage"],
      exclude: testsToExclude,
      cSettings: cSettings,
      swiftSettings: swiftSettings),
    // Builds a SystemPackage consumer with MemberImportVisibility enabled.
    // Fails if a C member of a vended type is attributed to the CSystem module.
    .testTarget(
      name: "MemberImportVisibility",
      dependencies: ["SystemPackage"],
      swiftSettings: [.enableUpcomingFeature("MemberImportVisibility")]),
  ],
  swiftLanguageModes: [.v6]
)
