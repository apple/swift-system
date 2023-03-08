/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)


// Strongly typed, Swifty interfaces to the most common and useful `fcntl`
// commands.

extension FileDescriptor {
  /// Get the flags associated with this file descriptor
  ///
  /// The corresponding C function is `fcntl` with the `F_GETFD` command.
  @_alwaysEmitIntoClient
  public func getFlags(retryOnInterrupt: Bool = true) throws -> Flags {
    try Flags(rawValue: control(
      .getFlags, retryOnInterrupt: retryOnInterrupt))
  }

  /// Set the file descriptor flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETFD` command.
  @_alwaysEmitIntoClient
  public func setFlags(
    _ value: Flags, retryOnInterrupt: Bool = true
  ) throws {
    _ = try control(
      .setFlags, value.rawValue, retryOnInterrupt: retryOnInterrupt)
  }

  /// Get descriptor status flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_GETFL` command.
  @_alwaysEmitIntoClient
  public func getStatusFlags(
    retryOnInterrupt: Bool = true
  ) throws -> StatusFlags {
    try StatusFlags(rawValue: control(
      .getStatusFlags, retryOnInterrupt: retryOnInterrupt))
  }

  /// Set descriptor status flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETFL` command.
  @_alwaysEmitIntoClient
  public func setStatusFlags(
    _ flags: StatusFlags, retryOnInterrupt: Bool = true
  ) throws {
    _ = try control(
      .setStatusFlags, flags.rawValue, retryOnInterrupt: retryOnInterrupt)
  }
}

extension FileDescriptor {
  /// Get the process ID or process group currently receiv-
  /// ing SIGIO and SIGURG signals.
  ///
  /// The corresponding C function is `fcntl` with the `F_GETOWN` command.
  @_alwaysEmitIntoClient
  public func getOwner(
    retryOnInterrupt: Bool = true
  ) throws -> (ProcessID, isGroup: Bool) {
    let pidOrPGID = try control(
      .getOwner, retryOnInterrupt: retryOnInterrupt)
    if pidOrPGID < 0 {
      return (ProcessID(rawValue: -pidOrPGID), isGroup: true)
    }
    return (ProcessID(rawValue: pidOrPGID), isGroup: false)
  }

  /// Set the process or process group to receive SIGIO and
  /// SIGURG signals.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETOWN` command.
  @_alwaysEmitIntoClient
  public func setOwner(
    _ id: ProcessID, isGroup: Bool, retryOnInterrupt: Bool = true
  ) throws {
    let pidOrPGID = isGroup ? -id.rawValue : id.rawValue
    _ = try control(.setOwner, pidOrPGID, retryOnInterrupt: retryOnInterrupt)
  }
}

extension FileDescriptor {
  /// Duplicate this file descriptor and return the newly created copy.
  ///
  /// - Parameters:
  ///   - `minRawValue`: A lower bound on the new file descriptor's raw value.
  ///   - `closeOnExec`: Whether the new descriptor's `closeOnExec` flag is set.
  /// - Returns: The lowest numbered available descriptor whose raw value is
  ///     greater than or equal to `minRawValue`.
  ///
  /// File descriptors are merely references to some underlying system resource.
  /// The system does not distinguish between the original and the new file
  /// descriptor in any way. For example, read, write and seek operations on
  /// one of them also affect the logical file position in the other, and
  /// append mode, non-blocking I/O and asynchronous I/O options are shared
  /// between the references. If a separate pointer into the file is desired,
  /// a different object reference to the file must be obtained by issuing an
  /// additional call to `open`.
  ///
  /// However, each file descriptor maintains its own close-on-exec flag.
  ///
  /// The corresponding C functions are `fcntl` with `F_DUPFD` and
  /// `F_DUPFD_CLOEXEC`.
  @_alwaysEmitIntoClient
  public func duplicate(
    minRawValue: CInt, closeOnExec: Bool, retryOnInterrupt: Bool = true
  ) throws -> FileDescriptor {
    let cmd: Command = closeOnExec ? .duplicateCloseOnExec : .duplicate
    return try FileDescriptor(rawValue: control(
      cmd, minRawValue, retryOnInterrupt: retryOnInterrupt))
  }

#if !os(Linux)

  /// Get the path of the file descriptor
  ///
  /// - Parameters:
  ///   - `noFirmLink`: Get the non firmlinked path of the file descriptor.
  ///
  /// The corresponding C functions are `fcntl` with `F_GETPATH` and
  /// `F_GETPATH_NOFIRMLINK`.
  public func getPath(
    noFirmLink: Bool = false, retryOnInterrupt: Bool = true
  ) throws -> FilePath {
    let cmd: Command = noFirmLink ? .getPathNoFirmLink : .getPath
    // TODO: have a uninitialized init on FilePath / SystemString...
    let bytes = try Array<SystemChar>(unsafeUninitializedCapacity: _maxPathLen) {
      (bufPtr, count: inout Int) in
      _ = try control(
        cmd,
        UnsafeMutableRawPointer(bufPtr.baseAddress!),
        retryOnInterrupt: retryOnInterrupt)
      // TODO: The below is probably the wrong formulation...
      count = system_strlen(
        UnsafeRawPointer(
          bufPtr.baseAddress!
        ).assumingMemoryBound(to: Int8.self))
    }
    return FilePath(SystemString(nullTerminated: bytes))
  }

#endif // !os(Linux)

}

#endif // !os(Windows)
