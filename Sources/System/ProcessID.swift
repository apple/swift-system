
/// TODO: docs
@frozen
public struct ProcessID: RawRepresentable, Hashable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.PID

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.PID) { self.rawValue = rawValue }
}

