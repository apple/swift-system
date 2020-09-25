/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

// For platform constants redefined in Swift. We redefine them here so that they
// can be @_alwaysEmitIntoClient without depending on Darwin or re-including a
// header (and applying attributes).

// MARK: errno
@_alwaysEmitIntoClient
internal var _ERRNO_NOT_USED: CInt { 0 }

@_alwaysEmitIntoClient
internal var _EPERM: CInt { 1 }

@_alwaysEmitIntoClient
internal var _ENOENT: CInt { 2 }

@_alwaysEmitIntoClient
internal var _ESRCH: CInt { 3 }

@_alwaysEmitIntoClient
internal var _EINTR: CInt { 4 }

@_alwaysEmitIntoClient
internal var _EIO: CInt { 5 }

@_alwaysEmitIntoClient
internal var _ENXIO: CInt { 6 }

@_alwaysEmitIntoClient
internal var _E2BIG: CInt { 7 }

@_alwaysEmitIntoClient
internal var _ENOEXEC: CInt { 8 }

@_alwaysEmitIntoClient
internal var _EBADF: CInt { 9 }

@_alwaysEmitIntoClient
internal var _ECHILD: CInt { 10 }

@_alwaysEmitIntoClient
internal var _EDEADLK: CInt { 11 }

@_alwaysEmitIntoClient
internal var _ENOMEM: CInt { 12 }

@_alwaysEmitIntoClient
internal var _EACCES: CInt { 13 }

@_alwaysEmitIntoClient
internal var _EFAULT: CInt { 14 }

@_alwaysEmitIntoClient
internal var _ENOTBLK: CInt { 15 }

@_alwaysEmitIntoClient
internal var _EBUSY: CInt { 16 }

@_alwaysEmitIntoClient
internal var _EEXIST: CInt { 17 }

@_alwaysEmitIntoClient
internal var _EXDEV: CInt { 18 }

@_alwaysEmitIntoClient
internal var _ENODEV: CInt { 19 }

@_alwaysEmitIntoClient
internal var _ENOTDIR: CInt { 20 }

@_alwaysEmitIntoClient
internal var _EISDIR: CInt { 21 }

@_alwaysEmitIntoClient
internal var _EINVAL: CInt { 22 }

@_alwaysEmitIntoClient
internal var _ENFILE: CInt { 23 }

@_alwaysEmitIntoClient
internal var _EMFILE: CInt { 24 }

@_alwaysEmitIntoClient
internal var _ENOTTY: CInt { 25 }

@_alwaysEmitIntoClient
internal var _ETXTBSY: CInt { 26 }

@_alwaysEmitIntoClient
internal var _EFBIG: CInt { 27 }

@_alwaysEmitIntoClient
internal var _ENOSPC: CInt { 28 }

@_alwaysEmitIntoClient
internal var _ESPIPE: CInt { 29 }

@_alwaysEmitIntoClient
internal var _EROFS: CInt { 30 }

@_alwaysEmitIntoClient
internal var _EMLINK: CInt { 31 }

@_alwaysEmitIntoClient
internal var _EPIPE: CInt { 32 }

@_alwaysEmitIntoClient
internal var _EDOM: CInt { 33 }

@_alwaysEmitIntoClient
internal var _ERANGE: CInt { 34 }

@_alwaysEmitIntoClient
internal var _EAGAIN: CInt { 35 }

@_alwaysEmitIntoClient
internal var _EWOULDBLOCK: CInt { _EAGAIN }

@_alwaysEmitIntoClient
internal var _EINPROGRESS: CInt { 36 }

@_alwaysEmitIntoClient
internal var _EALREADY: CInt { 37 }

@_alwaysEmitIntoClient
internal var _ENOTSOCK: CInt { 38 }

@_alwaysEmitIntoClient
internal var _EDESTADDRREQ: CInt { 39 }

@_alwaysEmitIntoClient
internal var _EMSGSIZE: CInt { 40 }

@_alwaysEmitIntoClient
internal var _EPROTOTYPE: CInt { 41 }

@_alwaysEmitIntoClient
internal var _ENOPROTOOPT: CInt { 42 }

@_alwaysEmitIntoClient
internal var _EPROTONOSUPPORT: CInt { 43 }

