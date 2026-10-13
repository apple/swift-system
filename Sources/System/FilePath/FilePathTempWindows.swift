/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Windows)

import WinSDK

/// Get the path to the system temporary directory.
internal func _getTemporaryDirectory() throws -> FilePath {
  return try withUnsafeTemporaryAllocation(of: CInterop.PlatformChar.self,
                                           capacity: Int(MAX_PATH) + 1) {
    buffer in

    guard GetTempPathW(DWORD(buffer.count), buffer.baseAddress) != 0 else {
      throw Errno(windowsError: GetLastError())
    }

    return FilePath(SystemString(platformString: buffer.baseAddress!))
  }
}

/// Invoke a closure for each file within a particular directory.
///
/// - Parameters:
///   - path: The path at which we should enumerate items.
///   - body: The closure that will be invoked.
///
/// We skip the `.` and `..` pseudo-entries.
fileprivate func forEachFile(
  at path: FilePath,
  _ body: (WIN32_FIND_DATAW) throws -> ()
) throws {
  let searchPath = path.appending("\\*")

  try searchPath.withPlatformString { szPath in
    var findData = WIN32_FIND_DATAW()
    let hFind = try szPath.withCanonicalPathRepresentation({ szPath in FindFirstFileW(szPath, &findData) })
    if hFind == INVALID_HANDLE_VALUE {
      throw Errno(windowsError: GetLastError())
    }
    defer {
      FindClose(hFind)
    }

    repeat {
      // Skip . and ..
      if findData.cFileName.0 == 46
           && (findData.cFileName.1 == 0
                 || (findData.cFileName.1 == 46
                       && findData.cFileName.2 == 0)) {
        continue
      }

      try body(findData)
    } while FindNextFileW(hFind, &findData)

    // FindNextFileW returns false both at the end of the enumeration and on
    // error; only ERROR_NO_MORE_FILES is the normal terminator. Treating a
    // transient error as end-of-directory would silently skip the remaining
    // entries and leave the tree partially deleted.
    let error = GetLastError()
    if error != ERROR_NO_MORE_FILES {
      throw Errno(windowsError: error)
    }
  }
}

/// Delete the entire contents of a directory, including its subdirectories.
///
/// - Parameters:
///   - path: The directory to be deleted.
///
/// Removes a directory completely, including all of its contents.
internal func _recursiveRemove(
  at path: FilePath
) throws {
  // First, deal with subdirectories
  try forEachFile(at: path) { findData in
    guard (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0 else {
      return
    }

    let name = withUnsafeBytes(of: findData.cFileName) {
      return SystemString(platformString: $0.assumingMemoryBound(
                            to: CInterop.PlatformChar.self).baseAddress!)
    }
    let component = FilePath.Component(name)!
    let subpath = path.appending(component)

    // A directory that is also a reparse point (a junction or directory
    // symlink) must not be recursed into: enumerating it would traverse into
    // the *target* and delete its contents. Remove the link itself instead;
    // RemoveDirectoryW deletes the reparse point without touching the target.
    if (findData.dwFileAttributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT)) != 0 {
      try subpath.withPlatformString { subpath in
        if try !subpath.withCanonicalPathRepresentation({ RemoveDirectoryW($0) }) {
          throw Errno(windowsError: GetLastError())
        }
      }
    } else {
      try _recursiveRemove(at: subpath)
    }
  }

  // Now delete everything else
  try forEachFile(at: path) { findData in
    let name = withUnsafeBytes(of: findData.cFileName) {
      return SystemString(platformString: $0.assumingMemoryBound(
                            to: CInterop.PlatformChar.self).baseAddress!)
    }
    let component = FilePath.Component(name)!
    let subpath = path.appending(component)

    if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0 {
      try subpath.withPlatformString { subpath in
        if try !subpath.withCanonicalPathRepresentation({ DeleteFileW($0) }) {
          throw Errno(windowsError: GetLastError())
        }
      }
    }
  }

  // Finally, delete the parent
  try path.withPlatformString {
    if try !$0.withCanonicalPathRepresentation({ RemoveDirectoryW($0) }) {
      throw Errno(windowsError: GetLastError())
    }
  }
}

#endif // os(Windows)
