/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

#if os(Windows)
import WinSDK
#endif

#if SYSTEM_PACKAGE && canImport(CSystem)
import CSystem // for csystem_strerror_r
#endif

#if canImport(Dispatch)
import Dispatch
#endif

@available(System 0.0.1, *)
final class ErrnoTest: XCTestCase {
  func testConstants() {
    XCTAssert(EPERM == Errno.notPermitted.rawValue)
    XCTAssert(ENOENT == Errno.noSuchFileOrDirectory.rawValue)
    XCTAssert(ESRCH == Errno.noSuchProcess.rawValue)
    XCTAssert(EINTR == Errno.interrupted.rawValue)
    XCTAssert(EIO == Errno.ioError.rawValue)
    XCTAssert(ENXIO == Errno.noSuchAddressOrDevice.rawValue)
    XCTAssert(E2BIG == Errno.argListTooLong.rawValue)
    XCTAssert(ENOEXEC == Errno.execFormatError.rawValue)
    XCTAssert(EBADF == Errno.badFileDescriptor.rawValue)
    XCTAssert(ECHILD == Errno.noChildProcess.rawValue)
    XCTAssert(EDEADLK == Errno.deadlock.rawValue)
    XCTAssert(ENOMEM == Errno.noMemory.rawValue)
    XCTAssert(EACCES == Errno.permissionDenied.rawValue)
    XCTAssert(EFAULT == Errno.badAddress.rawValue)
#if !os(Windows) && !os(WASI)
    XCTAssert(ENOTBLK == Errno.notBlockDevice.rawValue)
#endif
    XCTAssert(EBUSY == Errno.resourceBusy.rawValue)
    XCTAssert(EEXIST == Errno.fileExists.rawValue)
    XCTAssert(EXDEV == Errno.improperLink.rawValue)
    XCTAssert(ENODEV == Errno.operationNotSupportedByDevice.rawValue)
    XCTAssert(ENOTDIR == Errno.notDirectory.rawValue)
    XCTAssert(EISDIR == Errno.isDirectory.rawValue)
    XCTAssert(EINVAL == Errno.invalidArgument.rawValue)
    XCTAssert(ENFILE == Errno.tooManyOpenFilesInSystem.rawValue)
    XCTAssert(EMFILE == Errno.tooManyOpenFiles.rawValue)
#if !os(Windows)
    XCTAssert(ENOTTY == Errno.inappropriateIOCTLForDevice.rawValue)
    XCTAssert(ETXTBSY == Errno.textFileBusy.rawValue)
#endif
    XCTAssert(EFBIG == Errno.fileTooLarge.rawValue)
    XCTAssert(ENOSPC == Errno.noSpace.rawValue)
    XCTAssert(ESPIPE == Errno.illegalSeek.rawValue)
    XCTAssert(EROFS == Errno.readOnlyFileSystem.rawValue)
    XCTAssert(EMLINK == Errno.tooManyLinks.rawValue)
    XCTAssert(EPIPE == Errno.brokenPipe.rawValue)
    XCTAssert(EDOM == Errno.outOfDomain.rawValue)
    XCTAssert(ERANGE == Errno.outOfRange.rawValue)
    XCTAssert(EAGAIN == Errno.resourceTemporarilyUnavailable.rawValue)
    XCTAssert(EINPROGRESS == Errno.nowInProgress.rawValue)
    XCTAssert(EALREADY == Errno.alreadyInProcess.rawValue)
    XCTAssert(ENOTSOCK == Errno.notSocket.rawValue)
    XCTAssert(EDESTADDRREQ == Errno.addressRequired.rawValue)
    XCTAssert(EMSGSIZE == Errno.messageTooLong.rawValue)
    XCTAssert(EPROTOTYPE == Errno.protocolWrongTypeForSocket.rawValue)
    XCTAssert(ENOPROTOOPT == Errno.protocolNotAvailable.rawValue)
    XCTAssert(EPROTONOSUPPORT == Errno.protocolNotSupported.rawValue)
#if os(Windows)
    XCTAssert(WSAESOCKTNOSUPPORT == Errno.socketTypeNotSupported.rawValue)
    XCTAssert(WSAEOPNOTSUPP == Errno.notSupported.rawValue)
    XCTAssert(WSAEPFNOSUPPORT == Errno.protocolFamilyNotSupported.rawValue)
#else
    XCTAssert(ENOTSUP == Errno.notSupported.rawValue)
#if !os(WASI)
    XCTAssert(ESOCKTNOSUPPORT == Errno.socketTypeNotSupported.rawValue)
    XCTAssert(EPFNOSUPPORT == Errno.protocolFamilyNotSupported.rawValue)
#endif
#endif
    XCTAssert(EAFNOSUPPORT == Errno.addressFamilyNotSupported.rawValue)
    XCTAssert(EADDRINUSE == Errno.addressInUse.rawValue)
    XCTAssert(EADDRNOTAVAIL == Errno.addressNotAvailable.rawValue)
    XCTAssert(ENETDOWN == Errno.networkDown.rawValue)
    XCTAssert(ENETUNREACH == Errno.networkUnreachable.rawValue)
    XCTAssert(ENETRESET == Errno.networkReset.rawValue)
    XCTAssert(ECONNABORTED == Errno.connectionAbort.rawValue)
    XCTAssert(ECONNRESET == Errno.connectionReset.rawValue)
    XCTAssert(ENOBUFS == Errno.noBufferSpace.rawValue)
    XCTAssert(EISCONN == Errno.socketIsConnected.rawValue)
    XCTAssert(ENOTCONN == Errno.socketNotConnected.rawValue)
#if os(Windows)
    XCTAssert(WSAESHUTDOWN == Errno.socketShutdown.rawValue)
#elseif !os(WASI)
    XCTAssert(ESHUTDOWN == Errno.socketShutdown.rawValue)
#endif
    XCTAssert(ETIMEDOUT == Errno.timedOut.rawValue)
    XCTAssert(ECONNREFUSED == Errno.connectionRefused.rawValue)
    XCTAssert(ELOOP == Errno.tooManySymbolicLinkLevels.rawValue)
    XCTAssert(ENAMETOOLONG == Errno.fileNameTooLong.rawValue)
#if os(Windows)
    XCTAssert(WSAEHOSTDOWN == Errno.hostIsDown.rawValue)
#elseif !os(WASI)
    XCTAssert(EHOSTDOWN == Errno.hostIsDown.rawValue)
#endif
    XCTAssert(EHOSTUNREACH == Errno.noRouteToHost.rawValue)
    XCTAssert(ENOTEMPTY == Errno.directoryNotEmpty.rawValue)

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(EPROCLIM == Errno.tooManyProcesses.rawValue)
#endif

#if os(Windows)
    XCTAssert(WSAEUSERS == Errno.tooManyUsers.rawValue)
    XCTAssert(WSAEDQUOT == Errno.diskQuotaExceeded.rawValue)
    XCTAssert(WSAESTALE == Errno.staleNFSFileHandle.rawValue)
#else
#if !os(WASI)
    XCTAssert(EUSERS == Errno.tooManyUsers.rawValue)
#endif
    XCTAssert(EDQUOT == Errno.diskQuotaExceeded.rawValue)
    XCTAssert(ESTALE == Errno.staleNFSFileHandle.rawValue)
#endif

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(EBADRPC == Errno.rpcUnsuccessful.rawValue)
    XCTAssert(ERPCMISMATCH == Errno.rpcVersionMismatch.rawValue)
    XCTAssert(EPROGUNAVAIL == Errno.rpcProgramUnavailable.rawValue)
    XCTAssert(EPROGMISMATCH == Errno.rpcProgramVersionMismatch.rawValue)
    XCTAssert(EPROCUNAVAIL == Errno.rpcProcedureUnavailable.rawValue)
#endif

    XCTAssert(ENOLCK == Errno.noLocks.rawValue)
    XCTAssert(ENOSYS == Errno.noFunction.rawValue)

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
    XCTAssert(EFTYPE == Errno.badFileTypeOrFormat.rawValue)
    XCTAssert(EAUTH == Errno.authenticationError.rawValue)
    XCTAssert(ENEEDAUTH == Errno.needAuthenticator.rawValue)
#endif

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(EPWROFF == Errno.devicePowerIsOff.rawValue)
    XCTAssert(EDEVERR == Errno.deviceError.rawValue)
#endif

#if !os(Windows)
    XCTAssert(EOVERFLOW == Errno.overflow.rawValue)
#endif

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(EBADEXEC == Errno.badExecutable.rawValue)
    XCTAssert(EBADARCH == Errno.badCPUType.rawValue)
    XCTAssert(ESHLIBVERS == Errno.sharedLibraryVersionMismatch.rawValue)
    XCTAssert(EBADMACHO == Errno.malformedMachO.rawValue)
#endif

    XCTAssert(ECANCELED == Errno.canceled.rawValue)
#if !os(Windows)
    XCTAssert(EIDRM == Errno.identifierRemoved.rawValue)
    XCTAssert(ENOMSG == Errno.noMessage.rawValue)
#endif
    XCTAssert(EILSEQ == Errno.illegalByteSequence.rawValue)

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(ENOATTR == Errno.attributeNotFound.rawValue)
#endif

#if !os(Windows)
    XCTAssert(EBADMSG == Errno.badMessage.rawValue)
    XCTAssert(EMULTIHOP == Errno.multiHop.rawValue)
    XCTAssert(ENOLINK == Errno.noLink.rawValue)
    XCTAssert(EPROTO == Errno.protocolError.rawValue)
#endif

#if !os(Windows) && !os(FreeBSD) && !os(WASI)
    XCTAssert(ENODATA == Errno.noData.rawValue)
    XCTAssert(ENOSR == Errno.noStreamResources.rawValue)
    XCTAssert(ENOSTR == Errno.notStream.rawValue)
    XCTAssert(ETIME == Errno.timeout.rawValue)
#endif

    XCTAssert(EOPNOTSUPP == Errno.notSupportedOnSocket.rawValue)

    // From headers but not man page
#if !os(WASI) // Would need to use _getConst func from CSystem
    XCTAssert(EWOULDBLOCK == Errno.wouldBlock.rawValue)
#endif
#if os(Windows)
    XCTAssert(WSAETOOMANYREFS == Errno.tooManyReferences.rawValue)
    XCTAssert(WSAEREMOTE == Errno.tooManyRemoteLevels.rawValue)
#elseif !os(WASI)
    XCTAssert(ETOOMANYREFS == Errno.tooManyReferences.rawValue)
    XCTAssert(EREMOTE == Errno.tooManyRemoteLevels.rawValue)
#endif

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(ENOPOLICY == Errno.noSuchPolicy.rawValue)
#endif

#if !os(Windows)
    XCTAssert(ENOTRECOVERABLE == Errno.notRecoverable.rawValue)
    XCTAssert(EOWNERDEAD == Errno.previousOwnerDied.rawValue)
#endif

#if os(FreeBSD)
    XCTAssert(ENOTCAPABLE == Errno.notCapable.rawValue)
    XCTAssert(ECAPMODE == Errno.capabilityMode.rawValue)
    XCTAssert(EINTEGRITY == Errno.integrityCheckFailed.rawValue)
#endif

#if SYSTEM_PACKAGE_DARWIN
    XCTAssert(EQFULL == Errno.outputQueueFull.rawValue)
    XCTAssert(ELAST == Errno.lastErrnoValue.rawValue)
#endif
  }

