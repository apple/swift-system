/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

/// A namespace to access system variables
public enum SystemConfig {}

extension SystemConfig {
  public struct Name: RawRepresentable, Hashable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    fileprivate init(_ raw: CInt) { self.init(rawValue: raw) }
  }

  /// Get configurable system variables.
  ///
  /// The corresponding C function is `sysconf`.
  @_alwaysEmitIntoClient
  public static func get(_ name: Name) throws -> Int {
    try _get(name).get()
  }

  @usableFromInline
  internal static func _get(_ name: Name) -> Result<Int, Errno> {
    valueOrErrno(system_sysconf(name.rawValue))
  }
}

extension SystemConfig {
  public struct PathName: RawRepresentable, Hashable {
    @_alwaysEmitIntoClient
    public var rawValue: CInt

    @_alwaysEmitIntoClient
    public init(rawValue: CInt) { self.rawValue = rawValue }

    @_alwaysEmitIntoClient
    fileprivate init(_ raw: CInt) { self.init(rawValue: raw) }
  }

  /// Get configurable pathname variables.
  ///
  /// The corresponding C function is `pathconf`.
  @_alwaysEmitIntoClient
  public static func get(_ name: PathName, for path: FilePath) throws -> Int {
    try _get(name, for: path).get()
  }

  @usableFromInline
  internal static func _get(
    _ name: PathName, for path: FilePath
  ) -> Result<Int, Errno> {
    path.withPlatformString {
      valueOrErrno(system_pathconf($0, name.rawValue))
    }
  }

  /// Get configurable pathname variables.
  ///
  /// The corresponding C function is `fpathconf`.
  @_alwaysEmitIntoClient
  public static func get(_ name: PathName, for fd: FileDescriptor) throws -> Int {
    try _get(name, for: fd).get()
  }

  @usableFromInline
  internal static func _get(
    _ name: PathName, for fd: FileDescriptor
  ) -> Result<Int, Errno> {
    valueOrErrno(system_fpathconf(fd.rawValue, name.rawValue))
  }

}

// MARK: - Constants

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

extension SystemConfig.Name {
  /// The maximum bytes of argument to execve(2).
  ///
  /// The corresponding C constant is _SC_ARG_MAX) ``
  @_alwaysEmitIntoClient
  public static var maxArgumentBytes: Self { Self(_SC_ARG_MAX) }

  /// The maximum number of simultaneous processes per user id.
  ///
  /// The corresponding C constant is `_SC_CHILD_MAX)`
  @_alwaysEmitIntoClient
  public static var maxUserProcesses: Self { Self(_SC_CHILD_MAX) }

  /// The frequency of the statistics clock in ticks per second.
  ///
  /// The corresponding C constant is _SC_CLK_TCK) ``
  @_alwaysEmitIntoClient
  public static var clockTicks: Self { Self(_SC_CLK_TCK) }

  /// The maximum number of elements in the I/O vector used by readv(2),
  /// writev(2), recvmsg(2), and sendmsg(2).
  ///
  /// The corresponding C constant is _SC_IOV_MAX) ``
  @_alwaysEmitIntoClient
  public static var maxIOV: Self { Self(_SC_IOV_MAX) }

  /// The maximum number of supplemental groups.
  ///
  /// The corresponding C constant is `_SC_NGROUPS_MAX`
  @_alwaysEmitIntoClient
  public static var maxGroups: Self { Self(_SC_NGROUPS_MAX) }

  /// The number of processors configured.
  ///
  /// The corresponding C constant is `Name`
  @_alwaysEmitIntoClient
  public static var processorsConfigured: Self { Self(_SC_NPROCESSORS_CONF) }

  /// The number of processors currently online.
  ///
  /// The corresponding C constant is `Name`
  @_alwaysEmitIntoClient
  public static var processorsOnline: Self { Self(_SC_NPROCESSORS_ONLN) }

  /// The maximum number of open files per user id.
  ///
  /// The corresponding C constant is _SC_OPEN_MAX)``
  @_alwaysEmitIntoClient
  public static var maxOpenFiles: Self { Self(_SC_OPEN_MAX) }

  /// The size of a system page in bytes.
  ///
  /// The corresponding C constant is _SC_PAGESIZE)``
  @_alwaysEmitIntoClient
  public static var pageSize: Self { Self(_SC_PAGESIZE) }

  /// The minimum maximum number of streams that a process may have open at
  /// any one time.
  ///
  /// The corresponding C constant is `_SC_STREAM_MAX`
  @_alwaysEmitIntoClient
  public static var maxStreams: Self { Self(_SC_STREAM_MAX) }

  /// The minimum maximum number of types supported for the name of a
  /// timezone.
  ///
  /// The corresponding C constant is `_SC_TZNAME_MAX`
  @_alwaysEmitIntoClient
  public static var maxTimezones: Self { Self(_SC_TZNAME_MAX) }

