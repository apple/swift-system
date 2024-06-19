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
/// redundant intermediary separators and stripping any trailing separators.
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
/// <doc://com.apple.documentation/documentation/swift/equatable>
/// and <doc://com.apple.documentation/documentation/swift/hashable> protocols
/// by performing the protocols' operations on their raw byte contents.
/// This conformance allows file paths to be used,
/// for example, as keys in a dictionary.
/// However, the rules for path equivalence
/// are file-system–specific and have additional considerations
/// like case insensitivity, Unicode normalization, and symbolic links.
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
public struct FilePath: Sendable {
  // TODO(docs): Section on all the new syntactic operations, lexical normalization, decomposition,
  // components, etc.
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

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FilePath {
  /// The length of the file path, excluding the null terminator.
  public var length: Int { _storage.length }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FilePath: Hashable {}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension FilePath: Codable {
  public init(from decoder: any Decoder) throws {
    // Try to decode as a string first for the common case where the path can be
    // losslessly represented as a UTF-8 string.
    let singleValueContainer = try decoder.singleValueContainer()
    if let string = try? singleValueContainer.decode(String.self) {
      self.init(string)
      return
    }
    // Try to decode as an array of UTF-8 code unit on Unix and UTF-16 code unit on Windows.
    if let chars = try? singleValueContainer.decode([CInterop.PlatformChar].self) {
      // Decode code units in a fault-tolerant way instead of fatalError on non-null-terminated input
      // unlike the `init(platformString: [CInterop.PlatformChar])` initializer.
      guard let _ = chars.firstIndex(of: 0) else {
        throw DecodingError.dataCorruptedError(in: singleValueContainer, debugDescription: "Expected null-terminated array of \(CInterop.PlatformChar.self)")
      }
      self = chars.withUnsafeBufferPointer {
        FilePath(platformString: $0.baseAddress!)
      }
      return
    }

    // Otherwise, data is corrupted.
    throw DecodingError.dataCorruptedError(in: singleValueContainer, debugDescription: "Expected String or Array of \(CInterop.PlatformChar.self)")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    if let string = String(validating: self) {
      try container.encode(string)
    } else {
      try container.encode(_storage.nullTerminatedStorage)
    }
  }
}