  func testPatternMatching() {
    func throwsEPERM() throws {
      throw Errno.notPermitted
    }

    do {
      try throwsEPERM()
    } catch Errno.noSuchProcess {
      XCTAssert(false)
    } catch Errno.notPermitted {
      // pass
    } catch {
      XCTAssert(false)
    }
  }

  // TODO: `_code/_domain` for NSError bridging

  func testDescription() {
    XCTAssertEqual(Errno.noSuchFileOrDirectory.description, "No such file or directory")
    XCTAssertEqual(Errno.notPermitted.debugDescription, Errno.notPermitted.description)

    // Unknown error numbers still get a message.
    let unknown = Errno(rawValue: 98765).description
    XCTAssertFalse(unknown.isEmpty)
    #if !os(Windows) && !os(WASI) && !canImport(Musl)
    // Windows' message is just "Unknown error", and musl's (also used by
    // WASI) is "No error information", without the number.
    XCTAssert(unknown.contains("98765"), unknown)
    #endif
  }

  #if canImport(Dispatch)
  func testDescriptionIsThreadSafe() {
    // For unknown error numbers, strerror(3) may format the message into a
    // buffer shared by all threads, so concurrent calls could see each
    // other's messages.
    let errnos = (0..<64).map { Errno(rawValue: 90000 + CInt($0)) }
    let expected = errnos.map(\.description)
    let iterations = 200
    nonisolated(unsafe) let mismatches =
      UnsafeMutableBufferPointer<Int>.allocate(capacity: errnos.count)
    mismatches.initialize(repeating: 0)
    defer { mismatches.deallocate() }

    DispatchQueue.concurrentPerform(iterations: errnos.count) { index in
      for _ in 0..<iterations where errnos[index].description != expected[index] {
        mismatches[index] += 1
      }
    }
    XCTAssertEqual(mismatches.reduce(0, +), 0)
  }
  #endif

  #if SYSTEM_PACKAGE && canImport(CSystem)
  func testStrerrorShim() {
    var buffer = [CChar](repeating: 1, count: 256)
    XCTAssertEqual(csystem_strerror_r(ENOENT, &buffer, buffer.count), 0)
    XCTAssertEqual(
      buffer.withUnsafeBufferPointer { String(cString: $0.baseAddress!) },
      "No such file or directory")

    // A buffer that is too small yields a truncated, NUL-terminated message.
    var small = [CChar](repeating: 1, count: 4)
    XCTAssertEqual(csystem_strerror_r(ENOENT, &small, small.count), ERANGE)
    #if !os(Windows)
    XCTAssertEqual(
      small.withUnsafeBufferPointer { String(cString: $0.baseAddress!) },
      "No ")
    #endif
    XCTAssertEqual(small[3], 0)

    // A zero-length buffer is rejected without writing to it.
    var empty = CChar(1)
    XCTAssertEqual(csystem_strerror_r(ENOENT, &empty, 0), ERANGE)
    XCTAssertEqual(empty, 1)
  }
  #endif
}
