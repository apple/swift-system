/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

/// A file descriptor referring to a terminal device.
///
/// `TerminalDescriptor` wraps a `FileDescriptor` and provides terminal-specific
/// operations defined by POSIX. Use the failable initializer to safely
/// convert a file descriptor, or the `unchecked` initializer when you know the
/// descriptor refers to a terminal.
///
/// ```swift
/// // Safe conversion
/// if let terminal = TerminalDescriptor(FileDescriptor.standardInput) {
///     var attrs = try terminal.attributes()
///     attrs.localFlags.remove(.echo)
///     try terminal.setAttributes(attrs, when: .now)
/// }
///
/// // Unchecked (use when you know it's a terminal)
/// let terminal = TerminalDescriptor(unchecked: .standardInput)
/// ```
@frozen
@available(System 99, *)
public struct TerminalDescriptor: RawRepresentable, Hashable, Codable {
  /// The raw C file descriptor value.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a terminal descriptor from a raw file descriptor value.
  ///
  /// - Precondition: `rawValue` must refer to a terminal device.
  ///   Operations on a `TerminalDescriptor` created from a non-terminal
  ///   file descriptor will throw.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) {
    self.rawValue = rawValue
  }

  /// Creates a terminal descriptor from a file descriptor if it refers to a terminal.
  ///
  /// Returns `nil` if `fileDescriptor` does not refer to a terminal device.
  ///
  /// The corresponding C function is `isatty`.
  @_alwaysEmitIntoClient
  public init?(_ fileDescriptor: FileDescriptor) {
    guard system_isatty(fileDescriptor.rawValue) != 0 else {
      return nil
    }
    self.rawValue = fileDescriptor.rawValue
  }

  /// Creates a terminal descriptor without validating that the file descriptor
  /// refers to a terminal.
  ///
  /// - Precondition: `fileDescriptor` must refer to a terminal device.
  ///   Operations on a `TerminalDescriptor` created from a non-terminal
  ///   file descriptor will throw.
  @_alwaysEmitIntoClient
  public init(unchecked fileDescriptor: FileDescriptor) {
    self.rawValue = fileDescriptor.rawValue
  }

  /// The underlying file descriptor.
  @_alwaysEmitIntoClient
  public var fileDescriptor: FileDescriptor {
    FileDescriptor(rawValue: rawValue)
  }
}

// MARK: - FileDescriptor conveniences

@available(System 99, *)
extension FileDescriptor {
  /// Returns whether this file descriptor refers to a terminal device.
  ///
  /// The corresponding C function is `isatty`.
  @_alwaysEmitIntoClient
  public var isTerminal: Bool {
    system_isatty(rawValue) != 0
  }

  /// Returns this file descriptor as a terminal descriptor, or `nil` if
  /// it does not refer to a terminal device.
  @_alwaysEmitIntoClient
  public var asTerminal: TerminalDescriptor? {
    TerminalDescriptor(self)
  }
}

#endif
