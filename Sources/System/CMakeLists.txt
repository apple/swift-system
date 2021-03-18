#[[
This source file is part of the Swift System open source project

Copyright (c) 2020 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(System
  Errno.swift
  FileDescriptor.swift
  FileHelpers.swift
  FileOperations.swift
  FilePermissions.swift
  PlatformString.swift
  SystemString.swift
  Util.swift
  UtilConsumers.swift)
target_sources(System PRIVATE
  FilePath/FilePath.swift
  FilePath/FilePathComponents.swift
  FilePath/FilePathComponentView.swift
  FilePath/FilePathParsing.swift
  FilePath/FilePathString.swift
  FilePath/FilePathSyntax.swift
  FilePath/FilePathWindows.swift)
target_sources(System PRIVATE
  Internals/CInterop.swift
  Internals/Constants.swift
  Internals/Exports.swift
  Internals/Mocking.swift
  Internals/Syscalls.swift
  Internals/WindowsSyscallAdapters.swift)
target_link_libraries(System PRIVATE
  CSystem)


_install_target(System)
set_property(GLOBAL APPEND PROPERTY SWIFT_SYSTEM_EXPORTS System)
