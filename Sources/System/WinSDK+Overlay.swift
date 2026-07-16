/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(Windows)

import WinSDK

@_transparent
internal var CREATE_ALWAYS: DWORD {
  DWORD(WinSDK.CREATE_ALWAYS)
}

@_transparent
internal var CREATE_NEW: DWORD {
  DWORD(WinSDK.CREATE_NEW)
}

@_transparent
internal var ERROR_ACCESS_DENIED: DWORD {
  DWORD(WinSDK.ERROR_ACCESS_DENIED)
}

@_transparent
internal var ERROR_ALREADY_EXISTS: DWORD {
  DWORD(WinSDK.ERROR_ALREADY_EXISTS)
}

@_transparent
internal var ERROR_ARENA_TRASHED: DWORD {
  DWORD(WinSDK.ERROR_ARENA_TRASHED)
}

@_transparent
internal var ERROR_BAD_ENVIRONMENT: DWORD {
  DWORD(WinSDK.ERROR_BAD_ENVIRONMENT)
}

@_transparent
internal var ERROR_BAD_FORMAT: DWORD {
  DWORD(WinSDK.ERROR_BAD_FORMAT)
}

@_transparent
internal var ERROR_BAD_NET_NAME: DWORD {
  DWORD(WinSDK.ERROR_BAD_NET_NAME)
}

@_transparent
internal var ERROR_BAD_NETPATH: DWORD {
  DWORD(WinSDK.ERROR_BAD_NETPATH)
}

@_transparent
internal var ERROR_BAD_PATHNAME: DWORD {
  DWORD(WinSDK.ERROR_BAD_PATHNAME)
}

@_transparent
internal var ERROR_BROKEN_PIPE: DWORD {
  DWORD(WinSDK.ERROR_BROKEN_PIPE)
}

@_transparent
internal var ERROR_CANNOT_MAKE: DWORD {
  DWORD(WinSDK.ERROR_CANNOT_MAKE)
}

@_transparent
internal var ERROR_CHILD_NOT_COMPLETE: DWORD {
  DWORD(WinSDK.ERROR_CHILD_NOT_COMPLETE)
}

@_transparent
internal var ERROR_CURRENT_DIRECTORY: DWORD {
  DWORD(WinSDK.ERROR_CURRENT_DIRECTORY)
}

@_transparent
internal var ERROR_DIR_NOT_EMPTY: DWORD {
  DWORD(WinSDK.ERROR_DIR_NOT_EMPTY)
}

@_transparent
internal var ERROR_DISK_FULL: DWORD {
  DWORD(WinSDK.ERROR_DISK_FULL)
}

@_transparent
internal var ERROR_DRIVE_LOCKED: DWORD {
  DWORD(WinSDK.ERROR_DRIVE_LOCKED)
}

@_transparent
internal var ERROR_DIRECT_ACCESS_HANDLE: DWORD {
  DWORD(WinSDK.ERROR_DIRECT_ACCESS_HANDLE)
}

@_transparent
internal var ERROR_FILE_EXISTS: DWORD {
  DWORD(WinSDK.ERROR_FILE_EXISTS)
}

@_transparent
internal var ERROR_FILE_NOT_FOUND: DWORD {
  DWORD(WinSDK.ERROR_FILE_NOT_FOUND)
}

@_transparent
internal var ERROR_FAIL_I24: DWORD {
  DWORD(WinSDK.ERROR_FAIL_I24)
}

@_transparent
internal var ERROR_FILENAME_EXCED_RANGE: DWORD {
  DWORD(WinSDK.ERROR_FILENAME_EXCED_RANGE)
}

@_transparent
internal var ERROR_NEGATIVE_SEEK: DWORD {
  DWORD(WinSDK.ERROR_NEGATIVE_SEEK)
}

@_transparent
internal var ERROR_NO_MORE_FILES: DWORD {
  DWORD(WinSDK.ERROR_NO_MORE_FILES)
}

@_transparent
internal var ERROR_NO_UNICODE_TRANSLATION: DWORD {
  DWORD(WinSDK.ERROR_NO_UNICODE_TRANSLATION)
}

@_transparent
internal var ERROR_NOT_ENOUGH_MEMORY: DWORD {
  DWORD(WinSDK.ERROR_NOT_ENOUGH_MEMORY)
}

@_transparent
internal var ERROR_INVALID_ACCESS: DWORD {
  DWORD(WinSDK.ERROR_INVALID_ACCESS)
}

@_transparent
internal var ERROR_INVALID_BLOCK: DWORD {
  DWORD(WinSDK.ERROR_INVALID_BLOCK)
}

