# Back-Deploy CInterop.stat for Migration Compatibility

* Proposal: SYS-NNNN
* Author: [Jonathan Flat](https://github.com/jrflat)
* Status: **Awaiting review**
* Implementation:
* Review: ([pitch](https://forums.swift.org))

## Introduction

This proposal back-deploys `CInterop.stat(_:_:)` and `CInterop.Stat` from System to make them available on older OS versions, enabling a migration path for clients who may encounter naming conflicts with `FilePath.stat()` or `FileDescriptor.stat()` when System's new `Stat` API ships.

## Motivation

The introduction of `FilePath.stat()` and `FileDescriptor.stat()` in [SYS-0006](0006-system-stat.md) creates a potential source compatibility issue for a small number of clients. While we estimate this affects an exceedingly rare set of developers (1 case found in public GitHub repositories), we want to provide a clear migration path.

### Compatibility scenario

Some clients may have extended `FilePath` or `FileDescriptor` with custom functions that use `Darwin.stat()` and `Darwin.stat(_:_:)` **without** the `Darwin.` (or other libc) module qualification inside the function body:

```swift
extension FilePath {
  func isRegularFile() -> Bool {
    var s = stat()  // Calls Darwin.stat(_:_:) - unqualified!
    guard stat(self.string, &s) == 0 else {  // Calls Darwin.stat(_:_:) - unqualified!
      return false
    }
    return s.st_mode & S_IFMT == S_IFREG
  }
}
```

When the new `FilePath.stat()` API from SYS-0006 ships, these unqualified calls to `stat()` and `stat(_:_:)` will refer to the new instance method, causing build errors:

```
error: Call can throw, but it is not marked with 'try' and the error is not handled
error: Use of 'stat' refers to instance method rather than global function 'stat' in module 'Darwin'
```

### Why not just use `Darwin.stat`?

Clients could resolve the ambiguity by qualifying their calls with `Darwin.`, `Glibc.`, etc. However, this approach has several limitations:

1. **Cross-platform code**: Clients writing code for multiple platforms would need platform-specific `#if` blocks with code for each platform's libc module.
2. **Awkward syntax**: Due to the overload between the `stat` type and `stat(_:_:)` function, clients must use the verbose `Darwin.stat(_:_:)(path, &s)` syntax to call the function, which is unintuitive.
3. **Older deployment targets**: Clients supporting older deployment targets can't use the new `System.Stat` API on older OS versions but still need to avoid build breakage when compiled with an SDK that includes the new `FilePath.stat()`

By back-deploying `CInterop.stat(_:_:)` to `System 0.0.2 (macOS 12.0, iOS 15.0)`, we provide a cross-platform, ergonomic solution: clients can replace `stat(_:_:)` with `CInterop.stat(_:_:)` for older deployment targets, and use the new `Stat` API moving forward.

## Proposed solution

Back-deploy `CInterop.Stat` and `CInterop.stat(_:_:)` to `@available(System 0.0.2, *)`, making them available on `macOS 12.0, iOS 15.0` and aligned. Note that `System 0.0.2` already maps to earliest source availability when System is used as a package, so the back-deployment is only relevant for System as an OS framework.

### API Overview

```swift
#if !os(Windows)
@available(System 0.0.2, *) // Original availability of CInterop
extension CInterop {
  public typealias Stat = stat

  @_alwaysEmitIntoClient
  public static func stat(_ path: UnsafePointer<CChar>, _ s: inout CInterop.Stat) -> Int32
}
#endif
```

The implementation uses `@_alwaysEmitIntoClient` to make the function available on older OS versions by embedding the implementation in client code. This makes sense for a widely-available and standardized C function like `stat()`.

### Migration guidance

If you have `FilePath` or `FileDescriptor` extensions that use unqualified `stat()` calls and need to support older deployment targets, migrate to `CInterop.Stat` (type) and `CInterop.stat(_:_:)` (function):

#### Before:

```swift
extension FilePath {
  func isRegularFile() throws -> Bool {
    var s = stat()
    guard stat(self.string, &s) == 0 else {
      throw Errno.current
    }
    return s.st_mode & S_IFMT == S_IFREG
  }
}
```

#### After:

```swift
extension FilePath {
  func isRegularFile() throws -> Bool {
    var s = CInterop.Stat() // stat() --> CInterop.Stat()
    guard CInterop.stat(self.string, &s) == 0 else { // stat(_:_:) --> CInterop.stat(_:_:)
      throw Errno.current
    }
    return s.st_mode & S_IFMT == S_IFREG
  }
}
```

#### Migrate to the new `Stat` API:

Migrate to the more ergonomic interface on newer OS versions using `if #available`:

```swift
extension FilePath {
  func isRegularFile() throws -> Bool {
    if #available(macOS X, iOS Y, *) {
      return try stat().type == .regular // Calls FilePath.stat()
    }
    var s = CInterop.Stat()
    guard CInterop.stat(self.string, &s) == 0 else {
      throw Errno.current
    }
    return s.st_mode & S_IFMT == S_IFREG
  }
}
```

Alternatively, you may use just the new API if your deployment target supports it.

#### Who should use `CInterop.stat(_:_:)`?

This scenario is rare and only occurs when a project meets **all** of the following conditions:

1. Has a custom extension on `FilePath` or `FileDescriptor`, that
2. Uses **unqualified** `stat()` or `stat(_:_:)` calls inside that method, and
3. Needs to support deployment targets older than the new `Stat` API availability

If your code uses qualified calls, e.g. `Darwin.stat()`, or uses a wrapper around `stat()` already, it is **not** affected by this issue and no migration is needed.

## Detailed design

### CInterop extension

```swift
#if !os(Windows)
@available(System 0.0.2, *) // Original availability of CInterop
extension CInterop {
  /// The C `stat` struct.
  public typealias Stat = stat

  /// Calls the C `stat()` function.
  ///
  /// This is a direct wrapper around the C `stat()` system call.
  /// For a more ergonomic Swift API, use `Stat` instead.
  ///
  /// - Warning: This API is primarily intended for migration purposes when
  ///   supporting older deployment targets. If your deployment target supports
  ///   it, prefer using the `Stat` API introduced in SYS-0006, which provides 
  ///   type-safe, ergonomic access to file metadata in Swift.
  ///
  /// - Parameters:
  ///   - path: A null-terminated C string representing the file path.
  ///   - s: An `inout` reference to a `CInterop.Stat` struct to populate.
  /// - Returns: 0 on success, -1 on error (check `Errno.current`).
  @_alwaysEmitIntoClient
  public static func stat(_ path: UnsafePointer<CChar>, _ s: inout CInterop.Stat) -> Int32 {
    system_stat(path, &s)
  }
}
#endif
```

### Internal wrapper

The `system_stat` wrapper is also marked `@_alwaysEmitIntoClient` so it can be inlined. `system_stat` calls the global `stat` function for the current platform.

```swift
#if !os(Windows)
@_alwaysEmitIntoClient
internal func system_stat(_ path: UnsafePointer<CChar>, _ s: inout CInterop.Stat) -> Int32 {
  stat(path, &s)
}
#endif
```

## Source compatibility

This proposal is additive and source-compatible.

## ABI compatibility

This proposal is ABI-compatible. The use of `@_alwaysEmitIntoClient` ensures that the implementation is embedded in client code.

## Implications on adoption

Clients can adopt `CInterop.Stat` and `CInterop.stat(_:_:)` to support older deployment targets when building with the new SDK.

## Future directions

Once clients can raise their deployment targets to support the new `Stat` API introduced in SYS-0006, they should migrate to it, which provides:

- Type-safe, ergonomic Swift interfaces
- Strongly-typed wrappers (`FileType`, `FileMode`, `FilePermissions`, etc.)
- Proper error handling with typed throws

## Alternatives considered

### Do nothing

We could choose not to provide a migration path and let affected clients handle the ambiguity by:

1. Qualifying their calls with platform-specific modules (e.g. `Darwin.stat`)
2. Wrapping `stat()` in another function
3. Raising their deployment target to use the new `Stat` API

However, this creates an unnecessary burden for the (admittedly rare) affected clients, especially those who need to maintain backward compatibility with older OS versions.

### Use a different name for `FilePath.stat()`

We could use a different name such as `FilePath.statInfo()`, `FilePath.status()`, `FilePath.Stat()`, or `FilePath.fileInfo()`. However, considering the rarity of the issue, changing to a less concise, discoverable, and expressive function name is not preferrable when we can offer a migration solution.

### Create `stat()` overloads directly on `FilePath`

We could create `stat()` extensions on `FilePath` within System that guide a developer to use the new instance method via `try stat()`, e.g:

```swift
extension FilePath {
  @available(*, deprecated, message: "Use 'try stat()' in your FilePath extension to get a System.Stat instead. Then, use '.rawValue' to get the underlying C type if desired.")
  public func stat() -> CInterop.Stat {
    CInterop.Stat()
  }

  @available(*, deprecated, message: "Use 'try stat()' in your FilePath extension to get a System.Stat instead. Then, use '.rawValue' to get the underlying C type if desired.")
  public func stat(
    _ path: UnsafePointer<CChar>,
    _ s: inout CInterop.Stat
  ) -> Int32 {
    system_stat(path, &s)
  }
}
```

This is beneficial because it prevents any SDK breakage with only a System change. However, this is not a great long-term solution to have as public API because:

- It makes choosing the right `stat()` more confusing with 5 total overloads.
- It hurts discoverability for the new `Stat` API.

### Expose the internal `system_stat` wrapper directly

This would achieve the same effect as exposing `CInterop.stat(_:_:)`, but goes against the API naming/organization patterns in System. `CInterop` seems like a clear place for the direct C `stat` wrapper to belong.

### Back-deploy the full `Stat` API

Unlike functions and typealiases, types such as `Stat`, `FileType`, `FileMode`, etc. would require significant coordination and effort to back-deploy, making this alternative less desirable, especially considering it's not required to address the issue.