  /// Return 1 if job control is available on this system, otherwise -1.
  ///
  /// The corresponding C constant is `_SC_JOB_CONTROL`
  @_alwaysEmitIntoClient
  public static var jobControl: Self { Self(_SC_JOB_CONTROL) }

  /// Returns 1 if saved set-group and saved set-user ID is available,
  /// otherwise -1.
  ///
  /// The corresponding C constant is `_SC_SAVED_IDS)`
  @_alwaysEmitIntoClient
  public static var savedIds: Self { Self(_SC_SAVED_IDS) }

  /// The version of IEEE Std 1003.1 (``POSIX.1'') with which the system
  /// attempts to comply.
  ///
  /// The corresponding C constant is _SC_VERSION) ``
  @_alwaysEmitIntoClient
  public static var posixVersion: Self { Self(_SC_VERSION) }

  /// The maximum ibase/obase values in the bc(1) utility.
  ///
  /// The corresponding C constant is `_SC_BC_BASE_MAX`
  @_alwaysEmitIntoClient
  public static var maxBCBase: Self { Self(_SC_BC_BASE_MAX) }

  /// The maximum array size in the bc(1) utility.
  ///
  /// The corresponding C constant is `_SC_BC_DIM_MAX`
  @_alwaysEmitIntoClient
  public static var maxBCArray: Self { Self(_SC_BC_DIM_MAX) }

  /// The maximum scale value in the bc(1) utility.
  ///
  /// The corresponding C constant is `_SC_BC_SCALE_MAX`
  @_alwaysEmitIntoClient
  public static var maxBCScale: Self { Self(_SC_BC_SCALE_MAX) }

  /// The maximum string length in the bc(1) utility.
  ///
  /// The corresponding C constant is `_SC_BC_STRING_MAX`
  @_alwaysEmitIntoClient
  public static var maxBCString: Self { Self(_SC_BC_STRING_MAX) }

  /// The maximum number of weights that can be assigned to any entry of the
  /// LC_COLLATE order keyword in the locale definition file.
  ///
  /// The corresponding C constant is `Name`
  @_alwaysEmitIntoClient
  public static var maxCollationWeights: Self { Self(_SC_COLL_WEIGHTS_MAX) }

  /// The maximum number of expressions that can be nested within parenthesis
  /// by the expr(1) utility.
  ///
  /// The corresponding C constant is `_SC_EXPR_NEST_MAX`
  @_alwaysEmitIntoClient
  public static var maxNestedExpressions: Self { Self(_SC_EXPR_NEST_MAX) }

  /// The maximum length in bytes of a text-processing utility's input line.
  ///
  /// The corresponding C constant is _SC_LINE_MAX)``
  @_alwaysEmitIntoClient
  public static var maxLineBytes: Self { Self(_SC_LINE_MAX) }

  /// The maximum number of repeated occurrences of a regular expression
  /// permitted when using interval notation.
  ///
  /// The corresponding C constant is `_SC_RE_DUP_MAX`
  @_alwaysEmitIntoClient
  public static var maxRERepeated: Self { Self(_SC_RE_DUP_MAX) }

  /// The version of IEEE Std 1003.2 (``POSIX.2'') with which the system
  /// attempts to comply.
  ///
  /// The corresponding C constant is `_SC_2_VERSION)`
  @_alwaysEmitIntoClient
  public static var posix2Version: Self { Self(_SC_2_VERSION) }

  /// Return 1 if the system's C-language development facilities support the
  /// C-Language Bindings Option, otherwise -1.
  ///
  /// The corresponding C constant is _SC_2_C_BIND)``
  @_alwaysEmitIntoClient
  public static var supportsCBindings: Self { Self(_SC_2_C_BIND) }

  /// Return 1 if the system supports the C-Language Development Utilities
  /// Option, otherwise -1.
  ///
  /// The corresponding C constant is _SC_2_C_DEV) ``
  @_alwaysEmitIntoClient
  public static var supportsCDevelopment: Self { Self(_SC_2_C_DEV) }

  /// Return 1 if the system supports at least one terminal type capable of
  /// all operations described in IEEE Std 1003.2 (``POSIX.2''), otherwise -1.
  ///
  /// The corresponding C constant is `_SC_2_CHAR_TERM`
  @_alwaysEmitIntoClient
  public static var supportsPOSIXTerminals: Self { Self(_SC_2_CHAR_TERM) }

  /// Return 1 if the system supports the FORTRAN Development Utilities
  /// Option, otherwise -1.
  ///
  /// The corresponding C constant is `_SC_2_FORT_DEV`
  @_alwaysEmitIntoClient
  public static var supportsFORTRANDevelopment: Self { Self(_SC_2_FORT_DEV) }

  /// Return 1 if the system supports the FORTRAN Runtime Utilities Option,
  /// otherwise -1.
  ///
  /// The corresponding C constant is `_SC_2_FORT_RUN`
  @_alwaysEmitIntoClient
  public static var supportsFORTRANRuntime: Self { Self(_SC_2_FORT_RUN) }

