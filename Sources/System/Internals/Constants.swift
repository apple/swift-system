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

@_alwaysEmitIntoClient
internal var _POLLIN: CInt { POLLIN }

@_alwaysEmitIntoClient
internal var _POLLPRI: CInt { POLLPRI }

@_alwaysEmitIntoClient
internal var _POLLOUT: CInt { POLLOUT }

@_alwaysEmitIntoClient
internal var _POLLRDNORM: CInt { POLLRDNORM }

@_alwaysEmitIntoClient
internal var _POLLWRNORM: CInt { POLLWRNORM }

@_alwaysEmitIntoClient
internal var _POLLRDBAND: CInt { POLLRDBAND }

@_alwaysEmitIntoClient
internal var _POLLWRBAND: CInt { POLLWRBAND }

@_alwaysEmitIntoClient
internal var _POLLERR: CInt { POLLERR }

@_alwaysEmitIntoClient
internal var _POLLHUP: CInt { POLLHUP }

@_alwaysEmitIntoClient
internal var _POLLNVAL: CInt { POLLNVAL }

@_alwaysEmitIntoClient
internal var _INET_ADDRSTRLEN: CInt { INET_ADDRSTRLEN }

@_alwaysEmitIntoClient
internal var _INET6_ADDRSTRLEN: CInt { INET6_ADDRSTRLEN }

@_alwaysEmitIntoClient
internal var _INADDR_ANY: CInterop.IPv4Address {  CInterop.IPv4Address(s_addr: INADDR_ANY) }

@_alwaysEmitIntoClient
internal var _INADDR_LOOPBACK: CInterop.IPv4Address {  CInterop.IPv4Address(s_addr: INADDR_LOOPBACK) }

@_alwaysEmitIntoClient
internal var _INADDR6_ANY: CInterop.IPv6Address { in6addr_any }

@_alwaysEmitIntoClient
internal var _INADDR6_LOOPBACK: CInterop.IPv6Address { in6addr_loopback }

@_alwaysEmitIntoClient
internal var _AF_UNIX: CInt { AF_UNIX }

@_alwaysEmitIntoClient
internal var _AF_INET: CInt { AF_INET }

@_alwaysEmitIntoClient
internal var _AF_INET6: CInt { AF_INET6 }

@_alwaysEmitIntoClient
internal var _AF_IPX: CInt { AF_IPX }

@_alwaysEmitIntoClient
internal var _AF_APPLETALK: CInt { AF_APPLETALK }

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _AF_DECnet: CInt { AF_DECnet }

@_alwaysEmitIntoClient
internal var _AF_VSOCK: CInt { AF_VSOCK }

@_alwaysEmitIntoClient
internal var _AF_ISDN: CInt { AF_ISDN }
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _AF_IMPLINK: CInt { AF_IMPLINK }

@_alwaysEmitIntoClient
internal var _AF_PUP: CInt { AF_PUP }

@_alwaysEmitIntoClient
internal var _AF_CHAOS: CInt { AF_CHAOS }

@_alwaysEmitIntoClient
internal var _AF_NS: CInt { AF_NS }

@_alwaysEmitIntoClient
internal var _AF_ISO: CInt { AF_ISO }

@_alwaysEmitIntoClient
internal var _AF_PPP: CInt { AF_PPP }

@_alwaysEmitIntoClient
internal var _AF_LINK: CInt { AF_LINK }

@_alwaysEmitIntoClient
internal var _AF_NETBIOS: CInt { AF_NETBIOS }
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _AF_AX25: CInt { AF_AX25 }

@_alwaysEmitIntoClient
internal var _AF_X25: CInt { AF_X25 }

@_alwaysEmitIntoClient
internal var _AF_KEY: CInt { AF_KEY }

@_alwaysEmitIntoClient
internal var _AF_NETLINK: CInt { AF_NETLINK }

@_alwaysEmitIntoClient
internal var _AF_PACKET: CInt { AF_PACKET }

@_alwaysEmitIntoClient
internal var _AF_ATMSVC: CInt { AF_ATMSVC }

@_alwaysEmitIntoClient
internal var _AF_RDS: CInt { AF_RDS }

@_alwaysEmitIntoClient
internal var _AF_PPPOX: CInt { AF_PPPOX }