@_alwaysEmitIntoClient
internal var _ESOCKTNOSUPPORT: CInt { 44 }

@_alwaysEmitIntoClient
internal var _ENOTSUP: CInt { 45 }

@_alwaysEmitIntoClient
internal var _EPFNOSUPPORT: CInt { 46 }

@_alwaysEmitIntoClient
internal var _EAFNOSUPPORT: CInt { 47 }

@_alwaysEmitIntoClient
internal var _EADDRINUSE: CInt { 48 }

@_alwaysEmitIntoClient
internal var _EADDRNOTAVAIL: CInt { 49 }

@_alwaysEmitIntoClient
internal var _ENETDOWN: CInt { 50 }

@_alwaysEmitIntoClient
internal var _ENETUNREACH: CInt { 51 }

@_alwaysEmitIntoClient
internal var _ENETRESET: CInt { 52 }

@_alwaysEmitIntoClient
internal var _ECONNABORTED: CInt { 53 }

@_alwaysEmitIntoClient
internal var _ECONNRESET: CInt { 54 }

@_alwaysEmitIntoClient
internal var _ENOBUFS: CInt { 55 }

@_alwaysEmitIntoClient
internal var _EISCONN: CInt { 56 }

@_alwaysEmitIntoClient
internal var _ENOTCONN: CInt { 57 }

@_alwaysEmitIntoClient
internal var _ESHUTDOWN: CInt { 58 }

@_alwaysEmitIntoClient
internal var _ETOOMANYREFS: CInt { 59 }

@_alwaysEmitIntoClient
internal var _ETIMEDOUT: CInt { 60 }

@_alwaysEmitIntoClient
internal var _ECONNREFUSED: CInt { 61 }

@_alwaysEmitIntoClient
internal var _ELOOP: CInt { 62 }

@_alwaysEmitIntoClient
internal var _ENAMETOOLONG: CInt { 63 }

@_alwaysEmitIntoClient
internal var _EHOSTDOWN: CInt { 64 }

@_alwaysEmitIntoClient
internal var _EHOSTUNREACH: CInt { 65 }

@_alwaysEmitIntoClient
internal var _ENOTEMPTY: CInt { 66 }

@_alwaysEmitIntoClient
internal var _EPROCLIM: CInt { 67 }

@_alwaysEmitIntoClient
internal var _EUSERS: CInt { 68 }

@_alwaysEmitIntoClient
internal var _EDQUOT: CInt { 69 }

@_alwaysEmitIntoClient
internal var _ESTALE: CInt { 70 }

@_alwaysEmitIntoClient
internal var _EREMOTE: CInt { 71 }

@_alwaysEmitIntoClient
internal var _EBADRPC: CInt { 72 }

@_alwaysEmitIntoClient
internal var _ERPCMISMATCH: CInt { 73 }

@_alwaysEmitIntoClient
internal var _EPROGUNAVAIL: CInt { 74 }

@_alwaysEmitIntoClient
internal var _EPROGMISMATCH: CInt { 75 }

@_alwaysEmitIntoClient
internal var _EPROCUNAVAIL: CInt { 76 }

@_alwaysEmitIntoClient
internal var _ENOLCK: CInt { 77 }

@_alwaysEmitIntoClient
internal var _ENOSYS: CInt { 78 }

@_alwaysEmitIntoClient
internal var _EFTYPE: CInt { 79 }

@_alwaysEmitIntoClient
internal var _EAUTH: CInt { 80 }

@_alwaysEmitIntoClient
internal var _ENEEDAUTH: CInt { 81 }

@_alwaysEmitIntoClient
internal var _EPWROFF: CInt { 82 }

@_alwaysEmitIntoClient
internal var _EDEVERR: CInt { 83 }

@_alwaysEmitIntoClient
internal var _EOVERFLOW: CInt { 84 }

@_alwaysEmitIntoClient
internal var _EBADEXEC: CInt { 85 }

@_alwaysEmitIntoClient
internal var _EBADARCH: CInt { 86 }

@_alwaysEmitIntoClient
internal var _ESHLIBVERS: CInt { 87 }

@_alwaysEmitIntoClient
internal var _EBADMACHO: CInt { 88 }

@_alwaysEmitIntoClient
internal var _ECANCELED: CInt { 89 }

