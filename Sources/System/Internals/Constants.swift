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

// TODO: Re-enable when _GNU_SOURCE can be defined.
//#if os(FreeBSD) || os(Linux) || os(Android)
//@_alwaysEmitIntoClient
//internal var _AT_EMPTY_PATH: CInt { AT_EMPTY_PATH }
//#endif

// MARK: - File Mode / File Type

@_alwaysEmitIntoClient
internal var _MODE_FILETYPE_MASK: CInterop.Mode { S_IFMT }

@_alwaysEmitIntoClient
internal var _MODE_PERMISSIONS_MASK: CInterop.Mode { 0o7777 }

@_alwaysEmitIntoClient
internal var _S_IFDIR: CInterop.Mode { S_IFDIR }

@_alwaysEmitIntoClient
internal var _S_IFCHR: CInterop.Mode { S_IFCHR }

@_alwaysEmitIntoClient
internal var _S_IFBLK: CInterop.Mode { S_IFBLK }

@_alwaysEmitIntoClient
internal var _S_IFREG: CInterop.Mode { S_IFREG }

@_alwaysEmitIntoClient
internal var _S_IFIFO: CInterop.Mode { S_IFIFO }

@_alwaysEmitIntoClient
internal var _S_IFLNK: CInterop.Mode { S_IFLNK }

@_alwaysEmitIntoClient
internal var _S_IFSOCK: CInterop.Mode { S_IFSOCK }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _S_IFWHT: CInterop.Mode { S_IFWHT }
#endif

// MARK: - stat/chflags File Flags

// MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
@_alwaysEmitIntoClient
internal var _UF_NODUMP: CInterop.FileFlags { UInt32(bitPattern: UF_NODUMP) }

@_alwaysEmitIntoClient
internal var _UF_IMMUTABLE: CInterop.FileFlags { UInt32(bitPattern: UF_IMMUTABLE) }

@_alwaysEmitIntoClient
internal var _UF_APPEND: CInterop.FileFlags { UInt32(bitPattern: UF_APPEND) }

@_alwaysEmitIntoClient
internal var _SF_ARCHIVED: CInterop.FileFlags { UInt32(bitPattern: SF_ARCHIVED) }

@_alwaysEmitIntoClient
internal var _SF_IMMUTABLE: CInterop.FileFlags { UInt32(bitPattern: SF_IMMUTABLE) }

@_alwaysEmitIntoClient
internal var _SF_APPEND: CInterop.FileFlags { UInt32(bitPattern: SF_APPEND) }
#endif

// MARK: Flags Available on Darwin and FreeBSD

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@_alwaysEmitIntoClient
internal var _UF_OPAQUE: CInterop.FileFlags { UInt32(bitPattern: UF_OPAQUE) }

@_alwaysEmitIntoClient
internal var _UF_HIDDEN: CInterop.FileFlags { UInt32(bitPattern: UF_HIDDEN) }

@_alwaysEmitIntoClient
internal var _SF_NOUNLINK: CInterop.FileFlags { UInt32(bitPattern: SF_NOUNLINK) }
#endif

// MARK: Flags Available on Darwin Only

#if SYSTEM_PACKAGE_DARWIN
@_alwaysEmitIntoClient
internal var _UF_COMPRESSED: CInterop.FileFlags { UInt32(bitPattern: UF_COMPRESSED) }

@_alwaysEmitIntoClient
internal var _UF_TRACKED: CInterop.FileFlags { UInt32(bitPattern: UF_TRACKED) }

@_alwaysEmitIntoClient
internal var _UF_DATAVAULT: CInterop.FileFlags { UInt32(bitPattern: UF_DATAVAULT) }

@_alwaysEmitIntoClient
internal var _SF_RESTRICTED: CInterop.FileFlags { UInt32(bitPattern: SF_RESTRICTED) }

@_alwaysEmitIntoClient
internal var _SF_FIRMLINK: CInterop.FileFlags { UInt32(bitPattern: SF_FIRMLINK) }

@_alwaysEmitIntoClient
internal var _SF_DATALESS: CInterop.FileFlags { UInt32(bitPattern: SF_DATALESS) }
#endif

// MARK: Flags Available on FreeBSD Only

#if os(FreeBSD)
@_alwaysEmitIntoClient
internal var _UF_NOUNLINK: CInterop.FileFlags { UInt32(bitPattern: UF_NOUNLINK) }

@_alwaysEmitIntoClient
internal var _UF_OFFLINE: CInterop.FileFlags { UInt32(bitPattern: UF_OFFLINE) }

@_alwaysEmitIntoClient
internal var _UF_READONLY: CInterop.FileFlags { UInt32(bitPattern: UF_READONLY) }

@_alwaysEmitIntoClient
internal var _UF_REPARSE: CInterop.FileFlags { UInt32(bitPattern: UF_REPARSE) }

@_alwaysEmitIntoClient
internal var _UF_SPARSE: CInterop.FileFlags { UInt32(bitPattern: UF_SPARSE) }

@_alwaysEmitIntoClient
internal var _UF_SYSTEM: CInterop.FileFlags { UInt32(bitPattern: UF_SYSTEM) }

@_alwaysEmitIntoClient
internal var _SF_SNAPSHOT: CInterop.FileFlags { UInt32(bitPattern: SF_SNAPSHOT) }
#endif

#endif // !os(Windows)