  /// Return 1 if the system supports the creation of locales, otherwise -1.
  ///
  /// The corresponding C constant is `_SC_2_LOCALEDEF`
  @_alwaysEmitIntoClient
  public static var supportsLocales: Self { Self(_SC_2_LOCALEDEF) }

  /// Return 1 if the system supports the Software Development Utilities
  /// Option, otherwise -1.
  ///
  /// The corresponding C constant is _SC_2_SW_DEV)``
  @_alwaysEmitIntoClient
  public static var supportsSoftwareDevelopment: Self { Self(_SC_2_SW_DEV) }

  /// Return 1 if the system supports the User Portability Utilities Option,
  /// otherwise -1.
  ///
  /// The corresponding C constant _SC_2_UPE)is ``
  @_alwaysEmitIntoClient
  public static var supportsUserPortability: Self { Self(_SC_2_UPE) }

  /// The number of pages of physical memory.  Note that it is possible that
  /// the product of this value and the value of _SC_PAGESIZE will overflow a
  /// long in some configurations on a 32bit machine.
  ///
  /// The corresponding C constant is `_SC_PHYS_PAGES`
  @_alwaysEmitIntoClient
  public static var physicalMemoryPages: Self { Self(_SC_PHYS_PAGES) }
}

extension SystemConfig.PathName {

  /// The maximum file link count.
  ///
  /// The corresponding C constant is `_PC_LINK_MAX`.
  @_alwaysEmitIntoClient
  public static var maxLink: Self { Self(_PC_LINK_MAX) }

  /// The maximum number of bytes in terminal canonical input line.
  ///
  /// The corresponding C constant is `_PC_MAX_CANON`.
  @_alwaysEmitIntoClient
  public static var maxTerminalCanonicalLineBytes: Self {
    Self(_PC_MAX_CANON)
  }

  /// The minimum maximum number of bytes for which space is available in a
  /// terminal input queue.
  ///
  /// The corresponding C constant is `_PC_MAX_INPUT`.
  @_alwaysEmitIntoClient
  public static var maxTerminalInputBytes: Self { Self(_PC_MAX_INPUT) }

  /// The maximum number of bytes in a file name.
  ///
  /// The corresponding C constant is `_PC_NAME_MAX`.
  @_alwaysEmitIntoClient
  public static var maxFileNameBytes: Self { Self(_PC_NAME_MAX) }

  /// The maximum number of bytes in a pathname.
  ///
  /// The corresponding C constant is `_PC_PATH_MAX`.
  @_alwaysEmitIntoClient
  public static var maxPathBytes: Self { Self(_PC_PATH_MAX) }

  /// The maximum number of bytes which will be written atomically to a pipe.
  ///
  /// The corresponding C constant is `_PC_PIPE_BUF`.
  @_alwaysEmitIntoClient
  public static var maxPipeBufferBytes: Self { Self(_PC_PIPE_BUF) }

  /// Return 1 if appropriate privileges are required for the chown(2) system
  /// call, otherwise 0.
  ///
  /// The corresponding C constant is `_PC_CHOWN_RESTRICTED`.
  @_alwaysEmitIntoClient
  public static var isCHOWNRestricted: Self {
    Self(_PC_CHOWN_RESTRICTED)
  }

  /// Return 1 if file names longer than KERN_NAME_MAX are truncated.
  ///
  /// The corresponding C constant is `_PC_NO_TRUNC`.
  @_alwaysEmitIntoClient
  public static var isNameTruncated: Self { Self(_PC_NO_TRUNC) }

  /// Returns the terminal character disabling value.
  ///
  /// The corresponding C constant is `_PC_VDISABLE`.
  @_alwaysEmitIntoClient
  public static var disableTerminalCharacter: Self { Self(_PC_VDISABLE) }

  /// Returns the number of bits used to store maximum extended attribute size
  /// in bytes.  For example, if the maximum attribute size supported by a
  /// file system is 128K, the value returned will be 18.  However a value 18
  /// can mean that the maximum attribute size can be anywhere from (256KB -
  /// 1) to 128KB.  As a special case, the resource fork can have much larger
  /// size, and some file system specific extended attributes can have smaller
  /// and preset size; for example, Finder Info is always 32 bytes.
  ///
  /// The corresponding C constant is `_PC_XATTR_SIZE_BITS`.
  @_alwaysEmitIntoClient
  public static var maxExtendedAttributeByteSizeInBits: Self {
    Self(_PC_XATTR_SIZE_BITS)
  }

  /// If a file system supports the reporting of holes (see lseek(2)),
  /// pathconf() and fpathconf() return a positive number that represents the
  /// minimum hole size returned in bytes.  The offsets of holes returned will
  /// be aligned to this same value.  A special value of 1 is returned if the
  /// file system does not specify the minimum hole size but still reports
  /// holes.
  ///
  /// The corresponding C constant is `_PC_MIN_HOLE_SIZE`.
  @_alwaysEmitIntoClient
  public static var minimumHoleSize: Self { Self(_PC_MIN_HOLE_SIZE) }
}
