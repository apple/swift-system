//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if os(Windows)

import WinSDK

/// A Windows system error code.
///
/// This represents a value reported by `GetLastError`, or a code that
/// System synthesizes. See ``isSynthesized``.
///
/// The named constants cover every code that System's Win32 APIs document,
/// plus codes that callers commonly branch on. ``rawValue`` carries any
/// other code.
@frozen
@available(System 199, *)
public struct Win32Error: RawRepresentable, Error, Sendable, Hashable, Codable {
  /// The raw C error code.
  @_alwaysEmitIntoClient
  public let rawValue: DWORD

  /// Creates a strongly-typed error from a raw C error code.
  @_alwaysEmitIntoClient
  public init(rawValue: DWORD) { self.rawValue = rawValue }

  /// Creates a strongly-typed error from a raw C error code.
  @_alwaysEmitIntoClient
  public init(_ rawValue: DWORD) { self.rawValue = rawValue }

  /// No error.
  ///
  /// In rare cases, a Win32 function fails but `GetLastError` reports this
  /// code, so a `throws(Win32Error)` API can throw it.
  ///
  /// The corresponding C constant is `ERROR_SUCCESS`.
  @_alwaysEmitIntoClient
  public static var success: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_SUCCESS))
  }

  /// The requested function is invalid for its target, such as a size
  /// query on a console handle.
  ///
  /// The corresponding C constant is `ERROR_INVALID_FUNCTION`.
  @_alwaysEmitIntoClient
  public static var invalidFunction: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_INVALID_FUNCTION))
  }

  /// The file doesn't exist.
  ///
  /// A missing directory earlier in the path reports ``pathNotFound``
  /// instead.
  ///
  /// The corresponding C constant is `ERROR_FILE_NOT_FOUND`.
  @_alwaysEmitIntoClient
  public static var fileNotFound: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_FILE_NOT_FOUND))
  }

  /// Windows can't find the path, such as when a directory in the path
  /// doesn't exist.
  ///
  /// The corresponding C constant is `ERROR_PATH_NOT_FOUND`.
  @_alwaysEmitIntoClient
  public static var pathNotFound: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_PATH_NOT_FOUND))
  }

  /// The caller or handle doesn't have the access required for the operation.
  ///
  /// Windows also reports this for conditions unrelated to access rights,
  /// such as opening a file that's pending deletion.
  ///
  /// The corresponding C constant is `ERROR_ACCESS_DENIED`.
  @_alwaysEmitIntoClient
  public static var accessDenied: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_ACCESS_DENIED))
  }

  /// The handle is closed, isn't the kind required for the operation, or
  /// refers to an object that's no longer valid.
  ///
  /// The corresponding C constant is `ERROR_INVALID_HANDLE`.
  @_alwaysEmitIntoClient
  public static var invalidHandle: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_INVALID_HANDLE))
  }

  /// The device is not ready.
  ///
  /// The corresponding C constant is `ERROR_NOT_READY`.
  @_alwaysEmitIntoClient
  public static var deviceNotReady: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_NOT_READY))
  }

  /// The device detected a data error.
  ///
  /// The corresponding C constant is `ERROR_CRC`.
  @_alwaysEmitIntoClient
  public static var cyclicRedundancyCheck: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_CRC))
  }

  /// The device failed to complete a write.
  ///
  /// The corresponding C constant is `ERROR_WRITE_FAULT`.
  @_alwaysEmitIntoClient
  public static var writeFault: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_WRITE_FAULT))
  }

  /// The requested access or share mode conflicts with another handle to
  /// the file.
  ///
  /// This is retryable since the conflicting handle may close.
  ///
  /// The corresponding C constant is `ERROR_SHARING_VIOLATION`.
  @_alwaysEmitIntoClient
  public static var sharingViolation: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_SHARING_VIOLATION))
  }

  /// A byte-range lock conflicts with this read, write, or lock request.
  ///
  /// This is retryable since the conflicting lock may be released.
  ///
  /// The corresponding C constant is `ERROR_LOCK_VIOLATION`.
  @_alwaysEmitIntoClient
  public static var lockViolation: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_LOCK_VIOLATION))
  }

  /// The range to unlock doesn't match a lock held by this handle.
  ///
  /// The corresponding C constant is `ERROR_NOT_LOCKED`.
  @_alwaysEmitIntoClient
  public static var notLocked: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_NOT_LOCKED))
  }

  /// The seek would move the file pointer to a negative offset.
  ///
  /// The corresponding C constant is `ERROR_NEGATIVE_SEEK`.
  @_alwaysEmitIntoClient
  public static var negativeSeek: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_NEGATIVE_SEEK))
  }

  /// The operation reached the end of the file.
  ///
  /// A read from an explicit offset reports this when the offset is at or
  /// beyond the end of the file. A read from the file pointer at the same
  /// position returns zero bytes instead.
  ///
  /// The corresponding C constant is `ERROR_HANDLE_EOF`.
  @_alwaysEmitIntoClient
  public static var endOfFile: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_HANDLE_EOF))
  }

  /// The pipe's write end has closed, so there's nothing more to read.
  ///
  /// Despite its name, this is not the analog of ``Errno/brokenPipe``.
  /// A write to a pipe whose read end has closed reports ``noData``.
  ///
  /// The corresponding C constant is `ERROR_BROKEN_PIPE`.
  @_alwaysEmitIntoClient
  public static var brokenPipe: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_BROKEN_PIPE))
  }

  /// The operation isn't supported.
  ///
  /// Some targets report ``invalidFunction`` instead.
  ///
  /// The corresponding C constant is `ERROR_NOT_SUPPORTED`.
  @_alwaysEmitIntoClient
  public static var notSupported: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_NOT_SUPPORTED))
  }

  /// An exclusive create failed because the file already exists.
  ///
  /// `CreateFileW` reports this for `CREATE_NEW`. Directory creation reports
  /// ``alreadyExists`` instead.
  ///
  /// The corresponding C constant is `ERROR_FILE_EXISTS`.
  @_alwaysEmitIntoClient
  public static var fileExists: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_FILE_EXISTS))
  }

  /// An argument is invalid for the operation.
  ///
  /// System's wrappers also throw this for arguments they reject before
  /// calling Windows.
  ///
  /// The corresponding C constant is `ERROR_INVALID_PARAMETER`.
  @_alwaysEmitIntoClient
  public static var invalidParameter: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_INVALID_PARAMETER))
  }

  /// The buffer is too small for the result.
  ///
  /// A call that returns part of the result usually reports ``moreData``
  /// instead.
  ///
  /// The corresponding C constant is `ERROR_INSUFFICIENT_BUFFER`.
  @_alwaysEmitIntoClient
  public static var insufficientBuffer: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_INSUFFICIENT_BUFFER))
  }

  /// A name is invalid, such as a file name with a reserved character.
  ///
  /// The corresponding C constant is `ERROR_INVALID_NAME`.
  @_alwaysEmitIntoClient
  public static var invalidName: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_INVALID_NAME))
  }

  /// The path isn't in a form that Windows accepts.
  ///
  /// Windows also reports this when asked for the path of a handle that
  /// doesn't have one, such as an anonymous pipe.
  ///
  /// The corresponding C constant is `ERROR_BAD_PATHNAME`.
  @_alwaysEmitIntoClient
  public static var badPathName: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_BAD_PATHNAME))
  }

  /// The file already exists.
  ///
  /// Some functions also set this when they succeed on an existing file,
  /// such as `CreateFileW` with `CREATE_ALWAYS` or `OPEN_ALWAYS`.
  ///
  /// The corresponding C constant is `ERROR_ALREADY_EXISTS`.
  @_alwaysEmitIntoClient
  public static var alreadyExists: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_ALREADY_EXISTS))
  }

  /// The file would exceed a size limit.
  ///
  /// The corresponding C constant is `ERROR_FILE_TOO_LARGE`.
  @_alwaysEmitIntoClient
  public static var fileTooLarge: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_FILE_TOO_LARGE))
  }

  /// The volume doesn't have enough free space for the operation.
  ///
  /// The corresponding C constant is `ERROR_DISK_FULL`.
  @_alwaysEmitIntoClient
  public static var diskFull: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_DISK_FULL))
  }

  /// The named pipe has no free instance to connect to.
  ///
  /// This is retryable once the server frees or creates an instance.
  ///
  /// The corresponding C constant is `ERROR_PIPE_BUSY`.
  @_alwaysEmitIntoClient
  public static var pipeBusy: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_PIPE_BUSY))
  }

  /// No data is available, or the pipe's read end has closed.
  ///
  /// When writing, this is the analog of ``Errno/brokenPipe``. A nonblocking
  /// (`PIPE_NOWAIT`) read of an empty pipe reports this code, too.
  ///
  /// The corresponding C constant is `ERROR_NO_DATA`.
  @_alwaysEmitIntoClient
  public static var noData: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_NO_DATA))
  }

  /// The pipe isn't connected, such as after the server calls
  /// `DisconnectNamedPipe`.
  ///
  /// The corresponding C constant is `ERROR_PIPE_NOT_CONNECTED`.
  @_alwaysEmitIntoClient
  public static var pipeNotConnected: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_PIPE_NOT_CONNECTED))
  }

  /// More data is available than the buffer can hold.
  ///
  /// This is a retry instruction rather than a failure. Some variable-length
  /// queries report it when their buffer is too small, and a read from a
  /// message-mode pipe reports it after filling the buffer with the start
  /// of a longer message.
  ///
  /// The corresponding C constant is `ERROR_MORE_DATA`.
  @_alwaysEmitIntoClient
  public static var moreData: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_MORE_DATA))
  }

  /// The operation requires a directory, but the path doesn't name one.
  ///
  /// The corresponding C constant is `ERROR_DIRECTORY`.
  @_alwaysEmitIntoClient
  public static var notDirectory: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_DIRECTORY))
  }

  /// The I/O was canceled, such as by `CancelIoEx` or by its thread exiting.
  ///
  /// A console read interrupted by Ctrl+C reports this code, too.
  ///
  /// The corresponding C constant is `ERROR_OPERATION_ABORTED`.
  @_alwaysEmitIntoClient
  public static var operationAborted: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_OPERATION_ABORTED))
  }

  /// An overlapped operation started and hasn't finished yet.
  ///
  /// This is expected for overlapped I/O.
  ///
  /// The corresponding C constant is `ERROR_IO_PENDING`.
  @_alwaysEmitIntoClient
  public static var ioPending: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_IO_PENDING))
  }

  /// A memory mapping of the file blocks the operation.
  ///
  /// For example, truncating a file with an active memory mapping reports
  /// this code.
  ///
  /// The corresponding C constant is `ERROR_USER_MAPPED_FILE`.
  @_alwaysEmitIntoClient
  public static var userMappedFile: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_USER_MAPPED_FILE))
  }

  /// Windows can't resolve the path.
  ///
  /// The corresponding C constant is `ERROR_CANT_RESOLVE_FILENAME`.
  @_alwaysEmitIntoClient
  public static var cannotResolveFileName: Win32Error {
    Win32Error(DWORD(WinSDK.ERROR_CANT_RESOLVE_FILENAME))
  }

  /// A transfer stopped because a Win32 function succeeded without moving
  /// any data, such as a `WriteFile` that writes zero bytes.
  ///
  /// System synthesizes this code, `0xA0535901`, which has no corresponding
  /// C constant. See ``isSynthesized``.
  @_alwaysEmitIntoClient
  public static var incompleteTransfer: Win32Error { Win32Error(0xA053_5901) }

  /// Whether this is a code that System synthesizes instead of one that
  /// Windows reports.
  ///
  /// System only synthesizes a code when no Windows code fits. Synthesized
  /// codes are in the range `0xA0535900...0xA05359FF` and set the bit Windows
  /// reserves for application-defined codes.
  @_alwaysEmitIntoClient
  public var isSynthesized: Bool { rawValue & 0xFFFF_FF00 == 0xA053_5900 }
}

