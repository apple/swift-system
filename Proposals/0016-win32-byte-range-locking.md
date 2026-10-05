# Byte-Range Locking for `Win32.FileHandle`

* Proposal: [SYS-0016](0016-win32-byte-range-locking.md)
* Author: [Jonathan Flat](https://github.com/jrflat)
* Review Manager: TBD
* Status: **Draft**
* Implementation: TBD
* Review: TBD
* Depends on: [SYS-0010](0010-win32-namespace-and-error.md), [SYS-0011](0011-win32-filehandle.md), [SYS-0012](0012-win32-opening-handles.md)

#### Revision history

* **v1** Initial version.

## Introduction

This proposal adds scoped byte-range locking to `Win32.FileHandle`, the type introduced in [SYS-0011](0011-win32-filehandle.md).

## Motivation

### Mandatory locks with scoped safety

`FileDescriptor` exposes no locking API on any platform, and the gap matters more on Windows: `LockFileEx` locks are mandatory rather than advisory like `flock`, so the kernel rejects conflicting reads and writes by other processes whether or not they take locks themselves. A leaked lock can therefore be costly.

`UnlockFileEx` must also name the range `LockFileEx` locked, exactly. Windows locks don't split or coalesce, so unlocking part of a locked range, or one range spanning two adjacent locks, fails with `.notLocked`. POSIX `fcntl` locks do both, so this is a place where ported intuition is wrong.

A scoped `withLock(byteRange:mode:_:)` safely releases the lock on every exit and makes the two ranges match by construction.

## Proposed solution

Add `withLock(byteRange:mode:_:)` and `withLockIfAvailable(byteRange:mode:_:)` to `Win32.FileHandle`. The transfers in this example come from [SYS-0014](0014-win32-file-io.md).

```swift
#if os(Windows)
let handle = try Win32.FileHandle.open(
  path, access: [.genericRead, .genericWrite]
)

// Byte-range locks on Windows are mandatory, not advisory, so no other
// process or unrelated handle can read or write the header with `ReadFile`
// or `WriteFile` while it's being replaced.
try handle.withLock(byteRange: 0..<512) {
  try handle.write(newHeader, toAbsoluteOffset: 0)
  try handle.flush()
}
try handle.close()
#endif
```

## Detailed design

Wrapper constants and functions introduced here are `@_alwaysEmitIntoClient`. All APIs carry the availability of the System release that introduces them.

```swift
extension Win32 {
  /// Whether a byte-range lock admits other holders.
  @frozen
  public enum LockMode: Sendable, Hashable, Codable {
    /// A shared, or read, lock.
    ///
    /// Other handles may take a shared lock on an overlapping range, and any
    /// process may read it.
    ///
    /// - Important: A shared lock denies write access to the range for every
    ///   process, including the one that took it. Writing through this handle
    ///   inside a shared ``Win32/FileHandle/withLock(byteRange:mode:_:)``
    ///   fails with ``Win32Error/lockViolation``.
    ///
    /// The corresponding C value is a `dwFlags` without
    /// `LOCKFILE_EXCLUSIVE_LOCK`.
    case shared

    /// An exclusive, or write, lock.
    ///
    /// No other handle may lock an overlapping range, and reads and writes
    /// from other unrelated handles are denied. The locking handle and its
    /// duplicates in the same process may read and write freely, but a child
    /// process that inherits the handle may not.
    ///
    /// The corresponding C constant is `LOCKFILE_EXCLUSIVE_LOCK`.
    case exclusive
  }
}

extension Win32.FileHandle {
  /// Locks a byte range of the file, runs `body`, and unlocks the range.
  ///
  /// Acquires a lock for this handle. This call blocks while any handle holds
  /// a conflicting lock on an overlapping range, including the handle itself.
  /// Nesting this function with a conflicting lock will deadlock. See
  /// ``withLockIfAvailable(byteRange:mode:_:)`` to fail instead of waiting.
  ///
  /// `byteRange` defaults to `0...`, which locks the whole file, including
  /// bytes appended while the lock is held. An empty range locks nothing and
  /// never calls `LockFileEx`, so `body` runs immediately. A negative bound
  /// throws ``Win32Error/invalidParameter``. Byte `Int64.max` is not
  /// addressable, so a range closed at `Int64.max` ends one byte earlier.
  ///
  /// The range is unlocked when `body` returns or throws. If `body` succeeds
  /// but the unlock fails, the unlock error is thrown, discarding the result.
  /// If both fail, `body`'s error wins.
  ///
  /// - Important: Windows byte-range locks are mandatory, not advisory.
  ///   Unlike POSIX `flock`, the system rejects conflicting reads and writes
  ///   by other processes whether or not they take locks themselves. Locks
  ///   aren't enforced on memory-mapped views.
  ///
  /// The corresponding C functions are `LockFileEx` and `UnlockFileEx`.
  @available(*, noasync)
  public func withLock<R: ~Copyable>(
    byteRange: some RangeExpression<Int64> = Int64.zero...,
    mode: Win32.LockMode = .exclusive,
    _ body: () throws(Win32Error) -> R
  ) throws(Win32Error) -> R

  @available(*, noasync)
  @_disfavoredOverload
  public func withLock<R: ~Copyable>(
    byteRange: some RangeExpression<Int64> = Int64.zero...,
    mode: Win32.LockMode = .exclusive,
    _ body: () throws -> R
  ) throws -> R

  /// Locks a byte range of the file if it's available, runs `body`, and
  /// unlocks the range.
  ///
  /// - Returns: The value `body` returned, or `nil` if a conflicting lock
  ///   holds an overlapping range.
  ///
  /// The corresponding C functions are `LockFileEx` with
  /// `LOCKFILE_FAIL_IMMEDIATELY`, and `UnlockFileEx`.
  public func withLockIfAvailable<R: ~Copyable>(
    byteRange: some RangeExpression<Int64> = Int64.zero...,
    mode: Win32.LockMode = .exclusive,
    _ body: () throws(Win32Error) -> R
  ) throws(Win32Error) -> R?

  @_disfavoredOverload
  public func withLockIfAvailable<R: ~Copyable>(
    byteRange: some RangeExpression<Int64> = Int64.zero...,
    mode: Win32.LockMode = .exclusive,
    _ body: () throws -> R
  ) throws -> R?
}
```

Notes on the design:

* **Typed and untyped overloads.** Locking can fail, so unlike `Mutex.withLock`, `body`'s error can't pass through as a generic `E`. The typed overload serves a `body` that doesn't throw or is annotated `throws(Win32Error)`, such as one doing I/O on the same handle. An unannotated throwing `body` gets the untyped overload.
* **Requires a right in the handle's `Win32.AccessMask`.** Locking needs `.readData` or `.writeData` access, and only an exclusive lock lets the body write to the range it has locked.
* **Bounds are `Int64`** like every other position and length in the series, so the range an I/O call addresses can be locked without a conversion. `LockFileEx` accepts any unsigned 64-bit offset and length, but no file holds data past `Int64.max`, and .NET's `FileStream.Lock` and Java's `FileChannel.lock` stop there too. A negative bound throws `.invalidParameter` before calling `LockFileEx`, as a negative `offset` does in [SYS-0014](0014-win32-file-io.md). Since a range ends at or below `Int64.max`, `ERROR_INVALID_LOCK_RANGE` is unreachable. The default `0...` passes an offset of zero and a length of `Int64.max`.
* **`byteRange` is resolved with `RangeExpression.relative(to:)`** against an internal collection whose indices are `0..<Int64.max`. That collection's `index(after:)` saturates, so `0...Int64.max` clamps rather than trapping on `Int64.max + 1`. Byte `Int64.max` is therefore unaddressable, but no file can hold a byte there anyway.
* **`withLock` is `noasync`.** It can wait indefinitely for another process to unlock the range, which would block a Swift concurrency thread. `withLockIfAvailable(byteRange:mode:_:)` never waits, so `async` code can still call it.
* **`LOCKFILE_FAIL_IMMEDIATELY` is an entry point, not a parameter.** `Win32.LockMode` represents only the presence or absence of the other documented `dwFlags` bit, `LOCKFILE_EXCLUSIVE_LOCK`. The fast-fail shape of `withLockIfAvailable` matches `Mutex.withLockIfAvailable`, with the same no-spurious-failure guarantee.
* **Locking is a file-system feature.** On both a pipe and a console, `LockFileEx` fails with `ERROR_INVALID_FUNCTION`.
* **A lock can't outlive a scope.** With no explicit `lock()` and `unlock()`, three patterns are ruled out: a lock held for an object's lifetime, overlapping locks on disjoint ranges released in a non-LIFO order, and upgrading a shared lock to an exclusive one (upgrading on Windows means unlocking and re-locking). See **Alternatives considered** and **Future directions**.

## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.

## Implications on adoption

Everything here is reached through `Win32.FileHandle` and sits behind `#if os(Windows)`, so cross-platform callers must guard their uses.

## Future directions

* **Lock ownership as a value.** A `lock(byteRange:mode:)` returning a noncopyable token that releases its range on `deinit` would serve the object-lifetime and non-LIFO cases that the closure-based version can't express. It's left out for now because a leaked token blocks other processes, which requires additional consideration.
* **Locking across suspension points.** An `async` overload of `withLock(byteRange:mode:_:)`, which would hold a mandatory lock that blocks other processes across an unbounded `await`, deserves its own consideration.
* **Typed throws without an annotation.** Closure thrown-type inference, a future direction of [SE-0413](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0413-typed-throws.md), would let an unannotated `body` that throws only `Win32Error` select the typed overload.
* **Typed throws for other error types.** An overload generic over `E: Win32ErrorRepresentable`, a protocol requiring `init(_: Win32Error)`, could throw lock failures as the caller's error type. It would join the `Win32Error` overload, not replace it, since a non-throwing `body` infers `E == Never`.

## Alternatives considered

### Expose `lock` and `unlock` as primitives

Ship `LockFileEx` and `UnlockFileEx` as the two calls they are, with `withLock(byteRange:mode:_:)` on top.

Rejected because:

* The two ranges must match exactly, as **Motivation** describes. This can be hazardous, so `withLock(byteRange:mode:_:)` makes them match by construction.
* A leaked lock from mishandling is more risky since Windows byte-range locks are mandatory.
* We could add the lock token approach in **Future directions** later, and callers can use the raw Win32 functions until then.

### Model all lock flags in one `Win32.LockOptions` option set

Wrap `dwFlags` as one `Win32.LockOptions: OptionSet` with `exclusive` and `failImmediately` members.

Rejected because:

* `dwFlags` isn't a set of independent bits in the common case, since `.shared` is the absence of `.exclusive`.
* `LOCKFILE_FAIL_IMMEDIATELY` shouldn't be a flag; otherwise, it changes the ergonomic split between `withLock(byteRange:mode:_:)` and `withLockIfAvailable(byteRange:mode:_:)` into a function that might throw `.lockViolation` to express that the lock is contended.

`LockFileEx` has carried exactly two bits since NT 3.1 (released in 1993), but even if a future `LOCKFILE_*` flag was introduced, we could add a new parameter or entry point to support it.

### Take `UInt64` bounds

`LockFileEx` accepts any unsigned 64-bit offset and length, so a `RangeExpression<UInt64>` could express every lock it can take, including bytes past `Int64.max`.

Rejected because every other position and length in the series is an `Int64`, so locking the range an I/O call addresses would need a conversion at each call site, and no file holds data past `Int64.max`.

## Appendix

### Swift API to C mappings

| Swift | C |
| --- | --- |
| `Win32.FileHandle.withLock(byteRange:mode:_:)` | `LockFileEx`, then `UnlockFileEx` over the same range |
| `Win32.FileHandle.withLock(byteRange: n..., ...)` | the same, with `nNumberOfBytesToLockLow` and `High` covering `Int64.max - n` |
| `Win32.FileHandle.withLockIfAvailable(byteRange:mode:_:)` | the same, with `LOCKFILE_FAIL_IMMEDIATELY` |
| `Win32.LockMode.shared` | `dwFlags` without `LOCKFILE_EXCLUSIVE_LOCK` |
| `Win32.LockMode.exclusive` | `LOCKFILE_EXCLUSIVE_LOCK` |

Testing was performed on an ARM64 Windows 11 VM (build 22631), with every file on a local NTFS volume. The conflict, unlock, and mapped-view results were reproduced on an x64 Windows 11 PC (build 26200).
