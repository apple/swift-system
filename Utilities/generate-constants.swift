#! /usr/bin/env swift
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Run this script in the root directory of the swift-system package
// to regenerate the constant definitions corresponding to the
// current platform.
//
// ```
// $ cd <somewhere>/swift-system
// $ ./Utilities/generate-constants.swift
// ```
//
// This only needs to be done by package maintainers/contributors if
// they added or removed constants below, or in case the generated
// test case fails. In this latter case, some constants changed their
// value in the platform SDK, which usually requires some
// followup investigation.

import Foundation

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
let platformName = "Darwin"
let platformCondition = "os(macOS) || os(iOS) || os(watchOS) || os(tvOS)"
#elseif os(Linux)
let platformName = "Linux"
let platformCondition = "os(Linux)"
#elseif os(Windows)
let platformName = "Windows"
let platformCondition = "os(Windows)"
#else
#error("Unsupported platform")
#endif

var constants: [String: CInt] = [:]

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
constants["E2BIG"] = E2BIG
constants["EACCES"] = EACCES
constants["EADDRINUSE"] = EADDRINUSE
constants["EADDRNOTAVAIL"] = EADDRNOTAVAIL
constants["EAFNOSUPPORT"] = EAFNOSUPPORT
constants["EAGAIN"] = EAGAIN
constants["EALREADY"] = EALREADY
constants["EAUTH"] = EAUTH
constants["EBADARCH"] = EBADARCH
constants["EBADEXEC"] = EBADEXEC
constants["EBADF"] = EBADF
constants["EBADMACHO"] = EBADMACHO
constants["EBADMSG"] = EBADMSG
constants["EBADRPC"] = EBADRPC
constants["EBUSY"] = EBUSY
constants["ECANCELED"] = ECANCELED
constants["ECHILD"] = ECHILD
constants["ECONNABORTED"] = ECONNABORTED
constants["ECONNREFUSED"] = ECONNREFUSED
constants["ECONNRESET"] = ECONNRESET
constants["EDEADLK"] = EDEADLK
constants["EDESTADDRREQ"] = EDESTADDRREQ
constants["EDEVERR"] = EDEVERR
constants["EDOM"] = EDOM
constants["EDQUOT"] = EDQUOT
constants["EEXIST"] = EEXIST
constants["EFAULT"] = EFAULT
constants["EFBIG"] = EFBIG
constants["EFTYPE"] = EFTYPE
constants["EHOSTDOWN"] = EHOSTDOWN
constants["EHOSTUNREACH"] = EHOSTUNREACH
constants["EIDRM"] = EIDRM
constants["EILSEQ"] = EILSEQ
constants["EINPROGRESS"] = EINPROGRESS
constants["EINTR"] = EINTR
constants["EINVAL"] = EINVAL
constants["EIO"] = EIO
constants["EISCONN"] = EISCONN
constants["EISDIR"] = EISDIR
constants["ELAST"] = ELAST
constants["ELOOP"] = ELOOP
constants["EMFILE"] = EMFILE
constants["EMLINK"] = EMLINK
constants["EMSGSIZE"] = EMSGSIZE
constants["EMULTIHOP"] = EMULTIHOP
constants["ENAMETOOLONG"] = ENAMETOOLONG
constants["ENEEDAUTH"] = ENEEDAUTH
constants["ENETDOWN"] = ENETDOWN
constants["ENETRESET"] = ENETRESET
constants["ENETUNREACH"] = ENETUNREACH
constants["ENFILE"] = ENFILE
constants["ENOATTR"] = ENOATTR
constants["ENOBUFS"] = ENOBUFS
constants["ENODATA"] = ENODATA
constants["ENODEV"] = ENODEV
constants["ENOENT"] = ENOENT
constants["ENOEXEC"] = ENOEXEC
constants["ENOLCK"] = ENOLCK
constants["ENOLINK"] = ENOLINK
constants["ENOMEM"] = ENOMEM
constants["ENOMSG"] = ENOMSG
constants["ENOPOLICY"] = ENOPOLICY
constants["ENOPROTOOPT"] = ENOPROTOOPT
constants["ENOSPC"] = ENOSPC
constants["ENOSR"] = ENOSR
constants["ENOSTR"] = ENOSTR
constants["ENOSYS"] = ENOSYS
constants["ENOTBLK"] = ENOTBLK
constants["ENOTCONN"] = ENOTCONN
constants["ENOTDIR"] = ENOTDIR
constants["ENOTEMPTY"] = ENOTEMPTY
constants["ENOTRECOVERABLE"] = ENOTRECOVERABLE
constants["ENOTSOCK"] = ENOTSOCK
constants["ENOTSUP"] = ENOTSUP
constants["ENOTTY"] = ENOTTY
constants["ENXIO"] = ENXIO
constants["EOPNOTSUPP"] = EOPNOTSUPP
constants["EOVERFLOW"] = EOVERFLOW
constants["EOWNERDEAD"] = EOWNERDEAD
constants["EPERM"] = EPERM
constants["EPFNOSUPPORT"] = EPFNOSUPPORT
constants["EPIPE"] = EPIPE
constants["EPROCLIM"] = EPROCLIM
constants["EPROCUNAVAIL"] = EPROCUNAVAIL
constants["EPROGMISMATCH"] = EPROGMISMATCH
constants["EPROGUNAVAIL"] = EPROGUNAVAIL
constants["EPROTO"] = EPROTO
constants["EPROTONOSUPPORT"] = EPROTONOSUPPORT
constants["EPROTOTYPE"] = EPROTOTYPE
constants["EPWROFF"] = EPWROFF
constants["EQFULL"] = EQFULL
constants["ERANGE"] = ERANGE
constants["EREMOTE"] = EREMOTE
constants["EROFS"] = EROFS
constants["ERPCMISMATCH"] = ERPCMISMATCH
constants["ESHLIBVERS"] = ESHLIBVERS
constants["ESHUTDOWN"] = ESHUTDOWN
constants["ESOCKTNOSUPPORT"] = ESOCKTNOSUPPORT
constants["ESPIPE"] = ESPIPE
constants["ESRCH"] = ESRCH
constants["ESTALE"] = ESTALE
constants["ETIME"] = ETIME
constants["ETIMEDOUT"] = ETIMEDOUT
constants["ETOOMANYREFS"] = ETOOMANYREFS
constants["ETXTBSY"] = ETXTBSY
constants["EUSERS"] = EUSERS
constants["EWOULDBLOCK"] = EWOULDBLOCK
constants["EXDEV"] = EXDEV
constants["O_ACCMODE"] = O_ACCMODE
constants["O_APPEND"] = O_APPEND
constants["O_ASYNC"] = O_ASYNC
constants["O_CLOEXEC"] = O_CLOEXEC
constants["O_CREAT"] = O_CREAT
constants["O_DIRECTORY"] = O_DIRECTORY
constants["O_DP_GETRAWENCRYPTED"] = O_DP_GETRAWENCRYPTED
constants["O_DP_GETRAWUNENCRYPTED"] = O_DP_GETRAWUNENCRYPTED
constants["O_EVTONLY"] = O_EVTONLY
constants["O_EXCL"] = O_EXCL
constants["O_EXLOCK"] = O_EXLOCK
constants["O_NOCTTY"] = O_NOCTTY
constants["O_NOFOLLOW"] = O_NOFOLLOW
constants["O_NONBLOCK"] = O_NONBLOCK
constants["O_RDONLY"] = O_RDONLY
constants["O_RDWR"] = O_RDWR
constants["O_SHLOCK"] = O_SHLOCK
constants["O_SYMLINK"] = O_SYMLINK
constants["O_TRUNC"] = O_TRUNC
constants["O_WRONLY"] = O_WRONLY
constants["SEEK_CUR"] = SEEK_CUR
constants["SEEK_DATA"] = SEEK_DATA
constants["SEEK_END"] = SEEK_END
constants["SEEK_HOLE"] = SEEK_HOLE
constants["SEEK_SET"] = SEEK_SET
#endif // os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