@_alwaysEmitIntoClient
internal var _AF_WANPIPE: CInt { AF_WANPIPE }

@_alwaysEmitIntoClient
internal var _AF_LLC: CInt { AF_LLC }

@_alwaysEmitIntoClient
internal var _AF_IB: CInt { AF_IB }

@_alwaysEmitIntoClient
internal var _AF_MPLS: CInt { AF_MPLS }

@_alwaysEmitIntoClient
internal var _AF_CAN: CInt { AF_CAN }

@_alwaysEmitIntoClient
internal var _AF_TIPC: CInt { AF_TIPC }

@_alwaysEmitIntoClient
internal var _AF_BLUETOOTH: CInt { AF_BLUETOOTH }

@_alwaysEmitIntoClient
internal var _AF_IUCV: CInt { AF_IUCV }

@_alwaysEmitIntoClient
internal var _AF_RXRPC: CInt { AF_RXRPC }

@_alwaysEmitIntoClient
internal var _AF_PHONET: CInt { AF_PHONET }

@_alwaysEmitIntoClient
internal var _AF_IEEE802154: CInt { AF_IEEE802154 }

@_alwaysEmitIntoClient
internal var _AF_CAIF: CInt { AF_CAIF }

@_alwaysEmitIntoClient
internal var _AF_ALG: CInt { AF_ALG }

@_alwaysEmitIntoClient
internal var _AF_KCM: CInt { AF_KCM }

@_alwaysEmitIntoClient
internal var _AF_QIPCRTR: CInt { AF_QIPCRTR }

@_alwaysEmitIntoClient
internal var _AF_SMC: CInt { AF_SMC }

@_alwaysEmitIntoClient
internal var _AF_XDP: CInt { AF_XDP }
#endif

#if os(Windows)
@_alwaysEmitIntoClient
internal var _AF_IRDA: CInt { AF_IRDA }

@_alwaysEmitIntoClient
internal var _AF_BTH: CInt { AF_BTH }
#endif

@_alwaysEmitIntoClient
internal var _SOCK_STREAM: CInterop.SocketType { SOCK_STREAM }

@_alwaysEmitIntoClient
internal var _SOCK_DGRAM: CInterop.SocketType { SOCK_DGRAM }

@_alwaysEmitIntoClient
internal var _SOCK_RAW: CInterop.SocketType { SOCK_RAW }

@_alwaysEmitIntoClient
internal var _SOCK_RDM: CInterop.SocketType { SOCK_RDM }

@_alwaysEmitIntoClient
internal var _SOCK_SEQPACKET: CInterop.SocketType { SOCK_SEQPACKET }

#if os(Linux)
@_alwaysEmitIntoClient
internal var _SOCK_DCCP: CInterop.SocketType { SOCK_DCCP }

@_alwaysEmitIntoClient
internal var _SOCK_CLOEXEC: CInterop.SocketType { SOCK_CLOEXEC }

@_alwaysEmitIntoClient
internal var _SOCK_NONBLOCK: CInterop.SocketType { SOCK_NONBLOCK }
#endif

@_alwaysEmitIntoClient
internal var _IPPROTO_RAW: CInt { numericCast(IPPROTO_RAW) }

@_alwaysEmitIntoClient
internal var _IPPROTO_TCP: CInt { numericCast(IPPROTO_TCP) }

@_alwaysEmitIntoClient
internal var _IPPROTO_UDP: CInt { numericCast(IPPROTO_UDP) }

@_alwaysEmitIntoClient
internal var _SOL_SOCKET: CInt { SOL_SOCKET }

@_alwaysEmitIntoClient
internal var _SO_DEBUG: CInt { SO_DEBUG }

@_alwaysEmitIntoClient
internal var _SO_ACCEPTCONN: CInt { SO_ACCEPTCONN }

@_alwaysEmitIntoClient
internal var _SO_REUSEADDR: CInt { SO_REUSEADDR }

@_alwaysEmitIntoClient
internal var _SO_KEEPALIVE: CInt { SO_KEEPALIVE }

@_alwaysEmitIntoClient
internal var _SO_DONTROUTE: CInt { SO_DONTROUTE }

@_alwaysEmitIntoClient
internal var _SO_BROADCAST: CInt { SO_BROADCAST }
  
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _SO_USELOOPBACK: CInt { SO_USELOOPBACK }
#endif

