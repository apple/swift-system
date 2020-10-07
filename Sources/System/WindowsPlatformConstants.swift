/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Windows)

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
internal var _EAGAIN: CInt { 11 }

@_alwaysEmitIntoClient
internal var _ENOMEM: CInt { 12 }

@_alwaysEmitIntoClient
internal var _EACCES: CInt { 13 }

@_alwaysEmitIntoClient
internal var _EFAULT: CInt { 14 }

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
internal var _ENOTIFY: CInt { 25 }

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
internal var _EDEADLK: CInt { 36 }

@_alwaysEmitIntoClient
internal var _EDEADLOCK: CInt { 36 }

@_alwaysEmitIntoClient
internal var _ENAMETOOLONG: CInt { 38 }

@_alwaysEmitIntoClient
internal var _ENOLCK: CInt { 39 }

@_alwaysEmitIntoClient
internal var _ENOSYS: CInt { 40 }

@_alwaysEmitIntoClient
internal var _ENOTEMPTY: CInt { 41 }

@_alwaysEmitIntoClient
internal var _EILSEQ: CInt { 42 }

@_alwaysEmitIntoClient
internal var _STRUNCATE: CInt { 80 }


@_alwaysEmitIntoClient
internal var _O_RDONLY: CInt { 0x0000 }

@_alwaysEmitIntoClient
internal var _O_WRONLY: CInt { 0x0001 }

@_alwaysEmitIntoClient
internal var _O_RDWR: CInt { 0x0002 }

@_alwaysEmitIntoClient
internal var _O_APPEND: CInt { 0x0008 }

@_alwaysEmitIntoClient
internal var _O_CREAT: CInt { 0x0100 }

@_alwaysEmitIntoClient
internal var _O_TRUNC: CInt { 0x0200 }

@_alwaysEmitIntoClient
internal var _O_EXCL: CInt { 0x0400 }


@_alwaysEmitIntoClient
internal var _SEEK_SET: CInt { 0 }

@_alwaysEmitIntoClient
internal var _SEEK_CUR: CInt { 1 }

@_alwaysEmitIntoClient
internal var _SEEK_END: CInt { 2 }


// WinSock2

@_alwaysEmitIntoClient
internal var __EINTR: CInt { 10004 }

@_alwaysEmitIntoClient
internal var __EBADF: CInt { 10009 }

@_alwaysEmitIntoClient
internal var __EACCES: CInt { 10013 }

@_alwaysEmitIntoClient
internal var __EFAULT: CInt { 10014 }

@_alwaysEmitIntoClient
internal var __EINVAL: CInt { 10022 }

@_alwaysEmitIntoClient
internal var __EMFILE: CInt { 10024 }


@_alwaysEmitIntoClient
internal var _EWOULDBLOCK: CInt { 10035 }

@_alwaysEmitIntoClient
internal var _EINPROGRESS: CInt { 10036 }

@_alwaysEmitIntoClient
internal var _EALREADY: CInt { 10037 }

@_alwaysEmitIntoClient
internal var _ENOTSOCK: CInt { 10038 }

@_alwaysEmitIntoClient
internal var _EDESTADDRREQ: CInt { 10039 }

@_alwaysEmitIntoClient
internal var _EMSGSIZE: CInt { 10040 }

@_alwaysEmitIntoClient
internal var _EPROTOTYPE: CInt { 10041 }

@_alwaysEmitIntoClient
internal var _ENOPROTOOPT: CInt { 10042 }

@_alwaysEmitIntoClient
internal var _EPROTONOSUPPORT: CInt { 10043 }

@_alwaysEmitIntoClient
internal var _ESOCKTNOSUPPORT: CInt { 10044 }

@_alwaysEmitIntoClient
internal var _EOPNOTSUPP: CInt { 10045 }

@_alwaysEmitIntoClient
internal var _EPFNOSUPPORT: CInt { 10046 }

@_alwaysEmitIntoClient
internal var _EAFNOSUPPORT: CInt { 10047 }

@_alwaysEmitIntoClient
internal var _EADDRINUSE: CInt { 10048 }

@_alwaysEmitIntoClient
internal var _EADDRNOTAVAIL: CInt { 10049 }

@_alwaysEmitIntoClient
internal var _ENETDOWN: CInt { 10050 }

@_alwaysEmitIntoClient
internal var _ENETUNREACH: CInt { 10051 }

@_alwaysEmitIntoClient
internal var _ENETRESET: CInt { 10052 }

@_alwaysEmitIntoClient
internal var _ECONNABORTED: CInt { 10053 }

@_alwaysEmitIntoClient
internal var _ECONNRESET: CInt { 10054 }

@_alwaysEmitIntoClient
internal var _ENOBUFS: CInt { 10055 }

@_alwaysEmitIntoClient
internal var _EISCONN: CInt { 10056 }

@_alwaysEmitIntoClient
internal var _ENOTCONN: CInt { 10057 }

@_alwaysEmitIntoClient
internal var _ESHUTDOWN: CInt { 10058 }

@_alwaysEmitIntoClient
internal var _ETOOMANYREFS: CInt { 10059 }

@_alwaysEmitIntoClient
internal var _ETIMEDOUT: CInt { 10060 }

@_alwaysEmitIntoClient
internal var _ECONNREFUSED: CInt { 10061 }

@_alwaysEmitIntoClient
internal var _ELOOP: CInt { 10062 }

@_alwaysEmitIntoClient
internal var __ENAMETOOLONG: CInt { 10063 }

@_alwaysEmitIntoClient
internal var _EHOSTDOWN: CInt { 10064 }

@_alwaysEmitIntoClient
internal var _EHOSTUNREACH: CInt { 10065 }

@_alwaysEmitIntoClient
internal var __ENOTEMPTY: CInt { 10066 }

@_alwaysEmitIntoClient
internal var _EPROCLIM: CInt { 10067 }

@_alwaysEmitIntoClient
internal var _EUSERS: CInt { 10068 }

@_alwaysEmitIntoClient
internal var _EDQUOT: CInt { 10069 }

@_alwaysEmitIntoClient
internal var _ESTALE: CInt { 10070 }

@_alwaysEmitIntoClient
internal var _EREMOTE: CInt { 10071 }

// WSASYSNOTREADY = 10091
// WSAVERNOTSUPPORTED = 10092
// WSANOTINITIALIZED = 10093

@_alwaysEmitIntoClient
internal var _EDISCON: CInt { 10101 }

@_alwaysEmitIntoClient
internal var _ENOMORE: CInt { 10102 }

@_alwaysEmitIntoClient
internal var _ECANCELED: CInt { 10103 }

@_alwaysEmitIntoClient
internal var _EINVALIDPROCTABLE: CInt { 10104 }

@_alwaysEmitIntoClient
internal var _EINVALIDPROVIDER: CInt { 10105 }

@_alwaysEmitIntoClient
internal var _EPROVIDERFAILEDINIT: CInt { 10106 }

// WSASYSCALLFAILURE = 10107
// WSASERVICE_NOT_FOUND = 10108
// WSATYPE_NOT_FOUND = 10109
// WSA_E_NO_MORE = 10110
// WSA_E_CANCELLED = 10111

@_alwaysEmitIntoClient
internal var _EREFUSED: CInt { 10112 }

#endif
