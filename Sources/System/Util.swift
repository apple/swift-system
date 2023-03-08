/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Results in errno if i == -1
/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
private func valueOrErrno<I: FixedWidthInteger>(
  _ i: I
) -> Result<I, Errno> {
  i == -1 ? .failure(Errno.current) : .success(i)
}

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
private func nothingOrErrno<I: FixedWidthInteger>(
  _ i: I
) -> Result<(), Errno> {
  valueOrErrno(i).map { _ in () }
}

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
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

/*System 0.0.1, @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)*/
internal func nothingOrErrno<I: FixedWidthInteger>(
  retryOnInterrupt: Bool, _ f: () -> I
) -> Result<(), Errno> {
  valueOrErrno(retryOnInterrupt: retryOnInterrupt, f).map { _ in () }
}

/// Promote `Errno.wouldBlock` / `Errno.resourceTemporarilyUnavailable` to `nil`.
internal func _extractWouldBlock<T>(
  _ value: Result<T, Errno>
) -> Result<T, Errno>? {
  if case .failure(let err) = value, err == .wouldBlock {
    return nil
  }
  return value
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

/// Map byte offsets passed as a range expression to start+length, e.g. for
/// use in `struct flock`.
///
/// Start can be negative, e.g. for use with `SEEK_CUR`.
///
/// Convention: Half-open ranges or explicit `Int64.min` / `Int64.max` bounds
/// denote start or end.
///
/// Passing `Int64.min` as the lower bound maps to a start offset of `0`, such
/// that `..<5` would map to `(start: 0, length: 5)`.
///
/// Passing `Int64.max` as an upper bound maps to a length of `0` (i.e. rest
/// of file by convention), such that passing `5...` would map to `(start: 5,
/// length: 0)`.
///
/// NOTE: This is a utility function and can return negative start offsets and
/// negative lengths E.g. `(-3)...` for user with `SEEK_CUR` and `...(-3)`
/// (TBD). It's up to the caller to check any additional invariants
///
@_alwaysEmitIntoClient
internal func _mapByteRangeToByteOffsets(
  _ byteRange: (some RangeExpression<Int64>)?
) -> (start: Int64, length: Int64) {
  let allInts = Int64.min..<Int64.max
  let br = byteRange?.relative(to: allInts) ?? allInts

  let start = br.lowerBound == Int64.min ? 0 : br.lowerBound

  if br.upperBound == Int64.max {
    // l_len == 0 means until end of file
    return (start, 0)
  }
  return (start, br.upperBound - start)
}