@available(System 199, *)
extension Win32Error: CustomStringConvertible, CustomDebugStringConvertible {
  /// A localized description of the error.
  ///
  /// The message varies by language, so it's suitable for display or logging
  /// but not for textual matching. For a locale-independent rendering, use
  /// ``debugDescription``. If Windows provides no message for the code, this
  /// property returns ``debugDescription``. For a synthesized code, this
  /// property returns a fixed English message instead.
  ///
  /// The corresponding C function is `FormatMessageW`.
  @inline(never)
  public var description: String {
    if let message = _synthesizedMessage { return message }

    // With FORMAT_MESSAGE_ALLOCATE_BUFFER, `lpBuffer` is really an `LPWSTR *`
    // that receives a buffer allocated with LocalAlloc.
    var buffer: LPWSTR? = nil
    let length = withUnsafeMutablePointer(to: &buffer) {
      $0.withMemoryRebound(to: WCHAR.self, capacity: 1) { lpBuffer in
        FormatMessageW(
          DWORD(FORMAT_MESSAGE_FROM_SYSTEM
                  | FORMAT_MESSAGE_ALLOCATE_BUFFER
                  | FORMAT_MESSAGE_IGNORE_INSERTS),
          nil, rawValue, 0, lpBuffer, 0, nil)
      }
    }
    guard length > 0, let buffer else { return debugDescription }
    defer { LocalFree(buffer) }

    var message = String(
      decoding: UnsafeBufferPointer(start: buffer, count: Int(length)),
      as: UTF16.self)
    while message.last?.isNewline == true { message.removeLast() }
    return message.isEmpty ? debugDescription : message
  }

