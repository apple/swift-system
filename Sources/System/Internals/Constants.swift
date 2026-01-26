/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

// For platform constants redefined in Swift. We define them here so that
// they can be used anywhere without imports and without confusion to
// unavailable local decls.

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif os(Windows)
import CSystem
import ucrt
#elseif canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#elseif canImport(WASILibc)
import CSystem
import WASILibc
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

// MARK: errno
#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _ERRNO_NOT_USED: CInt { 0 }
#endif

@_alwaysEmitIntoClient
internal var _EPERM: CInt { EPERM }

@_alwaysEmitIntoClient
internal var _ENOENT: CInt { ENOENT }

@_alwaysEmitIntoClient
internal var _ESRCH: CInt { ESRCH }

@_alwaysEmitIntoClient
internal var _EINTR: CInt { EINTR }

@_alwaysEmitIntoClient
internal var _EIO: CInt { EIO }

@_alwaysEmitIntoClient
internal var _ENXIO: CInt { ENXIO }

@_alwaysEmitIntoClient
internal var _E2BIG: CInt { E2BIG }

@_alwaysEmitIntoClient
internal var _ENOEXEC: CInt { ENOEXEC }

@_alwaysEmitIntoClient
internal var _EBADF: CInt { EBADF }

@_alwaysEmitIntoClient
internal var _ECHILD: CInt { ECHILD }

@_alwaysEmitIntoClient
internal var _EDEADLK: CInt { EDEADLK }

@_alwaysEmitIntoClient
internal var _ENOMEM: CInt { ENOMEM }

@_alwaysEmitIntoClient
internal var _EACCES: CInt { EACCES }

@_alwaysEmitIntoClient
internal var _EFAULT: CInt { EFAULT }

#if !os(Windows) && !os(WASI)
@_alwaysEmitIntoClient
internal var _ENOTBLK: CInt { ENOTBLK }
#endif

@_alwaysEmitIntoClient
internal var _EBUSY: CInt { EBUSY }

@_alwaysEmitIntoClient
internal var _EEXIST: CInt { EEXIST }

@_alwaysEmitIntoClient
internal var _EXDEV: CInt { EXDEV }

@_alwaysEmitIntoClient
internal var _ENODEV: CInt { ENODEV }

@_alwaysEmitIntoClient
internal var _ENOTDIR: CInt { ENOTDIR }

@_alwaysEmitIntoClient
internal var _EISDIR: CInt { EISDIR }

@_alwaysEmitIntoClient
internal var _EINVAL: CInt { EINVAL }

@_alwaysEmitIntoClient
internal var _ENFILE: CInt { ENFILE }

@_alwaysEmitIntoClient
internal var _EMFILE: CInt { EMFILE }

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _ENOTTY: CInt { ENOTTY }

@_alwaysEmitIntoClient
internal var _ETXTBSY: CInt { ETXTBSY }
#endif

@_alwaysEmitIntoClient
internal var _EFBIG: CInt { EFBIG }

@_alwaysEmitIntoClient
internal var _ENOSPC: CInt { ENOSPC }

@_alwaysEmitIntoClient
internal var _ESPIPE: CInt { ESPIPE }

@_alwaysEmitIntoClient
internal var _EROFS: CInt { EROFS }

@_alwaysEmitIntoClient
internal var _EMLINK: CInt { EMLINK }

@_alwaysEmitIntoClient
internal var _EPIPE: CInt { EPIPE }

@_alwaysEmitIntoClient
internal var _EDOM: CInt { EDOM }

@_alwaysEmitIntoClient
internal var _ERANGE: CInt { ERANGE }

@_alwaysEmitIntoClient
internal var _EAGAIN: CInt { EAGAIN }

@_alwaysEmitIntoClient
internal var _EWOULDBLOCK: CInt {
#if os(WASI)
  _getConst_EWOULDBLOCK()
#else
  EWOULDBLOCK
#endif
}

@_alwaysEmitIntoClient
internal var _EINPROGRESS: CInt { EINPROGRESS }

@_alwaysEmitIntoClient
internal var _EALREADY: CInt { EALREADY }

@_alwaysEmitIntoClient
internal var _ENOTSOCK: CInt { ENOTSOCK }

@_alwaysEmitIntoClient
internal var _EDESTADDRREQ: CInt { EDESTADDRREQ }

@_alwaysEmitIntoClient
internal var _EMSGSIZE: CInt { EMSGSIZE }

@_alwaysEmitIntoClient
internal var _EPROTOTYPE: CInt { EPROTOTYPE }

@_alwaysEmitIntoClient
internal var _ENOPROTOOPT: CInt { ENOPROTOOPT }

@_alwaysEmitIntoClient
internal var _EPROTONOSUPPORT: CInt { EPROTONOSUPPORT }

