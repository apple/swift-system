// swift-tools-version:6.0
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription

struct Availability {
  var name: String
  var version: String
  var osAvailability: String

  var minSwiftPMVersions: String {
    "macOS 10.10, iOS 8.0, watchOS 2.0, tvOS 9.0, visionOS 1.0"
  }
  var minSpanDeploymentVersions: String {
    "macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0"
  }

  var isStandardAvailability: Bool { name == "System" }
}

let availabilityMap: [(String, String)] = [
  ("0.0.1", "macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0"),
  ("0.0.2", "macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0"),
  ("1.1.0", "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4"),
  ("1.2.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),
  ("1.4.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.0"),

  ("99", "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999"),
]

let availabilities: [Availability] =
  availabilityMap.map {
    Availability(name: "System", version: $0.0, osAvailability: $0.1)
  } + availabilityMap.prefix(5).map {
    Availability(name: "SystemWithSpan", version: $0.0, osAvailability: $0.1)
  }

let swiftSettingsAvailability = availabilities.map {
  availability -> SwiftSetting in
  let osVersionList: String
#if SYSTEM_ABI_STABLE
  // Use availability matching Darwin API.
  osVersionList = availability.osAvailability
#else
  if availability.isStandardAvailability {
    // Use availability matching SwiftPM minimum.
    osVersionList = availability.minSwiftPMVersions
  } else {
    // Use availability matching Span deployment minimum.
    osVersionList = availability.minSpanDeploymentVersions
  }
#endif
  return .enableExperimentalFeature(
    "AvailabilityMacro=\(availability.name) \(availability.version):\(osVersionList)"
  )
}

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
    .library(name: "SystemSockets", targets: ["SystemSockets"]),
    .executable(name: "system-samples", targets: ["Samples"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
  ],
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
    .target(
      name: "SystemSockets",
      dependencies: ["SystemPackage", "CSystem"],
      path: "Sources/SystemSockets",
      cSettings: cSettings,
      swiftSettings: swiftSettings),
    .testTarget(
      name: "SystemSocketsTests",
      dependencies: ["SystemSockets"],
      cSettings: cSettings,
      swiftSettings: swiftSettings),
    .executableTarget(
      name: "Samples",
      dependencies: [
        "SystemPackage",
        "SystemSockets",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/Samples",
      swiftSettings: swiftSettings),
  ],
  swiftLanguageVersions: [.v5]
)
