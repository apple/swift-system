/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// To aid debugging, force failures to fatal error
internal var forceFatalFailures = false

internal protocol TestCase {
  // TODO: want a source location stack, more fidelity, kinds of stack entries, etc
  var file: StaticString { get }
  var line: UInt { get }

  // TODO: Instead have an attribute to register a test in a allTests var, similar to the argument parser.
  func runAllTests()

  // Customization hook: add adornment to reported failure reason
  // Defaut: reason or empty
  func failureMessage(_ reason: String?) -> String
}

extension TestCase {
  // Default implementation
  func failureMessage(_ reason: String?) -> String { reason ?? "" }

  func expectEqualSequence<S1: Sequence, S2: Sequence>(
    _ expected: S1, _ actual: S2,
    _ message: String? = nil
  ) where S1.Element: Equatable, S1.Element == S2.Element {
    if !expected.elementsEqual(actual) {
      defer { print("expected: \(expected), actual: \(actual)") }
      fail(message)
    }
  }
  func expectEqual<E: Equatable>(
    _ expected: E, _ actual: E,
    _ message: String? = nil
  ) {
    if actual != expected {
      defer { print("expected: \(expected), actual: \(actual)") }
      fail(message)
    }
  }
  func expectNotEqual<E: Equatable>(
    _ expected: E, _ actual: E,
    _ message: String? = nil
  ) {
    if actual == expected {
      defer { print("expected not equal: \(expected) and \(actual)") }
      fail(message)
    }
  }
  func expectNil<T>(
    _ actual: T?,
    _ message: String? = nil
  ) {
    if actual != nil {
      defer { print("expected nil: \(actual!)") }
      fail(message)
    }
  }
  func expectNotNil<T>(
    _ actual: T?,
    _ message: String? = nil
  ) {
    if actual == nil {
      defer { print("expected non-nil") }
      fail(message)
    }
  }
  func expectTrue(
    _ actual: Bool,
    _ message: String? = nil
  ) {
    if !actual { fail(message) }
  }
  func expectFalse(
    _ actual: Bool,
    _ message: String? = nil
  ) {
    if actual { fail(message) }
  }

  func fail(_ reason: String? = nil) {
    XCTAssert(false, failureMessage(reason), file: file, line: line)
    if forceFatalFailures {
      fatalError(reason ?? "<no reason>")
    }
  }

}

internal struct MockTestCase: TestCase {
  var file: StaticString
  var line: UInt

  var expected: Trace.Entry
  var interruptBehavior: InterruptBehavior

  var interruptable: Bool { return interruptBehavior == .interruptable }

  internal enum InterruptBehavior {
    // Retry the syscall on EINTR
    case interruptable

    // Cannot return EINTR
    case noInterrupt

    // Cannot error at all
    case noError
  }

  var body: (_ retryOnInterrupt: Bool) throws -> ()

  init(
    _ file: StaticString = #file,
    _ line: UInt = #line,
    name: String,
    _ interruptable: InterruptBehavior,
    _ args: AnyHashable...,
    body: @escaping (_ retryOnInterrupt: Bool) throws -> ()
  ) {
    self.file = file
    self.line = line
    self.expected = Trace.Entry(name: name, args)
    self.interruptBehavior = interruptable
    self.body = body
  }

  func runAllTests() {
    XCTAssertFalse(MockingDriver.enabled)
    MockingDriver.withMockingEnabled { mocking in
      // Make sure we completely match the trace queue
      self.expectTrue(mocking.trace.isEmpty)
      defer { self.expectTrue(mocking.trace.isEmpty) }

      // Test our API mappings to the lower-level syscall invocation
      do {
        try body(true)
        self.expectEqual(self.expected, mocking.trace.dequeue())
      } catch {
        self.fail()
      }

      // Non-error-ing syscalls shouldn't ever throw
      guard interruptBehavior != .noError else {
        do {
          try body(interruptable)
          self.expectEqual(self.expected, mocking.trace.dequeue())
          try body(!interruptable)
          self.expectEqual(self.expected, mocking.trace.dequeue())
        } catch {
          self.fail()
        }
        return
      }

      // Test interupt behavior. Interruptable calls will be told not to
      // retry to catch the EINTR. Non-interruptable calls will be told to
      // retry, to make sure they don't spin (e.g. if API changes to include
      // interruptable)
      do {
        mocking.forceErrno = .always(errno: EINTR)
        try body(!interruptable)
        self.fail()
      } catch Errno.interrupted {
        // Success!
        self.expectEqual(self.expected, mocking.trace.dequeue())
      } catch {
        self.fail()
      }

      // Force a limited number of EINTRs, and make sure interruptable functions
      // retry that number of times. Non-interruptable functions should throw it.
      do {
        mocking.forceErrno = .counted(errno: EINTR, count: 3)

        try body(interruptable)
        self.expectEqual(self.expected, mocking.trace.dequeue()) // EINTR
        self.expectEqual(self.expected, mocking.trace.dequeue()) // EINTR
        self.expectEqual(self.expected, mocking.trace.dequeue()) // EINTR
        self.expectEqual(self.expected, mocking.trace.dequeue()) // Success
      } catch Errno.interrupted {
        self.expectFalse(interruptable)
        self.expectEqual(self.expected, mocking.trace.dequeue()) // EINTR
      } catch {
        self.fail()
      }
    }
  }
}

internal func withWindowsPaths(enabled: Bool, _ body: () -> ()) {
  _withWindowsPaths(enabled: enabled, body)
}
