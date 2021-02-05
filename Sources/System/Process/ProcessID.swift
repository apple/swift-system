
// FIXME(DO NOT MERGE): We need to find a way around this. We want to declare
// a typealias to a struct from a header, but don't want downstream to import
// Darwin or the whole header just for that.
//
import Darwin
extension CInterop {
  public typealias PID = Int32
  public typealias ProcTaskInfo = proc_taskinfo // FIXME
  public typealias RUsageInfo = rusage_info_current // FIXME
}

public struct ProcessID: RawRepresentable, Hashable, Codable {
  /// The raw C process id.
  @_alwaysEmitIntoClient
  public let rawValue: CInterop.PID

  /// Creates a strongly-typed process id from a raw C pid
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.PID) { self.rawValue = rawValue }

  fileprivate init(_ rawValue: CInterop.PID) { self.init(rawValue: rawValue) }

}

extension ProcessID {
  public static func current() -> ProcessID {
    ProcessID(getpid())
  }
}