#if !os(WASI)
@_alwaysEmitIntoClient
internal var _ESOCKTNOSUPPORT: CInt {
#if os(Windows)
  return WSAESOCKTNOSUPPORT
#else
  return ESOCKTNOSUPPORT
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _ENOTSUP: CInt {
#if os(Windows)
  return WSAEOPNOTSUPP
#else
  return ENOTSUP
#endif
}

#if !os(WASI)
@_alwaysEmitIntoClient
internal var _EPFNOSUPPORT: CInt {
#if os(Windows)
  return WSAEPFNOSUPPORT
#else
  return EPFNOSUPPORT
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _EAFNOSUPPORT: CInt { EAFNOSUPPORT }

@_alwaysEmitIntoClient
internal var _EADDRINUSE: CInt { EADDRINUSE }

@_alwaysEmitIntoClient
internal var _EADDRNOTAVAIL: CInt { EADDRNOTAVAIL }

@_alwaysEmitIntoClient
internal var _ENETDOWN: CInt { ENETDOWN }

@_alwaysEmitIntoClient
internal var _ENETUNREACH: CInt { ENETUNREACH }

@_alwaysEmitIntoClient
internal var _ENETRESET: CInt { ENETRESET }

@_alwaysEmitIntoClient
internal var _ECONNABORTED: CInt { ECONNABORTED }

@_alwaysEmitIntoClient
internal var _ECONNRESET: CInt { ECONNRESET }

@_alwaysEmitIntoClient
internal var _ENOBUFS: CInt { ENOBUFS }

@_alwaysEmitIntoClient
internal var _EISCONN: CInt { EISCONN }

@_alwaysEmitIntoClient
internal var _ENOTCONN: CInt { ENOTCONN }

#if !os(WASI)
@_alwaysEmitIntoClient
internal var _ESHUTDOWN: CInt {
#if os(Windows)
  return WSAESHUTDOWN
#else
  return ESHUTDOWN
#endif
}

@_alwaysEmitIntoClient
internal var _ETOOMANYREFS: CInt {
#if os(Windows)
  return WSAETOOMANYREFS
#else
  return ETOOMANYREFS
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _ETIMEDOUT: CInt { ETIMEDOUT }

@_alwaysEmitIntoClient
internal var _ECONNREFUSED: CInt { ECONNREFUSED }

@_alwaysEmitIntoClient
internal var _ELOOP: CInt { ELOOP }

@_alwaysEmitIntoClient
internal var _ENAMETOOLONG: CInt { ENAMETOOLONG }

#if !os(WASI)
@_alwaysEmitIntoClient
internal var _EHOSTDOWN: CInt {
#if os(Windows)
  return WSAEHOSTDOWN
#else
  return EHOSTDOWN
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _EHOSTUNREACH: CInt { EHOSTUNREACH }

@_alwaysEmitIntoClient
internal var _ENOTEMPTY: CInt { ENOTEMPTY }

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _EPROCLIM: CInt { EPROCLIM }
#endif

#if !os(WASI)
@_alwaysEmitIntoClient
internal var _EUSERS: CInt {
#if os(Windows)
  return WSAEUSERS
#else
  return EUSERS
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _EDQUOT: CInt {
#if os(Windows)
  return WSAEDQUOT
#else
  return EDQUOT
#endif
}

@_alwaysEmitIntoClient
internal var _ESTALE: CInt {
#if os(Windows)
  return WSAESTALE
#else
  return ESTALE
#endif
}

#if !os(WASI)
@_alwaysEmitIntoClient
internal var _EREMOTE: CInt {
#if os(Windows)
  return WSAEREMOTE
#else
  return EREMOTE
#endif
}
#endif

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _EBADRPC: CInt { EBADRPC }

@_alwaysEmitIntoClient
internal var _ERPCMISMATCH: CInt { ERPCMISMATCH }

@_alwaysEmitIntoClient
internal var _EPROGUNAVAIL: CInt { EPROGUNAVAIL }

@_alwaysEmitIntoClient
internal var _EPROGMISMATCH: CInt { EPROGMISMATCH }

@_alwaysEmitIntoClient
internal var _EPROCUNAVAIL: CInt { EPROCUNAVAIL }
#endif

@_alwaysEmitIntoClient
internal var _ENOLCK: CInt { ENOLCK }

@_alwaysEmitIntoClient
internal var _ENOSYS: CInt { ENOSYS }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _EFTYPE: CInt { EFTYPE }

@_alwaysEmitIntoClient
internal var _EAUTH: CInt { EAUTH }

@_alwaysEmitIntoClient
internal var _ENEEDAUTH: CInt { ENEEDAUTH }
#endif

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _EPWROFF: CInt { EPWROFF }

@_alwaysEmitIntoClient
internal var _EDEVERR: CInt { EDEVERR }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _EOVERFLOW: CInt { EOVERFLOW }
#endif

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _EBADEXEC: CInt { EBADEXEC }

@_alwaysEmitIntoClient
internal var _EBADARCH: CInt { EBADARCH }

@_alwaysEmitIntoClient
internal var _ESHLIBVERS: CInt { ESHLIBVERS }

@_alwaysEmitIntoClient
internal var _EBADMACHO: CInt { EBADMACHO }
#endif

@_alwaysEmitIntoClient
internal var _ECANCELED: CInt { ECANCELED }

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _EIDRM: CInt { EIDRM }

@_alwaysEmitIntoClient
internal var _ENOMSG: CInt { ENOMSG }
#endif

@_alwaysEmitIntoClient
internal var _EILSEQ: CInt { EILSEQ }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _ENOATTR: CInt { ENOATTR }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _EBADMSG: CInt { EBADMSG }

#if !os(OpenBSD)
@_alwaysEmitIntoClient
internal var _EMULTIHOP: CInt { EMULTIHOP }

#if !os(WASI) && !os(FreeBSD)
@_alwaysEmitIntoClient
internal var _ENODATA: CInt { ENODATA }
#endif

@_alwaysEmitIntoClient
internal var _ENOLINK: CInt { ENOLINK }

#if !os(WASI) && !os(FreeBSD)
@_alwaysEmitIntoClient
internal var _ENOSR: CInt { ENOSR }

@_alwaysEmitIntoClient
internal var _ENOSTR: CInt { ENOSTR }
#endif
#endif

@_alwaysEmitIntoClient
internal var _EPROTO: CInt { EPROTO }

#if !os(OpenBSD) && !os(WASI) && !os(FreeBSD)
@_alwaysEmitIntoClient
internal var _ETIME: CInt { ETIME }
#endif
#endif


@_alwaysEmitIntoClient
internal var _EOPNOTSUPP: CInt {
#if os(WASI)
  _getConst_EOPNOTSUPP()
#else
  EOPNOTSUPP
#endif
}

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _ENOPOLICY: CInt { ENOPOLICY }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _ENOTRECOVERABLE: CInt { ENOTRECOVERABLE }

@_alwaysEmitIntoClient
internal var _EOWNERDEAD: CInt { EOWNERDEAD }
#endif

#if os(FreeBSD)
@_alwaysEmitIntoClient
internal var _ENOTCAPABLE: CInt { ENOTCAPABLE }

@_alwaysEmitIntoClient
internal var _ECAPMODE: CInt { ECAPMODE }

@_alwaysEmitIntoClient
internal var _EINTEGRITY: CInt { EINTEGRITY }
#endif

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _EQFULL: CInt { EQFULL }
#endif

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _ELAST: CInt { ELAST }
#endif

// MARK: File Operations

@_alwaysEmitIntoClient
internal var _O_RDONLY: CInt { O_RDONLY }

@_alwaysEmitIntoClient
internal var _O_WRONLY: CInt { O_WRONLY }

@_alwaysEmitIntoClient
internal var _O_RDWR: CInt { O_RDWR }

#if !os(Windows)
#if canImport(Musl)
internal var _O_ACCMODE: CInt { 0x03|O_SEARCH }
#else
// TODO: API?
@_alwaysEmitIntoClient
internal var _O_ACCMODE: CInt {
#if os(WASI)
  _getConst_O_ACCMODE()
#else
  O_ACCMODE
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _O_NONBLOCK: CInt {
#if os(WASI)
  _getConst_O_NONBLOCK()
#else
  O_NONBLOCK
#endif
}
#endif

@_alwaysEmitIntoClient
internal var _O_APPEND: CInt {
#if os(WASI)
  _getConst_O_APPEND()
#else
  O_APPEND
#endif
}

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _O_SHLOCK: CInt { O_SHLOCK }

@_alwaysEmitIntoClient
internal var _O_EXLOCK: CInt { O_EXLOCK }
#endif

#if !os(Windows)
#if !os(WASI)
// TODO: API?
@_alwaysEmitIntoClient
internal var _O_ASYNC: CInt { O_ASYNC }
#endif

@_alwaysEmitIntoClient
internal var _O_NOFOLLOW: CInt { O_NOFOLLOW }
#endif

#if os(FreeBSD)
@_alwaysEmitIntoClient
internal var _O_FSYNC: CInt { O_FSYNC }

@_alwaysEmitIntoClient
internal var _O_SYNC: CInt { O_SYNC }
#endif

@_alwaysEmitIntoClient
internal var _O_CREAT: CInt {
#if os(WASI)
  _getConst_O_CREAT()
#else
  O_CREAT
#endif
}

@_alwaysEmitIntoClient
internal var _O_TRUNC: CInt {
#if os(WASI)
  _getConst_O_TRUNC()
#else
  O_TRUNC
#endif
}

@_alwaysEmitIntoClient
internal var _O_EXCL: CInt {
#if os(WASI)
  _getConst_O_EXCL()
#else
  O_EXCL
#endif
}

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _O_EVTONLY: CInt { O_EVTONLY }
#endif

#if !os(Windows)
// TODO: API?
@_alwaysEmitIntoClient
internal var _O_NOCTTY: CInt { O_NOCTTY }

@_alwaysEmitIntoClient
internal var _O_DIRECTORY: CInt {
#if os(WASI)
  _getConst_O_DIRECTORY()
#else
  O_DIRECTORY
#endif
}
#endif

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _O_SYMLINK: CInt { O_SYMLINK }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _O_CLOEXEC: CInt { O_CLOEXEC }
#endif

@_alwaysEmitIntoClient
internal var _SEEK_SET: CInt { SEEK_SET }

@_alwaysEmitIntoClient
internal var _SEEK_CUR: CInt { SEEK_CUR }

@_alwaysEmitIntoClient
internal var _SEEK_END: CInt { SEEK_END }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _SEEK_HOLE: CInt { SEEK_HOLE }

@_alwaysEmitIntoClient
internal var _SEEK_DATA: CInt { SEEK_DATA }
#endif

// MARK: - File System

#if !os(Windows)

@_alwaysEmitIntoClient
internal var _AT_FDCWD: CInt { AT_FDCWD }

// MARK: - fstatat Flags

@_alwaysEmitIntoClient
internal var _AT_SYMLINK_NOFOLLOW: CInt { AT_SYMLINK_NOFOLLOW }

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _AT_SYMLINK_NOFOLLOW_ANY: CInt { AT_SYMLINK_NOFOLLOW_ANY }
#endif

#if canImport(Darwin, _version: 346) || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _AT_RESOLVE_BENEATH: CInt { AT_RESOLVE_BENEATH }
#endif

// MARK: - File Mode / File Type

@_alwaysEmitIntoClient
internal var _MODE_FILETYPE_MASK: mode_t { S_IFMT }

@_alwaysEmitIntoClient
internal var _MODE_PERMISSIONS_MASK: mode_t { 0o7777 }

@_alwaysEmitIntoClient
internal var _S_IFDIR: mode_t { S_IFDIR }

@_alwaysEmitIntoClient
internal var _S_IFCHR: mode_t { S_IFCHR }

@_alwaysEmitIntoClient
internal var _S_IFBLK: mode_t { S_IFBLK }

@_alwaysEmitIntoClient
internal var _S_IFREG: mode_t { S_IFREG }

@_alwaysEmitIntoClient
internal var _S_IFIFO: mode_t { S_IFIFO }

@_alwaysEmitIntoClient
internal var _S_IFLNK: mode_t { S_IFLNK }

@_alwaysEmitIntoClient
internal var _S_IFSOCK: mode_t { S_IFSOCK }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _S_IFWHT: mode_t { S_IFWHT }
#endif

// MARK: - stat/chflags File Flags

// MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
@_alwaysEmitIntoClient
internal var _UF_NODUMP: UInt32 { UInt32(bitPattern: UF_NODUMP) }

@_alwaysEmitIntoClient
internal var _UF_IMMUTABLE: UInt32 { UInt32(bitPattern: UF_IMMUTABLE) }

@_alwaysEmitIntoClient
internal var _UF_APPEND: UInt32 { UInt32(bitPattern: UF_APPEND) }

@_alwaysEmitIntoClient
internal var _SF_ARCHIVED: UInt32 { UInt32(bitPattern: SF_ARCHIVED) }

@_alwaysEmitIntoClient
internal var _SF_IMMUTABLE: UInt32 { UInt32(bitPattern: SF_IMMUTABLE) }

@_alwaysEmitIntoClient
internal var _SF_APPEND: UInt32 { UInt32(bitPattern: SF_APPEND) }
#endif

// MARK: Flags Available on Darwin and FreeBSD

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _UF_OPAQUE: UInt32 { UInt32(bitPattern: UF_OPAQUE) }

@_alwaysEmitIntoClient
internal var _UF_HIDDEN: UInt32 { UInt32(bitPattern: UF_HIDDEN) }

@_alwaysEmitIntoClient
internal var _SF_NOUNLINK: UInt32 { UInt32(bitPattern: SF_NOUNLINK) }
#endif

// MARK: Flags Available on Darwin Only

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _UF_COMPRESSED: UInt32 { UInt32(bitPattern: UF_COMPRESSED) }

@_alwaysEmitIntoClient
internal var _UF_TRACKED: UInt32 { UInt32(bitPattern: UF_TRACKED) }

@_alwaysEmitIntoClient
internal var _UF_DATAVAULT: UInt32 { UInt32(bitPattern: UF_DATAVAULT) }

@_alwaysEmitIntoClient
internal var _SF_RESTRICTED: UInt32 { UInt32(bitPattern: SF_RESTRICTED) }

@_alwaysEmitIntoClient
internal var _SF_FIRMLINK: UInt32 { UInt32(bitPattern: SF_FIRMLINK) }

@_alwaysEmitIntoClient
internal var _SF_DATALESS: UInt32 { UInt32(bitPattern: SF_DATALESS) }
#endif

// MARK: Flags Available on FreeBSD Only

#if os(FreeBSD)
@_alwaysEmitIntoClient
internal var _UF_NOUNLINK: UInt32 { UInt32(bitPattern: UF_NOUNLINK) }

@_alwaysEmitIntoClient
internal var _UF_OFFLINE: UInt32 { UInt32(bitPattern: UF_OFFLINE) }

@_alwaysEmitIntoClient
internal var _UF_READONLY: UInt32 { UInt32(bitPattern: UF_READONLY) }

@_alwaysEmitIntoClient
internal var _UF_REPARSE: UInt32 { UInt32(bitPattern: UF_REPARSE) }

@_alwaysEmitIntoClient
internal var _UF_SPARSE: UInt32 { UInt32(bitPattern: UF_SPARSE) }

@_alwaysEmitIntoClient
internal var _UF_SYSTEM: UInt32 { UInt32(bitPattern: UF_SYSTEM) }

@_alwaysEmitIntoClient
internal var _SF_SNAPSHOT: UInt32 { UInt32(bitPattern: SF_SNAPSHOT) }
#endif

// MARK: - Terminal Control (termios)

// Special values
@_alwaysEmitIntoClient
internal var _NCCS: CInt { CInt(NCCS) }

@_alwaysEmitIntoClient
internal var __POSIX_VDISABLE: CInterop.ControlCharacterValue {
  // _POSIX_VDISABLE is typically 0xFF (255) on POSIX systems
  // On Darwin and Linux, it's defined as 0xFF
  0xFF
}

// Input flags (c_iflag)
@_alwaysEmitIntoClient
internal var _BRKINT: CInterop.TerminalFlags { CInterop.TerminalFlags(BRKINT) }

@_alwaysEmitIntoClient
internal var _ICRNL: CInterop.TerminalFlags { CInterop.TerminalFlags(ICRNL) }

@_alwaysEmitIntoClient
internal var _IGNBRK: CInterop.TerminalFlags { CInterop.TerminalFlags(IGNBRK) }

@_alwaysEmitIntoClient
internal var _IGNCR: CInterop.TerminalFlags { CInterop.TerminalFlags(IGNCR) }

@_alwaysEmitIntoClient
internal var _IGNPAR: CInterop.TerminalFlags { CInterop.TerminalFlags(IGNPAR) }

@_alwaysEmitIntoClient
internal var _INLCR: CInterop.TerminalFlags { CInterop.TerminalFlags(INLCR) }

@_alwaysEmitIntoClient
internal var _INPCK: CInterop.TerminalFlags { CInterop.TerminalFlags(INPCK) }

@_alwaysEmitIntoClient
internal var _ISTRIP: CInterop.TerminalFlags { CInterop.TerminalFlags(ISTRIP) }

@_alwaysEmitIntoClient
internal var _IXANY: CInterop.TerminalFlags { CInterop.TerminalFlags(IXANY) }

@_alwaysEmitIntoClient
internal var _IXOFF: CInterop.TerminalFlags { CInterop.TerminalFlags(IXOFF) }

@_alwaysEmitIntoClient
internal var _IXON: CInterop.TerminalFlags { CInterop.TerminalFlags(IXON) }

@_alwaysEmitIntoClient
internal var _PARMRK: CInterop.TerminalFlags { CInterop.TerminalFlags(PARMRK) }

@_alwaysEmitIntoClient
internal var _IMAXBEL: CInterop.TerminalFlags { CInterop.TerminalFlags(IMAXBEL) }

@_alwaysEmitIntoClient
internal var _IUTF8: CInterop.TerminalFlags { CInterop.TerminalFlags(IUTF8) }

#if os(Linux)
@_alwaysEmitIntoClient
internal var _IUCLC: CInterop.TerminalFlags { CInterop.TerminalFlags(IUCLC) }
#endif

// Output flags (c_oflag)
@_alwaysEmitIntoClient
internal var _OPOST: CInterop.TerminalFlags { CInterop.TerminalFlags(OPOST) }

@_alwaysEmitIntoClient
internal var _ONLCR: CInterop.TerminalFlags { CInterop.TerminalFlags(ONLCR) }

@_alwaysEmitIntoClient
internal var _OCRNL: CInterop.TerminalFlags { CInterop.TerminalFlags(OCRNL) }

@_alwaysEmitIntoClient
internal var _ONOCR: CInterop.TerminalFlags { CInterop.TerminalFlags(ONOCR) }

@_alwaysEmitIntoClient
internal var _ONLRET: CInterop.TerminalFlags { CInterop.TerminalFlags(ONLRET) }

@_alwaysEmitIntoClient
internal var _OFILL: CInterop.TerminalFlags { CInterop.TerminalFlags(OFILL) }

@_alwaysEmitIntoClient
internal var _OFDEL: CInterop.TerminalFlags { CInterop.TerminalFlags(OFDEL) }

@_alwaysEmitIntoClient
internal var _NLDLY: CInterop.TerminalFlags { CInterop.TerminalFlags(NLDLY) }

@_alwaysEmitIntoClient
internal var _NL0: CInterop.TerminalFlags { CInterop.TerminalFlags(NL0) }

@_alwaysEmitIntoClient
internal var _NL1: CInterop.TerminalFlags { CInterop.TerminalFlags(NL1) }

@_alwaysEmitIntoClient
internal var _CRDLY: CInterop.TerminalFlags { CInterop.TerminalFlags(CRDLY) }

@_alwaysEmitIntoClient
internal var _CR0: CInterop.TerminalFlags { CInterop.TerminalFlags(CR0) }

@_alwaysEmitIntoClient
internal var _CR1: CInterop.TerminalFlags { CInterop.TerminalFlags(CR1) }

@_alwaysEmitIntoClient
internal var _CR2: CInterop.TerminalFlags { CInterop.TerminalFlags(CR2) }

@_alwaysEmitIntoClient
internal var _CR3: CInterop.TerminalFlags { CInterop.TerminalFlags(CR3) }

@_alwaysEmitIntoClient
internal var _TABDLY: CInterop.TerminalFlags { CInterop.TerminalFlags(TABDLY) }

@_alwaysEmitIntoClient
internal var _TAB0: CInterop.TerminalFlags { CInterop.TerminalFlags(TAB0) }

@_alwaysEmitIntoClient
internal var _TAB1: CInterop.TerminalFlags { CInterop.TerminalFlags(TAB1) }

@_alwaysEmitIntoClient
internal var _TAB2: CInterop.TerminalFlags { CInterop.TerminalFlags(TAB2) }

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _TAB3: CInterop.TerminalFlags { CInterop.TerminalFlags(TAB3) }
#elseif os(Linux)
@_alwaysEmitIntoClient
internal var _XTABS: CInterop.TerminalFlags { CInterop.TerminalFlags(XTABS) }
#endif

@_alwaysEmitIntoClient
internal var _BSDLY: CInterop.TerminalFlags { CInterop.TerminalFlags(BSDLY) }

@_alwaysEmitIntoClient
internal var _BS0: CInterop.TerminalFlags { CInterop.TerminalFlags(BS0) }

@_alwaysEmitIntoClient
internal var _BS1: CInterop.TerminalFlags { CInterop.TerminalFlags(BS1) }

@_alwaysEmitIntoClient
internal var _VTDLY: CInterop.TerminalFlags { CInterop.TerminalFlags(VTDLY) }

@_alwaysEmitIntoClient
internal var _VT0: CInterop.TerminalFlags { CInterop.TerminalFlags(VT0) }

@_alwaysEmitIntoClient
internal var _VT1: CInterop.TerminalFlags { CInterop.TerminalFlags(VT1) }

@_alwaysEmitIntoClient
internal var _FFDLY: CInterop.TerminalFlags { CInterop.TerminalFlags(FFDLY) }

@_alwaysEmitIntoClient
internal var _FF0: CInterop.TerminalFlags { CInterop.TerminalFlags(FF0) }

@_alwaysEmitIntoClient
internal var _FF1: CInterop.TerminalFlags { CInterop.TerminalFlags(FF1) }

#if canImport(Darwin)
@_alwaysEmitIntoClient
internal var _OXTABS: CInterop.TerminalFlags { CInterop.TerminalFlags(OXTABS) }

@_alwaysEmitIntoClient
internal var _ONOEOT: CInterop.TerminalFlags { CInterop.TerminalFlags(ONOEOT) }
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _OLCUC: CInterop.TerminalFlags { CInterop.TerminalFlags(OLCUC) }
#endif

// Control flags (c_cflag)
@_alwaysEmitIntoClient
internal var _CREAD: CInterop.TerminalFlags { CInterop.TerminalFlags(CREAD) }

@_alwaysEmitIntoClient
internal var _CSTOPB: CInterop.TerminalFlags { CInterop.TerminalFlags(CSTOPB) }

@_alwaysEmitIntoClient
internal var _HUPCL: CInterop.TerminalFlags { CInterop.TerminalFlags(HUPCL) }

@_alwaysEmitIntoClient
internal var _CLOCAL: CInterop.TerminalFlags { CInterop.TerminalFlags(CLOCAL) }

@_alwaysEmitIntoClient
internal var _PARENB: CInterop.TerminalFlags { CInterop.TerminalFlags(PARENB) }

@_alwaysEmitIntoClient
internal var _PARODD: CInterop.TerminalFlags { CInterop.TerminalFlags(PARODD) }

@_alwaysEmitIntoClient
internal var _CSIZE: CInterop.TerminalFlags { CInterop.TerminalFlags(CSIZE) }

@_alwaysEmitIntoClient
internal var _CS5: CInterop.TerminalFlags { CInterop.TerminalFlags(CS5) }

@_alwaysEmitIntoClient
internal var _CS6: CInterop.TerminalFlags { CInterop.TerminalFlags(CS6) }

@_alwaysEmitIntoClient
internal var _CS7: CInterop.TerminalFlags { CInterop.TerminalFlags(CS7) }

@_alwaysEmitIntoClient
internal var _CS8: CInterop.TerminalFlags { CInterop.TerminalFlags(CS8) }

#if canImport(Darwin)
@_alwaysEmitIntoClient
internal var _CCTS_OFLOW: CInterop.TerminalFlags { CInterop.TerminalFlags(CCTS_OFLOW) }

@_alwaysEmitIntoClient
internal var _CRTS_IFLOW: CInterop.TerminalFlags { CInterop.TerminalFlags(CRTS_IFLOW) }

@_alwaysEmitIntoClient
internal var _CDTR_IFLOW: CInterop.TerminalFlags { CInterop.TerminalFlags(CDTR_IFLOW) }

@_alwaysEmitIntoClient
internal var _CDSR_OFLOW: CInterop.TerminalFlags { CInterop.TerminalFlags(CDSR_OFLOW) }

@_alwaysEmitIntoClient
internal var _CCAR_OFLOW: CInterop.TerminalFlags { CInterop.TerminalFlags(CCAR_OFLOW) }

@_alwaysEmitIntoClient
internal var _CRTSCTS: CInterop.TerminalFlags { CInterop.TerminalFlags(CRTSCTS) }
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _CRTSCTS: CInterop.TerminalFlags { CInterop.TerminalFlags(CRTSCTS) }

@_alwaysEmitIntoClient
internal var _CMSPAR: CInterop.TerminalFlags { CInterop.TerminalFlags(CMSPAR) }
#endif

// Local flags (c_lflag)
@_alwaysEmitIntoClient
internal var _ECHO: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHO) }

@_alwaysEmitIntoClient
internal var _ECHOE: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHOE) }

@_alwaysEmitIntoClient
internal var _ECHOK: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHOK) }

