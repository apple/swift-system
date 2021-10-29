/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Message Flags
@frozen
public struct MessageFlags: OptionSet, Hashable, Codable {
    
  /// The raw C file permissions.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Create a strongly-typed file permission from a raw C value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }

  @_alwaysEmitIntoClient
  private init(_ raw: CInt) { self.init(rawValue: raw) }
}

public extension MessageFlags {
    
    @_alwaysEmitIntoClient
    static var outOfBand: MessageFlags { MessageFlags(_MSG_OOB) }
    
    @_alwaysEmitIntoClient
    static var peek: MessageFlags { MessageFlags(_MSG_PEEK) }
    
    @_alwaysEmitIntoClient
    static var noRoute: MessageFlags { MessageFlags(_MSG_DONTROUTE) }
    
    @_alwaysEmitIntoClient
    static var endOfReadline: MessageFlags { MessageFlags(_MSG_EOR) }
}

extension MessageFlags
  : CustomStringConvertible, CustomDebugStringConvertible
{
  /// A textual representation of the file permissions.
  @inline(never)
  public var description: String {
    let descriptions: [(Element, StaticString)] = [
      (.outOfBand, ".outOfBand"),
      (.peek, ".peek"),
      (.noRoute, ".noRoute"),
      (.endOfReadline, ".endOfReadline")
    ]

    return _buildDescription(descriptions)
  }

  /// A textual representation of the file permissions, suitable for debugging.
  public var debugDescription: String { self.description }
}