@_alwaysEmitIntoClient
internal var _SO_LINGER: CInt { SO_LINGER }

#if os(Linux)
@_alwaysEmitIntoClient
internal var _SOL_NETLINK: CInt { SOL_NETLINK }

@_alwaysEmitIntoClient
internal var _SOL_BLUETOOTH: CInt { SOL_BLUETOOTH }

@_alwaysEmitIntoClient
internal var _SOL_L2CAP: CInt { 6 }
#endif

@_alwaysEmitIntoClient
internal var _MSG_DONTROUTE: CInt { numericCast(MSG_DONTROUTE) } /* send without using routing tables */

@_alwaysEmitIntoClient
internal var _MSG_EOR: CInt { numericCast(MSG_EOR) } /* data completes record */

@_alwaysEmitIntoClient
internal var _MSG_OOB: CInt { numericCast(MSG_OOB) } /* process out-of-band data */

@_alwaysEmitIntoClient
internal var _MSG_PEEK: CInt { numericCast(MSG_PEEK) } /* peek at incoming message */
@_alwaysEmitIntoClient
internal var _MSG_TRUNC: CInt { numericCast(MSG_TRUNC) } /* data discarded before delivery */
@_alwaysEmitIntoClient
internal var _MSG_CTRUNC: CInt { numericCast(MSG_CTRUNC) } /* control data lost before delivery */
@_alwaysEmitIntoClient
internal var _MSG_WAITALL: CInt { numericCast(MSG_WAITALL) } /* wait for full request or error */

@_alwaysEmitIntoClient
internal var _MSG_DONTWAIT: CInt { numericCast(MSG_DONTWAIT) } /* this message should be nonblocking */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
@_alwaysEmitIntoClient
internal var _MSG_EOF: CInt { numericCast(MSG_EOF) } /* data completes connection */

@_alwaysEmitIntoClient
internal var _MSG_WAITSTREAM: CInt { numericCast(MSG_WAITSTREAM) } /* wait up to full request.. may return partial */

@_alwaysEmitIntoClient
internal var _MSG_FLUSH: CInt { numericCast(MSG_FLUSH) } /* Start of 'hold' seq; dump so_temp, deprecated */
@_alwaysEmitIntoClient
internal var _MSG_HOLD: CInt { numericCast(MSG_HOLD) } /* Hold frag in so_temp, deprecated */
@_alwaysEmitIntoClient
internal var _MSG_SEND: CInt { numericCast(MSG_SEND) } /* Send the packet in so_temp, deprecated */
@_alwaysEmitIntoClient
internal var _MSG_HAVEMORE: CInt { numericCast(MSG_HAVEMORE) } /* Data ready to be read */
@_alwaysEmitIntoClient
internal var _MSG_RCVMORE: CInt { numericCast(MSG_RCVMORE) } /* Data remains in current pkt */

@_alwaysEmitIntoClient
internal var _MSG_NEEDSA: CInt { numericCast(MSG_NEEDSA) } /* Fail receive if socket address cannot be allocated */

@_alwaysEmitIntoClient
internal var _MSG_NOSIGNAL: CInt { numericCast(MSG_NOSIGNAL) } /* do not generate SIGPIPE on EOF */
#endif

#if os(Linux)
@_alwaysEmitIntoClient
internal var _MSG_CONFIRM: CInt { numericCast(MSG_CONFIRM) }

@_alwaysEmitIntoClient
internal var _MSG_MORE: CInt { numericCast(MSG_MORE) }
#endif

@_alwaysEmitIntoClient
internal var _fd_set_count: Int {
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    // __DARWIN_FD_SETSIZE is number of *bits*, so divide by number bits in each element to get element count
    // at present this is 1024 / 32 == 32
    return Int(__DARWIN_FD_SETSIZE) / 32
#elseif os(Linux) || os(FreeBSD) || os(Android)
#if arch(x86_64) || arch(arm64) || arch(s390x) || arch(powerpc64) || arch(powerpc64le)
    return 32
#elseif arch(i386) || arch(arm)
    return 16
#else
#error("This architecture isn't known. Add it to the 32-bit or 64-bit line.")
#endif
#elseif os(Windows)
    return 32
#endif
}
