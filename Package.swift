// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import PackageDescription

let settings: [SwiftSetting]? = [
  .define("SYSTEM_PACKAGE")
]

let targets: [PackageDescription.Target] = [
  .target(
    name: "SystemPackage",
    dependencies: ["CSystem"],
    path: "Sources/System",
    swiftSettings: [
      .define("SYSTEM_PACKAGE"),
      .define("ENABLE_MOCKING", .when(configuration: .debug))
    ]),
  .target(
    name: "CSystem",
    dependencies: []),

  .target(
    name: "SystemSockets",
    dependencies: ["SystemPackage"]),

  .testTarget(
    name: "SystemTests",
    dependencies: ["SystemPackage"],
    swiftSettings: settings
  ),

  .testTarget(
      name: "SystemSocketsTests",
      dependencies: ["SystemSockets"],
      swiftSettings: settings
    ),

  .target(
    name: "Samples",
    dependencies: [
      "SystemPackage",
      "SystemSockets",
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ],
    path: "Sources/Samples",
    swiftSettings: settings
  ),
]

let package = Package(
    name: "swift-system",
    products: [
      .library(name: "SystemPackage", targets: ["SystemPackage"]),
      .executable(name: "system-samples", targets: ["Samples"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: targets
)