@_alwaysEmitIntoClient
internal var _EIDRM: CInt { 90 }

@_alwaysEmitIntoClient
internal var _ENOMSG: CInt { 91 }

@_alwaysEmitIntoClient
internal var _EILSEQ: CInt { 92 }

@_alwaysEmitIntoClient
internal var _ENOATTR: CInt { 93 }

@_alwaysEmitIntoClient
internal var _EBADMSG: CInt { 94 }

@_alwaysEmitIntoClient
internal var _EMULTIHOP: CInt { 95 }

@_alwaysEmitIntoClient
internal var _ENODATA: CInt { 96 }

@_alwaysEmitIntoClient
internal var _ENOLINK: CInt { 97 }

@_alwaysEmitIntoClient
internal var _ENOSR: CInt { 98 }

@_alwaysEmitIntoClient
internal var _ENOSTR: CInt { 99 }

@_alwaysEmitIntoClient
internal var _EPROTO: CInt { 100 }

@_alwaysEmitIntoClient
internal var _ETIME: CInt { 101 }

@_alwaysEmitIntoClient
internal var _EOPNOTSUPP: CInt { 102 }

@_alwaysEmitIntoClient
internal var _ENOPOLICY: CInt { 103 }

@_alwaysEmitIntoClient
internal var _ENOTRECOVERABLE: CInt { 104 }

@_alwaysEmitIntoClient
internal var _EOWNERDEAD: CInt { 105 }

@_alwaysEmitIntoClient
internal var _EQFULL: CInt { 106 }

@_alwaysEmitIntoClient
internal var _ELAST: CInt { 106 }

// MARK: File Operations

@_alwaysEmitIntoClient
internal var _O_RDONLY: CInt { 0x0000 }

@_alwaysEmitIntoClient
internal var _O_WRONLY: CInt { 0x0001 }

@_alwaysEmitIntoClient
internal var _O_RDWR: CInt { 0x0002 }

// TODO: API?
@_alwaysEmitIntoClient
internal var _O_ACCMODE: CInt { 0x0003 }

@_alwaysEmitIntoClient
internal var _O_NONBLOCK: CInt { 0x0004 }

@_alwaysEmitIntoClient
internal var _O_APPEND: CInt { 0x0008 }

@_alwaysEmitIntoClient
internal var _O_SHLOCK: CInt { 0x0010 }

@_alwaysEmitIntoClient
internal var _O_EXLOCK: CInt { 0x0020 }

// TODO: API?
@_alwaysEmitIntoClient
internal var _O_ASYNC: CInt { 0x0040 }

@_alwaysEmitIntoClient
internal var _O_NOFOLLOW: CInt { 0x0100 }

@_alwaysEmitIntoClient
internal var _O_CREAT: CInt { 0x0200 }

@_alwaysEmitIntoClient
internal var _O_TRUNC: CInt { 0x0400 }

@_alwaysEmitIntoClient
internal var _O_EXCL: CInt { 0x0800 }

@_alwaysEmitIntoClient
internal var _O_EVTONLY: CInt { 0x8000 }

// TODO: API?
@_alwaysEmitIntoClient
internal var _O_NOCTTY: CInt { 0x20000 }

// TODO: API?
@_alwaysEmitIntoClient
internal var _O_DIRECTORY: CInt { 0x100000 }

@_alwaysEmitIntoClient
internal var _O_SYMLINK: CInt { 0x200000 }

@_alwaysEmitIntoClient
internal var _O_CLOEXEC: CInt { 0x1000000 }

// TODO: API?
@_alwaysEmitIntoClient
internal var _O_DP_GETRAWENCRYPTED: CInt { 0x0001 }

// TODO: API?
@_alwaysEmitIntoClient
internal var _O_DP_GETRAWUNENCRYPTED: CInt { 0x0002 }

@_alwaysEmitIntoClient
internal var _SEEK_SET: CInt { 0 }

@_alwaysEmitIntoClient
internal var _SEEK_CUR: CInt { 1 }

@_alwaysEmitIntoClient
internal var _SEEK_END: CInt { 2 }

@_alwaysEmitIntoClient
internal var _SEEK_HOLE: CInt { 3 }

@_alwaysEmitIntoClient
internal var _SEEK_DATA: CInt { 4 }

#endif
