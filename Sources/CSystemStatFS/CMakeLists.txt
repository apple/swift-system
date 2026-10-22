#[[
This source file is part of the Swift System open source project

Copyright (c) 2026 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(CSystemStatFS INTERFACE)
target_include_directories(CSystemStatFS INTERFACE
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
  $<INSTALL_INTERFACE:include/CSystemStatFS>)

install(FILES
  CSystemStatFS.h
  module.modulemap
  DESTINATION include/CSystemStatFS)
set_property(GLOBAL APPEND PROPERTY SWIFT_SYSTEM_EXPORTS CSystemStatFS)
