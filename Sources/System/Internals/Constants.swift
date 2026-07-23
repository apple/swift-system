/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
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
import CSystem
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

@_alwaysEmitIntoClient
internal var _O_CLOEXEC: CInt {
  #if os(Windows)
  O_NOINHERIT
  #else
  O_CLOEXEC
  #endif
}

#if !os(Windows)
@_alwaysEmitIntoClient
internal var _O_CLOFORK: CInt {
  #if !os(WASI) && !os(Linux) && !os(Android) && !canImport(Darwin) && !os(FreeBSD)
  O_CLOFORK
  #elseif os(FreeBSD)
  FREEBSD_O_CLOFORK
  #else
  0
  #endif
}
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
// `S_IFWHT` is `Int32` on FreeBSD.
@_alwaysEmitIntoClient
internal var _S_IFWHT: mode_t { .init(S_IFWHT) }
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

// MARK: - statfs/statvfs Mount Flags

// Darwin and BSD (`statfs`) and other platforms (`statvfs`) use different C
// names (`MNT_*` vs `ST_*`) for the flags they share, so flags are exposed
// here under general `_MOUNT_*` names that resolve per platform.

// MARK: Flags Available on All Platforms

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_RDONLY: CInterop.MountFlags {
  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_RDONLY)
  #elseif os(Linux) || os(Android)
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_RDONLY())
  #else
  CInterop.MountFlags(truncatingIfNeeded: ST_RDONLY)
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_SYNCHRONOUS: CInterop.MountFlags {
  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_SYNCHRONOUS)
  #elseif os(Linux) || os(Android)
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_SYNCHRONOUS())
  #else
  CInterop.MountFlags(truncatingIfNeeded: ST_SYNCHRONOUS)
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_NOEXEC: CInterop.MountFlags {
  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_NOEXEC)
  #elseif os(Linux) || os(Android)
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_NOEXEC())
  #else
  CInterop.MountFlags(truncatingIfNeeded: ST_NOEXEC)
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_NOSUID: CInterop.MountFlags {
  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_NOSUID)
  #elseif os(Linux) || os(Android)
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_NOSUID())
  #else
  CInterop.MountFlags(truncatingIfNeeded: ST_NOSUID)
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_NOATIME: CInterop.MountFlags {
  #if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_NOATIME)
  #elseif os(Linux) || os(Android)
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_NOATIME())
  #else
  CInterop.MountFlags(truncatingIfNeeded: ST_NOATIME)
  #endif
}

// MARK: Flags Available on All Platforms Except FreeBSD

#if !os(FreeBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_NODEV: CInterop.MountFlags {
  #if SYSTEM_PACKAGE_DARWIN || os(OpenBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_NODEV)
  #elseif os(Linux) || os(Android)
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_NODEV())
  #else
  CInterop.MountFlags(truncatingIfNeeded: ST_NODEV)
  #endif
}
#endif

// MARK: Flags Available on Linux, WASI, and Android

#if os(Linux) || os(WASI) || os(Android)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _ST_MANDLOCK: CInterop.MountFlags {
  #if os(WASI)
  CInterop.MountFlags(truncatingIfNeeded: ST_MANDLOCK)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_MANDLOCK())
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _ST_NODIRATIME: CInterop.MountFlags {
  #if os(WASI)
  CInterop.MountFlags(truncatingIfNeeded: ST_NODIRATIME)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_NODIRATIME())
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _ST_RELATIME: CInterop.MountFlags {
  #if os(WASI)
  CInterop.MountFlags(truncatingIfNeeded: ST_RELATIME)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_RELATIME())
  #endif
}
#endif

// MARK: Flags Available on Linux and WASI Only

#if os(Linux) || os(WASI)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _ST_WRITE: CInterop.MountFlags {
  #if os(WASI)
  CInterop.MountFlags(truncatingIfNeeded: ST_WRITE)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_WRITE())
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _ST_APPEND: CInterop.MountFlags {
  #if os(WASI)
  CInterop.MountFlags(truncatingIfNeeded: ST_APPEND)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_APPEND())
  #endif
}

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _ST_IMMUTABLE: CInterop.MountFlags {
  #if os(WASI)
  CInterop.MountFlags(truncatingIfNeeded: ST_IMMUTABLE)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_IMMUTABLE())
  #endif
}
#endif

// MARK: Flags Available on Linux, Android, and FreeBSD

#if os(Linux) || os(Android) || os(FreeBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MOUNT_NOSYMFOLLOW: CInterop.MountFlags {
  #if os(FreeBSD)
  CInterop.MountFlags(truncatingIfNeeded: MNT_NOSYMFOLLOW)
  #else
  CInterop.MountFlags(truncatingIfNeeded: _system_get_ST_NOSYMFOLLOW())
  #endif
}
#endif

// MARK: Flags Available on Darwin, FreeBSD, and OpenBSD

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD) || os(OpenBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_ASYNC: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_ASYNC) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_EXPORTED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_EXPORTED) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_LOCAL: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_LOCAL) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_QUOTA: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_QUOTA) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_ROOTFS: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_ROOTFS) }
#endif

// MARK: Flags Available on Darwin and FreeBSD

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_UNION: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_UNION) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_AUTOMOUNTED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_AUTOMOUNTED) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_MULTILABEL: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_MULTILABEL) }
#endif

// MARK: Flags Available on FreeBSD and OpenBSD

#if os(FreeBSD) || os(OpenBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_EXRDONLY: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_EXRDONLY) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_DEFEXPORTED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_DEFEXPORTED) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_EXPORTANON: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_EXPORTANON) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_SOFTDEP: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_SOFTDEP) }
#endif

// MARK: Flags Available on Darwin Only

#if SYSTEM_PACKAGE_DARWIN
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_CPROTECT: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_CPROTECT) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_REMOVABLE: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_REMOVABLE) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_QUARANTINE: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_QUARANTINE) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_DOVOLFS: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_DOVOLFS) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_DONTBROWSE: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_DONTBROWSE) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_IGNORE_OWNERSHIP: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_IGNORE_OWNERSHIP) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_JOURNALED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_JOURNALED) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_NOUSERXATTR: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_NOUSERXATTR) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_DEFWRITE: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_DEFWRITE) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_NOFOLLOW: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_NOFOLLOW) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_SNAPSHOT: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_SNAPSHOT) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_STRICTATIME: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_STRICTATIME) }
#endif

// MARK: Flags Available on FreeBSD Only

#if os(FreeBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_EXKERB: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_EXKERB) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_EXPUBLIC: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_EXPUBLIC) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_ACLS: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_ACLS) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_GJOURNAL: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_GJOURNAL) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_IGNORE: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_IGNORE) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_NFS4ACLS: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_NFS4ACLS) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_NOCLUSTERR: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_NOCLUSTERR) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_NOCLUSTERW: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_NOCLUSTERW) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_SUIDDIR: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_SUIDDIR) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_SUJ: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_SUJ) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_UNTRUSTED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_UNTRUSTED) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_USER: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_USER) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_VERIFIED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_VERIFIED) }
#endif

// MARK: Flags Available on OpenBSD Only

#if os(OpenBSD)
@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_NOPERM: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_NOPERM) }

@available(System 199, *)
@_alwaysEmitIntoClient
internal var _MNT_WXALLOWED: CInterop.MountFlags { CInterop.MountFlags(truncatingIfNeeded: MNT_WXALLOWED) }
#endif

#endif // !os(Windows)
