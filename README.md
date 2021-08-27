# Swift System

Swift System provides idiomatic interfaces to system calls and low-level currency types. Our vision is for System to act as the single home for low-level system interfaces for all supported Swift platforms.

## Multi-platform not Cross-platform

System is a multi-platform library, not a cross-platform one. It provides a separate set of APIs and behaviors on every supported platform, closely reflecting the underlying OS interfaces. A single import will pull in the native platform interfaces specific for the targeted OS.

Our immediate goal is to simplify building cross-platform libraries and applications such as SwiftNIO and SwiftPM. System does not eliminate the need for `#if os()` conditionals to implement cross-platform abstractions, but it does make it safer and more expressive to fill out the platform-specific parts.

## Usage

```swift
import SystemPackage

let message: String = "Hello, world!" + "\n"
let path: FilePath = "/tmp/log"
let fd = try FileDescriptor.open(
  path, .writeOnly, options: [.append, .create], permissions: .ownerReadWrite)
try fd.closeAfter {
  _ = try fd.writeAll(message.utf8)
}
```

## Adding `SystemPackage` as a Dependency

To use the `SystemPackage` library in a SwiftPM project,
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
```

Finally, include `"SystemPackage"` as a dependency for your executable target:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        .package(url: "https://github.com/apple/swift-system", from: "1.0.0"),
        // other dependencies
    ],
    targets: [
        .target(name: "MyTarget", dependencies: [
            .product(name: "SystemPackage", package: "swift-system"),
        ]),
        // other targets
    ]
)
```

## Source Stability

The Swift System package is source stable. The version numbers follow [Semantic Versioning][semver] -- source breaking changes to public API can only land in a new major version.

[semver]: https://semver.org

## Contributing

Before contributing, please read [CONTRIBUTING.md](CONTRIBUTING.md). 

## LICENSE

See [LICENSE](LICENSE.txt) for license information. 
