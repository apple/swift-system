/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Linux)

// Ugh, this is really bad. For Darwin, we can at least rely on
// these values not changing much, but in theory they could change
// per Linux flavor or version (if no ABI)

// MARK: errno

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
internal var _EDEADLK: CInt { 35 }

@_alwaysEmitIntoClient
internal var _ENAMETOOLONG: CInt { 36 }

@_alwaysEmitIntoClient
internal var _ENOLCK: CInt { 37 }

@_alwaysEmitIntoClient
internal var _ENOSYS: CInt { 38 }

@_alwaysEmitIntoClient
internal var _ENOTEMPTY: CInt { 39 }

@_alwaysEmitIntoClient
internal var _ELOOP: CInt { 40 }

@_alwaysEmitIntoClient
internal var _EWOULDBLOCK: CInt { _EAGAIN }

@_alwaysEmitIntoClient
internal var _ENOMSG: CInt { 42 }

@_alwaysEmitIntoClient
internal var _EIDRM: CInt { 43 }

@_alwaysEmitIntoClient
internal var _ECHRNG: CInt { 44 }

@_alwaysEmitIntoClient
internal var _EL2NSYNC: CInt { 45 }

@_alwaysEmitIntoClient
internal var _EL3HLT: CInt { 46 }

@_alwaysEmitIntoClient
internal var _EL3RST: CInt { 47 }

@_alwaysEmitIntoClient
internal var _ELNRNG: CInt { 48 }

@_alwaysEmitIntoClient
internal var _EUNATCH: CInt { 49 }

@_alwaysEmitIntoClient
internal var _ENOCSI: CInt { 50 }

@_alwaysEmitIntoClient
internal var _EL2HLT: CInt { 51 }

@_alwaysEmitIntoClient
internal var _EBADE: CInt { 52 }

@_alwaysEmitIntoClient
internal var _EBADR: CInt { 53 }

@_alwaysEmitIntoClient
internal var _EXFULL: CInt { 54 }

@_alwaysEmitIntoClient
internal var _ENOANO: CInt { 55 }

@_alwaysEmitIntoClient
internal var _EBADRQC: CInt { 56 }

@_alwaysEmitIntoClient
internal var _EBADSLT: CInt { 57 }

@_alwaysEmitIntoClient
internal var _EDEADLOCK: CInt { _EDEADLK }

@_alwaysEmitIntoClient
internal var _EBFONT: CInt { 59 }

@_alwaysEmitIntoClient
internal var _ENOSTR: CInt { 60 }

@_alwaysEmitIntoClient
internal var _ENODATA: CInt { 61 }

@_alwaysEmitIntoClient
internal var _ETIME: CInt { 62 }

@_alwaysEmitIntoClient
internal var _ENOSR: CInt { 63 }

@_alwaysEmitIntoClient
internal var _ENONET: CInt { 64 }

@_alwaysEmitIntoClient
internal var _ENOPKG: CInt { 65 }

@_alwaysEmitIntoClient
internal var _EREMOTE: CInt { 66 }

@_alwaysEmitIntoClient
internal var _ENOLINK: CInt { 67 }

@_alwaysEmitIntoClient
internal var _EADV: CInt { 68 }

@_alwaysEmitIntoClient
internal var _ESRMNT: CInt { 69 }

@_alwaysEmitIntoClient
internal var _ECOMM: CInt { 70 }

@_alwaysEmitIntoClient
internal var _EPROTO: CInt { 71 }

@_alwaysEmitIntoClient
internal var _EMULTIHOP: CInt { 72 }

@_alwaysEmitIntoClient
internal var _EDOTDOT: CInt { 73 }

@_alwaysEmitIntoClient
internal var _EBADMSG: CInt { 74 }

@_alwaysEmitIntoClient
internal var _EOVERFLOW: CInt { 75 }

@_alwaysEmitIntoClient
internal var _ENOTUNIQ: CInt { 76 }

@_alwaysEmitIntoClient
internal var _EBADFD: CInt { 77 }

@_alwaysEmitIntoClient
internal var _EREMCHG: CInt { 78 }

@_alwaysEmitIntoClient
internal var _ELIBACC: CInt { 79 }

@_alwaysEmitIntoClient
internal var _ELIBBAD: CInt { 80 }

@_alwaysEmitIntoClient
internal var _ELIBSCN: CInt { 81 }

@_alwaysEmitIntoClient
internal var _ELIBMAX: CInt { 82 }

@_alwaysEmitIntoClient
internal var _ELIBEXEC: CInt { 83 }

@_alwaysEmitIntoClient
internal var _EILSEQ: CInt { 84 }

@_alwaysEmitIntoClient
internal var _ERESTART: CInt { 85 }

@_alwaysEmitIntoClient
internal var _ESTRPIPE: CInt { 86 }

@_alwaysEmitIntoClient
internal var _EUSERS: CInt { 87 }

@_alwaysEmitIntoClient
internal var _ENOTSOCK: CInt { 88 }

@_alwaysEmitIntoClient
internal var _EDESTADDRREQ: CInt { 89 }

@_alwaysEmitIntoClient
internal var _EMSGSIZE: CInt { 90 }

@_alwaysEmitIntoClient
internal var _EPROTOTYPE: CInt { 91 }

@_alwaysEmitIntoClient
internal var _ENOPROTOOPT: CInt { 92 }

@_alwaysEmitIntoClient
internal var _EPROTONOSUPPORT: CInt { 93 }

@_alwaysEmitIntoClient
internal var _ESOCKTNOSUPPORT: CInt { 94 }

@_alwaysEmitIntoClient
internal var _EOPNOTSUPP: CInt { 95 }

@_alwaysEmitIntoClient
internal var _ENOTSUP: CInt { _EOPNOTSUPP }

