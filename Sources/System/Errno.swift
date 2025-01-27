/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// An error number used by system calls to communicate what kind of error
/// occurred.
@frozen
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
public struct Errno: RawRepresentable, Error, Hashable, Codable {
  /// The raw C error number.
  @_alwaysEmitIntoClient
  public let rawValue: CInt

  /// Creates a strongly typed error number from a raw C error number.
  @_alwaysEmitIntoClient
  public init(rawValue: CInt) { self.rawValue = rawValue }

#if SYSTEM_PACKAGE_DARWIN
  /// Error. Not used.
  @_alwaysEmitIntoClient
  public static var notUsed: Errno { .init(rawValue: _ERRNO_NOT_USED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notUsed")
  public static var ERRNO_NOT_USED: Errno { notUsed }
#endif

  /// Operation not permitted.
  ///
  /// An attempt was made to perform an operation
  /// limited to processes with appropriate privileges
  /// or to the owner of a file or other resources.
  ///
  /// The corresponding C error is `EPERM`.
  @_alwaysEmitIntoClient
  public static var notPermitted: Errno { .init(rawValue: _EPERM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notPermitted")
  public static var EPERM: Errno { notPermitted }

  /// No such file or directory.
  ///
  /// A component of a specified pathname didn't exist,
  /// or the pathname was an empty string.
  ///
  /// The corresponding C error is `ENOENT`.
  @_alwaysEmitIntoClient
  public static var noSuchFileOrDirectory: Errno { .init(rawValue: _ENOENT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noSuchFileOrDirectory")
  public static var ENOENT: Errno { noSuchFileOrDirectory }

  /// No such process.
  ///
  /// There isn't a process that corresponds to the specified process ID.
  ///
  /// The corresponding C error is `ESRCH`.
  @_alwaysEmitIntoClient
  public static var noSuchProcess: Errno { .init(rawValue: _ESRCH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noSuchProcess")
  public static var ESRCH: Errno { noSuchProcess }

  /// Interrupted function call.
  ///
  /// The process caught an asynchronous signal (such as `SIGINT` or `SIGQUIT`)
  /// during the execution of an interruptible function.
  /// If the signal handler performs a normal return,
  /// the caller of the interrupted function call receives this error.
  ///
  /// The corresponding C error is `EINTR`.
  @_alwaysEmitIntoClient
  public static var interrupted: Errno { .init(rawValue: _EINTR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "interrupted")
  public static var EINTR: Errno { interrupted }

  /// Input/output error.
  ///
  /// Some physical input or output error occurred.
  /// This error isn't reported until
  /// you attempt a subsequent operation on the same file descriptor,
  /// and the error may be lost (overwritten) by subsequent errors.
  ///
  /// The corresponding C error is `EIO`.
  @_alwaysEmitIntoClient
  public static var ioError: Errno { .init(rawValue: _EIO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "ioError")
  public static var EIO: Errno { ioError }

  /// No such device or address.
  ///
  /// Input or output on a special file referred to a device that didn't exist,
  /// or made a request beyond the limits of the device.
  /// This error may also occur when, for example,
  /// a tape drive isn't online or when there isn't a disk pack loaded on a drive.
  ///
  /// The corresponding C error is `ENXIO`.
  @_alwaysEmitIntoClient
  public static var noSuchAddressOrDevice: Errno { .init(rawValue: _ENXIO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noSuchAddressOrDevice")
  public static var ENXIO: Errno { noSuchAddressOrDevice }

  /// The argument list is too long.
  ///
  /// The number of bytes
  /// used for the argument and environment list of the new process
  /// exceeded the limit `NCARGS`, as defined in `<sys/param.h>`.
  ///
  /// The corresponding C error is `E2BIG`.
  @_alwaysEmitIntoClient
  public static var argListTooLong: Errno { .init(rawValue: _E2BIG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "argListTooLong")
  public static var E2BIG: Errno { argListTooLong }

  /// Executable format error.
  ///
  /// A request was made to execute a file that,
  /// although it has the appropriate permissions,
  /// isn't in the format required for an executable file.
  ///
  /// The corresponding C error is `ENOEXEC`.
  @_alwaysEmitIntoClient
  public static var execFormatError: Errno { .init(rawValue: _ENOEXEC) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "execFormatError")
  public static var ENOEXEC: Errno { execFormatError }

  /// Bad file descriptor.
  ///
  /// A file descriptor argument was out of range,
  /// referred to no open file,
  /// or a read (write) request was made to a file
  /// that was only open for writing (reading).
  ///
  /// The corresponding C error is `EBADF`.
  @_alwaysEmitIntoClient
  public static var badFileDescriptor: Errno { .init(rawValue: _EBADF) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badFileDescriptor")
  public static var EBADF: Errno { badFileDescriptor }

  /// No child processes.
  ///
  /// A `wait(2)` or `waitpid(2)` function was executed
  /// by a process that dosn't have any existing child processes
  /// or whose child processes are all already being waited for.
  ///
  /// The corresponding C error is `ECHILD`.
  @_alwaysEmitIntoClient
  public static var noChildProcess: Errno { .init(rawValue: _ECHILD) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noChildProcess")
  public static var ECHILD: Errno { noChildProcess }

  /// Resource deadlock avoided.
  ///
  /// You attempted to lock a system resource
  /// that would have resulted in a deadlock.
  ///
  /// The corresponding C error is `EDEADLK`.
  @_alwaysEmitIntoClient
  public static var deadlock: Errno { .init(rawValue: _EDEADLK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "deadlock")
  public static var EDEADLK: Errno { deadlock }

  /// Can't allocate memory.
  ///
  /// The new process image required more memory
  /// than was allowed by the hardware
  /// or by system-imposed memory management constraints.
  /// A lack of swap space is normally temporary;
  /// however, a lack of core is not.
  /// You can increase soft limits up to their corresponding hard limits.
  ///
  /// The corresponding C error is `ENOMEM`.
  @_alwaysEmitIntoClient
  public static var noMemory: Errno { .init(rawValue: _ENOMEM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noMemory")
  public static var ENOMEM: Errno { noMemory }

  /// Permission denied.
  ///
  /// You attempted to access a file
  /// in a way that's forbidden by the file's access permissions.
  ///
  /// The corresponding C error is `EACCES`.
  @_alwaysEmitIntoClient
  public static var permissionDenied: Errno { .init(rawValue: _EACCES) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "permissionDenied")
  public static var EACCES: Errno { permissionDenied }

  /// Bad address.
  ///
  /// An address passed as an argument to a system call was invalid.
  ///
  /// The corresponding C error is `EFAULT`.
  @_alwaysEmitIntoClient
  public static var badAddress: Errno { .init(rawValue: _EFAULT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badAddress")
  public static var EFAULT: Errno { badAddress }

#if !os(Windows) && !os(WASI)
  /// Not a block device.
  ///
  /// You attempted a block device operation on a nonblock device or file.
  ///
  /// The corresponding C error is `ENOTBLK`.
  @_alwaysEmitIntoClient
  public static var notBlockDevice: Errno { .init(rawValue: _ENOTBLK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notBlockDevice")
  public static var ENOTBLK: Errno { notBlockDevice }
#endif

  /// Resource busy.
  ///
  /// You attempted to use a system resource which was in use at the time,
  /// in a manner that would have conflicted with the request.
  ///
  /// The corresponding C error is `EBUSY`.
  @_alwaysEmitIntoClient
  public static var resourceBusy: Errno { .init(rawValue: _EBUSY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "resourceBusy")
  public static var EBUSY: Errno { resourceBusy }

  /// File exists.
  ///
  /// An existing file was mentioned in an inappropriate context;
  /// for example, as the new link name in a link function.
  ///
  /// The corresponding C error is `EEXIST`.
  @_alwaysEmitIntoClient
  public static var fileExists: Errno { .init(rawValue: _EEXIST) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "fileExists")
  public static var EEXIST: Errno { fileExists }

  /// Improper link.
  ///
  /// You attempted to create a hard link to a file on another file system.
  ///
  /// The corresponding C error is `EXDEV`.
  @_alwaysEmitIntoClient
  public static var improperLink: Errno { .init(rawValue: _EXDEV) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "improperLink")
  public static var EXDEV: Errno { improperLink }

  /// Operation not supported by device.
  ///
  /// You attempted to apply an inappropriate function to a device;
  /// for example, trying to read a write-only device such as a printer.
  ///
  /// The corresponding C error is `ENODEV`.
  @_alwaysEmitIntoClient
  public static var operationNotSupportedByDevice: Errno { .init(rawValue: _ENODEV) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "operationNotSupportedByDevice")
  public static var ENODEV: Errno { operationNotSupportedByDevice }

  /// Not a directory.
  ///
  /// A component of the specified pathname exists,
  /// but it wasn't a directory,
  /// when a directory was expected.
  ///
  /// The corresponding C error is `ENOTDIR`.
  @_alwaysEmitIntoClient
  public static var notDirectory: Errno { .init(rawValue: _ENOTDIR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notDirectory")
  public static var ENOTDIR: Errno { notDirectory }

  /// Is a directory.
  ///
  /// You attempted to open a directory with write mode specified.
  /// Directories can be opened only in read mode.
  ///
  /// The corresponding C error is `EISDIR`.
  @_alwaysEmitIntoClient
  public static var isDirectory: Errno { .init(rawValue: _EISDIR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "isDirectory")
  public static var EISDIR: Errno { isDirectory }

  /// Invalid argument.
  ///
  /// One or more of the specified arguments wasn't valid;
  /// for example, specifying an undefined signal to a signal or kill function.
  ///
  /// The corresponding C error is `EINVAL`.
  @_alwaysEmitIntoClient
  public static var invalidArgument: Errno { .init(rawValue: _EINVAL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "invalidArgument")
  public static var EINVAL: Errno { invalidArgument }

  /// The system has too many open files.
  ///
  /// The maximum number of file descriptors
  /// allowable on the system has been reached;
  /// requests to open a file can't be satisfied
  /// until you close at least one file descriptor.
  ///
  /// The corresponding C error is `ENFILE`.
  @_alwaysEmitIntoClient
  public static var tooManyOpenFilesInSystem: Errno { .init(rawValue: _ENFILE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyOpenFilesInSystem")
  public static var ENFILE: Errno { tooManyOpenFilesInSystem }

  /// This process has too many open files.
  ///
  /// To check the current limit,
  /// call the `getdtablesize` function.
  ///
  /// The corresponding C error is `EMFILE`.
  @_alwaysEmitIntoClient
  public static var tooManyOpenFiles: Errno { .init(rawValue: _EMFILE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyOpenFiles")
  public static var EMFILE: Errno { tooManyOpenFiles }

#if !os(Windows)
  /// Inappropriate control function.
  ///
  /// You attempted a control function
  /// that can't be performed on the specified file or device.
  /// For information about control functions, see `ioctl(2)`.
  ///
  /// The corresponding C error is `ENOTTY`.
  @_alwaysEmitIntoClient
  public static var inappropriateIOCTLForDevice: Errno { .init(rawValue: _ENOTTY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "inappropriateIOCTLForDevice")
  public static var ENOTTY: Errno { inappropriateIOCTLForDevice }

  /// Text file busy.
  ///
  /// The new process was a pure procedure (shared text) file,
  /// which was already open for writing by another process,
  /// or while the pure procedure file was being executed,
  /// an open call requested write access.
  ///
  /// The corresponding C error is `ETXTBSY`.
  @_alwaysEmitIntoClient
  public static var textFileBusy: Errno { .init(rawValue: _ETXTBSY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "textFileBusy")
  public static var ETXTBSY: Errno { textFileBusy }
#endif

  /// The file is too large.
  ///
  /// The file exceeds the maximum size allowed by the file system.
  /// For example, the maximum size on UFS is about 2.1 gigabytes,
  /// and about 9,223 petabytes on HFS-Plus and Apple File System.
  ///
  /// The corresponding C error is `EFBIG`.
  @_alwaysEmitIntoClient
  public static var fileTooLarge: Errno { .init(rawValue: _EFBIG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "fileTooLarge")
  public static var EFBIG: Errno { fileTooLarge }

  /// Device out of space.
  ///
  /// A write to an ordinary file,
  /// the creation of a directory or symbolic link,
  /// or the creation of a directory entry failed
  /// because there aren't any available disk blocks on the file system,
  /// or the allocation of an inode for a newly created file failed
  /// because there aren't any inodes available on the file system.
  ///
  /// The corresponding C error is `ENOSPC`.
  @_alwaysEmitIntoClient
  public static var noSpace: Errno { .init(rawValue: _ENOSPC) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noSpace")
  public static var ENOSPC: Errno { noSpace }

  /// Illegal seek.
  ///
  /// An `lseek(2)` function was issued on a socket, pipe or FIFO.
  ///
  /// The corresponding C error is `ESPIPE`.
  @_alwaysEmitIntoClient
  public static var illegalSeek: Errno { .init(rawValue: _ESPIPE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "illegalSeek")
  public static var ESPIPE: Errno { illegalSeek }

  /// Read-only file system.
  ///
  /// You attempted to modify a file or directory
  /// on a file system that was read-only at the time.
  ///
  /// The corresponding C error is `EROFS`.
  @_alwaysEmitIntoClient
  public static var readOnlyFileSystem: Errno { .init(rawValue: _EROFS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "readOnlyFileSystem")
  public static var EROFS: Errno { readOnlyFileSystem }

  /// Too many links.
  ///
  /// The maximum number of hard links to a single file (32767)
  /// has been exceeded.
  ///
  /// The corresponding C error is `EMLINK`.
  @_alwaysEmitIntoClient
  public static var tooManyLinks: Errno { .init(rawValue: _EMLINK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyLinks")
  public static var EMLINK: Errno { tooManyLinks }

  /// Broken pipe.
  ///
  /// You attempted to write to a pipe, socket, or FIFO
  /// that doesn't have a process reading its data.
  ///
  /// The corresponding C error is `EPIPE`.
  @_alwaysEmitIntoClient
  public static var brokenPipe: Errno { .init(rawValue: _EPIPE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "brokenPipe")
  public static var EPIPE: Errno { brokenPipe }

  /// Numerical argument out of domain.
  ///
  /// A numerical input argument was outside the defined domain of the
  /// mathematical function.
  ///
  /// The corresponding C error is `EDOM`.
  @_alwaysEmitIntoClient
  public static var outOfDomain: Errno { .init(rawValue: _EDOM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "outOfDomain")
  public static var EDOM: Errno { outOfDomain }

  /// Numerical result out of range.
  ///
  /// A numerical result of the function
  /// was too large to fit in the available space;
  /// for example, because it exceeded a floating point number's
  /// level of precision.
  ///
  /// The corresponding C error is `ERANGE`.
  @_alwaysEmitIntoClient
  public static var outOfRange: Errno { .init(rawValue: _ERANGE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "outOfRange")
  public static var ERANGE: Errno { outOfRange }

  /// Resource temporarily unavailable.
  ///
  /// This is a temporary condition;
  /// later calls to the same routine may complete normally.
  /// Make the same function call again later.
  ///
  /// The corresponding C error is `EAGAIN`.
  @_alwaysEmitIntoClient
  public static var resourceTemporarilyUnavailable: Errno { .init(rawValue: _EAGAIN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "resourceTemporarilyUnavailable")
  public static var EAGAIN: Errno { resourceTemporarilyUnavailable }

  /// Operation now in progress.
  ///
  /// You attempted an operation that takes a long time to complete,
  /// such as `connect(2)` or `connectx(2)`,
  /// on a nonblocking object.
  /// See also `fcntl(2)`.
  ///
  /// The corresponding C error is `EINPROGRESS`.
  @_alwaysEmitIntoClient
  public static var nowInProgress: Errno { .init(rawValue: _EINPROGRESS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "nowInProgress")
  public static var EINPROGRESS: Errno { nowInProgress }

  /// Operation already in progress.
  ///
  /// You attempted an operation on a nonblocking object
  /// that already had an operation in progress.
  ///
  /// The corresponding C error is `EALREADY`.
  @_alwaysEmitIntoClient
  public static var alreadyInProcess: Errno { .init(rawValue: _EALREADY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "alreadyInProcess")
  public static var EALREADY: Errno { alreadyInProcess }

  /// A socket operation was performed on something that isn't a socket.
  ///
  /// The corresponding C error is `ENOTSOCK`.
  @_alwaysEmitIntoClient
  public static var notSocket: Errno { .init(rawValue: _ENOTSOCK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notSocket")
  public static var ENOTSOCK: Errno { notSocket }

  /// Destination address required.
  ///
  /// A required address was omitted from a socket operation.
  ///
  /// The corresponding C error is `EDESTADDRREQ`.
  @_alwaysEmitIntoClient
  public static var addressRequired: Errno { .init(rawValue: _EDESTADDRREQ) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "addressRequired")
  public static var EDESTADDRREQ: Errno { addressRequired }

  /// Message too long.
  ///
  /// A message sent on a socket was larger than
  /// the internal message buffer or some other network limit.
  ///
  /// The corresponding C error is `EMSGSIZE`.
  @_alwaysEmitIntoClient
  public static var messageTooLong: Errno { .init(rawValue: _EMSGSIZE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "messageTooLong")
  public static var EMSGSIZE: Errno { messageTooLong }

  /// Protocol wrong for socket type.
  ///
  /// A protocol was specified that doesn't support
  /// the semantics of the socket type requested.
  /// For example,
  /// you can't use the ARPA Internet UDP protocol with type `SOCK_STREAM`.
  ///
  /// The corresponding C error is `EPROTOTYPE`.
  @_alwaysEmitIntoClient
  public static var protocolWrongTypeForSocket: Errno { .init(rawValue: _EPROTOTYPE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "protocolWrongTypeForSocket")
  public static var EPROTOTYPE: Errno { protocolWrongTypeForSocket }

  /// Protocol not available.
  ///
  /// A bad option or level was specified
  /// in a `getsockopt(2)` or `setsockopt(2)` call.
  ///
  /// The corresponding C error is `ENOPROTOOPT`.
  @_alwaysEmitIntoClient
  public static var protocolNotAvailable: Errno { .init(rawValue: _ENOPROTOOPT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "protocolNotAvailable")
  public static var ENOPROTOOPT: Errno { protocolNotAvailable }

  /// Protocol not supported.
  ///
  /// The protocol hasn't been configured into the system,
  /// or no implementation for it exists.
  ///
  /// The corresponding C error is `EPROTONOSUPPORT`.
  @_alwaysEmitIntoClient
  public static var protocolNotSupported: Errno { .init(rawValue: _EPROTONOSUPPORT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "protocolNotSupported")
  public static var EPROTONOSUPPORT: Errno { protocolNotSupported }

#if !os(WASI)
  /// Socket type not supported.
  ///
  /// Support for the socket type hasn't been configured into the system
  /// or no implementation for it exists.
  ///
  /// The corresponding C error is `ESOCKTNOSUPPORT`.
  @_alwaysEmitIntoClient
  public static var socketTypeNotSupported: Errno { .init(rawValue: _ESOCKTNOSUPPORT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "socketTypeNotSupported")
  public static var ESOCKTNOSUPPORT: Errno { socketTypeNotSupported }
#endif

  /// Not supported.
  ///
  /// The attempted operation isn't supported
  /// for the type of object referenced.
  ///
  /// The corresponding C error is `ENOTSUP`.
  @_alwaysEmitIntoClient
  public static var notSupported: Errno { .init(rawValue: _ENOTSUP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notSupported")
  public static var ENOTSUP: Errno { notSupported }

#if !os(WASI)
  /// Protocol family not supported.
  ///
  /// The protocol family hasn't been configured into the system
  /// or no implementation for it exists.
  ///
  /// The corresponding C error is `EPFNOSUPPORT`.
  @_alwaysEmitIntoClient
  public static var protocolFamilyNotSupported: Errno { .init(rawValue: _EPFNOSUPPORT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "protocolFamilyNotSupported")
  public static var EPFNOSUPPORT: Errno { protocolFamilyNotSupported }
#endif

  /// The address family isn't supported by the protocol family.
  ///
  /// An address incompatible with the requested protocol was used.
  /// For example, you shouldn't necessarily expect
  /// to be able to use name server addresses with ARPA Internet protocols.
  ///
  /// The corresponding C error is `EAFNOSUPPORT`.
  @_alwaysEmitIntoClient
  public static var addressFamilyNotSupported: Errno { .init(rawValue: _EAFNOSUPPORT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "addressFamilyNotSupported")
  public static var EAFNOSUPPORT: Errno { addressFamilyNotSupported }

  /// Address already in use.
  ///
  /// Only one use of each address is normally permitted.
  ///
  /// The corresponding C error is `EADDRINUSE`.
  @_alwaysEmitIntoClient
  public static var addressInUse: Errno { .init(rawValue: _EADDRINUSE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "addressInUse")
  public static var EADDRINUSE: Errno { addressInUse }

  /// Can't assign the requested address.
  ///
  /// This error normally results from
  /// an attempt to create a socket with an address that isn't on this machine.
  ///
  /// The corresponding C error is `EADDRNOTAVAIL`.
  @_alwaysEmitIntoClient
  public static var addressNotAvailable: Errno { .init(rawValue: _EADDRNOTAVAIL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "addressNotAvailable")
  public static var EADDRNOTAVAIL: Errno { addressNotAvailable }

  /// Network is down.
  ///
  /// A socket operation encountered a dead network.
  ///
  /// The corresponding C error is `ENETDOWN`.
  @_alwaysEmitIntoClient
  public static var networkDown: Errno { .init(rawValue: _ENETDOWN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "networkDown")
  public static var ENETDOWN: Errno { networkDown }

  /// Network is unreachable.
  ///
  /// A socket operation was attempted to an unreachable network.
  ///
  /// The corresponding C error is `ENETUNREACH`.
  @_alwaysEmitIntoClient
  public static var networkUnreachable: Errno { .init(rawValue: _ENETUNREACH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "networkUnreachable")
  public static var ENETUNREACH: Errno { networkUnreachable }

  /// Network dropped connection on reset.
  ///
  /// The host you were connected to crashed and restarted.
  ///
  /// The corresponding C error is `ENETRESET`.
  @_alwaysEmitIntoClient
  public static var networkReset: Errno { .init(rawValue: _ENETRESET) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "networkReset")
  public static var ENETRESET: Errno { networkReset }

  /// Software caused a connection abort.
  ///
  /// A connection abort was caused internal to your host machine.
  ///
  /// The corresponding C error is `ECONNABORTED`.
  @_alwaysEmitIntoClient
  public static var connectionAbort: Errno { .init(rawValue: _ECONNABORTED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "connectionAbort")
  public static var ECONNABORTED: Errno { connectionAbort }

  /// Connection reset by peer.
  ///
  /// A connection was forcibly closed by a peer.
  /// This normally results from a loss of the connection
  /// on the remote socket due to a timeout or a reboot.
  ///
  /// The corresponding C error is `ECONNRESET`.
  @_alwaysEmitIntoClient
  public static var connectionReset: Errno { .init(rawValue: _ECONNRESET) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "connectionReset")
  public static var ECONNRESET: Errno { connectionReset }

  /// No buffer space available.
  ///
  /// An operation on a socket or pipe wasn't performed
  /// because the system lacked sufficient buffer space
  /// or because a queue was full.
  ///
  /// The corresponding C error is `ENOBUFS`.
  @_alwaysEmitIntoClient
  public static var noBufferSpace: Errno { .init(rawValue: _ENOBUFS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noBufferSpace")
  public static var ENOBUFS: Errno { noBufferSpace }

  /// Socket is already connected.
  ///
  /// A `connect(2)` or `connectx(2)` request was made
  /// on an already connected socket,
  /// or a `sendto(2)` or `sendmsg(2)` request was made
  /// on a connected socket specified a destination when already connected.
  ///
  /// The corresponding C error is `EISCONN`.
  @_alwaysEmitIntoClient
  public static var socketIsConnected: Errno { .init(rawValue: _EISCONN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "socketIsConnected")
  public static var EISCONN: Errno { socketIsConnected }

  /// Socket is not connected.
  ///
  /// A request to send or receive data wasn't permitted
  /// because the socket wasn't connected and,
  /// when sending on a datagram socket,
  /// no address was supplied.
  ///
  /// The corresponding C error is `ENOTCONN`.
  @_alwaysEmitIntoClient
  public static var socketNotConnected: Errno { .init(rawValue: _ENOTCONN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "socketNotConnected")
  public static var ENOTCONN: Errno { socketNotConnected }

#if !os(WASI)
  /// Can't send after socket shutdown.
  ///
  /// A request to send data wasn't permitted
  /// because the socket had already been shut down
  /// with a previous `shutdown(2)` call.
  ///
  /// The corresponding C error is `ESHUTDOWN`.
  @_alwaysEmitIntoClient
  public static var socketShutdown: Errno { .init(rawValue: _ESHUTDOWN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "socketShutdown")
  public static var ESHUTDOWN: Errno { socketShutdown }
#endif

  /// Operation timed out.
  ///
  /// A `connect(2)`, `connectx(2)` or `send(2)` request failed
  /// because the connected party didn't properly respond
  /// within the required period of time.
  /// The timeout period is dependent on the communication protocol.
  ///
  /// The corresponding C error is `ETIMEDOUT`.
  @_alwaysEmitIntoClient
  public static var timedOut: Errno { .init(rawValue: _ETIMEDOUT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "timedOut")
  public static var ETIMEDOUT: Errno { timedOut }

  /// Connection refused.
  ///
  /// No connection could be made
  /// because the target machine actively refused it.
  /// This usually results from trying to connect to a service
  /// that's inactive on the foreign host.
  ///
  /// The corresponding C error is `ECONNREFUSED`.
  @_alwaysEmitIntoClient
  public static var connectionRefused: Errno { .init(rawValue: _ECONNREFUSED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "connectionRefused")
  public static var ECONNREFUSED: Errno { connectionRefused }

  /// Too many levels of symbolic links.
  ///
  /// A pathname lookup involved more than eight symbolic links.
  ///
  /// The corresponding C error is `ELOOP`.
  @_alwaysEmitIntoClient
  public static var tooManySymbolicLinkLevels: Errno { .init(rawValue: _ELOOP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManySymbolicLinkLevels")
  public static var ELOOP: Errno { tooManySymbolicLinkLevels }

  /// The file name is too long.
  ///
  /// A component of a pathname exceeded 255 (`MAXNAMELEN`) characters,
  /// or an entire pathname exceeded 1023 (`MAXPATHLEN-1`) characters.
  ///
  /// The corresponding C error is `ENAMETOOLONG`.
  @_alwaysEmitIntoClient
  public static var fileNameTooLong: Errno { .init(rawValue: _ENAMETOOLONG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "fileNameTooLong")
  public static var ENAMETOOLONG: Errno { fileNameTooLong }

#if !os(WASI)
  /// The host is down.
  ///
  /// A socket operation failed because the destination host was down.
  ///
  /// The corresponding C error is `EHOSTDOWN`.
  @_alwaysEmitIntoClient
  public static var hostIsDown: Errno { .init(rawValue: _EHOSTDOWN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "hostIsDown")
  public static var EHOSTDOWN: Errno { hostIsDown }
#endif

  /// No route to host.
  ///
  /// A socket operation failed because the destination host was unreachable.
  ///
  /// The corresponding C error is `EHOSTUNREACH`.
  @_alwaysEmitIntoClient
  public static var noRouteToHost: Errno { .init(rawValue: _EHOSTUNREACH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noRouteToHost")
  public static var EHOSTUNREACH: Errno { noRouteToHost }

  /// Directory not empty.
  ///
  /// A directory with entries other than `.` and `..`
  /// was supplied to a `remove(2)` directory or `rename(2)` call.
  ///
  /// The corresponding C error is `ENOTEMPTY`.
  @_alwaysEmitIntoClient
  public static var directoryNotEmpty: Errno { .init(rawValue: _ENOTEMPTY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "directoryNotEmpty")
  public static var ENOTEMPTY: Errno { directoryNotEmpty }

#if SYSTEM_PACKAGE_DARWIN
  /// Too many processes.
  ///
  /// The corresponding C error is `EPROCLIM`.
  @_alwaysEmitIntoClient
  public static var tooManyProcesses: Errno { .init(rawValue: _EPROCLIM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyProcesses")
  public static var EPROCLIM: Errno { tooManyProcesses }
#endif

#if !os(WASI)
  /// Too many users.
  ///
  /// The quota system ran out of table entries.
  ///
  /// The corresponding C error is `EUSERS`.
  @_alwaysEmitIntoClient
  public static var tooManyUsers: Errno { .init(rawValue: _EUSERS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyUsers")
  public static var EUSERS: Errno { tooManyUsers }
#endif

  /// Disk quota exceeded.
  ///
  /// A write to an ordinary file,
  /// the creation of a directory or symbolic link,
  /// or the creation of a directory entry failed
  /// because the user's quota of disk blocks was exhausted,
  /// or the allocation of an inode for a newly created file failed
  /// because the user's quota of inodes was exhausted.
  ///
  /// The corresponding C error is `EDQUOT`.
  @_alwaysEmitIntoClient
  public static var diskQuotaExceeded: Errno { .init(rawValue: _EDQUOT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "diskQuotaExceeded")
  public static var EDQUOT: Errno { diskQuotaExceeded }

  /// Stale NFS file handle.
  ///
  /// You attempted access an open file on an NFS filesystem,
  /// which is now unavailable as referenced by the given file descriptor.
  /// This may indicate that the file was deleted on the NFS server
  /// or that some other catastrophic event occurred.
  ///
  /// The corresponding C error is `ESTALE`.
  @_alwaysEmitIntoClient
  public static var staleNFSFileHandle: Errno { .init(rawValue: _ESTALE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "staleNFSFileHandle")
  public static var ESTALE: Errno { staleNFSFileHandle }

// TODO: Add Linux's RPC equivalents
#if SYSTEM_PACKAGE_DARWIN

  /// The structure of the remote procedure call (RPC) is bad.
  ///
  /// Exchange of RPC information was unsuccessful.
  ///
  /// The corresponding C error is `EBADRPC`.
  @_alwaysEmitIntoClient
  public static var rpcUnsuccessful: Errno { .init(rawValue: _EBADRPC) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "rpcUnsuccessful")
  public static var EBADRPC: Errno { rpcUnsuccessful }

  /// The version of the remote procedure call (RPC) is incorrect.
  ///
  /// The version of RPC on the remote peer
  /// isn't compatible with the local version.
  ///
  /// The corresponding C error is `ERPCMISMATCH`.
  @_alwaysEmitIntoClient
  public static var rpcVersionMismatch: Errno { .init(rawValue: _ERPCMISMATCH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "rpcVersionMismatch")
  public static var ERPCMISMATCH: Errno { rpcVersionMismatch }

  /// The remote procedure call (RPC) program isn't available.
  ///
  /// The requested program isn't registered on the remote host.
  ///
  /// The corresponding C error is `EPROGUNAVAIL`.
  @_alwaysEmitIntoClient
  public static var rpcProgramUnavailable: Errno { .init(rawValue: _EPROGUNAVAIL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "rpcProgramUnavailable")
  public static var EPROGUNAVAIL: Errno { rpcProgramUnavailable }

  /// The version of the remote procedure call (RPC) program is incorrect.
  ///
  /// The requested version of the program
  /// isn't available on the remote host.
  ///
  /// The corresponding C error is `EPROGMISMATCH`.
  @_alwaysEmitIntoClient
  public static var rpcProgramVersionMismatch: Errno { .init(rawValue: _EPROGMISMATCH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "rpcProgramVersionMismatch")
  public static var EPROGMISMATCH: Errno { rpcProgramVersionMismatch }

  /// Bad procedure for program.
  ///
  /// A remote procedure call was attempted for a procedure
  /// that doesn't exist in the remote program.
  ///
  /// The corresponding C error is `EPROCUNAVAIL`.
  @_alwaysEmitIntoClient
  public static var rpcProcedureUnavailable: Errno { .init(rawValue: _EPROCUNAVAIL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "rpcProcedureUnavailable")
  public static var EPROCUNAVAIL: Errno { rpcProcedureUnavailable }
#endif

  /// No locks available.
  ///
  /// You have reached the system-imposed limit
  /// on the number of simultaneous files.
  ///
  /// The corresponding C error is `ENOLCK`.
  @_alwaysEmitIntoClient
  public static var noLocks: Errno { .init(rawValue: _ENOLCK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noLocks")
  public static var ENOLCK: Errno { noLocks }

  /// Function not implemented.
  ///
  /// You attempted a system call that isn't available on this system.
  ///
  /// The corresponding C error is `ENOSYS`.
  @_alwaysEmitIntoClient
  public static var noFunction: Errno { .init(rawValue: _ENOSYS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noFunction")
  public static var ENOSYS: Errno { noFunction }

// BSD
#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Inappropriate file type or format.
  ///
  /// The file was the wrong type for the operation,
  /// or a data file had the wrong format.
  ///
  /// The corresponding C error is `EFTYPE`.
  @_alwaysEmitIntoClient
  public static var badFileTypeOrFormat: Errno { .init(rawValue: _EFTYPE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badFileTypeOrFormat")
  public static var EFTYPE: Errno { badFileTypeOrFormat }
#endif

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Authentication error.
  ///
  /// The authentication ticket used to mount an NFS file system was invalid.
  ///
  /// The corresponding C error is `EAUTH`.
  @_alwaysEmitIntoClient
  public static var authenticationError: Errno { .init(rawValue: _EAUTH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "authenticationError")
  public static var EAUTH: Errno { authenticationError }

  /// Need authenticator.
  ///
  /// Before mounting the given NFS file system,
  /// you must obtain an authentication ticket.
  ///
  /// The corresponding C error is `ENEEDAUTH`.
  @_alwaysEmitIntoClient
  public static var needAuthenticator: Errno { .init(rawValue: _ENEEDAUTH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "needAuthenticator")
  public static var ENEEDAUTH: Errno { needAuthenticator }
#endif

#if SYSTEM_PACKAGE_DARWIN
  /// Device power is off.
  ///
  /// The corresponding C error is `EPWROFF`.
  @_alwaysEmitIntoClient
  public static var devicePowerIsOff: Errno { .init(rawValue: _EPWROFF) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "devicePowerIsOff")
  public static var EPWROFF: Errno { devicePowerIsOff }

  /// Device error.
  ///
  /// A device error has occurred;
  /// for example, a printer running out of paper.
  ///
  /// The corresponding C error is `EDEVERR`.
  @_alwaysEmitIntoClient
  public static var deviceError: Errno { .init(rawValue: _EDEVERR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "deviceError")
  public static var EDEVERR: Errno { deviceError }
#endif

#if !os(Windows)
  /// Value too large to be stored in data type.
  ///
  /// A numerical result of the function
  /// is too large to be stored in the space that the caller provided.
  ///
  /// The corresponding C error is `EOVERFLOW`.
  @_alwaysEmitIntoClient
  public static var overflow: Errno { .init(rawValue: _EOVERFLOW) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "overflow")
  public static var EOVERFLOW: Errno { overflow }
#endif

#if SYSTEM_PACKAGE_DARWIN
  /// Bad executable or shared library.
  ///
  /// The executable or shared library being referenced was malformed.
  ///
  /// The corresponding C error is `EBADEXEC`.
  @_alwaysEmitIntoClient
  public static var badExecutable: Errno { .init(rawValue: _EBADEXEC) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badExecutable")
  public static var EBADEXEC: Errno { badExecutable }

  /// Bad CPU type in executable.
  ///
  /// The specified executable doesn't support the current CPU.
  ///
  /// The corresponding C error is `EBADARCH`.
  @_alwaysEmitIntoClient
  public static var badCPUType: Errno { .init(rawValue: _EBADARCH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badCPUType")
  public static var EBADARCH: Errno { badCPUType }

  /// Shared library version mismatch.
  ///
  /// The version of the shared library on the system
  /// doesn't match the expected version.
  ///
  /// The corresponding C error is `ESHLIBVERS`.
  @_alwaysEmitIntoClient
  public static var sharedLibraryVersionMismatch: Errno { .init(rawValue: _ESHLIBVERS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "sharedLibraryVersionMismatch")
  public static var ESHLIBVERS: Errno { sharedLibraryVersionMismatch }

  /// Malformed Mach-O file.
  ///
  /// The Mach object file is malformed.
  ///
  /// The corresponding C error is `EBADMACHO`.
  @_alwaysEmitIntoClient
  public static var malformedMachO: Errno { .init(rawValue: _EBADMACHO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "malformedMachO")
  public static var EBADMACHO: Errno { malformedMachO }
#endif

  /// Operation canceled.
  ///
  /// The scheduled operation was canceled.
  ///
  /// The corresponding C error is `ECANCELED`.
  @_alwaysEmitIntoClient
  public static var canceled: Errno { .init(rawValue: _ECANCELED) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "canceled")
  public static var ECANCELED: Errno { canceled }

#if !os(Windows)
  /// Identifier removed.
  ///
  /// An IPC identifier was removed while the current process was waiting on it.
  ///
  /// The corresponding C error is `EIDRM`.
  @_alwaysEmitIntoClient
  public static var identifierRemoved: Errno { .init(rawValue: _EIDRM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "identifierRemoved")
  public static var EIDRM: Errno { identifierRemoved }

  /// No message of desired type.
  ///
  /// An IPC message queue doesn't contain a message of the desired type,
  /// or a message catalog doesn't contain the requested message.
  ///
  /// The corresponding C error is `ENOMSG`.
  @_alwaysEmitIntoClient
  public static var noMessage: Errno { .init(rawValue: _ENOMSG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noMessage")
  public static var ENOMSG: Errno { noMessage }
#endif

  /// Illegal byte sequence.
  ///
  /// While decoding a multibyte character,
  /// the function encountered an invalid or incomplete sequence of bytes,
  /// or the given wide character is invalid.
  ///
  /// The corresponding C error is `EILSEQ`.
  @_alwaysEmitIntoClient
  public static var illegalByteSequence: Errno { .init(rawValue: _EILSEQ) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "illegalByteSequence")
  public static var EILSEQ: Errno { illegalByteSequence }

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// Attribute not found.
  ///
  /// The specified extended attribute doesn't exist.
  ///
  /// The corresponding C error is `ENOATTR`.
  @_alwaysEmitIntoClient
  public static var attributeNotFound: Errno { .init(rawValue: _ENOATTR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "attributeNotFound")
  public static var ENOATTR: Errno { attributeNotFound }
#endif

#if !os(Windows)
  /// Bad message.
  ///
  /// The message to be received is inappropriate
  /// for the attempted operation.
  ///
  /// The corresponding C error is `EBADMSG`.
  @_alwaysEmitIntoClient
  public static var badMessage: Errno { .init(rawValue: _EBADMSG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badMessage")
  public static var EBADMSG: Errno { badMessage }

#if !os(OpenBSD)
  /// Reserved.
  ///
  /// This error is reserved for future use.
  ///
  /// The corresponding C error is `EMULTIHOP`.
  @_alwaysEmitIntoClient
  public static var multiHop: Errno { .init(rawValue: _EMULTIHOP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "multiHop")
  public static var EMULTIHOP: Errno { multiHop }

#if !os(WASI) && !os(FreeBSD)
  /// No message available.
  ///
  /// No message was available to be received by the requested operation.
  ///
  /// The corresponding C error is `ENODATA`.
  @_alwaysEmitIntoClient
  public static var noData: Errno { .init(rawValue: _ENODATA) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noData")
  public static var ENODATA: Errno { noData }
#endif

  /// Reserved.
  ///
  /// This error is reserved for future use.
  ///
  /// The corresponding C error is `ENOLINK`.
  @_alwaysEmitIntoClient
  public static var noLink: Errno { .init(rawValue: _ENOLINK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noLink")
  public static var ENOLINK: Errno { noLink }

#if !os(WASI) && !os(FreeBSD)
  /// Reserved.
  ///
  /// This error is reserved for future use.
  ///
  /// The corresponding C error is `ENOSR`.
  @_alwaysEmitIntoClient
  public static var noStreamResources: Errno { .init(rawValue: _ENOSR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noStreamResources")
  public static var ENOSR: Errno { noStreamResources }

  /// Reserved.
  ///
  /// This error is reserved for future use.
  ///
  /// The corresponding C error is `ENOSTR`.
  @_alwaysEmitIntoClient
  public static var notStream: Errno { .init(rawValue: _ENOSTR) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notStream")
  public static var ENOSTR: Errno { notStream }
#endif
#endif

  /// Protocol error.
  ///
  /// Some protocol error occurred.
  /// This error is device-specific,
  /// but generally isn't related to a hardware failure.
  ///
  /// The corresponding C error is `EPROTO`.
  @_alwaysEmitIntoClient
  public static var protocolError: Errno { .init(rawValue: _EPROTO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "protocolError")
  public static var EPROTO: Errno { protocolError }

#if !os(OpenBSD) && !os(WASI) && !os(FreeBSD)
  /// Reserved.
  ///
  /// This error is reserved for future use.
  ///
  /// The corresponding C error is `ETIME`.
  @_alwaysEmitIntoClient
  public static var timeout: Errno { .init(rawValue: _ETIME) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "timeout")
  public static var ETIME: Errno { timeout }
#endif
#endif

  /// Operation not supported on socket.
  ///
  /// The attempted operation isn't supported for the type of socket referenced;
  /// for example, trying to accept a connection on a datagram socket.
  ///
  /// The corresponding C error is `EOPNOTSUPP`.
  @_alwaysEmitIntoClient
  public static var notSupportedOnSocket: Errno { .init(rawValue: _EOPNOTSUPP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notSupportedOnSocket")
  public static var EOPNOTSUPP: Errno { notSupportedOnSocket }
}

// Constants defined in header but not man page
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension Errno {
  /// Operation would block.
  ///
  /// The corresponding C error is `EWOULDBLOCK`.
  @_alwaysEmitIntoClient
  public static var wouldBlock: Errno { .init(rawValue: _EWOULDBLOCK) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "wouldBlock")
  public static var EWOULDBLOCK: Errno { wouldBlock }

#if !os(WASI)
  /// Too many references: can't splice.
  ///
  /// The corresponding C error is `ETOOMANYREFS`.
  @_alwaysEmitIntoClient
  public static var tooManyReferences: Errno { .init(rawValue: _ETOOMANYREFS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyReferences")
  public static var ETOOMANYREFS: Errno { tooManyReferences }

  /// Too many levels of remote in path.
  ///
  /// The corresponding C error is `EREMOTE`.
  @_alwaysEmitIntoClient
  public static var tooManyRemoteLevels: Errno { .init(rawValue: _EREMOTE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "tooManyRemoteLevels")
  public static var EREMOTE: Errno { tooManyRemoteLevels }
#endif

#if SYSTEM_PACKAGE_DARWIN
  /// No such policy registered.
  ///
  /// The corresponding C error is `ENOPOLICY`.
  @_alwaysEmitIntoClient
  public static var noSuchPolicy: Errno { .init(rawValue: _ENOPOLICY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "noSuchPolicy")
  public static var ENOPOLICY: Errno { noSuchPolicy }
#endif

#if !os(Windows)
  /// State not recoverable.
  ///
  /// The corresponding C error is `ENOTRECOVERABLE`.
  @_alwaysEmitIntoClient
  public static var notRecoverable: Errno { .init(rawValue: _ENOTRECOVERABLE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notRecoverable")
  public static var ENOTRECOVERABLE: Errno { notRecoverable }

  /// Previous pthread mutex owner died.
  ///
  /// The corresponding C error is `EOWNERDEAD`.
  @_alwaysEmitIntoClient
  public static var previousOwnerDied: Errno { .init(rawValue: _EOWNERDEAD) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "previousOwnerDied")
  public static var EOWNERDEAD: Errno { previousOwnerDied }
#endif

#if os(FreeBSD)
  /// Capabilities insufficient.
  ///
  /// The corresponding C error is `ENOTCAPABLE`.
  @_alwaysEmitIntoClient
  public static var notCapable: Errno { .init(rawValue: _ENOTCAPABLE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "notCapable")
  public static var ENOTCAPABLE: Errno { notCapable }

  /// Not permitted in capability mode.
  ///
  /// The corresponding C error is `ECAPMODE`.
  @_alwaysEmitIntoClient
  public static var capabilityMode: Errno { .init(rawValue: _ECAPMODE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "capabilityMode")
  public static var ECAPMODE: Errno { capabilityMode }

  /// Integrity check failed.
  ///
  /// The corresponding C error is `EINTEGRITY`.
  @_alwaysEmitIntoClient
  public static var integrityCheckFailed: Errno { .init(rawValue: _EINTEGRITY) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "integrityCheckFailed")
  public static var EINTEGRITY: Errno { integrityCheckFailed }
#endif

#if SYSTEM_PACKAGE_DARWIN
  /// Interface output queue is full.
  ///
  /// The corresponding C error is `EQFULL`.
  @_alwaysEmitIntoClient
  public static var outputQueueFull: Errno { .init(rawValue: _EQFULL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "outputQueueFull")
  public static var EQFULL: Errno { outputQueueFull }
#endif

#if SYSTEM_PACKAGE_DARWIN || os(FreeBSD)
  /// The largest valid error.
  ///
  /// This value is the largest valid value
  /// encountered using the C `errno` global variable.
  /// It isn't a valid error.
  ///
  /// The corresponding C error is `ELAST`.
  @_alwaysEmitIntoClient
  public static var lastErrnoValue: Errno { .init(rawValue: _ELAST) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "lastErrnoValue")
  public static var ELAST: Errno { lastErrnoValue }
#endif
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension Errno {
  // TODO: We want to provide safe access to `errno`, but we need a
  // release-barrier to do so.

  /// The current error value, set by system calls if an error occurs.
  ///
  /// The corresponding C global variable is `errno`.
  internal static var current: Errno {
    get { Errno(rawValue: system_errno) }
    set { system_errno = newValue.rawValue }
  }
}

// Use "hidden" entry points for `NSError` bridging
@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension Errno {
  public var _code: Int { Int(rawValue) }

  public var _domain: String { "NSPOSIXErrorDomain" }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension Errno: CustomStringConvertible, CustomDebugStringConvertible {
  ///  A textual representation of the most recent error
  ///  returned by a system call.
  ///
  /// The corresponding C function is `strerror(3)`.
  @inline(never)
  public var description: String {
    guard let ptr = system_strerror(self.rawValue) else { return "unknown error" }
    return String(cString: ptr)
  }

  ///  A textual representation,
  ///  suitable for debugging,
  ///  of the most recent error returned by a system call.
  ///
  /// The corresponding C function is `strerror(3)`.
  public var debugDescription: String { self.description }
}

@available(/*System 0.0.1: macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0*/iOS 8, *)
extension Errno {
  @_alwaysEmitIntoClient
  public static func ~=(_ lhs: Errno, _ rhs: Error) -> Bool {
    guard let value = rhs as? Errno else { return false }
    return lhs == value
  }
}

