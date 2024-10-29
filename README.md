# Swift System

Swift System provides idiomatic interfaces to system calls and low-level currency types. Our vision is for System to act as the single home for low-level system interfaces for all supported Swift platforms.

## No Cross-platform Abstractions

Swift System is not a cross-platform library. It provides a separate set of APIs and behaviors on every supported platform, closely reflecting the underlying OS interfaces. A single import will pull in the native platform interfaces specific for the targeted OS.

Our immediate goal is to simplify building cross-platform libraries and applications such as SwiftNIO and SwiftPM. It is not a design goal for System to eliminate the need for `#if os()` conditionals to implement cross-platform abstractions; rather, our goal is to make it safer and more expressive to fill out the platform-specific parts.

(That said, it is desirable to avoid unnecessary differences -- for example, when two operating systems share the same C name for a system call, ideally Swift System would expose them using the same Swift name. This is a particularly obvious expectation for system interfaces that implement an industry standard, such as POSIX.)

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

[API documentation](https://swiftpackageindex.com/apple/swift-system/main/documentation/SystemPackage)

## Adding `SystemPackage` as a Dependency

To use the `SystemPackage` library in a SwiftPM project,
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/apple/swift-system", from: "1.4.0"),
```

Finally, include `"SystemPackage"` as a dependency for your executable target:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        .package(url: "https://github.com/apple/swift-system", from: "1.4.0"),
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

At this time, the Swift System package supports three types of operating systems: Darwin-based, POSIX-like, and Windows. The source-stability status of the package differs according to the platform:

| Platform type     | Source Stability |
| ----------------- | --------------- |
| Darwin (macOS, iOS, etc.) | Stable |
| POSIX (Linux, WASI, etc.) | Stable |
| Windows | Unstable |

The package version numbers follow [Semantic Versioning][semver] -- source breaking changes to source-stable public API can only land in a new major version. However, platforms for which support has not reached source stability may see source-breaking changes in a new minor version.

[semver]: https://semver.org

The public API of the swift-system package consists of non-underscored declarations that are marked `public` in the `SystemPackage` module.

By "underscored declarations" we mean declarations that have a leading underscore anywhere in their fully qualified name. For instance, here are some names that wouldn't be considered part of the public API, even if they were technically marked public:

- `FooModule.Bar._someMember(value:)` (underscored member)
- `FooModule._Bar.someMember` (underscored type)
- `_FooModule.Bar` (underscored module)
- `FooModule.Bar.init(_value:)` (underscored initializer)

Interfaces that aren't part of the public API may continue to change in any release, including patch releases. If you have a use case that requires using non-public APIs, please submit a Feature Request describing it! We'd like the public interface to be as useful as possible -- although preferably without compromising safety or limiting future evolution.

Future minor versions of the package may update these rules as needed.

## Toolchain Requirements

The following table maps existing package releases to their minimum required Swift toolchain release:

| Package version         | Swift version   | Xcode release |
| ----------------------- | --------------- | ------------- |
| swift-system 1.3.x | >= Swift 5.8  | >= Xcode 14.3 |
| swift-system 1.4.x | >= Swift 5.9  | >= Xcode 15.0 |

We'd like this package to quickly embrace Swift language and toolchain improvements that are relevant to its mandate. Accordingly, from time to time, new versions of this package require clients to upgrade to a more recent Swift toolchain release. (This allows the package to make use of new language/stdlib features, build on compiler bug fixes, and adopt new package manager functionality as soon as they are available.) Patch (i.e., bugfix) releases will not increase the required toolchain version, but any minor (i.e., new feature) release may do so.

(Note: the package has no minimum deployment target, so while it does require clients to use a recent Swift toolchain to build it, the code itself is able to run on any OS release that supports running Swift code.)

## Licensing

See [LICENSE](LICENSE.txt) for license information. 

## Contributing

Before contributing, please read [CONTRIBUTING.md](CONTRIBUTING.md).

### Branching Strategy

We maintain separate branches for each active minor version of the package:

| Package version         | Branch      | 
| ----------------------- | ----------- |
| swift-system 1.3.x | release/1.3 |
| swift-system 1.4.x (unreleased) | release/1.4 |
| swift-system 1.5.x (unreleased) | main        |

Changes must land on the branch corresponding to the earliest release that they will need to ship on. They are periodically propagated to subsequent branches, in the following direction:

`release/1.3` → `release/1.4` → `main`

For example, anything landing on `release/1.3` will eventually appear on `release/1.4` and then `main` too; there is no need to file standalone PRs for each release line. (Change propagation currently requires manual work -- it is performed by project maintainers.)

### Code of Conduct

Like all Swift.org projects, we would like the Swift System project to foster a diverse and friendly community. We expect contributors to adhere to the [Swift.org Code of Conduct](https://swift.org/code-of-conduct/). A copy of this document is [available in this repository][coc].

[coc]: CODE_OF_CONDUCT.md
