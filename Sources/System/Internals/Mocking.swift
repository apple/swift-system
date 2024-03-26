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

// Provide access to the driver, context, and trace stack of mocking
internal class MockingDriver {
  // Record syscalls and their arguments
  internal var trace = Trace()

  // Mock errors inside syscalls
  internal var forceErrno = ForceErrno.none

  // Whether we should pretend to be Windows for syntactic operations
  // inside FilePath
  fileprivate var forceWindowsSyntaxForPaths: Bool? = nil
}

private let driverKey: _PlatformTLSKey = { makeTLSKey() }()

internal var currentMockingDriver: MockingDriver? {
  #if !ENABLE_MOCKING
    fatalError("Contextual mocking in non-mocking build")
  #endif

  guard let rawPtr = getTLS(driverKey) else { return nil }

  return Unmanaged<MockingDriver>.fromOpaque(rawPtr).takeUnretainedValue()
}

extension MockingDriver {
  /// Enables mocking for the duration of `f` with a clean trace queue
  /// Restores prior mocking status and trace queue after execution
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

// Check TLS for mocking
@inline(never)
private var contextualMockingEnabled: Bool {
  return currentMockingDriver != nil
}

extension MockingDriver {
  internal static var enabled: Bool { mockingEnabled }

  internal static var forceWindowsPaths: Bool? {
    currentMockingDriver?.forceWindowsSyntaxForPaths
  }
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

@inline(__always)
internal var forceWindowsPaths: Bool? {
  #if !ENABLE_MOCKING
  return false
  #else
  return MockingDriver.forceWindowsPaths
  #endif
}


#if ENABLE_MOCKING
// Strip the mock_system prefix and the arg list suffix
private func originalSyscallName(_ function: String) -> String {
  // `function` must be of format `system_<name>(<parameters>)`
  precondition(function.starts(with: "system_"))
  return String(function.dropFirst("system_".count).prefix { $0 != "(" })
}

private func mockImpl(
  name: String,
  path: UnsafePointer<CInterop.PlatformChar>?,
  _ args: [AnyHashable]
) -> CInt {
  precondition(mockingEnabled)
  let origName = originalSyscallName(name)
  guard let driver = currentMockingDriver else {
    fatalError("Mocking requested from non-mocking context")
  }
  var mockArgs: Array<AnyHashable> = []
  if let p = path {
    mockArgs.append(String(_errorCorrectingPlatformString: p))
  }
  mockArgs.append(contentsOf: args)
  driver.trace.add(Trace.Entry(name: origName, mockArgs))

  switch driver.forceErrno {
  case .none: break
  case .always(let e):
    system_errno = e
    return -1
  case .counted(let e, let count):
    assert(count >= 1)
    system_errno = e
    driver.forceErrno = count > 1 ? .counted(errno: e, count: count-1) : .none
    return -1
  }

  return 0
}

internal func _mock(
  name: String = #function, path: UnsafePointer<CInterop.PlatformChar>? = nil, _ args: AnyHashable...
) -> CInt {
  return mockImpl(name: name, path: path, args)
}
internal func _mockInt(
  name: String = #function, path: UnsafePointer<CInterop.PlatformChar>? = nil, _ args: AnyHashable...
) -> Int {
  Int(mockImpl(name: name, path: path, args))
}

internal func _mockOffT(
  name: String = #function, path: UnsafePointer<CInterop.PlatformChar>? = nil, _ args: AnyHashable...
) -> _COffT {
  _COffT(mockImpl(name: name, path: path, args))
}
#endif // ENABLE_MOCKING

// Force paths to be treated as Windows syntactically if `enabled` is
// true, and as POSIX syntactically if not.
internal func _withWindowsPaths(enabled: Bool, _ body: () -> ()) {
  #if ENABLE_MOCKING
  MockingDriver.withMockingEnabled { driver in
    driver.forceWindowsSyntaxForPaths = enabled
    body()
  }
  #else
  body()
  #endif
}
