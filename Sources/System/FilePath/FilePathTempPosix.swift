/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

/// Get the path to the system temporary directory.
internal func _getTemporaryDirectory() throws -> FilePath {
  guard let tmp = system_getenv("TMPDIR") else {
    return "/tmp"
  }

  return FilePath(SystemString(platformString: tmp))
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
  let dirfd = try FileDescriptor.open(path, .readOnly, options: .directory)
  defer {
    try? dirfd.close()
  }

  let dot: (CInterop.PlatformChar, CInterop.PlatformChar) = (46, 0)
  try withUnsafeBytes(of: dot) {
    try recursiveRemove(
      in: dirfd.rawValue,
      name: $0.assumingMemoryBound(to: CInterop.PlatformChar.self).baseAddress!
    )
  }

  try path.withPlatformString {
    if system_rmdir($0) != 0 {
      throw Errno.current
    }
  }
}

/// Open a directory by reference to its parent and name.
///
/// - Parameters:
///   - dirfd: An open file descriptor for the parent directory.
///   - name: The name of the directory to open.
/// - Returns: A pointer to a `DIR` structure.
///
/// This is like `opendir()`, but instead of taking a path, it uses a
/// file descriptor pointing at the parent, thus avoiding path length
/// limits.
fileprivate func impl_opendirat(
  _ dirfd: CInt,
  _ name: UnsafePointer<CInterop.PlatformChar>
) -> system_DIRPtr? {
  let fd = system_openat(dirfd, name,
                         FileDescriptor.AccessMode.readOnly.rawValue
                           | FileDescriptor.OpenOptions.directory.rawValue)
  if fd < 0 {
    return nil
  }
  return system_fdopendir(fd)
}

/// Invoke a closure for each file within a particular directory.
///
/// - Parameters:
///   - dirfd: The parent of the directory to be enumerated.
///   - subdir: The subdirectory to be enumerated.
///   - body: The closure that will be invoked.
///
/// We skip the `.` and `..` pseudo-entries.
fileprivate func forEachFile(
  in dirfd: CInt,
  subdir: UnsafePointer<CInterop.PlatformChar>,
  _ body: (system_dirent) throws -> ()
) throws {
  guard let dir = impl_opendirat(dirfd, subdir) else {
    throw Errno.current
  }
  defer {
    _ = system_closedir(dir)
  }

  while let dirent = system_readdir(dir) {
    // Skip . and ..
    if dirent.pointee.d_name.0 == 46
         && (dirent.pointee.d_name.1 == 0
               || (dirent.pointee.d_name.1 == 46
                     && dirent.pointee.d_name.2 == 0)) {
      continue
    }

    try body(dirent.pointee)
  }
}

/// Delete the entire contents of a directory, including its subdirectories.
///
/// - Parameters:
///   - dirfd: The parent of the directory to be removed.
///   - name: The name of the directory to be removed.
///
/// Removes a directory completely, including all of its contents.
fileprivate func recursiveRemove(
  in dirfd: CInt,
  name: UnsafePointer<CInterop.PlatformChar>
) throws {
  // First, deal with subdirectories
  try forEachFile(in: dirfd, subdir: name) { dirent in
    if dirent.d_type == SYSTEM_DT_DIR {
      try withUnsafeBytes(of: dirent.d_name) {
        try recursiveRemove(
          in: dirfd,
          name: $0.assumingMemoryBound(to: CInterop.PlatformChar.self)
            .baseAddress!
        )
      }
    }
  }

  // Now delete the contents of this directory
  try forEachFile(in: dirfd, subdir: name) { dirent in
    let flag: CInt

    if dirent.d_type == SYSTEM_DT_DIR {
      flag = SYSTEM_AT_REMOVE_DIR
    } else {
      flag = 0
    }

    let result = withUnsafeBytes(of: dirent.d_name) {
      system_unlinkat(dirfd,
                      $0.assumingMemoryBound(to: CInterop.PlatformChar.self)
                        .baseAddress!,
                      flag)
    }

    if result != 0 {
      throw Errno.current
    }
  }
}

#endif // !os(Windows)