@_transparent
internal var ERROR_INVALID_DATA: DWORD {
  DWORD(WinSDK.ERROR_INVALID_DATA)
}

@_transparent
internal var ERROR_INVALID_DRIVE: DWORD {
  DWORD(WinSDK.ERROR_INVALID_DRIVE)
}

@_transparent
internal var ERROR_INVALID_FUNCTION: DWORD {
  DWORD(WinSDK.ERROR_INVALID_FUNCTION)
}

@_transparent
internal var ERROR_INVALID_HANDLE: DWORD {
  DWORD(WinSDK.ERROR_INVALID_HANDLE)
}

@_transparent
internal var ERROR_INFLOOP_IN_RELOC_CHAIN: DWORD {
  DWORD(WinSDK.ERROR_INFLOOP_IN_RELOC_CHAIN)
}

@_transparent
internal var ERROR_INVALID_PARAMETER: DWORD {
  DWORD(WinSDK.ERROR_INVALID_PARAMETER)
}

@_transparent
internal var ERROR_INVALID_STARTING_CODESEG: DWORD {
  DWORD(WinSDK.ERROR_INVALID_STARTING_CODESEG)
}

@_transparent
internal var ERROR_INVALID_TARGET_HANDLE: DWORD {
  DWORD(WinSDK.ERROR_INVALID_TARGET_HANDLE)
}

@_transparent
internal var ERROR_LOCK_FAILED: DWORD {
  DWORD(WinSDK.ERROR_LOCK_FAILED)
}

@_transparent
internal var ERROR_LOCK_VIOLATION: DWORD {
  DWORD(WinSDK.ERROR_LOCK_VIOLATION)
}

@_transparent
internal var ERROR_MAX_THRDS_REACHED: DWORD {
  DWORD(WinSDK.ERROR_MAX_THRDS_REACHED)
}

@_transparent
internal var ERROR_NESTING_NOT_ALLOWED: DWORD {
  DWORD(WinSDK.ERROR_NESTING_NOT_ALLOWED)
}

@_transparent
internal var ERROR_NETWORK_ACCESS_DENIED: DWORD {
  DWORD(WinSDK.ERROR_NETWORK_ACCESS_DENIED)
}

@_transparent
internal var ERROR_NO_PROC_SLOTS: DWORD {
  DWORD(WinSDK.ERROR_NO_PROC_SLOTS)
}

@_transparent
internal var ERROR_NOT_ENOUGH_QUOTA: DWORD {
  DWORD(WinSDK.ERROR_NOT_ENOUGH_QUOTA)
}

@_transparent
internal var ERROR_NOT_LOCKED: DWORD {
  DWORD(WinSDK.ERROR_NOT_LOCKED)
}

@_transparent
internal var ERROR_NOT_SAME_DEVICE: DWORD {
  DWORD(WinSDK.ERROR_NOT_SAME_DEVICE)
}

@_transparent
internal var ERROR_PATH_NOT_FOUND: DWORD {
  DWORD(WinSDK.ERROR_PATH_NOT_FOUND)
}

@_transparent
internal var ERROR_SEEK_ON_DEVICE: DWORD {
  DWORD(WinSDK.ERROR_SEEK_ON_DEVICE)
}

@_transparent
internal var ERROR_SHARING_BUFFER_EXCEEDED: DWORD {
  DWORD(WinSDK.ERROR_SHARING_BUFFER_EXCEEDED)
}

@_transparent
internal var ERROR_SUCCESS: DWORD {
  DWORD(WinSDK.ERROR_SUCCESS)
}

@_transparent
internal var ERROR_WAIT_NO_CHILDREN: DWORD {
  DWORD(WinSDK.ERROR_WAIT_NO_CHILDREN)
}

@_transparent
internal var ERROR_WRITE_PROTECT: DWORD {
  DWORD(WinSDK.ERROR_WRITE_PROTECT)
}

@_transparent
internal var ERROR_TOO_MANY_OPEN_FILES: DWORD {
  DWORD(WinSDK.ERROR_TOO_MANY_OPEN_FILES)
}

@_transparent
internal var FILE_APPEND_DATA: DWORD {
  DWORD(WinSDK.FILE_APPEND_DATA)
}

@_transparent
internal var FILE_ATTRIBUTE_DIRECTORY: DWORD {
  DWORD(WinSDK.FILE_ATTRIBUTE_DIRECTORY)
}

@_transparent
internal var FILE_ATTRIBUTE_NORMAL: DWORD {
  DWORD(WinSDK.FILE_ATTRIBUTE_NORMAL)
}