@_alwaysEmitIntoClient
internal var _ECHONL: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHONL) }

@_alwaysEmitIntoClient
internal var _ICANON: CInterop.TerminalFlags { CInterop.TerminalFlags(ICANON) }

@_alwaysEmitIntoClient
internal var _IEXTEN: CInterop.TerminalFlags { CInterop.TerminalFlags(IEXTEN) }

@_alwaysEmitIntoClient
internal var _ISIG: CInterop.TerminalFlags { CInterop.TerminalFlags(ISIG) }

@_alwaysEmitIntoClient
internal var _NOFLSH: CInterop.TerminalFlags { CInterop.TerminalFlags(NOFLSH) }

@_alwaysEmitIntoClient
internal var _TOSTOP: CInterop.TerminalFlags { CInterop.TerminalFlags(TOSTOP) }

@_alwaysEmitIntoClient
internal var _ECHOCTL: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHOCTL) }

@_alwaysEmitIntoClient
internal var _ECHOKE: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHOKE) }

@_alwaysEmitIntoClient
internal var _ECHOPRT: CInterop.TerminalFlags { CInterop.TerminalFlags(ECHOPRT) }

@_alwaysEmitIntoClient
internal var _FLUSHO: CInterop.TerminalFlags { CInterop.TerminalFlags(FLUSHO) }

