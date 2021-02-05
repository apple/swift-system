
extension CInterop {
  public typealias SigSet = UInt32 // TODO: Linux?
}


public struct SignalSet: Hashable, Codable {
  internal var pointee: CInterop.SigSet

  internal init(pointee: CInterop.SigSet) { self.pointee = pointee }

  // Only to be used prior to producing an empty or full set
  fileprivate init(uninitialized: ()) {
    self.pointee = 0
  }
}

extension SignalSet {
  internal func withUnsafePointer<T>(
    _ f: (UnsafePointer<CInterop.SigSet>) throws -> T
  ) rethrows -> T {
    try Swift.withUnsafePointer(to: self.pointee) { try f($0) }
  }
  internal mutating func withUnsafeMutablePointer<T>(
    _ f: (UnsafeMutablePointer<CInterop.SigSet>) throws -> T
  ) rethrows -> T {
    try Swift.withUnsafeMutablePointer(to: &self.pointee) { try f($0) }
  }
}

// FIXME(DO NOT MERGE): Make foo wrappers, for mocking etc.
import Darwin

extension SignalSet {
  public mutating func insert(_ sig: Signal) {
    _ = withUnsafeMutablePointer { sigaddset($0, sig.rawValue) }
  }
  public mutating func remove(_ sig: Signal) {
    _ = withUnsafeMutablePointer { sigdelset($0, sig.rawValue) }
  }

  public func contains(_ sig: Signal) -> Bool {
    1 == withUnsafePointer { sigismember($0, sig.rawValue) }
  }

  public static var empty: SignalSet {
    var ret = SignalSet(uninitialized: ())
    _ = ret.withUnsafeMutablePointer { sigemptyset($0) }
    return ret
  }

  public static var full: SignalSet {
    var ret = SignalSet(uninitialized: ())
    _ = ret.withUnsafeMutablePointer { sigfillset($0) }
    return ret
  }
}

extension SignalSet: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Signal...) {
    self = SignalSet.empty
    elements.forEach { self.insert($0) }
  }

  public typealias ArrayLiteralElement = Signal
}

extension SignalSet {
  // TODO: Proper name for this concept
  public static var _defaultForSPM: SignalSet {
    #if os(macOS)
    var ret = SignalSet.full
    ret.remove(.kill)
    ret.remove(.stop)
    #else
    var ret = SignalSet.empty
    for i in 1 ..< Signal.unused.rawValue {
      let sig = Signal(rawValue: i)
      guard sig != .kill && sig != .stop else { continue }
      ret.insert(sig)
    }
    #endif
    return ret
  }

}
