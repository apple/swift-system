/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Syscall mocking support for SystemSockets
//
// This mirrors the mocking infrastructure from SystemPackage for use in socket tests.

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#endif

import SystemPackage

#if ENABLE_MOCKING
internal struct Trace {
  internal struct Entry {
    internal var name: String
    internal var arguments: [AnyHashable]

    internal init(name: String, _ arguments: [AnyHashable]) {
      self.name = name
      self.arguments = arguments
    }
  }

  private var entries: [Entry] = []
  private var firstEntry: Int = 0

  internal var isEmpty: Bool { firstEntry >= entries.count }

  internal mutating func dequeue() -> Entry? {
    guard !self.isEmpty else { return nil }
    defer { firstEntry += 1 }
    return entries[firstEntry]
  }

  fileprivate mutating func add(_ e: Entry) {
    entries.append(e)
  }
}

internal enum ForceErrno: Equatable {
  case none
  case always(errno: CInt)
  case counted(errno: CInt, count: Int)
}

internal class MockingDriver {
  internal var trace = Trace()
  internal var forceErrno = ForceErrno.none
}

// TLS support
#if os(Windows)
internal typealias _PlatformTLSKey = DWORD
#else
internal typealias _PlatformTLSKey = pthread_key_t
#endif

private func makeTLSKey() -> _PlatformTLSKey {
  #if os(Windows)
  let raw: DWORD = FlsAlloc(nil)
  if raw == FLS_OUT_OF_INDEXES {
    fatalError("Unable to create key")
  }
  return raw
  #else
  var raw = pthread_key_t()
  guard 0 == pthread_key_create(&raw, nil) else {
    fatalError("Unable to create key")
  }
  return raw
  #endif
}

private func setTLS(_ key: _PlatformTLSKey, _ p: UnsafeMutableRawPointer?) {
  #if os(Windows)
  guard FlsSetValue(key, p) else {
    fatalError("Unable to set TLS")
  }
  #else
  guard 0 == pthread_setspecific(key, p) else {
    fatalError("Unable to set TLS")
  }
  #endif
}

private func getTLS(_ key: _PlatformTLSKey) -> UnsafeMutableRawPointer? {
  #if os(Windows)
  return FlsGetValue(key)
  #else
  return pthread_getspecific(key)
  #endif
}

private let driverKey: _PlatformTLSKey = { makeTLSKey() }()

internal var currentMockingDriver: MockingDriver? {
  guard let rawPtr = getTLS(driverKey) else { return nil }
  return Unmanaged<MockingDriver>.fromOpaque(rawPtr).takeUnretainedValue()
}

extension MockingDriver {
  internal static func withMockingEnabled(
    _ f: (MockingDriver) throws -> ()
  ) rethrows {
    let priorMocking = currentMockingDriver
    let driver = MockingDriver()

    defer {
      if let object = priorMocking {
        setTLS(driverKey, Unmanaged.passUnretained(object).toOpaque())
      } else {
        setTLS(driverKey, nil)
      }
      _fixLifetime(driver)
    }

    setTLS(driverKey, Unmanaged.passUnretained(driver).toOpaque())
    return try f(driver)
  }
}

@inline(never)
private var contextualMockingEnabled: Bool {
  return currentMockingDriver != nil
}

extension MockingDriver {
  internal static var enabled: Bool { mockingEnabled }
}
#endif // ENABLE_MOCKING

@inline(__always)
internal var mockingEnabled: Bool {
  #if ENABLE_MOCKING
  return contextualMockingEnabled
  #else
  return false
  #endif
}

#if ENABLE_MOCKING
private func originalSyscallName(_ function: String) -> String {
  precondition(function.starts(with: "system_"))
  return String(function.dropFirst("system_".count).prefix { $0 != "(" })
}

private func mockImpl(
  name: String,
  _ args: [AnyHashable]
) -> CInt {
  precondition(mockingEnabled)
  let origName = originalSyscallName(name)
  guard let driver = currentMockingDriver else {
    fatalError("Mocking requested from non-mocking context")
  }
  driver.trace.add(Trace.Entry(name: origName, args))

  switch driver.forceErrno {
  case .none: break
  case .always(let e):
    system_errno = e
    return -1
  case .counted(let e, let count):
    assert(count >= 1)
    system_errno = e
    driver.forceErrno = count > 1 ? .counted(errno: e, count: count - 1) : .none
    return -1
  }

  return 0
}

internal func _mock(
  name: String = #function, _ args: AnyHashable...
) -> CInt {
  return mockImpl(name: name, args)
}

internal func _mockInt(
  name: String = #function, _ args: AnyHashable...
) -> Int {
  Int(mockImpl(name: name, args))
}
#endif // ENABLE_MOCKING
