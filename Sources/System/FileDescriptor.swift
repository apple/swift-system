/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// An abstract handle to an input or output data resource,
/// such as a file or a socket.
///
/// You are responsible for managing the lifetime and validity
/// of `FileDescriptor` values,
/// in the same way as you manage a raw C file handle.
@frozen
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
public struct FileDescriptor: RawRepresentable, Hashable, Codable {
  /// The raw C file handle.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly-typed file handle from a raw C file handle.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }
}

// Standard file descriptors.
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FileDescriptor {
  /// The standard input file descriptor, with a numeric value of 0.
  @_alwaysEmitIntoClient
  public static var standardInput: FileDescriptor { .init(rawValue: 0) }

  /// The standard output file descriptor, with a numeric value of 1.
  @_alwaysEmitIntoClient
  public static var standardOutput: FileDescriptor { .init(rawValue: 1) }

  /// The standard error file descriptor, with a numeric value of 2.
  @_alwaysEmitIntoClient
  public static var standardError: FileDescriptor { .init(rawValue: 2) }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FileDescriptor {
  /// The desired read and write access for a newly opened file.
  @frozen
  @available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
  public struct AccessMode: RawRepresentable, Sendable, Hashable, Codable {
    /// The raw C access mode.
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    /// Creates a strongly-typed access mode from a raw C access mode.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Opens the file for reading only.
    ///
    /// The corresponding C constant is `O_RDONLY`.
    @_alwaysEmitIntoClient
    public static var readOnly: AccessMode { AccessMode(rawValue: _O_RDONLY) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "readOnly")
    public static var O_RDONLY: AccessMode { readOnly }

    /// Opens the file for writing only.
    ///
    /// The corresponding C constant is `O_WRONLY`.
    @_alwaysEmitIntoClient
    public static var writeOnly: AccessMode { AccessMode(rawValue: _O_WRONLY) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "writeOnly")
    public static var O_WRONLY: AccessMode { writeOnly }

    /// Opens the file for reading and writing.
    ///
    /// The corresponding C constant is `O_RDWR`.
    @_alwaysEmitIntoClient
    public static var readWrite: AccessMode { AccessMode(rawValue: _O_RDWR) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "readWrite")
    public static var O_RDWR: AccessMode { readWrite }
  }

  /// Options that specify behavior for a newly-opened file.
  @frozen
  @available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
  public struct OpenOptions: OptionSet, Sendable, Hashable, Codable {
    /// The raw C options.
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    /// Create a strongly-typed options value from raw C options.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

#if !os(Windows)
    /// Indicates that opening the file doesn't
    /// wait for the file or device to become available.
    ///
    /// If this option is specified,
    /// the system doesn't wait for the device or file
    /// to be ready or available.
    /// If the
    /// <doc:FileDescriptor/open(_:_:options:permissions:retryOnInterrupt:)-2266j>
    /// call would result in the process being blocked for some reason,
    /// that method returns immediately.
    /// This flag also has the effect of making all
    /// subsequent input and output operations on the open file nonblocking.
    ///
    /// The corresponding C constant is `O_NONBLOCK`.
    @_alwaysEmitIntoClient
    public static var nonBlocking: OpenOptions { .init(rawValue: _O_NONBLOCK) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "nonBlocking")
    public static var O_NONBLOCK: OpenOptions { nonBlocking }
#endif

    /// Indicates that each write operation appends to the file.
    ///
    /// If this option is specified,
    /// each time you write to the file,
    /// the new data is written at the end of the file,
    /// after all existing file data.
    ///
    /// The corresponding C constant is `O_APPEND`.
    @_alwaysEmitIntoClient
    public static var append: OpenOptions { .init(rawValue: _O_APPEND) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "append")
    public static var O_APPEND: OpenOptions { append }

    /// Indicates that opening the file creates the file if it doesn't exist.
    ///
    /// The corresponding C constant is `O_CREAT`.
    @_alwaysEmitIntoClient
    public static var create: OpenOptions { .init(rawValue: _O_CREAT) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "create")
    public static var O_CREAT: OpenOptions { create }

    /// Indicates that opening the file truncates the file if it exists.
    ///
    /// If this option is specified and the file exists,
    /// the file is truncated to zero bytes
    /// before any other operations are performed.
    ///
    /// The corresponding C constant is `O_TRUNC`.
    @_alwaysEmitIntoClient
    public static var truncate: OpenOptions { .init(rawValue: _O_TRUNC) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "truncate")
    public static var O_TRUNC: OpenOptions { truncate }

    /// Indicates that opening the file creates the file,
    /// expecting that it doesn't exist.
    ///
    /// If this option and ``create`` are both specified and the file exists,
    /// <doc:FileDescriptor/open(_:_:options:permissions:retryOnInterrupt:)-2266j>
    /// returns an error instead of creating the file.
    /// You can use this, for example,
    /// to implement a simple exclusive-access locking mechanism.
    ///
    /// If this option and ``create`` are both specified
    /// and the last component of the file's path is a symbolic link,
    /// <doc:FileDescriptor/open(_:_:options:permissions:retryOnInterrupt:)-2266j>
    /// fails even if the symbolic link points to a nonexistent name.
    ///
    /// The corresponding C constant is `O_EXCL`.
    @_alwaysEmitIntoClient
    public static var exclusiveCreate: OpenOptions { .init(rawValue: _O_EXCL) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "exclusiveCreate")
    public static var O_EXCL: OpenOptions { exclusiveCreate }

#if SYSTEM_PACKAGE_DARWIN
    /// Indicates that opening the file
    /// atomically obtains a shared lock on the file.
    ///
    /// Setting this option or the ``exclusiveLock`` option
    /// obtains a lock with `flock(2)` semantics.
    /// If you're creating a file using the ``create`` option,
    /// the request for the lock always succeeds
    /// except on file systems that don't support locking.
    ///
    /// The corresponding C constant is `O_SHLOCK`.
    @_alwaysEmitIntoClient
    public static var sharedLock: OpenOptions { .init(rawValue: _O_SHLOCK) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "sharedLock")
    public static var O_SHLOCK: OpenOptions { sharedLock }

    /// Indicates that opening the file
    /// atomically obtains an exclusive lock.
    ///
    /// Setting this option or the ``sharedLock`` option.
    /// obtains a lock with `flock(2)` semantics.
    /// If you're creating a file using the ``create`` option,
    /// the request for the lock always succeeds
    /// except on file systems that don't support locking.
    ///
    /// The corresponding C constant is `O_EXLOCK`.
    @_alwaysEmitIntoClient
    public static var exclusiveLock: OpenOptions { .init(rawValue: _O_EXLOCK) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "exclusiveLock")
    public static var O_EXLOCK: OpenOptions { exclusiveLock }
#endif

#if !os(Windows)
    /// Indicates that opening the file doesn't follow symlinks.
    ///
    /// If you specify this option
    /// and the file path you pass to
    /// <doc:FileDescriptor/open(_:_:options:permissions:retryOnInterrupt:)-2266j>
    /// is a symbolic link,
    /// then that open operation fails.
    ///
    /// The corresponding C constant is `O_NOFOLLOW`.
    @_alwaysEmitIntoClient
    public static var noFollow: OpenOptions { .init(rawValue: _O_NOFOLLOW) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "noFollow")
    public static var O_NOFOLLOW: OpenOptions { noFollow }

    /// Indicates that opening the file only succeeds if the file is a directory.
    ///
    /// If you specify this option and the file path you pass to
    /// <doc:FileDescriptor/open(_:_:options:permissions:retryOnInterrupt:)-2266j>
    /// is a not a directory, then that open operation fails.
    ///
    /// The corresponding C constant is `O_DIRECTORY`.
    @_alwaysEmitIntoClient
    public static var directory: OpenOptions { .init(rawValue: _O_DIRECTORY) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "directory")
    public static var O_DIRECTORY: OpenOptions { directory }
#endif

#if SYSTEM_PACKAGE_DARWIN
    /// Indicates that opening the file
    /// opens symbolic links instead of following them.
    ///
    /// If you specify this option
    /// and the file path you pass to
    /// <doc:FileDescriptor/open(_:_:options:permissions:retryOnInterrupt:)-2266j>
    /// is a symbolic link,
    /// then the link itself is opened instead of what it links to.
    ///
    /// The corresponding C constant is `O_SYMLINK`.
    @_alwaysEmitIntoClient
    public static var symlink: OpenOptions { .init(rawValue: _O_SYMLINK) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "symlink")
    public static var O_SYMLINK: OpenOptions { symlink }

    /// Indicates that opening the file monitors a file for changes.
    ///
    /// Specify this option when opening a file for event notifications,
    /// such as a file handle returned by the `kqueue(2)` function,
    /// rather than for reading or writing.
    /// Files opened with this option
    /// don't prevent their containing volume from being unmounted.
    ///
    /// The corresponding C constant is `O_EVTONLY`.
    @_alwaysEmitIntoClient
    public static var eventOnly: OpenOptions { .init(rawValue: _O_EVTONLY) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "eventOnly")
    public static var O_EVTONLY: OpenOptions { eventOnly }
#endif

#if !os(Windows)
    /// Indicates that executing a program closes the file.
    ///
    /// Normally, file descriptors remain open
    /// across calls to the `exec(2)` family of functions.
    /// If you specify this option,
    /// the file descriptor is closed when replacing this process
    /// with another process.
    ///
    /// The state of the file
    /// descriptor flags can be inspected using `F_GETFD`,
    /// as described in the `fcntl(2)` man page.
    ///
    /// The corresponding C constant is `O_CLOEXEC`.
    @_alwaysEmitIntoClient
    public static var closeOnExec: OpenOptions { .init(rawValue: _O_CLOEXEC) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "closeOnExec")
    public static var O_CLOEXEC: OpenOptions { closeOnExec }
#endif
  }

  /// Options for specifying what a file descriptor's offset is relative to.
  @frozen
  @available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
  public struct SeekOrigin: RawRepresentable, Sendable, Hashable, Codable {
    /// The raw C value.
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    /// Create a strongly-typed seek origin from a raw C value.
    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    /// Indicates that the offset should be set to the specified value.
    ///
    /// The corresponding C constant is `SEEK_SET`.
    @_alwaysEmitIntoClient
    public static var start: SeekOrigin { SeekOrigin(rawValue: _SEEK_SET) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "start")
    public static var SEEK_SET: SeekOrigin { start }

    /// Indicates that the offset should be set
    /// to the specified number of bytes after the current location.
    ///
    /// The corresponding C constant is `SEEK_CUR`.
    @_alwaysEmitIntoClient
    public static var current: SeekOrigin { SeekOrigin(rawValue: _SEEK_CUR) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "current")
    public static var SEEK_CUR: SeekOrigin { current }

    /// Indicates that the offset should be set
    /// to the size of the file plus the specified number of bytes.
    ///
    /// The corresponding C constant is `SEEK_END`.
    @_alwaysEmitIntoClient
    public static var end: SeekOrigin { SeekOrigin(rawValue: _SEEK_END) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "end")
    public static var SEEK_END: SeekOrigin { end }

// TODO: These are available on some versions of Linux with appropriate
// macro defines.
#if SYSTEM_PACKAGE_DARWIN
    /// Indicates that the offset should be set
    /// to the next hole after the specified number of bytes.
    ///
    /// For information about what is considered a hole,
    /// see the `lseek(2)` man page.
    ///
    /// The corresponding C constant is `SEEK_HOLE`.
    @_alwaysEmitIntoClient
    public static var nextHole: SeekOrigin { SeekOrigin(rawValue: _SEEK_HOLE) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "nextHole")
    public static var SEEK_HOLE: SeekOrigin { nextHole }

    /// Indicates that the offset should be set
    /// to the start of the next file region
    /// that isn't a hole
    /// and is greater than or equal to the supplied offset.
    ///
    /// The corresponding C constant is `SEEK_DATA`.
    @_alwaysEmitIntoClient
    public static var nextData: SeekOrigin { SeekOrigin(rawValue: _SEEK_DATA) }

    @_alwaysEmitIntoClient
    @available(*, unavailable, renamed: "nextData")
    public static var SEEK_DATA: SeekOrigin { nextData }
#endif

  }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FileDescriptor.AccessMode
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the access mode.
  @inline(never)
  public var description: String {
    switch self {
    case .readOnly: return "readOnly"
    case .writeOnly: return "writeOnly"
    case .readWrite: return "readWrite"
    default: return "\(Self.self)(rawValue: \(self.rawValue))"
    }
  }

  /// A textual representation of the access mode, suitable for debugging
  public var debugDescription: String { self.description }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FileDescriptor.SeekOrigin
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the seek origin.
  @inline(never)
  public var description: String {
    switch self {
    case .start: return "start"
    case .current: return "current"
    case .end: return "end"
#if SYSTEM_PACKAGE_DARWIN
    case .nextHole: return "nextHole"
    case .nextData: return "nextData"
#endif
    default: return "\(Self.self)(rawValue: \(self.rawValue))"
    }
  }

  /// A textual representation of the seek origin, suitable for debugging.
  public var debugDescription: String { self.description }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FileDescriptor.OpenOptions
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the open options.
  @inline(never)
  public var description: String {
#if SYSTEM_PACKAGE_DARWIN
    let descriptions: [(Element, StaticString)] = [
      (.nonBlocking, ".nonBlocking"),
      (.append, ".append"),
      (.create, ".create"),
      (.truncate, ".truncate"),
      (.exclusiveCreate, ".exclusiveCreate"),
      (.sharedLock, ".sharedLock"),
      (.exclusiveLock, ".exclusiveLock"),
      (.noFollow, ".noFollow"),
      (.symlink, ".symlink"),
      (.eventOnly, ".eventOnly"),
      (.closeOnExec, ".closeOnExec")
    ]
#elseif os(Windows)
    let descriptions: [(Element, StaticString)] = [
      (.append, ".append"),
      (.create, ".create"),
      (.truncate, ".truncate"),
      (.exclusiveCreate, ".exclusiveCreate"),
    ]
#else
    let descriptions: [(Element, StaticString)] = [
      (.nonBlocking, ".nonBlocking"),
      (.append, ".append"),
      (.create, ".create"),
      (.truncate, ".truncate"),
      (.exclusiveCreate, ".exclusiveCreate"),
      (.noFollow, ".noFollow"),
      (.closeOnExec, ".closeOnExec")
    ]
#endif

    return _buildDescription(descriptions)
  }

  /// A textual representation of the open options, suitable for debugging.
  public var debugDescription: String { self.description }
}

// The decision on whether to make FileDescriptor Sendable or not
// is currently being discussed in https://github.com/apple/swift-system/pull/112
//@available(*, unavailable, message: "File descriptors are not completely thread-safe.")
//extension FileDescriptor: Sendable {}
