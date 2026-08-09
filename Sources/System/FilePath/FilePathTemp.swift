/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/


// MARK: - API

/// Create a temporary path for the duration of the closure.
///
/// - Parameters:
///   - basename: The base name for the temporary path.
///   - body: The closure to execute.
///
/// Creates a temporary directory with a name based on the given `basename`,
/// executes `body`, passing in the path of the created directory, then
/// deletes the directory and all of its contents before returning.
internal func withTemporaryFilePath<R>(
  basename: _StdlibFilePath.Component,
  _ body: (FilePath) throws -> R
) throws -> R {
  let temporaryDir = try createUniqueTemporaryDirectory(basename: basename)
  defer {
    try? _recursiveRemove(at: temporaryDir)
  }

  // The directory machinery below works on the stdlib backing, but callers get
  // a `FilePath`, and it has to honor the process-wide backing selection rather
  // than inherit this file's. Rebuilding it from the platform string routes it
  // through the wrapper's normal construction funnel.
  let handedOut = temporaryDir.withPlatformString { FilePath(platformString: $0) }
  return try body(handedOut)
}

// MARK: - Internals

fileprivate let base64 = Array<UInt8>(
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".utf8
)

/// Create a directory that is only accessible to the current user.
///
/// - Parameters:
///   - path: The path of the directory to create.
/// - Returns: `true` if a new directory was created.
///
/// This function will throw if there is an error, except if the error
/// is that the directory exists, in which case it returns `false`.
fileprivate func makeLockedDownDirectory(at path: _StdlibFilePath) throws -> Bool {
  return try path.withPlatformString {
    if system_mkdir($0, 0o700) == 0 {
      return true
    }
    let err = system_errno
    if err == Errno.fileExists.rawValue {
      return false
    } else {
      throw Errno(rawValue: err)
    }
  }
}

/// Generate a random string of base64 filename safe characters.
///
/// - Parameters:
///   - length: The number of characters in the returned string.
/// - Returns: A random string of length `length`.
fileprivate func createRandomString(length: Int) -> String {
  return String(
    decoding: (0..<length).map{
      _ in base64[Int.random(in: 0..<64)]
    },
    as: UTF8.self
  )
}

/// Given a base name, create a uniquely named temporary directory.
///
/// - Parameters:
///   - basename: The base name for the new directory.
/// - Returns: The path to the new directory.
///
/// Creates a directory in the system temporary directory whose name
/// starts with `basename`, followed by a `.` and then a random
/// string of characters.
fileprivate func createUniqueTemporaryDirectory(
  basename: _StdlibFilePath.Component
) throws -> _StdlibFilePath {
  var tempDir = try _getTemporaryDirectory()
  tempDir.append(basename)

  while true {
    tempDir.extension = createRandomString(length: 16)

    if try makeLockedDownDirectory(at: tempDir) {
      return tempDir
    }
  }
}
