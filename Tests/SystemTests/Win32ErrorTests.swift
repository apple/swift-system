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

import Testing
import WinSDK

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

@Suite("Win32Error")
private struct Win32ErrorTests {

  @available(System 199, *)
  static var namedCodes: [(Win32Error, DWORD, String)] {
    [
      (.success, 0, "ERROR_SUCCESS"),
      (.invalidFunction, 1, "ERROR_INVALID_FUNCTION"),
      (.fileNotFound, 2, "ERROR_FILE_NOT_FOUND"),
      (.pathNotFound, 3, "ERROR_PATH_NOT_FOUND"),
      (.accessDenied, 5, "ERROR_ACCESS_DENIED"),
      (.invalidHandle, 6, "ERROR_INVALID_HANDLE"),
      (.deviceNotReady, 21, "ERROR_NOT_READY"),
      (.cyclicRedundancyCheck, 23, "ERROR_CRC"),
      (.writeFault, 29, "ERROR_WRITE_FAULT"),
      (.sharingViolation, 32, "ERROR_SHARING_VIOLATION"),
      (.lockViolation, 33, "ERROR_LOCK_VIOLATION"),
      (.endOfFile, 38, "ERROR_HANDLE_EOF"),
      (.notSupported, 50, "ERROR_NOT_SUPPORTED"),
      (.fileExists, 80, "ERROR_FILE_EXISTS"),
      (.invalidParameter, 87, "ERROR_INVALID_PARAMETER"),
      (.brokenPipe, 109, "ERROR_BROKEN_PIPE"),
      (.diskFull, 112, "ERROR_DISK_FULL"),
      (.insufficientBuffer, 122, "ERROR_INSUFFICIENT_BUFFER"),
      (.invalidName, 123, "ERROR_INVALID_NAME"),
      (.negativeSeek, 131, "ERROR_NEGATIVE_SEEK"),
      (.notLocked, 158, "ERROR_NOT_LOCKED"),
      (.badPathName, 161, "ERROR_BAD_PATHNAME"),
      (.alreadyExists, 183, "ERROR_ALREADY_EXISTS"),
      (.fileTooLarge, 223, "ERROR_FILE_TOO_LARGE"),
      (.pipeBusy, 231, "ERROR_PIPE_BUSY"),
      (.noData, 232, "ERROR_NO_DATA"),
      (.pipeNotConnected, 233, "ERROR_PIPE_NOT_CONNECTED"),
      (.moreData, 234, "ERROR_MORE_DATA"),
      (.notDirectory, 267, "ERROR_DIRECTORY"),
      (.operationAborted, 995, "ERROR_OPERATION_ABORTED"),
      (.ioPending, 997, "ERROR_IO_PENDING"),
      (.userMappedFile, 1224, "ERROR_USER_MAPPED_FILE"),
      (.cannotResolveFileName, 1921, "ERROR_CANT_RESOLVE_FILENAME"),
    ]
  }

  @available(System 199, *)
  @Test func debugDescription() {
    for (error, value, name) in Self.namedCodes {
      let hex = String(value, radix: 16, uppercase: true)
      #expect(error.debugDescription == "\(name) (\(value), 0x\(hex))")
    }
    #expect(Win32Error(12345).debugDescription == "(12345, 0x3039)")
    #expect(Win32Error.incompleteTransfer.debugDescription == "Win32Error.incompleteTransfer (2689816833, 0xA0535901)")
  }

  @available(System 199, *)
  @Test func description() {
    // The system message is localized, so check only its shape.
    for (error, _, name) in Self.namedCodes {
      let message = error.description
      #expect(message != error.debugDescription, "\(name) has no message")
      #expect(message.last?.isNewline == false, "\(name)")
    }

    // Bit 29 marks an application-defined code, which has no system message.
    let unknown = Win32Error(0x2000_1234)
    #expect(unknown.description == unknown.debugDescription)

    #expect(Win32Error.incompleteTransfer.description == "The operation completed without transferring all of the data.")
  }

  @available(System 199, *)
  @Test func isSynthesized() {
    #expect(Win32Error.incompleteTransfer.isSynthesized)
    #expect(Win32Error(0xA053_5900).isSynthesized)
    #expect(Win32Error(0xA053_59FF).isSynthesized)
    #expect(!Win32Error(0xA053_5A00).isSynthesized)
    #expect(!Win32Error(0x2053_5901).isSynthesized)
  }

  @available(System 199, *)
  @Test func patternMatching() {
    do {
      throw Win32Error.sharingViolation
    } catch Win32Error.accessDenied {
      Issue.record("Matched the wrong code")
    } catch Win32Error.sharingViolation {
      // Expected.
    } catch {
      Issue.record("Didn't match: \(error)")
    }

    #expect(!(Win32Error.accessDenied ~= Errno.permissionDenied))
  }

  @available(System 199, *)
  @Test func errnoApproximation() {
    #expect(Errno(approximating: .fileNotFound) == .noSuchFileOrDirectory)
    #expect(Errno(approximating: .accessDenied) == .permissionDenied)
    // Codes 19 through 36 all become EACCES.
    #expect(Errno(approximating: .sharingViolation) == .permissionDenied)
    #expect(Errno(approximating: .lockViolation) == .permissionDenied)
    #expect(Errno(approximating: .brokenPipe) == .brokenPipe)
    #expect(Errno(approximating: .alreadyExists) == .fileExists)
    #expect(Errno(approximating: .diskFull) == .noSpace)
    // Unrecognized codes become EINVAL.
    #expect(Errno(approximating: .notSupported) == .invalidArgument)
    #expect(Errno(approximating: .noData) == .invalidArgument)
    #expect(Errno(approximating: Win32Error(12345)) == .invalidArgument)
  }
}

#endif
