// swift-tools-version:5.9
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

let cSettings: [CSetting] = [
  .define("_CRT_SECURE_NO_WARNINGS", .when(platforms: [.windows])),
]

let availability = [
    ("0.0.1", "macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0"),
    ("0.0.2", "macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0"),
    // FIXME: 0.0.3
    ("1.1.0", "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4"),
    // FIXME: 1.1.1
    ("1.2.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),
    // FIXME: 1.2.1
    ("1.3.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),
    // FIXME: 1.3.1
    // FIXME: 1.3.2
    ("1.4.0", "macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4"),
    // FIXME: 1.4.1
    // FIXME: 1.4.2
    // FIXME: 1.5.0
]

let swiftSettings: [SwiftSetting] = [
  .define(
    "SYSTEM_PACKAGE_DARWIN",
    .when(platforms: [.macOS, .macCatalyst, .iOS, .watchOS, .tvOS, .visionOS])),
  .define("SYSTEM_PACKAGE"),
  .define("ENABLE_MOCKING", .when(configuration: .debug)),
] + availability.map { (version, osAvailability) -> SwiftSetting in
  #if SYSTEM_PACKAGE
  // Matches default SwiftPM availability
  let availability = "macOS 10.10, iOS 8.0, watchOS 2.0, tvOS 9.0, visionOS 1.0"
  #else
  let availability = osAvailability
  #endif

  return .enableExperimentalFeature(
    "AvailabilityMacro=System \(version):\(availability)")
}

let package = Package(
  name: "swift-system",
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
      exclude: ["CMakeLists.txt"],
      cSettings: cSettings,
      swiftSettings: swiftSettings),
    .testTarget(
      name: "SystemTests",
      dependencies: ["SystemPackage"],
      cSettings: cSettings,
      swiftSettings: swiftSettings),
  ])
