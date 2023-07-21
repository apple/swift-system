
#if !os(Windows)

/// The process identifier (aka PID) used to uniquely identify an active process.
///
/// The corresponding C type is `pid_t`
@frozen
public struct ProcessID: RawRepresentable, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.PID

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.PID) { self.rawValue = rawValue }
}

#endif
