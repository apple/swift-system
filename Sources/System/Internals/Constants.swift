/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
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

// TODO: API?
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

@_alwaysEmitIntoClient
internal var _PF_LOCAL: CInt { PF_LOCAL }

@_alwaysEmitIntoClient
internal var _PF_UNIX: CInt { PF_UNIX }

@_alwaysEmitIntoClient
internal var _PF_INET: CInt { PF_INET }

@_alwaysEmitIntoClient
internal var _PF_ROUTE: CInt { PF_ROUTE }

@_alwaysEmitIntoClient
internal var _PF_KEY: CInt { PF_KEY }

@_alwaysEmitIntoClient
internal var _PF_INET6: CInt { PF_INET6 }

@_alwaysEmitIntoClient
internal var _PF_SYSTEM: CInt { PF_SYSTEM }

@_alwaysEmitIntoClient
internal var _PF_NDRV: CInt { PF_NDRV }

@_alwaysEmitIntoClient
internal var _SOCK_STREAM: CInt { SOCK_STREAM }

@_alwaysEmitIntoClient
internal var _SOCK_DGRAM: CInt { SOCK_DGRAM }

@_alwaysEmitIntoClient
internal var _SOCK_RAW: CInt { SOCK_RAW }

@_alwaysEmitIntoClient
internal var _MSG_OOB: CInt { MSG_OOB }

@_alwaysEmitIntoClient
internal var _MSG_DONTROUTE: CInt { MSG_DONTROUTE }

@_alwaysEmitIntoClient
internal var _MSG_PEEK: CInt { MSG_PEEK }

@_alwaysEmitIntoClient
internal var _MSG_WAITALL: CInt { MSG_WAITALL }

@_alwaysEmitIntoClient
internal var _SHUT_RD: CInt { SHUT_RD }

@_alwaysEmitIntoClient
internal var _SHUT_WR: CInt { SHUT_WR }

@_alwaysEmitIntoClient
internal var _SHUT_RDWR: CInt { SHUT_RDWR }

@_alwaysEmitIntoClient
internal var _SO_DEBUG: CInt { SO_DEBUG }

@_alwaysEmitIntoClient
internal var _SO_REUSEADDR: CInt { SO_REUSEADDR }

@_alwaysEmitIntoClient
internal var _SO_REUSEPORT: CInt { SO_REUSEPORT }

@_alwaysEmitIntoClient
internal var _SO_KEEPALIVE: CInt { SO_KEEPALIVE }

@_alwaysEmitIntoClient
internal var _SO_DONTROUTE: CInt { SO_DONTROUTE }

@_alwaysEmitIntoClient
internal var _SO_LINGER: CInt { SO_LINGER }

@_alwaysEmitIntoClient
internal var _SO_BROADCAST: CInt { SO_BROADCAST }

@_alwaysEmitIntoClient
internal var _SO_OOBINLINE: CInt { SO_OOBINLINE }

@_alwaysEmitIntoClient
internal var _SO_SNDBUF: CInt { SO_SNDBUF }

@_alwaysEmitIntoClient
internal var _SO_RCVBUF: CInt { SO_RCVBUF }

@_alwaysEmitIntoClient
internal var _SO_SNDLOWAT: CInt { SO_SNDLOWAT }

@_alwaysEmitIntoClient
internal var _SO_RCVLOWAT: CInt { SO_RCVLOWAT }

@_alwaysEmitIntoClient
internal var _SO_SNDTIMEO: CInt { SO_SNDTIMEO }

@_alwaysEmitIntoClient
internal var _SO_RCVTIMEO: CInt { SO_RCVTIMEO }

@_alwaysEmitIntoClient
internal var _SO_TYPE: CInt { SO_TYPE }

@_alwaysEmitIntoClient
internal var _SO_ERROR: CInt { SO_ERROR }

@_alwaysEmitIntoClient
internal var _SO_NOSIGPIPE: CInt { SO_NOSIGPIPE }

@_alwaysEmitIntoClient
internal var _SO_NREAD: CInt { SO_NREAD }

@_alwaysEmitIntoClient
internal var _SO_NWRITE: CInt { SO_NWRITE }

@_alwaysEmitIntoClient
internal var _SO_LINGER_SEC: CInt { SO_LINGER_SEC }

@_alwaysEmitIntoClient
internal var _TCP_NODELAY: CInt { TCP_NODELAY }

@_alwaysEmitIntoClient
internal var _TCP_MAXSEG: CInt { TCP_MAXSEG }

@_alwaysEmitIntoClient
internal var _TCP_NOOPT: CInt { TCP_NOOPT }

@_alwaysEmitIntoClient
internal var _TCP_NOPUSH: CInt { TCP_NOPUSH }

@_alwaysEmitIntoClient
internal var _TCP_KEEPALIVE: CInt { TCP_KEEPALIVE }

@_alwaysEmitIntoClient
internal var _TCP_CONNECTIONTIMEOUT: CInt { TCP_CONNECTIONTIMEOUT }

@_alwaysEmitIntoClient
internal var _TCP_KEEPINTVL: CInt { TCP_KEEPINTVL }

@_alwaysEmitIntoClient
internal var _TCP_KEEPCNT: CInt { TCP_KEEPCNT }

