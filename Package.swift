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

let swiftSettings: [SwiftSetting] = [
  .define(
    "SYSTEM_PACKAGE_DARWIN",
    .when(platforms: [.macOS, .macCatalyst, .iOS, .watchOS, .tvOS, .visionOS])),
  .define("SYSTEM_PACKAGE"),
  .define("ENABLE_MOCKING", .when(configuration: .debug)),
]

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
