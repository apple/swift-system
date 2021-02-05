
extension ProcessID {
  public struct ResourceUsageInfo: RawRepresentable/*, Hashable, Codable*/ {
    /// The raw C process id.
    @_alwaysEmitIntoClient
    public let rawValue: CInterop.RUsageInfo

    /// Creates a strongly-typed process id from a raw C pid
    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.RUsageInfo) { self.rawValue = rawValue }

    fileprivate init(_ rawValue: CInterop.RUsageInfo) {
      self.init(rawValue: rawValue)
    }

    fileprivate static var blank: ResourceUsageInfo {
      ResourceUsageInfo(rusage_info_current())
    }
  }
}

// FIXME(DO NOT MERGE): system_foo wrappers for these and mocking
import CSystem
extension ProcessID {
  public func getResourceUsageInfo() throws -> ResourceUsageInfo {
    var current = ResourceUsageInfo.blank
    try withUnsafeMutablePointer(to: &current) {
      try $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
        guard 0 == proc_pid_rusage(self.rawValue, RUSAGE_INFO_CURRENT, $0) else {
          throw Errno(rawValue: errno)
        }
      }
    }
    return current
  }
}

// FIXME: docs or comments, the headers have none...
// FIXME: names
extension ProcessID.ResourceUsageInfo {
  // FIXME: UUID proper type
  public typealias UUID = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

  /// `ri_uuid`: TBD
  public var uuid: UUID { rawValue.ri_uuid }

  /// `ri_user_time`: TBD
  public var userTime: UInt64 { rawValue.ri_user_time }

  /// `ri_system_time`: TBD
  public var systemTime: UInt64 { rawValue.ri_system_time }

  /// `ri_pkg_idle_wkups`: TBD
  public var pkgIdleWakeups: UInt64 { rawValue.ri_pkg_idle_wkups }

  /// `ri_interrupt_wkups`: TBD
  public var interruptWakeups: UInt64 { rawValue.ri_interrupt_wkups }

  /// `ri_pageins`: TBD
  public var pageIns: UInt64 { rawValue.ri_pageins }

  /// `ri_wired_size`: TBD
  public var wiredSize: UInt64 { rawValue.ri_wired_size }

  /// `ri_resident_size`: TBD
  public var residentSize: UInt64 { rawValue.ri_resident_size }

  /// `ri_phys_footprint`: TBD
  public var physicalFootprint: UInt64 { rawValue.ri_phys_footprint }

  /// `ri_proc_start_abstime`: TBD
  public var processStartAbsoluteTime: UInt64 { rawValue.ri_proc_start_abstime }

  /// `ri_proc_exit_abstime`: TBD
  public var processExitAbsoluteTime: UInt64 { rawValue.ri_proc_exit_abstime }

  /// `ri_child_user_time`: TBD
  public var childUserTime: UInt64 { rawValue.ri_child_user_time }

  /// `ri_child_system_time`: TBD
  public var childSystemTime: UInt64 { rawValue.ri_child_system_time }

  /// `ri_child_pkg_idle_wkups`: TBD
  public var childPkgIdleWakeups: UInt64 { rawValue.ri_child_pkg_idle_wkups }

  /// `ri_child_interrupt_wkups`: TBD
  public var childInterruptWakeups: UInt64 { rawValue.ri_child_interrupt_wkups }

  /// `ri_child_pageins`: TBD
  public var childPageIns: UInt64 { rawValue.ri_child_pageins }

  /// `ri_child_elapsed_abstime`: TBD
  public var childElapsedAbsoluteTime: UInt64 { rawValue.ri_child_elapsed_abstime }

  /// `ri_diskio_bytesread`: TBD
  public var diskIOBytesRead: UInt64 { rawValue.ri_diskio_bytesread }

  /// `ri_diskio_byteswritten`: TBD
  public var diskIOBytesWritten: UInt64 { rawValue.ri_diskio_byteswritten }

  /// `ri_cpu_time_qos_default`: TBD
  public var cpuTimeQOSDefault: UInt64 { rawValue.ri_cpu_time_qos_default }

  /// `ri_cpu_time_qos_maintenance`: TBD
  public var cpuTimeQOSMaintenance: UInt64 { rawValue.ri_cpu_time_qos_maintenance }

  /// `ri_cpu_time_qos_background`: TBD
  public var cpuTimeQOSBackground: UInt64 { rawValue.ri_cpu_time_qos_background }

  /// `ri_cpu_time_qos_utility`: TBD
  public var cpuTimeQOSUtility: UInt64 { rawValue.ri_cpu_time_qos_utility }

  /// `ri_cpu_time_qos_legacy`: TBD
  public var cpuTimeQOSLegacy: UInt64 { rawValue.ri_cpu_time_qos_legacy }

  /// `ri_cpu_time_qos_user_initiated`: TBD
  public var cpuTimeQOSUserInitiated: UInt64 { rawValue.ri_cpu_time_qos_user_initiated }

  /// `ri_cpu_time_qos_user_interactive`: TBD
  public var cpuTimeQOSUserInteractive: UInt64 { rawValue.ri_cpu_time_qos_user_interactive }

  /// `ri_billed_system_time`: TBD
  public var billedSystemTime: UInt64 { rawValue.ri_billed_system_time }

  /// `ri_serviced_system_time`: TBD
  public var servicedSystemTime: UInt64 { rawValue.ri_serviced_system_time }

  /// `ri_logical_writes`: TBD
  public var logicalWrites: UInt64 { rawValue.ri_logical_writes }

  /// `ri_lifetime_max_phys_footprint`: TBD
  public var lifetimeMaxPhysicalFootprint: UInt64 { rawValue.ri_lifetime_max_phys_footprint }

  /// `ri_instructions`: TBD
  public var instructions: UInt64 { rawValue.ri_instructions }

  /// `ri_cycles`: TBD
  public var cycles: UInt64 { rawValue.ri_cycles }

  /// `ri_billed_energy`: TBD
  public var billedEnergy: UInt64 { rawValue.ri_billed_energy }

  /// `ri_serviced_energy`: TBD
  public var servicedEnergy: UInt64 { rawValue.ri_serviced_energy }

  /// `ri_interval_max_phys_footprint`: TBD
  public var intervalMaxPhysicalFootprint: UInt64 { rawValue.ri_interval_max_phys_footprint }

  /// `ri_runnable_time`: TBD
  public var runnableTime: UInt64 { rawValue.ri_runnable_time }

  /// `ri_flags`: TBD
  public var flags: UInt64 { rawValue.ri_flags }

}


