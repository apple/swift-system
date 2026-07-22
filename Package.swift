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
    self.sourceAvailability = "macOS 10.10, iOS 8.0, watchOS 2.0, tvOS 9.0, visionOS 1.0"
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

  Available("1.4.1", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
  Available("1.4.2", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
  Available("1.5.0", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
  Available("1.6.0", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
  Available("1.6.1", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),

  Available("99", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
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
  // --- SE-0529 FilePath port ---
  // Settings folded in for the base (Sources/System/FilePath) and the compat
  // layer (Sources/System/SystemFilePath), mirroring the prep repo's separate
  // FilePath + SystemFilePath targets now that they share one module.
  //
  // Defines the `SwiftStdlib 9999` availability token every base decl carries.
  .enableExperimentalFeature(
    "AvailabilityMacro=SwiftStdlib 9999:macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
  // Selects the base's real per-platform resolve() syscall branch and its own
  // _internalInvariant, instead of the stdlib SwiftShims stub branch.
  .define("FILEPATH_PACKAGE"),
  // swift-system historically ships a non-failable FilePath(_: String); the
  // base's is failable and the two can't coexist on one type. This makes the
  // base drop its public failable init?(_:) so the compat layer's non-failable
  // init(_:) is the sole one (see FilePathStringBridging.swift / the compat
  // FilePathString.swift PORT note).
  .define("FILEPATH_SYSTEM_STRING_COMPAT"),
  // The base is 9999-gated; the swift-system substrate that calls it is not.
  // Disable enforcement (matches the prep's consumer targets).
  .unsafeFlags(["-Xfrontend", "-disable-availability-checking"]),
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
let platforms: [SupportedPlatform]? = nil
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
  swiftLanguageModes: [.v5]
)
