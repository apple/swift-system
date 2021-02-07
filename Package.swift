// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import PackageDescription

let targets: [PackageDescription.Target] = [
  .target(
    name: "SystemPackage",
    dependencies: ["SystemInternals"],
    path: "Sources/System"),
  .target(
    name: "SystemInternals",
    dependencies: ["CSystem"],
    swiftSettings: [
      .define("ENABLE_MOCKING", .when(configuration: .debug))
    ]),
  .target(
    name: "CSystem",
    dependencies: []),
  .target(
    name: "CodeGen",
    dependencies: ["SystemPackage"]),
  .target(
    name: "RunCodeGen",
    dependencies: ["CodeGen"]),

  .testTarget(
    name: "SystemTests",
    dependencies: ["SystemPackage"]),
  .testTarget(
    name: "CodeGenTests",
    dependencies: ["CodeGen"]),
]

let package = Package(
    name: "swift-system",
    products: [
        .library(name: "SystemPackage", targets: ["SystemPackage"]),
    ],
    dependencies: [],
    targets: targets
)
