#[[
This source file is part of the Swift System open source project

Copyright (c) 2020 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

cmake_minimum_required(VERSION 3.16.0)
project(swift-system
  LANGUAGES C Swift)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

include(SwiftSupport)

add_subdirectory(Sources)

get_property(SWIFT_SYSTEM_EXPORTS GLOBAL PROPERTY SWIFT_SYSTEM_EXPORTS)
export(TARGETS ${SWIFT_SYSTEM_EXPORTS}
  NAMESPACE SwiftSystem::
  FILE swift-system-config.cmake
  EXPORT_LINK_INTERFACE_LIBRARIES)
