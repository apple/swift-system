/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// Represents a location in the file system.
///
/// This structure recognizes directory separators  (e.g. `/`), roots, and
/// requires that the content terminates in a NUL (`0x0`). Beyond that, it
/// does not give any meaning to the bytes that it contains. The file system
/// defines how the content is interpreted; for example, by its choice of string
/// encoding.
///
/// On construction, `FilePath` will normalize separators by removing
/// reduncant intermediary separators and stripping any trailing separators.
/// On Windows, `FilePath` will also normalize forward slashes `/` into
/// backslashes `\`, as preferred by the platform.
///
/// The code below creates a file path from a string literal,
/// and then uses it to open and append to a log file:
///
///     let message: String = "This is a log message."
///     let path: FilePath = "/tmp/log"
///     let fd = try FileDescriptor.open(path, .writeOnly, options: .append)
///     try fd.closeAfter { try fd.writeAll(message.utf8) }
///
/// File paths conform to the
/// and <doc://com.apple.documentation/documentation/swift/equatable>
/// and <doc://com.apple.documentation/documentation/swift/hashable> protocols
/// by performing the protocols' operations on their raw byte contents.
/// This conformance allows file paths to be used,
/// for example, as keys in a dictionary.
/// However, the rules for path equivalence
/// are file-system–specific and have additional considerations
/// like case insensitivity, Unicode normalization, and symbolic links.
///
// TODO(docs): Section on all the new syntactic operations, lexical normalization, decomposition,
// components, etc.
// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public struct FilePath {
  internal var _storage: SystemString

  /// Creates an empty, null-terminated path.
  public init() {
    self._storage = SystemString()
    _invariantCheck()
  }

  // In addition to the empty init, this init will properly normalize
  // separators. All other initializers should be implemented by
  // ultimately deferring to a normalizing init.
  internal init(_ str: SystemString) {
    self._storage = str
    self._normalizeSeparators()
    _invariantCheck()
  }
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath {
  /// The length of the file path, excluding the null terminator.
  public var length: Int { _storage.length }
}

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension FilePath: Hashable, Codable {}