  /// A locale-independent description of the error, suitable for tests and
  /// structured logs.
  ///
  /// A code with a named constant shows its symbolic name and value, such
  /// as `ERROR_SHARING_VIOLATION (32, 0x20)`. Any other code shows only its
  /// value, such as `(12345, 0x3039)`.
  public var debugDescription: String {
    let hex = "0x" + String(rawValue, radix: 16, uppercase: true)
    guard let _name else { return "(\(rawValue), \(hex))" }
    return "\(_name) (\(rawValue), \(hex))"
  }
}

@available(System 199, *)
extension Win32Error {
  /// The symbolic name of a code that has a named constant.
  internal var _name: String? {
    switch rawValue {
    case Win32Error.success.rawValue: "ERROR_SUCCESS"
    case Win32Error.invalidFunction.rawValue: "ERROR_INVALID_FUNCTION"
    case Win32Error.fileNotFound.rawValue: "ERROR_FILE_NOT_FOUND"
    case Win32Error.pathNotFound.rawValue: "ERROR_PATH_NOT_FOUND"
    case Win32Error.accessDenied.rawValue: "ERROR_ACCESS_DENIED"
    case Win32Error.invalidHandle.rawValue: "ERROR_INVALID_HANDLE"
    case Win32Error.deviceNotReady.rawValue: "ERROR_NOT_READY"
    case Win32Error.cyclicRedundancyCheck.rawValue: "ERROR_CRC"
    case Win32Error.writeFault.rawValue: "ERROR_WRITE_FAULT"
    case Win32Error.sharingViolation.rawValue: "ERROR_SHARING_VIOLATION"
    case Win32Error.lockViolation.rawValue: "ERROR_LOCK_VIOLATION"
    case Win32Error.notLocked.rawValue: "ERROR_NOT_LOCKED"
    case Win32Error.negativeSeek.rawValue: "ERROR_NEGATIVE_SEEK"
    case Win32Error.endOfFile.rawValue: "ERROR_HANDLE_EOF"
    case Win32Error.brokenPipe.rawValue: "ERROR_BROKEN_PIPE"
    case Win32Error.notSupported.rawValue: "ERROR_NOT_SUPPORTED"
    case Win32Error.fileExists.rawValue: "ERROR_FILE_EXISTS"
    case Win32Error.invalidParameter.rawValue: "ERROR_INVALID_PARAMETER"
    case Win32Error.insufficientBuffer.rawValue: "ERROR_INSUFFICIENT_BUFFER"
    case Win32Error.invalidName.rawValue: "ERROR_INVALID_NAME"
    case Win32Error.badPathName.rawValue: "ERROR_BAD_PATHNAME"
    case Win32Error.alreadyExists.rawValue: "ERROR_ALREADY_EXISTS"
    case Win32Error.fileTooLarge.rawValue: "ERROR_FILE_TOO_LARGE"
    case Win32Error.diskFull.rawValue: "ERROR_DISK_FULL"
    case Win32Error.pipeBusy.rawValue: "ERROR_PIPE_BUSY"
    case Win32Error.noData.rawValue: "ERROR_NO_DATA"
    case Win32Error.pipeNotConnected.rawValue: "ERROR_PIPE_NOT_CONNECTED"
    case Win32Error.moreData.rawValue: "ERROR_MORE_DATA"
    case Win32Error.notDirectory.rawValue: "ERROR_DIRECTORY"
    case Win32Error.operationAborted.rawValue: "ERROR_OPERATION_ABORTED"
    case Win32Error.ioPending.rawValue: "ERROR_IO_PENDING"
    case Win32Error.userMappedFile.rawValue: "ERROR_USER_MAPPED_FILE"
    case Win32Error.cannotResolveFileName.rawValue: "ERROR_CANT_RESOLVE_FILENAME"
    // A synthesized code has no C constant, so it's named for its Swift
    // spelling.
    case Win32Error.incompleteTransfer.rawValue:
      "Win32Error.incompleteTransfer"
    default: nil
    }
  }

  /// The message for a synthesized code, which has no system message.
  internal var _synthesizedMessage: String? {
    switch rawValue {
    case Win32Error.incompleteTransfer.rawValue:
      "The operation completed without transferring all of the data."
    default: nil
    }
  }
}

@available(System 199, *)
extension Win32Error {
  @_alwaysEmitIntoClient
  public static func ~= (_ lhs: Win32Error, _ rhs: Error) -> Bool {
    guard let value = rhs as? Win32Error else { return false }
    return lhs == value
  }
}

#endif
