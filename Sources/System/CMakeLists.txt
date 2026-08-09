#[[
This source file is part of the Swift System open source project

Copyright (c) 2020 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(SystemPackage
  Errno.swift
  ErrnoWindows.swift
  FileDescriptor.swift
  FileHelpers.swift
  FileOperations.swift
  FilePermissions.swift
  MachPort.swift
  PlatformString.swift
  SystemString.swift
  Util.swift
  Util+StringArray.swift
  UtilConsumers.swift
  WinSDK+Overlay.swift)
set_target_properties(SystemPackage PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

# Availability macro definitions.
# Should stay in sync with the `availability` array in Package.swift,
# matching `sourceAvailability`, which is the minimum Swift availability.
# Availability support for Darwin platforms is omitted.
set(SWIFT_SYSTEM_AVAILABILITY_VERSIONS
  0.0.1 0.0.2 0.0.3
  1.1.0 1.1.1 1.2.0 1.2.1 1.3.0 1.3.1 1.3.2 1.4.0
  1.7.0
  199)
set(SWIFT_SYSTEM_SOURCE_AVAILABILITY
  "macOS 10.10, iOS 8.0, watchOS 2.0, tvOS 9.0, visionOS 1.0")
# The SE-0529 FilePath core carries @available(SwiftStdlib 9999, *). Mapped to
# 26, the floor where `Span` (which its code-unit views vend) is available.
# Should stay in sync with the SwiftStdlib 9999 macro in Package.swift.
set(SWIFT_SYSTEM_STDLIB_AVAILABILITY
  "macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26")
set(SWIFT_SYSTEM_AVAILABILITY_MACRO)
foreach(version IN LISTS SWIFT_SYSTEM_AVAILABILITY_VERSIONS)
  list(APPEND SWIFT_SYSTEM_AVAILABILITY_MACRO
    "SHELL:-enable-experimental-feature \"AvailabilityMacro=System ${version}:${SWIFT_SYSTEM_SOURCE_AVAILABILITY}\"")
endforeach()

target_compile_options(SystemPackage PRIVATE
  -enable-experimental-feature Lifetimes
  ${SWIFT_SYSTEM_AVAILABILITY_MACRO}
  "SHELL:-enable-experimental-feature \"AvailabilityMacro=SwiftStdlib 9999:${SWIFT_SYSTEM_STDLIB_AVAILABILITY}\""
  -swift-version 5
  "SHELL:-package-name swift-system")
# Selects the package flavor of the SE-0529 core: its own _internalInvariant,
# and a libc resolve() instead of the SwiftShims one.
target_compile_definitions(SystemPackage PRIVATE FILEPATH_PACKAGE)
# The dual-backing FilePath. `FilePath` itself is the wrapper in Wrapper/; the
# two implementations it dispatches to are _StdlibFilePath/ (SE-0529) and
# _SwiftSystemFilePath/ (the historical one), and FilePath/ is the compat
# adapter that reprovisions swift-system's own FilePath API on top of the core.
target_sources(SystemPackage PRIVATE
  _StdlibFilePath/FilePath.swift
  _StdlibFilePath/FilePathAnchor.swift
  _StdlibFilePath/FilePathCodeUnits.swift
  _StdlibFilePath/FilePathComponent.swift
  _StdlibFilePath/FilePathComponentView.swift
  _StdlibFilePath/FilePathDarwin.swift
  _StdlibFilePath/FilePathDecomposition.swift
  _StdlibFilePath/FilePathInternals.swift
  _StdlibFilePath/FilePathParsing.swift
  _StdlibFilePath/FilePathResolve.swift
  _StdlibFilePath/FilePathStringBridging.swift
  _StdlibFilePath/FilePathSystemString.swift
  _StdlibFilePath/FilePathWindows.swift)
target_sources(SystemPackage PRIVATE
  _SwiftSystemFilePath/_SwiftSystemFilePath.swift
  _SwiftSystemFilePath/_SwiftSystemFilePathComponents.swift
  _SwiftSystemFilePath/_SwiftSystemFilePathComponentView.swift
  _SwiftSystemFilePath/_SwiftSystemFilePathParsing.swift
  _SwiftSystemFilePath/_SwiftSystemFilePathString.swift
  _SwiftSystemFilePath/_SwiftSystemFilePathSyntax.swift
  _SwiftSystemFilePath/_SwiftSystemFilePathWindows.swift)
target_sources(SystemPackage PRIVATE
  Wrapper/WrapperComponent.swift
  Wrapper/WrapperComponentView.swift
  Wrapper/WrapperConformances.swift
  Wrapper/WrapperExtras.swift
  Wrapper/WrapperFilePath.swift
  Wrapper/WrapperRoot.swift
  Wrapper/WrapperString.swift
  Wrapper/WrapperSyntax.swift)
target_sources(SystemPackage PRIVATE
  FilePath/FilePathCompatInternals.swift
  FilePath/FilePathCompatShims.swift
  FilePath/FilePathComponentCompat.swift
  FilePath/FilePathComponents.swift
  FilePath/FilePathConformances.swift
  FilePath/FilePathString.swift
  FilePath/FilePathSyntax.swift
  FilePath/FilePathTemp.swift
  FilePath/FilePathTempPosix.swift
  FilePath/FilePathTempWindows.swift
  FilePath/SystemStringShim.swift)
target_sources(SystemPackage PRIVATE
  FileSystem/FileFlags.swift
  FileSystem/FileMode.swift
  FileSystem/FileType.swift
  FileSystem/Identifiers.swift
  FileSystem/Stat.swift)
if(CMAKE_SYSTEM_NAME STREQUAL Linux)
  target_sources(SystemPackage PRIVATE
    IORing/IOCompletion.swift
    IORing/IORequest.swift
    IORing/IORing.swift
    IORing/IORing+Util.swift
    IORing/RawIORequest.swift)
endif()
target_sources(SystemPackage PRIVATE
  Internals/Backcompat.swift
  Internals/CInterop.swift
  Internals/Constants.swift
  Internals/Exports.swift
  Internals/Mocking.swift
  Internals/RawBuffer.swift
  Internals/Syscalls.swift
  Internals/WindowsSyscallAdapters.swift)
target_link_libraries(SystemPackage PUBLIC
  CSystem)

set(SWIFT_SYSTEM_APPLE_PLATFORMS "Darwin" "iOS" "watchOS" "tvOS" "visionOS")
if(CMAKE_SYSTEM_NAME IN_LIST SWIFT_SYSTEM_APPLE_PLATFORMS)
  target_compile_definitions(SystemPackage PRIVATE SYSTEM_PACKAGE_DARWIN)
endif()

_install_target(SystemPackage)
set_property(GLOBAL APPEND PROPERTY SWIFT_SYSTEM_EXPORTS SystemPackage)
