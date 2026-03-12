# Add support for `dup3` and `pipe2` POSIX API to `FileDescriptor`

* Proposal: SYS-0007
- Author(s): Jake Petroules <jake.petroules@apple.com>, Guillaume Lessard <guillaume.lessard@apple.com>

* Other Reviews: [Swift Forums Pitch](https://forums.swift.org/t/82486)

##### Revision history

* **v1** Initial version

## Introduction

Swift System today provides `FileDescriptor.duplicate()`, `FileDescriptor.duplicate(as:)` and `FileDescriptor.pipe()` cover APIs for the POSIX `dup`, `dup2`, and `pipe` functions, respectively.

This proposal adds additional `FileDescriptor` overloads to cover new POSIX 2024 functions in this family of APIs. These overloads will be available on Linux, FreeBSD and Android.

## Motivation

It is considered best practice to set the `O_CLOEXEC` (close-on-exec) bit on newly created file descriptors to prevent them from being inherited by subprocesses.

Some POSIX functions such as `open` provide a "flags" parameter allowing this the close-on-exec bit to be set atomically on the newly created file descriptor. However, others provide no such flags parameter, and require the caller to use `fcntl` to set the close-on-exec bit after the fact. This can lead to race conditions and security bugs where file descriptors can be inherited between calling the function creating the file descriptor, and calling `fcntl`.

POSIX 2024 corrects this deficiency for `dup2` and `pipe` by introducing `dup3` and `pipe2` variants that allow the close-on-exec bit to be set atomically.

While it's *also* considered best practice for subprocess spawning code to close all open file descriptors in the newly created subprocess (swiftlang/swift-subprocess does this for example), there is no guarantee that a user of Swift System is using a mechanism which does so throughout their entire process, and might be using process spawning code they don't control. Adding the proposed overloads will allow developers to write code which adopts a posture of defence in depth with respect to opened file descriptors.

## Proposed solution

This proposal adds new overloads to `FileDescriptor.duplicate(as:)` and `FileDescriptor.pipe()` that will wrap the functionality of the `dup3` and `pipe2` functions.

## Example usage

```swift
import System

let fd0 = try FileDescriptor.open("/tmp/test.txt", .readOnly)
let fd1 = FileDescriptor(rawValue: 731)
let fd2 = fd0.duplicate(as: fd1, options: [.closeOnFork, .closeOnExec])
```

## Detailed design

`FileDescriptor` will add the following overloads and types:

```swift
struct FileDescriptor {
  /// Creates a unidirectional data channel, which can be used for
  /// interprocess communication.
  ///
  /// - Parameters:
  ///   - options: The behavior for creating the pipe.
  ///
  /// - Returns: The pair of file descriptors.
  ///
  /// The corresponding C function is `pipe2`.
  public static func pipe(
    options: PipeOptions
  ) throws(Errno) -> (readEnd: FileDescriptor, writeEnd: FileDescriptor)

  /// Duplicates this file descriptor and return the newly created copy.
  ///
  /// - Parameters:
  ///   - `target`: The desired target file descriptor.
  ///   - `options`: The behavior for creating the target file descriptor.
  ///   - retryOnInterrupt: Whether to retry the write operation
  ///      if it throws ``Errno/interrupted``. The default is `true`.
  ///      Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: The new file descriptor.
  ///
  /// If the `target` descriptor is already in use, then it is first
  /// deallocated as if a close(2) call had been done first.
  ///
  /// File descriptors are merely references to some underlying system resource.
  /// The system does not distinguish between the original and the new file
  /// descriptor in any way. For example, read, write and seek operations on
  /// one of them also affect the logical file position in the other, and
  /// append mode, non-blocking I/O and asynchronous I/O options are shared
  /// between the references. If a separate pointer into the file is desired,
  /// a different object reference to the file must be obtained by issuing an
  /// additional call to `open`.
  ///
  /// However, each file descriptor maintains its own close-on-exec flag.
  ///
  /// The corresponding C function is `dup3`.
  @discardableResult
  public func duplicate(
    as target: FileDescriptor,
    options: DuplicateOptions,
    retryOnInterrupt: Bool = true
  ) throws(Errno) -> FileDescriptor

  /// Options that specify behavior for a newly-created pipe.
  public struct PipeOptions: OptionSet, Sendable, Hashable, Codable {
    /// The raw C options.
    public var rawValue: CInt

    /// Create a strongly-typed options value from raw C options.
    public init(rawValue: CInt)

    /// Indicates that all subsequent input and output operations
    /// on the pipe's file descriptors will be nonblocking.
    ///
    /// The corresponding C constant is `O_NONBLOCK`.
    public static var nonBlocking: OpenOptions

    /// Indicates that executing a program closes the file.
    ///
    /// Normally, file descriptors remain open across calls to the `exec(2)`
    /// family of functions. If you specify this option, the file descriptor
    /// is closed when replacing this process with another process.
    ///
    /// The state of the file descriptor flags can be inspected using `F_GETFD`,
    /// as described in the `fcntl(2)` man page.
    ///
    /// The corresponding C constant is `O_CLOEXEC`.
    public static var closeOnExec: PipeOptions

    /// Indicates that forking a program closes the file.
    ///
    /// Normally, file descriptors remain open across calls to the `fork(2)`
    /// function. If you specify this option, the file descriptor is closed
    /// when forking this process into another process.
    ///
    /// The state of the file descriptor flags can be inspected using `F_GETFD`,
    /// as described in the `fcntl(2)` man page.
    ///
    /// The corresponding C constant is `O_CLOFORK`.
    public static var closeOnFork: PipeOptions
  }

  /// Options that specify behavior for a duplicated file descriptor.
  public struct DuplicateOptions: OptionSet, Sendable, Hashable, Codable {
    /// The raw C options.
    public var rawValue: CInt

    /// Create a strongly-typed options value from raw C options.
    public init(rawValue: CInt)

    /// Normally, file descriptors remain open across calls to the `exec(2)`
    /// family of functions. If you specify this option, the file descriptor
    /// is closed when replacing this process with another process.
    ///
    /// The state of the file descriptor flags can be inspected using `F_GETFD`,
    /// as described in the `fcntl(2)` man page.
    ///
    /// The corresponding C constant is `O_CLOEXEC`.
    public static var closeOnExec: DuplicateOptions

    /// Indicates that forking a program closes the file.
    ///
    /// Normally, file descriptors remain open across calls to the `fork(2)`
    /// function. If you specify this option, the file descriptor is closed
    /// when forking this process into another process.
    ///
    /// The state of the file descriptor flags can be inspected using `F_GETFD`,
    /// as described in the `fcntl(2)` man page.
    ///
    /// The corresponding C constant is `O_CLOFORK`.
    public static var closeOnFork: DuplicateOptions
  }
}
```

These API additions are unavailable on Windows and Darwin, as the underlying `dup3` and `pipe2` APIs do not exist.

`closeOnFork` is unavailable on Linux and Android, as the underlying `O_CLOFORK` constant does not exist.

## Impact on existing code

This change will have no impact on existing code, as it is purely additive.

## Alternatives considered

None. The underlying POSIX API are additions that help C developers follow best practices, and these overloads provide the same value to Swift developers.
