// swift-tools-version:5.9

/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020-2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import PackageDescription

let DarwinPlatforms: [Platform] = [.macOS, .iOS, .watchOS, .tvOS, .visionOS]

let package = Package(
    name: "swift-system",
    platforms: [.macOS(.v10_13), .iOS(.v12), .watchOS(.v4), .tvOS(.v12), .visionOS(.v1)],
    products: [
      .library(name: "SystemPackage", targets: ["SystemPackage"])
    ],
    dependencies: [],
    targets: [
      .target(
        name: "CSystem",
        dependencies: []),
      .target(
        name: "SystemPackage",
        dependencies: ["CSystem"],
        path: "Sources/System",
        cSettings: [
          .define("_CRT_SECURE_NO_WARNINGS")
        ],
        swiftSettings: [
          .define("SYSTEM_PACKAGE"),
          .define("SYSTEM_PACKAGE_DARWIN", .when(platforms: DarwinPlatforms)),
          .define("ENABLE_MOCKING", .when(configuration: .debug))
        ]),
      .testTarget(
        name: "SystemTests",
        dependencies: ["SystemPackage"],
        swiftSettings: [
          .define("SYSTEM_PACKAGE"),
          .define("SYSTEM_PACKAGE_DARWIN", .when(platforms: DarwinPlatforms)),
        ]),
    ]
)