#if os(Linux)
constants["E2BIG"] = E2BIG
constants["EACCES"] = EACCES
constants["EADDRINUSE"] = EADDRINUSE
constants["EADDRNOTAVAIL"] = EADDRNOTAVAIL
constants["EADV"] = EADV
constants["EAFNOSUPPORT"] = EAFNOSUPPORT
constants["EAGAIN"] = EAGAIN
constants["EALREADY"] = EALREADY
constants["EBADE"] = EBADE
constants["EBADF"] = EBADF
constants["EBADFD"] = EBADFD
constants["EBADMSG"] = EBADMSG
constants["EBADR"] = EBADR
constants["EBADRQC"] = EBADRQC
constants["EBADSLT"] = EBADSLT
constants["EBFONT"] = EBFONT
constants["EBUSY"] = EBUSY
constants["ECANCELED"] = ECANCELED
constants["ECHILD"] = ECHILD
constants["ECHRNG"] = ECHRNG
constants["ECOMM"] = ECOMM
constants["ECONNABORTED"] = ECONNABORTED
constants["ECONNREFUSED"] = ECONNREFUSED
constants["ECONNRESET"] = ECONNRESET
constants["EDEADLK"] = EDEADLK
constants["EDEADLOCK"] = EDEADLOCK
constants["EDESTADDRREQ"] = EDESTADDRREQ
constants["EDOM"] = EDOM
constants["EDOTDOT"] = EDOTDOT
constants["EDQUOT"] = EDQUOT
constants["EEXIST"] = EEXIST
constants["EFAULT"] = EFAULT
constants["EFBIG"] = EFBIG
constants["EHOSTDOWN"] = EHOSTDOWN
constants["EHOSTUNREACH"] = EHOSTUNREACH
constants["EHWPOISON"] = EHWPOISON
constants["EIDRM"] = EIDRM
constants["EILSEQ"] = EILSEQ
constants["EINPROGRESS"] = EINPROGRESS
constants["EINTR"] = EINTR
constants["EINVAL"] = EINVAL
constants["EIO"] = EIO
constants["EISCONN"] = EISCONN
constants["EISDIR"] = EISDIR
constants["EISNAM"] = EISNAM
constants["EKEYEXPIRED"] = EKEYEXPIRED
constants["EKEYREJECTED"] = EKEYREJECTED
constants["EKEYREVOKED"] = EKEYREVOKED
constants["EL2HLT"] = EL2HLT
constants["EL2NSYNC"] = EL2NSYNC
constants["EL3HLT"] = EL3HLT
constants["EL3RST"] = EL3RST
constants["ELIBACC"] = ELIBACC
constants["ELIBBAD"] = ELIBBAD
constants["ELIBEXEC"] = ELIBEXEC
constants["ELIBMAX"] = ELIBMAX
constants["ELIBSCN"] = ELIBSCN
constants["ELNRNG"] = ELNRNG
constants["ELOOP"] = ELOOP
constants["EMEDIUMTYPE"] = EMEDIUMTYPE
constants["EMFILE"] = EMFILE
constants["EMLINK"] = EMLINK
constants["EMSGSIZE"] = EMSGSIZE
constants["EMULTIHOP"] = EMULTIHOP
constants["ENAMETOOLONG"] = ENAMETOOLONG
constants["ENAVAIL"] = ENAVAIL
constants["ENETDOWN"] = ENETDOWN
constants["ENETRESET"] = ENETRESET
constants["ENETUNREACH"] = ENETUNREACH
constants["ENFILE"] = ENFILE
constants["ENOANO"] = ENOANO
constants["ENOBUFS"] = ENOBUFS
constants["ENOCSI"] = ENOCSI
constants["ENODATA"] = ENODATA
constants["ENODEV"] = ENODEV
constants["ENOENT"] = ENOENT
constants["ENOEXEC"] = ENOEXEC
constants["ENOKEY"] = ENOKEY
constants["ENOLCK"] = ENOLCK
constants["ENOLINK"] = ENOLINK
constants["ENOMEDIUM"] = ENOMEDIUM
constants["ENOMEM"] = ENOMEM
constants["ENOMSG"] = ENOMSG
constants["ENONET"] = ENONET
constants["ENOPKG"] = ENOPKG
constants["ENOPROTOOPT"] = ENOPROTOOPT
constants["ENOSPC"] = ENOSPC
constants["ENOSR"] = ENOSR
constants["ENOSTR"] = ENOSTR
constants["ENOSYS"] = ENOSYS
constants["ENOTBLK"] = ENOTBLK
constants["ENOTCONN"] = ENOTCONN
constants["ENOTDIR"] = ENOTDIR
constants["ENOTEMPTY"] = ENOTEMPTY
constants["ENOTNAM"] = ENOTNAM
constants["ENOTRECOVERABLE"] = ENOTRECOVERABLE
constants["ENOTSOCK"] = ENOTSOCK
constants["ENOTSUP"] = ENOTSUP
constants["ENOTTY"] = ENOTTY
constants["ENOTUNIQ"] = ENOTUNIQ
constants["ENXIO"] = ENXIO
constants["EOPNOTSUPP"] = EOPNOTSUPP
constants["EOVERFLOW"] = EOVERFLOW
constants["EOWNERDEAD"] = EOWNERDEAD
constants["EPERM"] = EPERM
constants["EPFNOSUPPORT"] = EPFNOSUPPORT
constants["EPIPE"] = EPIPE
constants["EPROTO"] = EPROTO
constants["EPROTONOSUPPORT"] = EPROTONOSUPPORT
constants["EPROTOTYPE"] = EPROTOTYPE
constants["ERANGE"] = ERANGE
constants["EREMCHG"] = EREMCHG
constants["EREMOTE"] = EREMOTE
constants["EREMOTEIO"] = EREMOTEIO
constants["ERESTART"] = ERESTART
constants["ERFKILL"] = ERFKILL
constants["EROFS"] = EROFS
constants["ESHUTDOWN"] = ESHUTDOWN
constants["ESOCKTNOSUPPORT"] = ESOCKTNOSUPPORT
constants["ESPIPE"] = ESPIPE
constants["ESRCH"] = ESRCH
constants["ESRMNT"] = ESRMNT
constants["ESTALE"] = ESTALE
constants["ESTRPIPE"] = ESTRPIPE
constants["ETIME"] = ETIME
constants["ETIMEDOUT"] = ETIMEDOUT
constants["ETOOMANYREFS"] = ETOOMANYREFS
constants["ETXTBSY"] = ETXTBSY
constants["EUCLEAN"] = EUCLEAN
constants["EUNATCH"] = EUNATCH
constants["EUSERS"] = EUSERS
constants["EWOULDBLOCK"] = EWOULDBLOCK
constants["EXDEV"] = EXDEV
constants["EXFULL"] = EXFULL
constants["FASYNC"] = FASYNC
constants["O_ACCMODE"] = O_ACCMODE
constants["O_APPEND"] = O_APPEND
constants["O_CLOEXEC"] = O_CLOEXEC
constants["O_CREAT"] = O_CREAT
constants["O_DIRECT"] = O_DIRECT
constants["O_DIRECTORY"] = O_DIRECTORY
constants["O_DSYNC"] = O_DSYNC
constants["O_EXCL"] = O_EXCL
constants["O_LARGEFILE"] = O_LARGEFILE
constants["O_NOATIME"] = O_NOATIME
constants["O_NOCTTY"] = O_NOCTTY
constants["O_NOFOLLOW"] = O_NOFOLLOW
constants["O_NONBLOCK"] = O_NONBLOCK
constants["O_RDONLY"] = O_RDONLY
constants["O_RDWR"] = O_RDWR
constants["O_TRUNC"] = O_TRUNC
constants["O_WRONLY"] = O_WRONLY
constants["SEEK_CUR"] = SEEK_CUR
constants["SEEK_END"] = SEEK_END
constants["SEEK_SET"] = SEEK_SET
#endif // os(Linux)

