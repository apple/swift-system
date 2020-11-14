/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest
import SystemInternals
import SystemPackage

internal protocol TestCase {
  // TODO: want a source location stack, more fidelity, kinds of stack entries, etc
  var file: StaticString { get }
  var line: UInt { get }

  // TODO: Instead have an attribute to register a test in a allTests var, similar to the argument parser.
  func runAllTests()
}
extension TestCase {
  func expectEqualSequence<S1: Sequence, S2: Sequence>(
    _ expected: S1, _ actual: S2,
    _ message: String? = nil
  ) where S1.Element: Equatable, S1.Element == S2.Element {
    if !actual.elementsEqual(expected) {
      fail(message)
    }
  }
  func expectEqual<E: Equatable>(
    _ expected: E, _ actual: E,
    _ message: String? = nil
  ) {
    if actual != expected {
      fail(message)
    }
  }
  func expectTrue(
    _ actual: Bool,
    _ message: String? = nil
  ) {
    expectEqual(true, actual, message)
  }
  func expectFalse(
    _ actual: Bool,
    _ message: String? = nil
  ) {
    expectEqual(false, actual, message)
  }

  func fail(_ reason: String? = nil) {
    XCTAssert(false, reason ?? "", file: file, line: line)
  }
}

internal struct MockTestCase: TestCase {
  var file: StaticString
  var line: UInt

  var expected: Trace.Entry
  var interruptable: Bool

  var body: (_ retryOnInterrupt: Bool) throws -> ()

  init(
    _ file: StaticString = #file,
    _ line: UInt = #line,
    name: String,
    _ args: AnyHashable...,
    interruptable: Bool,
    _ body: @escaping (_ retryOnInterrupt: Bool) throws -> ()
  ) {
    self.file = file
    self.line = line
    self.expected = Trace.Entry(name: name, args)
    self.interruptable = interruptable
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
