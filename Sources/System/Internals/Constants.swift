/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// For platform constants redefined in Swift. We define them here so that
// they can be used anywhere without imports and without confusion to
// unavailable local decls.

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#elseif os(Linux) || os(FreeBSD) || os(Android)
import CSystem
import Glibc
#elseif os(Windows)
import CSystem
import ucrt
#else
#error("Unsupported Platform")
#endif

// MARK: errno
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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

#if !os(Windows)
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
internal var _EWOULDBLOCK: CInt { EWOULDBLOCK }

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

@_alwaysEmitIntoClient
internal var _ESOCKTNOSUPPORT: CInt {
#if os(Windows)
  return WSAESOCKTNOSUPPORT
#else
  return ESOCKTNOSUPPORT
#endif
}

@_alwaysEmitIntoClient
internal var _ENOTSUP: CInt {
#if os(Windows)
  return WSAEOPNOTSUPP
#else
  return ENOTSUP
#endif
}

@_alwaysEmitIntoClient
internal var _EPFNOSUPPORT: CInt {
#if os(Windows)
  return WSAEPFNOSUPPORT
#else
  return EPFNOSUPPORT
#endif
}

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

@_alwaysEmitIntoClient
internal var _ETIMEDOUT: CInt { ETIMEDOUT }

@_alwaysEmitIntoClient
internal var _ECONNREFUSED: CInt { ECONNREFUSED }

@_alwaysEmitIntoClient
internal var _ELOOP: CInt { ELOOP }

@_alwaysEmitIntoClient
internal var _ENAMETOOLONG: CInt { ENAMETOOLONG }

@_alwaysEmitIntoClient
internal var _EHOSTDOWN: CInt {
#if os(Windows)
  return WSAEHOSTDOWN
#else
  return EHOSTDOWN
#endif
}

@_alwaysEmitIntoClient
internal var _EHOSTUNREACH: CInt { EHOSTUNREACH }

@_alwaysEmitIntoClient
internal var _ENOTEMPTY: CInt { ENOTEMPTY }

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _EPROCLIM: CInt { EPROCLIM }
#endif

@_alwaysEmitIntoClient
internal var _EUSERS: CInt {
#if os(Windows)
  return WSAEUSERS
#else
  return EUSERS
#endif
}

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

@_alwaysEmitIntoClient
internal var _EREMOTE: CInt {
#if os(Windows)
  return WSAEREMOTE
#else
  return EREMOTE
#endif
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _EFTYPE: CInt { EFTYPE }

@_alwaysEmitIntoClient
internal var _EAUTH: CInt { EAUTH }

@_alwaysEmitIntoClient
internal var _ENEEDAUTH: CInt { ENEEDAUTH }

@_alwaysEmitIntoClient
internal var _EPWROFF: CInt { EPWROFF }

@_alwaysEmitIntoClient
internal var _EDEVERR: CInt { EDEVERR }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _EOVERFLOW: CInt { EOVERFLOW }
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _ENOATTR: CInt { ENOATTR }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _EBADMSG: CInt { EBADMSG }

@_alwaysEmitIntoClient
internal var _EMULTIHOP: CInt { EMULTIHOP }

@_alwaysEmitIntoClient
internal var _ENODATA: CInt { ENODATA }

@_alwaysEmitIntoClient
internal var _ENOLINK: CInt { ENOLINK }

@_alwaysEmitIntoClient
internal var _ENOSR: CInt { ENOSR }

@_alwaysEmitIntoClient
internal var _ENOSTR: CInt { ENOSTR }

@_alwaysEmitIntoClient
internal var _EPROTO: CInt { EPROTO }

@_alwaysEmitIntoClient
internal var _ETIME: CInt { ETIME }
#endif

@_alwaysEmitIntoClient
internal var _EOPNOTSUPP: CInt { EOPNOTSUPP }

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _ENOPOLICY: CInt { ENOPOLICY }
#endif

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _ENOTRECOVERABLE: CInt { ENOTRECOVERABLE }

@_alwaysEmitIntoClient
internal var _EOWNERDEAD: CInt { EOWNERDEAD }
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _EQFULL: CInt { EQFULL }

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
// TODO: API?
@_alwaysEmitIntoClient
internal var _O_ACCMODE: CInt { O_ACCMODE }

@_alwaysEmitIntoClient
internal var _O_NONBLOCK: CInt { O_NONBLOCK }
#endif

@_alwaysEmitIntoClient
internal var _O_APPEND: CInt { O_APPEND }

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _O_SHLOCK: CInt { O_SHLOCK }

@_alwaysEmitIntoClient
internal var _O_EXLOCK: CInt { O_EXLOCK }
#endif

#if !os(Windows)
// TODO: API?
@_alwaysEmitIntoClient
internal var _O_ASYNC: CInt { O_ASYNC }

@_alwaysEmitIntoClient
internal var _O_NOFOLLOW: CInt { O_NOFOLLOW }
#endif

@_alwaysEmitIntoClient
internal var _O_CREAT: CInt { O_CREAT }

@_alwaysEmitIntoClient
internal var _O_TRUNC: CInt { O_TRUNC }

@_alwaysEmitIntoClient
internal var _O_EXCL: CInt { O_EXCL }

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _O_EVTONLY: CInt { O_EVTONLY }
#endif

#if !os(Windows)
// TODO: API?
@_alwaysEmitIntoClient
internal var _O_NOCTTY: CInt { O_NOCTTY }

@_alwaysEmitIntoClient
internal var _O_DIRECTORY: CInt { O_DIRECTORY }
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _SEEK_HOLE: CInt { SEEK_HOLE }

@_alwaysEmitIntoClient
internal var _SEEK_DATA: CInt { SEEK_DATA }
#endif

