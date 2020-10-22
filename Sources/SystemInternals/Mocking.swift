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

#if ENABLE_MOCKING
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

public enum ForceErrno: Equatable {
  case none
  case always(errno: CInt)

  case counted(errno: CInt, count: Int)
}

// Provide access to the driver, context, and trace stack of mocking
public class MockingDriver {
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
#elseif os(Windows)
import ucrt
import WinSDK
#else
#error("Unsupported Platform")
#endif

#if os(Windows)
internal let key: DWORD = {
  var raw: DWORD = FlsAlloc(nil)
  if raw == FLS_OUT_OF_INDEXES {
    fatalError("Unable to create key")
  }
  return raw
}()
#else
internal let key: pthread_key_t = {
  var raw = pthread_key_t()
  guard 0 == pthread_key_create(&raw, nil) else {
    fatalError("Unable to create key")
  }
  return raw
}()
#endif

internal var currentMockingDriver: MockingDriver? {
  #if !ENABLE_MOCKING
    fatalError("Contextual mocking in non-mocking build")
  #endif

#if os(Windows)
  guard let rawPtr = FlsGetValue(key) else { return nil }
#else
  guard let rawPtr = pthread_getspecific(key) else { return nil }
#endif

  return Unmanaged<MockingDriver>.fromOpaque(rawPtr).takeUnretainedValue()
}

extension MockingDriver {
  /// Enables mocking for the duration of `f` with a clean trace queue
  /// Restores prior mocking status and trace queue after execution
  public static func withMockingEnabled(
    _ f: (MockingDriver) throws -> ()
  ) rethrows {
    let priorMocking = currentMockingDriver
    let driver = MockingDriver()

    defer {
      if let object = priorMocking {
#if os(Windows)
        _ = FlsSetValue(key, Unmanaged.passUnretained(object).toOpaque())
#else
        pthread_setspecific(key, Unmanaged.passUnretained(object).toOpaque())
#endif
      } else {
#if os(Windows)
        _ = FlsSetValue(key, nil)
#else
        pthread_setspecific(key, nil)
#endif
      }
      _fixLifetime(driver)
    }

#if os(Windows)
    guard FlsSetValue(key, Unmanaged.passUnretained(driver).toOpaque()) else {
      fatalError("Unable to set TLSData")
    }
#else
    guard 0 == pthread_setspecific(key, Unmanaged.passUnretained(driver).toOpaque()) else {
      fatalError("Unable to set TLSData")
    }
#endif

    return try f(driver)
  }
}

// Check TLS for mocking
@inline(never)
private var contextualMockingEnabled: Bool {
  return currentMockingDriver != nil
}

extension MockingDriver {
  public static var enabled: Bool { mockingEnabled }
}

#endif // ENABLE_MOCKING

@inline(__always)
internal var mockingEnabled: Bool {
  // Fast constant-foldable check for release builds
  #if ENABLE_MOCKING
    return contextualMockingEnabled
  #else
    return false
  #endif
}