#if os(Windows)
constants["E2BIG"] = E2BIG
constants["EACCES"] = EACCES
constants["EADDRINUSE"] = EADDRINUSE
constants["EADDRNOTAVAIL"] = EADDRNOTAVAIL
constants["EAFNOSUPPORT"] = EAFNOSUPPORT
constants["EAGAIN"] = EAGAIN
constants["EALREADY"] = EALREADY
constants["EBADF"] = EBADF
constants["EBUSY"] = EBUSY
constants["ECANCELED"] = ECANCELED
constants["ECHILD"] = ECHILD
constants["ECONNABORTED"] = ECONNABORTED
constants["ECONNREFUSED"] = ECONNREFUSED
constants["ECONNRESET"] = ECONNRESET
constants["EDEADLK"] = EDEADLK
constants["EDEADLOCK"] = EDEADLOCK
constants["EDESTADDRREQ"] = EDESTADDRREQ
constants["EDISCON"] = EDISCON
constants["EDOM"] = EDOM
constants["EDQUOT"] = EDQUOT
constants["EEXIST"] = EEXIST
constants["EFAULT"] = EFAULT
constants["EFBIG"] = EFBIG
constants["EHOSTDOWN"] = EHOSTDOWN
constants["EHOSTUNREACH"] = EHOSTUNREACH
constants["EILSEQ"] = EILSEQ
constants["EINPROGRESS"] = EINPROGRESS
constants["EINTR"] = EINTR
constants["EINVAL"] = EINVAL
constants["EINVALIDPROCTABLE"] = EINVALIDPROCTABLE
constants["EINVALIDPROVIDER"] = EINVALIDPROVIDER
constants["EIO"] = EIO
constants["EISCONN"] = EISCONN
constants["EISDIR"] = EISDIR
constants["ELOOP"] = ELOOP
constants["EMFILE"] = EMFILE
constants["EMLINK"] = EMLINK
constants["EMSGSIZE"] = EMSGSIZE
constants["ENAMETOOLONG"] = ENAMETOOLONG
constants["ENETDOWN"] = ENETDOWN
constants["ENETRESET"] = ENETRESET
constants["ENETUNREACH"] = ENETUNREACH
constants["ENFILE"] = ENFILE
constants["ENOBUFS"] = ENOBUFS
constants["ENODEV"] = ENODEV
constants["ENOENT"] = ENOENT
constants["ENOEXEC"] = ENOEXEC
constants["ENOLCK"] = ENOLCK
constants["ENOMEM"] = ENOMEM
constants["ENOMORE"] = ENOMORE
constants["ENOPROTOOPT"] = ENOPROTOOPT
constants["ENOSPC"] = ENOSPC
constants["ENOSYS"] = ENOSYS
constants["ENOTCONN"] = ENOTCONN
constants["ENOTDIR"] = ENOTDIR
constants["ENOTEMPTY"] = ENOTEMPTY
constants["ENOTIFY"] = ENOTIFY
constants["ENOTSOCK"] = ENOTSOCK
constants["ENXIO"] = ENXIO
constants["EOPNOTSUPP"] = EOPNOTSUPP
constants["EPERM"] = EPERM
constants["EPFNOSUPPORT"] = EPFNOSUPPORT
constants["EPIPE"] = EPIPE
constants["EPROCLIM"] = EPROCLIM
constants["EPROTONOSUPPORT"] = EPROTONOSUPPORT
constants["EPROTOTYPE"] = EPROTOTYPE
constants["EPROVIDERFAILEDINIT"] = EPROVIDERFAILEDINIT
constants["ERANGE"] = ERANGE
constants["EREFUSED"] = EREFUSED
constants["EREMOTE"] = EREMOTE
constants["EROFS"] = EROFS
constants["ESHUTDOWN"] = ESHUTDOWN
constants["ESOCKTNOSUPPORT"] = ESOCKTNOSUPPORT
constants["ESPIPE"] = ESPIPE
constants["ESRCH"] = ESRCH
constants["ESTALE"] = ESTALE
constants["ETIMEDOUT"] = ETIMEDOUT
constants["ETOOMANYREFS"] = ETOOMANYREFS
constants["EUSERS"] = EUSERS
constants["EWOULDBLOCK"] = EWOULDBLOCK
constants["EXDEV"] = EXDEV
constants["O_APPEND"] = O_APPEND
constants["O_CREAT"] = O_CREAT
constants["O_EXCL"] = O_EXCL
constants["O_RDONLY"] = O_RDONLY
constants["O_RDWR"] = O_RDWR
constants["O_TRUNC"] = O_TRUNC
constants["O_WRONLY"] = O_WRONLY
constants["SEEK_CUR"] = SEEK_CUR
constants["SEEK_END"] = SEEK_END
constants["SEEK_SET"] = SEEK_SET
constants["STRUNCATE"] = STRUNCATE
constants["_EACCES"] = _EACCES
constants["_EBADF"] = _EBADF
constants["_EFAULT"] = _EFAULT
constants["_EINTR"] = _EINTR
constants["_EINVAL"] = _EINVAL
constants["_EMFILE"] = _EMFILE
constants["_ENAMETOOLONG"] = _ENAMETOOLONG
constants["_ENOTEMPTY"] = _ENOTEMPTY
#endif // os(Windows)

