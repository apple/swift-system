#if canImport(System) && canImport(SystemPackage)
import System
import SystemPackage

@available(System 0.0.2, *)
extension SystemPackage.FilePath {
  @available(System 0.0.2, *)
  public init(converting path: System.FilePath) {
    self = path.withPlatformString(Self.init(platformString:))
  }
}

@available(System 0.0.2, *)
extension System.FilePath {
  @available(System 0.0.2, *)
  public init(converting path: SystemPackage.FilePath) {
    self = path.withPlatformString(Self.init(platformString:))
  }
}

@available(System 0.0.1, *)
extension SystemPackage.FileDescriptor {
  @available(System 0.0.1, *)
  public init(converting descriptor: System.FileDescriptor) {
    self.init(rawValue: descriptor.rawValue)
  }
}

@available(System 0.0.1, *)
extension System.FileDescriptor {
  @available(System 0.0.1, *)
  public init(converting descriptor: SystemPackage.FileDescriptor) {
    self.init(rawValue: descriptor.rawValue)
  }
}
#endif // canImport(System) && canImport(SystemPackage)
