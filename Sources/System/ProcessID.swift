
#if !os(Windows)

/// The process identifier (aka PID) used to uniquely identify an active process.
///
/// The corresponding C type is `pid_t`
@frozen
public struct ProcessID: RawRepresentable, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.PID

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.PID) {
    // We assert instead of precondition, as the user may want to
    // use this to ferry a PIDOrPGID value (denoted by a negative number).
    // They would a `EINVAL` on use, instead of trapping the process.
    assert(rawValue >= 0, "Process IDs are always positive")
    self.rawValue = rawValue
  }
}

#endif