// Check that we're running in the correct directory.
let url = URL(fileURLWithPath: "./Sources/System/autogenerated")
guard (try? url.checkResourceIsReachable()) == true else {
  print("This script needs to be run in the root directory of the swift-system package.")
  exit(1)
}

////////////////////////////////////////////////////////////////////////////////

// Generate Sources/System/autogenerated/<Platform>PlatformConstants.swift

var constantsFile = """
  // *** DO NOT EDIT THIS FILE; IT IS AUTOGENERATED. ***

  #if \(platformCondition)

  """

for (name, value) in constants.sorted(by: { $0.key < $1.key }) {
  constantsFile += """
    @_alwaysEmitIntoClient internal var _\(name): CInt { \(value) }

    """
}
constantsFile += """
  #endif // \(platformCondition)

  """

try! NSString(string: constantsFile).write(
  toFile: "./Sources/System/autogenerated/\(platformName)PlatformConstants.swift",
  atomically: true,
  encoding: String.Encoding.utf8.rawValue)

////////////////////////////////////////////////////////////////////////////////

// Generate Tests/SystemTests/autogenerated/<Platform>PlatformConstantsTests.swift
var testFile = """
  // *** DO NOT EDIT THIS FILE; IT IS AUTOGENERATED. ***

  import XCTest
  @testable import SystemPackage

  class \(platformName)ConstantsTests: XCTestCase {
    func testConstants() {
      #if \(platformCondition)

  """
for (name, _) in constants.sorted(by: { $0.key < $1.key }) {
  testFile += """
        XCTAssertEqual(_\(name), \(name))

    """
}
testFile += """
      #endif // \(platformCondition)
    }
  }

  """
try! NSString(string: testFile).write(
  toFile: "./Tests/SystemTests/autogenerated/\(platformName)PlatformConstantsTests.swift",
  atomically: true,
  encoding: String.Encoding.utf8.rawValue)
