/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// File Events bitmask
@frozen
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public struct FileEvents: OptionSet, Hashable, Codable {
    
    /// The raw C file events.
    @_alwaysEmitIntoClient
    public let rawValue: CInterop.FileEvent

    /// Create a strongly-typed file events from a raw C value.
    @_alwaysEmitIntoClient
    public init(rawValue: CInterop.FileEvent) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    private init(_ raw: CInt) { self.init(rawValue: numericCast(raw)) }
}

public extension FileEvents {
    
    /// There is data to read.
    @_alwaysEmitIntoClient
    static var read: FileEvents { FileEvents(_POLLIN) }
    
    /// There is urgent data to read (e.g., out-of-band data on TCP socket;
    /// pseudoterminal master in packet mode has seen state change in slave).
    @_alwaysEmitIntoClient
    static var readUrgent: FileEvents { FileEvents(_POLLPRI) }
    
    /// Writing now will not block.
    @_alwaysEmitIntoClient
    static var write: FileEvents { FileEvents(_POLLOUT) }
    
    /// Error condition.
    @_alwaysEmitIntoClient
    static var error: FileEvents { FileEvents(_POLLERR) }
    
    /// Hang up.
    @_alwaysEmitIntoClient
    static var hangup: FileEvents { FileEvents(_POLLHUP) }
    
    /// Error condition.
    @_alwaysEmitIntoClient
    static var invalidRequest: FileEvents { FileEvents(_POLLNVAL) }
}


extension FileEvents
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the file permissions.
  @inline(never)
  public var description: String {
    let descriptions: [(Element, StaticString)] = [
      (.read, ".read"),
      (.readUrgent, ".readUrgent"),
      (.write, ".write"),
      (.error, ".error"),
      (.hangup, ".hangup"),
      (.invalidRequest, ".invalidRequest")
    ]

    return _buildDescription(descriptions)
  }

  /// A textual representation of the file permissions, suitable for debugging.
  public var debugDescription: String { self.description }
}
