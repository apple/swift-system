/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Utility functions for socket operations

import SystemPackage

extension Errno {
  internal static var current: Errno {
    get { Errno(rawValue: system_errno) }
    set { system_errno = newValue.rawValue }
  }
}

// Results in errno if i == -1
@available(System 0.0.1, *)
private func valueOrErrno<I: FixedWidthInteger>(
  _ i: I
) -> Result<I, Errno> {
  i == -1 ? .failure(Errno.current) : .success(i)
}

@available(System 0.0.1, *)
private func nothingOrErrno<I: FixedWidthInteger>(
  _ i: I
) -> Result<(), Errno> {
  valueOrErrno(i).map { _ in () }
}

@available(System 0.0.1, *)
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

@available(System 0.0.1, *)
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
  if _slowPath(_isDebugAssertConfiguration()) {
    precondition(
      condition(), String(describing: message), file: file, line: line)
  }
}

extension OptionSet {
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

internal func _withOptionalUnsafePointerOrNull<T, R>(
  to value: T?,
  _ body: (UnsafePointer<T>?) throws -> R
) rethrows -> R {
  guard let value = value else {
    return try body(nil)
  }
  return try withUnsafePointer(to: value, body)
}
