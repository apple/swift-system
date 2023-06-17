/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - stat
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  /// Obtain information about the file pointed to by the FileDescriptor.
  ///
  /// - Parameters:
  ///   - retryOnInterrupt: Whether to retry the read operation
  ///     if it throws ``Errno/interrupted``.
  ///     The default is `true`.
  ///     Pass `false` to try only once and throw an error upon interruption.
  /// - Returns: A `FileStatus` for the file pointed to by `self`.
  ///
  /// The corresponding C function is `fstat`.
  @_alwaysEmitIntoClient
  public func getFileStatus(
    retryOnInterrupt: Bool = true
  ) throws -> FileStatus {
    try _getFileStatus(
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _getFileStatus(
    retryOnInterrupt: Bool = true
  ) -> Result<FileStatus, Errno> {
    var result = CInterop.Stat()
    return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fstat(self.rawValue, &result)
    }.map { FileStatus(rawValue: result) }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - chmod
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func changeFileMode(
    to mode: FileMode,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileMode(
      to: mode,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }
  
  @usableFromInline
  internal func _changeFileMode(
    to mode: FileMode,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fchmod(self.rawValue, mode.rawValue)
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - chown
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func changeFileOwner(
    to owner: (userID: CInterop.UserID, groupID: CInterop.GroupID),
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileOwner(
      to: owner,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileOwner(
    to owner: (userID: CInterop.UserID, groupID: CInterop.GroupID),
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fchown(self.rawValue, owner.userID, owner.groupID)
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - chflags
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  internal func changeFileFlags(
    to flags: FileFlags,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileFlags(
      to: flags,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileFlags(
    to flags: FileFlags,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
      system_fchflags(self.rawValue, flags.rawValue)
    }
  }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// MARK: - utimens
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  @_alwaysEmitIntoClient
  public func changeFileTimes(
    to times: (access: TimeSpecification, modification: TimeSpecification)?,
    retryOnInterrupt: Bool = true
  ) throws {
    try _changeFileTimes(
      to: times,
      retryOnInterrupt: retryOnInterrupt
    ).get()
  }

  @usableFromInline
  internal func _changeFileTimes(
    to times: (access: TimeSpecification, modification: TimeSpecification)?,
    retryOnInterrupt: Bool
  ) -> Result<Void, Errno> {
    if let times = times {
      return withUnsafePointer(to: times) { tuplePtr in
        tuplePtr.withMemoryRebound(to: CInterop.TimeSpec.self, capacity: 2) {
          timespecPtr in
          nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
            system_futimens(self.rawValue, timespecPtr)
          }
        }
      }
    } else {
      return nothingOrErrno(retryOnInterrupt: retryOnInterrupt) {
        system_futimens(self.rawValue, nil)
      }
    }
  }
}
#endif