@_alwaysEmitIntoClient
internal var _PENDIN: CInterop.TerminalFlags { CInterop.TerminalFlags(PENDIN) }

#if canImport(Darwin)
@_alwaysEmitIntoClient
internal var _ALTWERASE: CInterop.TerminalFlags { CInterop.TerminalFlags(ALTWERASE) }

@_alwaysEmitIntoClient
internal var _EXTPROC: CInterop.TerminalFlags { CInterop.TerminalFlags(EXTPROC) }

@_alwaysEmitIntoClient
internal var _NOKERNINFO: CInterop.TerminalFlags { CInterop.TerminalFlags(NOKERNINFO) }
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _EXTPROC: CInterop.TerminalFlags { CInterop.TerminalFlags(EXTPROC) }
#endif

// Control characters (c_cc indices)
@_alwaysEmitIntoClient
internal var _VEOF: CInt { CInt(VEOF) }

@_alwaysEmitIntoClient
internal var _VEOL: CInt { CInt(VEOL) }

@_alwaysEmitIntoClient
internal var _VERASE: CInt { CInt(VERASE) }

@_alwaysEmitIntoClient
internal var _VINTR: CInt { CInt(VINTR) }

@_alwaysEmitIntoClient
internal var _VKILL: CInt { CInt(VKILL) }