@_alwaysEmitIntoClient
internal var _TCP_SENDMOREACKS: CInt { TCP_SENDMOREACKS }

@_alwaysEmitIntoClient
internal var _TCP_ENABLE_ECN: CInt { TCP_ENABLE_ECN }

@_alwaysEmitIntoClient
internal var _TCP_NOTSENT_LOWAT: CInt { TCP_NOTSENT_LOWAT }

@_alwaysEmitIntoClient
internal var _TCP_FASTOPEN: CInt { TCP_FASTOPEN }

@_alwaysEmitIntoClient
internal var _TCP_CONNECTION_INFO: CInt { TCP_CONNECTION_INFO }

@_alwaysEmitIntoClient
internal var _IP_OPTIONS: CInt { IP_OPTIONS }

@_alwaysEmitIntoClient
internal var _IP_TOS: CInt { IP_TOS }

@_alwaysEmitIntoClient
internal var _IP_TTL: CInt { IP_TTL }

@_alwaysEmitIntoClient
internal var _IP_RECVDSTADDR: CInt { IP_RECVDSTADDR }

@_alwaysEmitIntoClient
internal var _IP_RECVTOS: CInt { IP_RECVTOS }

@_alwaysEmitIntoClient
internal var _IP_MULTICAST_TTL: CInt { IP_MULTICAST_TTL }

@_alwaysEmitIntoClient
internal var _IP_MULTICAST_IF: CInt { IP_MULTICAST_IF }

@_alwaysEmitIntoClient
internal var _IP_MULTICAST_LOOP: CInt { IP_MULTICAST_LOOP }

@_alwaysEmitIntoClient
internal var _IP_ADD_MEMBERSHIP: CInt { IP_ADD_MEMBERSHIP }

@_alwaysEmitIntoClient
internal var _IP_DROP_MEMBERSHIP: CInt { IP_DROP_MEMBERSHIP }

@_alwaysEmitIntoClient
internal var _IP_HDRINCL: CInt { IP_HDRINCL }

@_alwaysEmitIntoClient
internal var _IPV6_UNICAST_HOPS: CInt { IPV6_UNICAST_HOPS }

@_alwaysEmitIntoClient
internal var _IPV6_MULTICAST_IF: CInt { IPV6_MULTICAST_IF }

@_alwaysEmitIntoClient
internal var _IPV6_MULTICAST_HOPS: CInt { IPV6_MULTICAST_HOPS }

@_alwaysEmitIntoClient
internal var _IPV6_MULTICAST_LOOP: CInt { IPV6_MULTICAST_LOOP }

@_alwaysEmitIntoClient
internal var _IPV6_JOIN_GROUP: CInt { IPV6_JOIN_GROUP }

@_alwaysEmitIntoClient
internal var _IPV6_LEAVE_GROUP: CInt { IPV6_LEAVE_GROUP }

@_alwaysEmitIntoClient
internal var _IPV6_PORTRANGE: CInt { IPV6_PORTRANGE }

//@_alwaysEmitIntoClient
//internal var _IPV6_PKTINFO: CInt { IPV6_PKTINFO }
//
//@_alwaysEmitIntoClient
//internal var _IPV6_HOPLIMIT: CInt { IPV6_HOPLIMIT }
//
//@_alwaysEmitIntoClient
//internal var _IPV6_HOPOPTS: CInt { IPV6_HOPOPTS }
//
//@_alwaysEmitIntoClient
//internal var _IPV6_DSTOPTS: CInt { IPV6_DSTOPTS }

@_alwaysEmitIntoClient
internal var _IPV6_TCLASS: CInt { IPV6_TCLASS }

@_alwaysEmitIntoClient
internal var _IPV6_RECVTCLASS: CInt { IPV6_RECVTCLASS }

//@_alwaysEmitIntoClient
//internal var _IPV6_RTHDR: CInt { IPV6_RTHDR }
//
//@_alwaysEmitIntoClient
//internal var _IPV6_PKTOPTIONS: CInt { IPV6_PKTOPTIONS }

@_alwaysEmitIntoClient
internal var _IPV6_CHECKSUM: CInt { IPV6_CHECKSUM }

@_alwaysEmitIntoClient
internal var _IPV6_V6ONLY: CInt { IPV6_V6ONLY }

//@_alwaysEmitIntoClient
//internal var _IPV6_USE_MIN_MTU: CInt { IPV6_USE_MIN_MTU }

@_alwaysEmitIntoClient
internal var _IPPROTO_IP: CInt { IPPROTO_IP }

@_alwaysEmitIntoClient
internal var _IPPROTO_IPV6: CInt { IPPROTO_IPV6 }

@_alwaysEmitIntoClient
internal var _IPPROTO_TCP: CInt { IPPROTO_TCP }

@_alwaysEmitIntoClient
internal var _SOL_SOCKET: CInt { SOL_SOCKET }

@_alwaysEmitIntoClient
internal var _INET_ADDRSTRLEN: CInt { INET_ADDRSTRLEN }

@_alwaysEmitIntoClient
internal var _INET6_ADDRSTRLEN: CInt { INET6_ADDRSTRLEN }
