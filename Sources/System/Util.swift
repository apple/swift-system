/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Results in errno if i == -1
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
private func valueOrErrno<I: FixedWidthInteger>(
  _ i: I
) -> Result<I, Errno> {
  i == -1 ? .failure(Errno.current) : .success(i)
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
private func nothingOrErrno<I: FixedWidthInteger>(
  _ i: I
) -> Result<(), Errno> {
  valueOrErrno(i).map { _ in () }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
internal func valueOrErrno<I: FixedWidthInteger>(
  retryOnInterrupt: Bool, _ f: () -> I
) -> Result<I, Errno> {
  repeat {
    switch valueOrErrno(f()) {
    case .success(let r): return .success(r)
    case .failure(let err):
      guard retryOnInterrupt && err == .interrupted else { return .failure(err) }
      break
    }
  } while true
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
internal func nothingOrErrno<I: FixedWidthInteger>(
  retryOnInterrupt: Bool, _ f: () -> I
) -> Result<(), Errno> {
  valueOrErrno(retryOnInterrupt: retryOnInterrupt, f).map { _ in () }
}

// Run a precondition for debug client builds
internal func _debugPrecondition(
  _ condition: @autoclosure () -> Bool,
  _ message: StaticString = StaticString(),
  file: StaticString = #file, line: UInt = #line
) {
  // Only check in debug mode.
  if _slowPath(_isDebugAssertConfiguration()) {
    precondition(
      condition(), String(describing: message), file: file, line: line)
  }
}

extension OpaquePointer {
  internal var _isNULL: Bool {
    OpaquePointer(bitPattern: Int(bitPattern: self)) == nil
  }
}

extension Sequence {
  // Tries to recast contiguous pointer if available, otherwise allocates memory.
  internal func _withRawBufferPointer<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    guard let result = try self.withContiguousStorageIfAvailable({
      try body(UnsafeRawBufferPointer($0))
    }) else {
      return try Array(self).withUnsafeBytes(body)
    }
    return result
  }
}

extension OptionSet {
  // Helper method for building up a comma-separated list of options
  //
  // Taking an array of descriptions reduces code size vs
  // a series of calls due to avoiding register copies. Make sure
  // to pass an array literal and not an array built up from a series of
  // append calls, else that will massively bloat code size. This takes
  // StaticStrings because otherwise we get a warning about getting evicted
  // from the shared cache.
  @inline(never)
  internal func _buildDescription(
    _ descriptions: [(Element, StaticString)]
  ) -> String {
    var copy = self
    var result = "["

    for (option, name) in descriptions {
      if _slowPath(copy.contains(option)) {
        result += name.description
        copy.remove(option)
        if !copy.isEmpty { result += ", " }
      }
    }

    if _slowPath(!copy.isEmpty) {
      result += "\(Self.self)(rawValue: \(copy.rawValue))"
    }
    result += "]"
    return result
  }
}

internal func _dropCommonPrefix<C: Collection>(
  _ lhs: C, _ rhs: C
) -> (C.SubSequence, C.SubSequence)
where C.Element: Equatable {
  var (lhs, rhs) = (lhs[...], rhs[...])
  while lhs.first != nil && lhs.first == rhs.first {
    lhs.removeFirst()
    rhs.removeFirst()
  }
  return (lhs, rhs)
}

extension MutableCollection where Element: Equatable {
  mutating func _replaceAll(_ e: Element, with new: Element) {
    for idx in self.indices {
      if self[idx] == e { self[idx] = new }
    }
  }
}

internal func _withOptionalUnsafePointerOrNull<T, R>(
  to value: T?,
  _ body: (UnsafePointer<T>?) throws -> R
) rethrows -> R {
  guard let value = value else {
    return try body(nil)
  }
  return try withUnsafePointer(to: value, body)
}

/// Calls `body` with a temporary buffer of the indicated size,
/// possibly stack-allocated.
internal func _withStackBuffer<R>(
  capacity: Int,
  _ body: (UnsafeMutableRawBufferPointer) throws -> R
) rethrows -> R {
  typealias StackStorage = (
    UInt64, UInt64, UInt64, UInt64,
    UInt64, UInt64, UInt64, UInt64,
    UInt64, UInt64, UInt64, UInt64,
    UInt64, UInt64, UInt64, UInt64
  )
  if capacity > MemoryLayout<StackStorage>.size {
    var buffer = _RawBuffer(minimumCapacity: capacity)
    return try buffer.withUnsafeMutableBytes { buffer in
      try body(.init(rebasing: buffer[..<capacity]))
    }
  } else {
    var storage: StackStorage = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    return try withUnsafeMutableBytes(of: &storage) { buffer in
      try body(.init(rebasing: buffer[..<capacity]))
    }
  }
}
