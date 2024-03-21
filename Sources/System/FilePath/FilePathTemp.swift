/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - API

public func withTemporaryPath<R>(
  basename: FilePath.Component,
  _ body: (FilePath) throws -> R
) throws -> R {
  let temporaryDir = try createUniqueTemporaryDirectory(basename: basename)
  defer {
    try? recursiveRemove(at: temporaryDir)
  }

  return try body(temporaryDir)
}

// MARK: - Internals

#if os(Windows)
import WinSDK

fileprivate func getTemporaryDirectory() throws -> FilePath {
  return try withUnsafeTemporaryAllocation(of: CInterop.PlatformChar.self,
                                           capacity: Int(MAX_PATH) + 1) {
    buffer in

    guard GetTempPath2W(DWORD(buffer.count), buffer.baseAddress) != 0 else {
      throw Errno(windowsError: GetLastError())
    }

    return FilePath(SystemString(platformString: buffer.baseAddress!))
  }
}

fileprivate func forEachFile(
  at path: FilePath,
  _ body: (WIN32_FIND_DATAW) throws -> ()
) rethrows {
  let searchPath = path.appending("\\*")

  try searchPath.withPlatformString { szPath in
    var findData = WIN32_FIND_DATAW()
    let hFind = FindFirstFileW(szPath, &findData)
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
  }
}

fileprivate func recursiveRemove(at path: FilePath) throws {
  // First, deal with subdirectories
  try forEachFile(at: path) { findData in
    if (findData.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY)) != 0 {
      let name = withUnsafeBytes(of: findData.cFileName) {
        return SystemString(platformString: $0.assumingMemoryBound(
                              to: CInterop.PlatformChar.self).baseAddress!)
      }
      let component = FilePath.Component(name)!
      let subpath = path.appending(component)

      try recursiveRemove(at: subpath)
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

    if (findData.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY)) == 0 {
      try subpath.withPlatformString {
        if !DeleteFileW($0) {
          throw Errno(windowsError: GetLastError())
        }
      }
    }
  }

  // Finally, delete the parent
  try path.withPlatformString {
    if !RemoveDirectoryW($0) {
      throw Errno(windowsError: GetLastError())
    }
  }
}

#else
fileprivate func getTemporaryDirectory() throws -> FilePath {
  #if SYSTEM_PACKAGE_DARWIN
  var capacity = 1024
  while true {
    let path: FilePath? = withUnsafeTemporaryAllocation(
      of: CInterop.PlatformChar.self,
      capacity: capacity
    ) { buffer in
      let len = system_confstr(SYSTEM_CS_DARWIN_USER_TEMP_DIR,
                               buffer.baseAddress!,
                               buffer.count)
      if len == 0 {
        // Fall back to "/tmp" if we can't read the temp directory
        return "/tmp"
      }
      // If it was truncated, increase capaciy and try again
      if len > buffer.count {
        capacity = len
        return nil
      }
      return FilePath(SystemString(platformString: buffer.baseAddress!))
    }
    if let path = path {
      return path
    }
  }
  #else
  return "/tmp"
  #endif
}

fileprivate func recursiveRemove(at path: FilePath) throws {
  let dirfd = try FileDescriptor.open(path, .readOnly, options: .directory)
  defer {
    try? dirfd.close()
  }

  let dot: (CInterop.PlatformChar, CInterop.PlatformChar) = (46, 0)
  try withUnsafeBytes(of: dot) {
    try recursiveRemove(
      in: dirfd.rawValue,
      path: $0.assumingMemoryBound(to: CInterop.PlatformChar.self).baseAddress!
    )
  }

  try path.withPlatformString {
    if system_rmdir($0) != 0 {
      throw Errno.current
    }
  }
}

fileprivate func impl_opendirat(
  _ dirfd: CInt,
  _ path: UnsafePointer<CInterop.PlatformChar>
) -> UnsafeMutablePointer<system_DIR>? {
  let fd = system_openat(dirfd, path,
                         FileDescriptor.AccessMode.readOnly.rawValue
                           | FileDescriptor.OpenOptions.directory.rawValue)
  if fd < 0 {
    return nil
  }
  return system_fdopendir(fd)
}

fileprivate func forEachFile(
  in dirfd: CInt, path: UnsafePointer<CInterop.PlatformChar>,
  _ body: (system_dirent) throws -> ()
) throws {
  guard let dir = impl_opendirat(dirfd, path) else {
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

internal func recursiveRemove(
  in dirfd: CInt,
  path: UnsafePointer<CInterop.PlatformChar>
) throws {
  // First, deal with subdirectories
  try forEachFile(in: dirfd, path: path) { dirent in
    if dirent.d_type == SYSTEM_DT_DIR {
      try withUnsafeBytes(of: dirent.d_name) {
        try recursiveRemove(
          in: dirfd,
          path: $0.assumingMemoryBound(to: CInterop.PlatformChar.self)
            .baseAddress!
        )
      }
    }
  }

  // Now delete the contents of this directory
  try forEachFile(in: dirfd, path: path) { dirent in
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
#endif

fileprivate let base64 = Array<UInt8>(
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".utf8
)

fileprivate func makeTempDirectory(at: FilePath) throws -> Bool {
  return try at.withPlatformString {
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

fileprivate func createRandomString(length: Int) -> String {
  return String(
    decoding: (0..<length).map{
      _ in base64[Int.random(in: 0..<64)]
    },
    as: UTF8.self
  )
}

internal func createUniqueTemporaryDirectory(
  basename: FilePath.Component
) throws -> FilePath {
  var tempDir = try getTemporaryDirectory()
  tempDir.append(basename)

  while true {
    tempDir.extension = createRandomString(length: 16)

    if try makeTempDirectory(at: tempDir) {
      return tempDir
    }
  }
}