@_alwaysEmitIntoClient
internal var _VMIN: CInt { CInt(VMIN) }

@_alwaysEmitIntoClient
internal var _VQUIT: CInt { CInt(VQUIT) }

@_alwaysEmitIntoClient
internal var _VSTART: CInt { CInt(VSTART) }

@_alwaysEmitIntoClient
internal var _VSTOP: CInt { CInt(VSTOP) }

@_alwaysEmitIntoClient
internal var _VSUSP: CInt { CInt(VSUSP) }

@_alwaysEmitIntoClient
internal var _VTIME: CInt { CInt(VTIME) }

@_alwaysEmitIntoClient
internal var _VEOL2: CInt { CInt(VEOL2) }

@_alwaysEmitIntoClient
internal var _VWERASE: CInt { CInt(VWERASE) }

@_alwaysEmitIntoClient
internal var _VREPRINT: CInt { CInt(VREPRINT) }

@_alwaysEmitIntoClient
internal var _VDISCARD: CInt { CInt(VDISCARD) }

@_alwaysEmitIntoClient
internal var _VLNEXT: CInt { CInt(VLNEXT) }

#if canImport(Darwin)
@_alwaysEmitIntoClient
internal var _VSTATUS: CInt { CInt(VSTATUS) }

@_alwaysEmitIntoClient
internal var _VDSUSP: CInt { CInt(VDSUSP) }
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _VSWTC: CInt { CInt(VSWTC) }
#endif

