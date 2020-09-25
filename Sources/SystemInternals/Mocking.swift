/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Syscall mocking support.
//
// NOTE: This is currently the bare minimum needed for System's testing purposes, though we do
// eventually want to expose some solution to users.
//
// Mocking is contextual, accessible through MockingDriver.withMockingEnabled. Mocking
// state, including whether it is enabled, is stored in thread-local storage. Mocking is only
// enabled in testing builds of System currently, to minimize runtime overhead of release builds.
//

public struct Trace {
  public struct Entry: Hashable {
    var name: String
    var arguments: [AnyHashable]

    public init(name: String, _ arguments: [AnyHashable]) {
      self.name = name
      self.arguments = arguments
    }
  }

  private var entries: [Entry] = []
  private var firstEntry: Int = 0

  public var isEmpty: Bool { firstEntry >= entries.count }

  public mutating func dequeue() -> Entry? {
    guard !self.isEmpty else { return nil }
    defer { firstEntry += 1 }
    return entries[firstEntry]
  }

  internal mutating func add(_ e: Entry) {
    entries.append(e)
  }

  public mutating func clear() { entries.removeAll() }
}

// TODO: Track
public struct WriteBuffer {
  public var enabled: Bool = false

  private var buffer: [UInt8] = []
  private var chunkSize: Int? = nil

  internal mutating func write(_ buf: UnsafeRawBufferPointer) -> Int {
    guard enabled else { return 0 }
    let chunk = chunkSize ?? buf.count
    buffer.append(contentsOf: buf.prefix(chunk))
    return chunk
  }

  public var contents: [UInt8] { buffer }
}

public enum ForceErrno {
  case none
  case always(errno: CInt)

  case counted(errno: CInt, count: Int)
}

// Provide access to the driver, context, and trace stack of mocking
public class MockingDriver {
  // Whether to bypass this shim and go straight to the syscall
  public var enableMocking = false

  // Record syscalls and their arguments
  public var trace = Trace()

  // Mock errors inside syscalls
  public var forceErrno = ForceErrno.none

  // A buffer to put `write` bytes into
  public var writeBuffer = WriteBuffer()
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import Glibc
#else
#error("Unsupported Platform")
#endif

internal let key: pthread_key_t = {
  var raw = pthread_key_t()
  func releaseObject(_ raw: UnsafeMutableRawPointer) -> () {
    Unmanaged<MockingDriver>.fromOpaque(raw).release()
  }
  guard 0 == pthread_key_create(&raw, releaseObject) else {
    fatalError("Unable to create key")
  }
  // TODO: All threads are sharing the same object; this is wrong
  let object = MockingDriver()

  guard 0 == pthread_setspecific(raw, Unmanaged.passRetained(object).toOpaque()) else {
    fatalError("Unable to set TLSData")
  }
  return raw
}()

internal var currentMockingDriver: MockingDriver {
  #if !ENABLE_MOCKING
    fatalError("Contextual mocking in non-mocking build")
  #endif

  // TODO: Do we need a lazy initialization check here?
  return Unmanaged<MockingDriver>.fromOpaque(pthread_getspecific(key)!).takeUnretainedValue()
}

extension MockingDriver {
  /// Whether mocking is enabled on this thread
  public static var enabled: Bool { mockingEnabled }

  /// Enables mocking for the duration of `f` with a clean trace queue
  /// Restores prior mocking status and trace queue after execution
  public static func withMockingEnabled(
    _ f: (MockingDriver) throws -> ()
  ) rethrows {
    let priorMocking = currentMockingDriver.enableMocking
    defer {
      currentMockingDriver.enableMocking = priorMocking
    }
    currentMockingDriver.enableMocking = true

    let oldTrace = currentMockingDriver.trace
    defer { currentMockingDriver.trace = oldTrace }

    currentMockingDriver.trace.clear()
    return try f(currentMockingDriver)
  }
}

// Check TLS for mocking
@inline(never)
private var contextualMockingEnabled: Bool {
  return currentMockingDriver.enableMocking
}

@inline(__always)
internal var mockingEnabled: Bool {
  // Fast constant-foldable check for release builds
  #if !ENABLE_MOCKING
    return false
  #endif

  return contextualMockingEnabled
}