@_transparent
internal var FILE_ATTRIBUTE_TEMPORARY: DWORD {
  DWORD(WinSDK.FILE_ATTRIBUTE_TEMPORARY)
}

@_transparent
internal var FILE_BEGIN: DWORD {
  DWORD(WinSDK.FILE_BEGIN)
}

@_transparent
internal var FILE_CURRENT: DWORD {
  DWORD(WinSDK.FILE_CURRENT)
}

@_transparent
internal var FILE_DELETE_CHILD: DWORD {
  DWORD(WinSDK.FILE_DELETE_CHILD)
}

@_transparent
package var FILE_EXECUTE: DWORD {
  DWORD(WinSDK.FILE_EXECUTE)
}

@_transparent
internal var FILE_FLAG_DELETE_ON_CLOSE: DWORD {
  DWORD(WinSDK.FILE_FLAG_DELETE_ON_CLOSE)
}

@_transparent
internal var FILE_FLAG_RANDOM_ACCESS: DWORD {
  DWORD(WinSDK.FILE_FLAG_RANDOM_ACCESS)
}

@_transparent
internal var FILE_FLAG_SEQUENTIAL_SCAN: DWORD {
  DWORD(WinSDK.FILE_FLAG_SEQUENTIAL_SCAN)
}

@_transparent
package var FILE_READ_ATTRIBUTES: DWORD {
  DWORD(WinSDK.FILE_READ_ATTRIBUTES)
}

@_transparent
internal var FILE_READ_DATA: DWORD {
  DWORD(WinSDK.FILE_READ_DATA)
}

@_transparent
internal var FILE_READ_EA: DWORD {
  DWORD(WinSDK.FILE_READ_EA)
}

@_transparent
internal var FILE_SHARE_DELETE: DWORD {
  DWORD(WinSDK.FILE_SHARE_DELETE)
}

@_transparent
internal var FILE_SHARE_READ: DWORD {
  DWORD(WinSDK.FILE_SHARE_READ)
}

@_transparent
internal var FILE_SHARE_WRITE: DWORD {
  DWORD(WinSDK.FILE_SHARE_WRITE)
}

@_transparent
package var FILE_WRITE_ATTRIBUTES: DWORD {
  DWORD(WinSDK.FILE_WRITE_ATTRIBUTES)
}

@_transparent
internal var FILE_WRITE_DATA: DWORD {
  DWORD(WinSDK.FILE_WRITE_DATA)
}

@_transparent
internal var FILE_WRITE_EA: DWORD {
  DWORD(WinSDK.FILE_WRITE_EA)
}

@_transparent
internal var GENERIC_READ: DWORD {
  DWORD(WinSDK.GENERIC_READ)
}

@_transparent
internal var GENERIC_WRITE: DWORD {
  DWORD(WinSDK.GENERIC_WRITE)
}

@_transparent
internal var NO_INHERITANCE: DWORD {
  DWORD(WinSDK.NO_INHERITANCE)
}

@_transparent
internal var OPEN_ALWAYS: DWORD {
  DWORD(WinSDK.OPEN_ALWAYS)
}

@_transparent
internal var OPEN_EXISTING: DWORD {
  DWORD(WinSDK.OPEN_EXISTING)
}

@_transparent
internal var SE_DACL_PROTECTED: SECURITY_DESCRIPTOR_CONTROL {
  SECURITY_DESCRIPTOR_CONTROL(WinSDK.SE_DACL_PROTECTED)
}

@_transparent
internal var SECURITY_DESCRIPTOR_REVISION: DWORD {
  DWORD(WinSDK.SECURITY_DESCRIPTOR_REVISION)
}

@_transparent
internal var SECURITY_WORLD_RID: DWORD {
  DWORD(WinSDK.SECURITY_WORLD_RID)
}

@_transparent
internal var STANDARD_RIGHTS_READ: DWORD {
  DWORD(WinSDK.STANDARD_RIGHTS_READ)
}

@_transparent
internal var STANDARD_RIGHTS_EXECUTE: DWORD {
  DWORD(WinSDK.STANDARD_RIGHTS_EXECUTE)
}

@_transparent
internal var STANDARD_RIGHTS_WRITE: DWORD {
  DWORD(WinSDK.STANDARD_RIGHTS_WRITE)
}

@_transparent
internal var SYNCHRONIZE: DWORD {
  DWORD(WinSDK.SYNCHRONIZE)
}

@_transparent
internal var TRUNCATE_EXISTING: DWORD {
  DWORD(WinSDK.TRUNCATE_EXISTING)
}

#endif