// Baud rates
@_alwaysEmitIntoClient
internal var _B0: CInterop.SpeedT { CInterop.SpeedT(B0) }

@_alwaysEmitIntoClient
internal var _B50: CInterop.SpeedT { CInterop.SpeedT(B50) }

@_alwaysEmitIntoClient
internal var _B75: CInterop.SpeedT { CInterop.SpeedT(B75) }

@_alwaysEmitIntoClient
internal var _B110: CInterop.SpeedT { CInterop.SpeedT(B110) }

@_alwaysEmitIntoClient
internal var _B134: CInterop.SpeedT { CInterop.SpeedT(B134) }

@_alwaysEmitIntoClient
internal var _B150: CInterop.SpeedT { CInterop.SpeedT(B150) }

@_alwaysEmitIntoClient
internal var _B200: CInterop.SpeedT { CInterop.SpeedT(B200) }

@_alwaysEmitIntoClient
internal var _B300: CInterop.SpeedT { CInterop.SpeedT(B300) }

@_alwaysEmitIntoClient
internal var _B600: CInterop.SpeedT { CInterop.SpeedT(B600) }

@_alwaysEmitIntoClient
internal var _B1200: CInterop.SpeedT { CInterop.SpeedT(B1200) }

@_alwaysEmitIntoClient
internal var _B1800: CInterop.SpeedT { CInterop.SpeedT(B1800) }

