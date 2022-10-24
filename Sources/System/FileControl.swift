/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Strongly typed, Swifty interfaces to the most common and useful `fcntl`
// commands.

extension FileDescriptor {
  // TODO: flags struct or individual queries? or a namespace with individual queries?
  // These types aren't really `Control`s...

  /// Get the flags associated with this file descriptor
  ///
  /// The corresponding C function is `fcntl` with the `F_GETFD` command.
  @_alwaysEmitIntoClient
  public func getFlags() throws -> Control.Flags {
    try Control.Flags(rawValue: control(.getFlags))
  }

  /// Set the file descriptor flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETFD` command.
  @_alwaysEmitIntoClient
  public func setFlags(_ value: Control.Flags) throws {
    _ = try control(.setFlags, value.rawValue)
  }

  /// Get descriptor status flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_GETFL` command.
  @_alwaysEmitIntoClient
  public func getStatusFlags() throws -> Control.StatusFlags {
    try Control.StatusFlags(rawValue: control(.getStatusFlags))
  }

  /// Set descriptor status flags.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETFL` command.
  @_alwaysEmitIntoClient
  public func setStatusFlags(_ flags: Control.StatusFlags) throws {
    _ = try control(.setStatusFlags, flags.rawValue)
  }
}


extension FileDescriptor {
  // TODO: Unify this dup with the other dups which have come in since...

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
    minRawValue: CInt, closeOnExec: Bool
  ) throws -> FileDescriptor {
    let cmd: Control.Command = closeOnExec ? .duplicateCloseOnExec : .duplicate
    return try FileDescriptor(rawValue: control(cmd, minRawValue))
  }

  #if !os(Linux)
  /// Get the path of the file descriptor
  ///
  /// - Parameters:
  ///   - `noFirmLink`: Get the non firmlinked path of the file descriptor.
  ///
  /// The corresponding C functions are `fcntl` with `F_GETPATH` and
  /// `F_GETPATH_NOFIRMLINK`.
  public func getPath(noFirmLink: Bool = false) throws -> FilePath {
    let cmd: Control.Command = noFirmLink ? .getPathNoFirmLink : .getPath
    // TODO: have a uninitialized init on FilePath / SystemString...
    let bytes = try Array<SystemChar>(unsafeUninitializedCapacity: _maxPathLen) {
      (bufPtr, count: inout Int) in
      _ = try control(cmd, UnsafeMutableRawPointer(bufPtr.baseAddress!))
      count = 1 + system_strlen(
        UnsafeRawPointer(bufPtr.baseAddress!).assumingMemoryBound(to: Int8.self))
    }
    return FilePath(SystemString(nullTerminated: bytes))
  }
  #endif
}

// TODO: More fsync functionality using `F_BARRIERFSYNC` and `F_FULLFSYNC`,
// coinciding with the sketch for fsync.

// MARK: - To add in the future with process support

extension FileDescriptor {
  // TODO: Flesh out PID work and see if there's a better, common formulation
  // of the process-or-group id concept.
  // TODO: @frozen
  // TODO: public
  private struct PIDOrPGID: RawRepresentable {
    @_alwaysEmitIntoClient
    public let rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// TODO: PID type
    @_alwaysEmitIntoClient
    public var asPID: CInt? { rawValue >= 0 ? rawValue : nil }

    /// TODO: PGID type
    @_alwaysEmitIntoClient
    public var asPositiveGroupID: CInt? {
      rawValue >= 0 ? nil : -rawValue
    }

    /// TODO: PID type
    @_alwaysEmitIntoClient
    public init(pid id: CInt) {
      precondition(id >= 0)
      self.init(rawValue: id)
    }

    /// TODO: PGID type
    @_alwaysEmitIntoClient
    public init(positiveGroupID id: CInt) {
      precondition(id >= 0)
      self.init(rawValue: -id)
    }
  }

  /// Get the process ID or process group currently receiv-
  /// ing SIGIO and SIGURG signals.
  ///
  /// The corresponding C function is `fcntl` with the `F_GETOWN` command.
  // TODO:  @_alwaysEmitIntoClient
  // TODO: public
  private func getOwner() throws -> PIDOrPGID {
    try PIDOrPGID(rawValue: control(.getOwner))
  }

  /// Set the process or process group to receive SIGIO and
  /// SIGURG signals.
  ///
  /// The corresponding C function is `fcntl` with the `F_SETOWN` command.
  // TODO:  @_alwaysEmitIntoClient
  // TODO: public
  private func setOwner(_ id: PIDOrPGID) throws {
    _ = try control(.setOwner, id.rawValue)
  }
}