@_alwaysEmitIntoClient
internal var _EPFNOSUPPORT: CInt { 96 }

@_alwaysEmitIntoClient
internal var _EAFNOSUPPORT: CInt { 97 }

@_alwaysEmitIntoClient
internal var _EADDRINUSE: CInt { 98 }

@_alwaysEmitIntoClient
internal var _EADDRNOTAVAIL: CInt { 99 }

@_alwaysEmitIntoClient
internal var _ENETDOWN: CInt { 100 }

@_alwaysEmitIntoClient
internal var _ENETUNREACH: CInt { 101 }

@_alwaysEmitIntoClient
internal var _ENETRESET: CInt { 102 }

@_alwaysEmitIntoClient
internal var _ECONNABORTED: CInt { 103 }

@_alwaysEmitIntoClient
internal var _ECONNRESET: CInt { 104 }

@_alwaysEmitIntoClient
internal var _ENOBUFS: CInt { 105 }

@_alwaysEmitIntoClient
internal var _EISCONN: CInt { 106 }

@_alwaysEmitIntoClient
internal var _ENOTCONN: CInt { 107 }

@_alwaysEmitIntoClient
internal var _ESHUTDOWN: CInt { 108 }

@_alwaysEmitIntoClient
internal var _ETOOMANYREFS: CInt { 109 }

@_alwaysEmitIntoClient
internal var _ETIMEDOUT: CInt { 110 }

@_alwaysEmitIntoClient
internal var _ECONNREFUSED: CInt { 111 }

@_alwaysEmitIntoClient
internal var _EHOSTDOWN: CInt { 112 }

@_alwaysEmitIntoClient
internal var _EHOSTUNREACH: CInt { 113 }

@_alwaysEmitIntoClient
internal var _EALREADY: CInt { 114 }

@_alwaysEmitIntoClient
internal var _EINPROGRESS: CInt { 115 }

@_alwaysEmitIntoClient
internal var _ESTALE: CInt { 116 }

@_alwaysEmitIntoClient
internal var _EUCLEAN: CInt { 117 }

@_alwaysEmitIntoClient
internal var _ENOTNAM: CInt { 118 }

@_alwaysEmitIntoClient
internal var _ENAVAIL: CInt { 119 }

@_alwaysEmitIntoClient
internal var _EISNAM: CInt { 120 }

@_alwaysEmitIntoClient
internal var _EREMOTEIO: CInt { 121 }

@_alwaysEmitIntoClient
internal var _EDQUOT: CInt { 122 }

@_alwaysEmitIntoClient
internal var _ENOMEDIUM: CInt { 123 }

@_alwaysEmitIntoClient
internal var _EMEDIUMTYPE: CInt { 124 }

@_alwaysEmitIntoClient
internal var _ECANCELED: CInt { 125 }

@_alwaysEmitIntoClient
internal var _ENOKEY: CInt { 126 }

@_alwaysEmitIntoClient
internal var _EKEYEXPIRED: CInt { 127 }

@_alwaysEmitIntoClient
internal var _EKEYREVOKED: CInt { 128 }

@_alwaysEmitIntoClient
internal var _EKEYREJECTED: CInt { 129 }

@_alwaysEmitIntoClient
internal var _EOWNERDEAD: CInt { 130 }

@_alwaysEmitIntoClient
internal var _ENOTRECOVERABLE: CInt { 131 }

@_alwaysEmitIntoClient
internal var _ERFKILL: CInt { 132 }

@_alwaysEmitIntoClient
internal var _EHWPOISON: CInt { 133 }


// MARK: File Operations

@_alwaysEmitIntoClient
internal var _O_ACCMODE: CInt { 0o00000003 }

@_alwaysEmitIntoClient
internal var _O_RDONLY: CInt { 0o00000000 }

@_alwaysEmitIntoClient
internal var _O_WRONLY: CInt { 0o00000001 }

@_alwaysEmitIntoClient
internal var _O_RDWR: CInt { 0o00000002 }

@_alwaysEmitIntoClient
internal var _O_CREAT: CInt { 0o00000100 }

@_alwaysEmitIntoClient
internal var _O_EXCL: CInt { 0o00000200 }

@_alwaysEmitIntoClient
internal var _O_NOCTTY: CInt { 0o00000400 }

@_alwaysEmitIntoClient
internal var _O_TRUNC: CInt { 0o00001000 }

@_alwaysEmitIntoClient
internal var _O_APPEND: CInt { 0o00002000 }

@_alwaysEmitIntoClient
internal var _O_NONBLOCK: CInt { 0o00004000 }

@_alwaysEmitIntoClient
internal var _O_DSYNC: CInt { 0o00010000 }

@_alwaysEmitIntoClient
internal var _FASYNC: CInt { 0o00020000 }

@_alwaysEmitIntoClient
internal var _O_DIRECT: CInt { 0o00040000 }

@_alwaysEmitIntoClient
internal var _O_LARGEFILE: CInt { 0o00100000 }

@_alwaysEmitIntoClient
internal var _O_DIRECTORY: CInt { 0o00200000 }

@_alwaysEmitIntoClient
internal var _O_NOFOLLOW: CInt { 0o00400000 }

@_alwaysEmitIntoClient
internal var _O_NOATIME: CInt { 0o01000000 }

@_alwaysEmitIntoClient
internal var _O_CLOEXEC: CInt { 0o02000000 }


@_alwaysEmitIntoClient
internal var _SEEK_SET: CInt { 0 }

@_alwaysEmitIntoClient
internal var _SEEK_CUR: CInt { 1 }

@_alwaysEmitIntoClient
internal var _SEEK_END: CInt { 2 }

#endif