@_alwaysEmitIntoClient
internal var _B2400: CInterop.SpeedT { CInterop.SpeedT(B2400) }

@_alwaysEmitIntoClient
internal var _B4800: CInterop.SpeedT { CInterop.SpeedT(B4800) }

@_alwaysEmitIntoClient
internal var _B9600: CInterop.SpeedT { CInterop.SpeedT(B9600) }

@_alwaysEmitIntoClient
internal var _B19200: CInterop.SpeedT { CInterop.SpeedT(B19200) }

@_alwaysEmitIntoClient
internal var _B38400: CInterop.SpeedT { CInterop.SpeedT(B38400) }

@_alwaysEmitIntoClient
internal var _B57600: CInterop.SpeedT { CInterop.SpeedT(B57600) }

@_alwaysEmitIntoClient
internal var _B115200: CInterop.SpeedT { CInterop.SpeedT(B115200) }

@_alwaysEmitIntoClient
internal var _B230400: CInterop.SpeedT { CInterop.SpeedT(B230400) }

#if canImport(Darwin)
@_alwaysEmitIntoClient
internal var _B7200: CInterop.SpeedT { CInterop.SpeedT(B7200) }

@_alwaysEmitIntoClient
internal var _B14400: CInterop.SpeedT { CInterop.SpeedT(B14400) }

