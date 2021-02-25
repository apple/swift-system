
// FIXME(DO NOT MERGE): system_foo wrappers for these and mocking
import CSystem

extension ProcessID {
  public struct TaskInfo: RawRepresentable/*, Hashable, Codable*/ {
    /// The raw C process id.
    @_alwaysEmitIntoClient
    public let rawValue: CInterop.ProcTaskInfo

    /// Creates a strongly-typed process id from a raw C pid
    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.ProcTaskInfo) { self.rawValue = rawValue }

    fileprivate init(_ rawValue: CInterop.ProcTaskInfo) {
      self.init(rawValue: rawValue)
    }
  }
  public func getTaskInfo() throws -> TaskInfo {
    var result = TaskInfo.RawValue()
    try withUnsafeMutableBytes(of: &result) {
      let val = proc_pidinfo(self.rawValue, PROC_PIDTASKINFO, 0, $0.baseAddress, Int32($0.count))
      // What is this wacky shenanigans?
      guard MemoryLayout<TaskInfo.RawValue>.stride == val else {
        throw Errno(rawValue: val)
      }
    }
    return TaskInfo(result)
  }
}

extension ProcessID.TaskInfo {

  /// `pti_virtual_size`: virtual memory size (bytes)
  public var virtualSize: UInt64 { UInt64(rawValue.pti_virtual_size) }

  /// `pti_resident_size`: resident memory size (bytes)
  public var residentSize: UInt64 { UInt64(rawValue.pti_resident_size) }

  /// `pti_total_user`: total time
  public var totalUserTime: UInt64 { UInt64(rawValue.pti_total_user) }

  /// `pti_threads_user`: existing threads only
  public var userThreads: UInt64 { UInt64(rawValue.pti_threads_user) }

  /// `pti_policy`: default policy for new threads
  public var policy: Int { Int(rawValue.pti_policy) }

  /// `pti_faults`: number of page faults
  public var pageFaults: Int { Int(rawValue.pti_faults) }

  /// `pti_pageins`: number of actual pageins
  public var pageIns: Int { Int(rawValue.pti_pageins) }

  /// `pti_cow_faults`: number of copy-on-write faults
  public var cowFaults: Int { Int(rawValue.pti_cow_faults) }

  /// `pti_messages_sent`: number of messages sent
  public var messagesSent: Int { Int(rawValue.pti_messages_sent) }

  /// `pti_messages_received`: number of messages received
  public var messagesReceived: Int { Int(rawValue.pti_messages_received) }

  /// `pti_syscalls_mach`: number of mach system calls
  public var syscallsMach: Int { Int(rawValue.pti_syscalls_mach) }

  /// `pti_syscalls_unix`: number of unix system calls
  public var syscallsUnix: Int { Int(rawValue.pti_syscalls_unix) }

  /// `pti_csw`: number of context switches
  public var contextSwitches: Int { Int(rawValue.pti_csw) }

  /// `pti_threadnum`: number of threads in the task
  public var taskThreads: Int { Int(rawValue.pti_threadnum) }

  /// `pti_numrunning`: number of running threads
  public var runningThreads: Int { Int(rawValue.pti_numrunning) }

  /// `pti_priority`: task priority
  public var taskPriority: Int { Int(rawValue.pti_priority) }

}
