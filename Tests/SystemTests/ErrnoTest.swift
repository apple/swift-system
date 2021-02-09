/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
import SystemPackage
#else
import System
#endif

// @available(macOS 10.16, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
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
    XCTAssert(ENOTBLK == Errno.notBlockDevice.rawValue)
    XCTAssert(EBUSY == Errno.resourceBusy.rawValue)
    XCTAssert(EEXIST == Errno.fileExists.rawValue)
    XCTAssert(EXDEV == Errno.improperLink.rawValue)
    XCTAssert(ENODEV == Errno.operationNotSupportedByDevice.rawValue)
    XCTAssert(ENOTDIR == Errno.notDirectory.rawValue)
    XCTAssert(EISDIR == Errno.isDirectory.rawValue)
    XCTAssert(EINVAL == Errno.invalidArgument.rawValue)
    XCTAssert(ENFILE == Errno.tooManyOpenFilesInSystem.rawValue)
    XCTAssert(EMFILE == Errno.tooManyOpenFiles.rawValue)
    XCTAssert(ENOTTY == Errno.inappropriateIOCTLForDevice.rawValue)
    XCTAssert(ETXTBSY == Errno.textFileBusy.rawValue)
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
    XCTAssert(ESOCKTNOSUPPORT == Errno.socketTypeNotSupported.rawValue)
    XCTAssert(ENOTSUP == Errno.notSupported.rawValue)
    XCTAssert(EPFNOSUPPORT == Errno.protocolFamilyNotSupported.rawValue)
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
    XCTAssert(ESHUTDOWN == Errno.socketShutdown.rawValue)
    XCTAssert(ETIMEDOUT == Errno.timedOut.rawValue)
    XCTAssert(ECONNREFUSED == Errno.connectionRefused.rawValue)
    XCTAssert(ELOOP == Errno.tooManySymbolicLinkLevels.rawValue)
    XCTAssert(ENAMETOOLONG == Errno.fileNameTooLong.rawValue)
    XCTAssert(EHOSTDOWN == Errno.hostIsDown.rawValue)
    XCTAssert(EHOSTUNREACH == Errno.noRouteToHost.rawValue)
    XCTAssert(ENOTEMPTY == Errno.directoryNotEmpty.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    XCTAssert(EPROCLIM == Errno.tooManyProcesses.rawValue)
#endif

    XCTAssert(EUSERS == Errno.tooManyUsers.rawValue)
    XCTAssert(EDQUOT == Errno.diskQuotaExceeded.rawValue)
    XCTAssert(ESTALE == Errno.staleNFSFileHandle.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    XCTAssert(EBADRPC == Errno.rpcUnsuccessful.rawValue)
    XCTAssert(ERPCMISMATCH == Errno.rpcVersionMismatch.rawValue)
    XCTAssert(EPROGUNAVAIL == Errno.rpcProgramUnavailable.rawValue)
    XCTAssert(EPROGMISMATCH == Errno.rpcProgramVersionMismatch.rawValue)
    XCTAssert(EPROCUNAVAIL == Errno.rpcProcedureUnavailable.rawValue)
#endif

    XCTAssert(ENOLCK == Errno.noLocks.rawValue)
    XCTAssert(ENOSYS == Errno.noFunction.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    XCTAssert(EFTYPE == Errno.badFileTypeOrFormat.rawValue)
    XCTAssert(EAUTH == Errno.authenticationError.rawValue)
    XCTAssert(ENEEDAUTH == Errno.needAuthenticator.rawValue)
    XCTAssert(EPWROFF == Errno.devicePowerIsOff.rawValue)
    XCTAssert(EDEVERR == Errno.deviceError.rawValue)
#endif

    XCTAssert(EOVERFLOW == Errno.overflow.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    XCTAssert(EBADEXEC == Errno.badExecutable.rawValue)
    XCTAssert(EBADARCH == Errno.badCPUType.rawValue)
    XCTAssert(ESHLIBVERS == Errno.sharedLibraryVersionMismatch.rawValue)
    XCTAssert(EBADMACHO == Errno.malformedMachO.rawValue)
#endif

    XCTAssert(ECANCELED == Errno.canceled.rawValue)
    XCTAssert(EIDRM == Errno.identifierRemoved.rawValue)
    XCTAssert(ENOMSG == Errno.noMessage.rawValue)
    XCTAssert(EILSEQ == Errno.illegalByteSequence.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    XCTAssert(ENOATTR == Errno.attributeNotFound.rawValue)
#endif

    XCTAssert(EBADMSG == Errno.badMessage.rawValue)
    XCTAssert(EMULTIHOP == Errno.multiHop.rawValue)
    XCTAssert(ENODATA == Errno.noData.rawValue)
    XCTAssert(ENOLINK == Errno.noLink.rawValue)
    XCTAssert(ENOSR == Errno.noStreamResources.rawValue)
    XCTAssert(ENOSTR == Errno.notStream.rawValue)
    XCTAssert(EPROTO == Errno.protocolError.rawValue)
    XCTAssert(ETIME == Errno.timeout.rawValue)
    XCTAssert(EOPNOTSUPP == Errno.notSupportedOnSocket.rawValue)

    // From headers but not man page
    XCTAssert(EWOULDBLOCK == Errno.wouldBlock.rawValue)
    XCTAssert(ETOOMANYREFS == Errno.tooManyReferences.rawValue)
    XCTAssert(EREMOTE == Errno.tooManyRemoteLevels.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    XCTAssert(ENOPOLICY == Errno.noSuchPolicy.rawValue)
#endif

    XCTAssert(ENOTRECOVERABLE == Errno.notRecoverable.rawValue)
    XCTAssert(EOWNERDEAD == Errno.previousOwnerDied.rawValue)

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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

  // TODO: `description`
}