@_alwaysEmitIntoClient
internal var _B28800: CInterop.SpeedT { CInterop.SpeedT(B28800) }

@_alwaysEmitIntoClient
internal var _B76800: CInterop.SpeedT { CInterop.SpeedT(B76800) }
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _B460800: CInterop.SpeedT { CInterop.SpeedT(B460800) }

@_alwaysEmitIntoClient
internal var _B500000: CInterop.SpeedT { CInterop.SpeedT(B500000) }

@_alwaysEmitIntoClient
internal var _B576000: CInterop.SpeedT { CInterop.SpeedT(B576000) }

@_alwaysEmitIntoClient
internal var _B921600: CInterop.SpeedT { CInterop.SpeedT(B921600) }

@_alwaysEmitIntoClient
internal var _B1000000: CInterop.SpeedT { CInterop.SpeedT(B1000000) }

@_alwaysEmitIntoClient
internal var _B1152000: CInterop.SpeedT { CInterop.SpeedT(B1152000) }

@_alwaysEmitIntoClient
internal var _B1500000: CInterop.SpeedT { CInterop.SpeedT(B1500000) }

@_alwaysEmitIntoClient
internal var _B2000000: CInterop.SpeedT { CInterop.SpeedT(B2000000) }

@_alwaysEmitIntoClient
internal var _B2500000: CInterop.SpeedT { CInterop.SpeedT(B2500000) }

@_alwaysEmitIntoClient
internal var _B3000000: CInterop.SpeedT { CInterop.SpeedT(B3000000) }

@_alwaysEmitIntoClient
internal var _B3500000: CInterop.SpeedT { CInterop.SpeedT(B3500000) }

@_alwaysEmitIntoClient
internal var _B4000000: CInterop.SpeedT { CInterop.SpeedT(B4000000) }
#endif

// SetAction constants
@_alwaysEmitIntoClient
internal var _TCSANOW: CInt { CInt(TCSANOW) }

@_alwaysEmitIntoClient
internal var _TCSADRAIN: CInt { CInt(TCSADRAIN) }

@_alwaysEmitIntoClient
internal var _TCSAFLUSH: CInt { CInt(TCSAFLUSH) }

#if canImport(Darwin)
@_alwaysEmitIntoClient
internal var _TCSASOFT: CInt { CInt(TCSASOFT) }
#endif

// Queue constants
@_alwaysEmitIntoClient
internal var _TCIFLUSH: CInt { CInt(TCIFLUSH) }

@_alwaysEmitIntoClient
internal var _TCOFLUSH: CInt { CInt(TCOFLUSH) }

@_alwaysEmitIntoClient
internal var _TCIOFLUSH: CInt { CInt(TCIOFLUSH) }

// Flow action constants
@_alwaysEmitIntoClient
internal var _TCOOFF: CInt { CInt(TCOOFF) }

@_alwaysEmitIntoClient
internal var _TCOON: CInt { CInt(TCOON) }

@_alwaysEmitIntoClient
internal var _TCIOFF: CInt { CInt(TCIOFF) }

@_alwaysEmitIntoClient
internal var _TCION: CInt { CInt(TCION) }

#endif // !os(Windows)
