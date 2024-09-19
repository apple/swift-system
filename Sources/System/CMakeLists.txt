#[[
This source file is part of the Swift System open source project

Copyright (c) 2020 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(SystemPackage
  Errno.swift
  FileDescriptor.swift
  FileHelpers.swift
  FileOperations.swift
  FilePermissions.swift
  MachPort.swift
  PlatformString.swift
  SystemString.swift
  Util.swift
  Util+StringArray.swift
  UtilConsumers.swift)
set_target_properties(SystemPackage PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_sources(SystemPackage PRIVATE
  FilePath/FilePath.swift
  FilePath/FilePathComponents.swift
  FilePath/FilePathComponentView.swift
  FilePath/FilePathParsing.swift
  FilePath/FilePathString.swift
  FilePath/FilePathSyntax.swift
  FilePath/FilePathWindows.swift)
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
