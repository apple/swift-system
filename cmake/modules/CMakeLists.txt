#[[
This source file is part of the Swift System open source Project

Copyright (c) 2021 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

set(SWIFT_SYSTEM_EXPORTS_FILE ${CMAKE_CURRENT_BINARY_DIR}/SwiftSystemExports.cmake)

configure_file(SwiftSystemConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/SwiftSystemConfig.cmake)

get_property(SWIFT_SYSTEM_EXPORTS GLOBAL PROPERTY SWIFT_SYSTEM_EXPORTS)
export(TARGETS ${SWIFT_SYSTEM_EXPORTS}
  NAMESPACE SwiftSystem::
  FILE ${SWIFT_SYSTEM_EXPORTS_FILE}
  EXPORT_LINK_INTERFACE_LIBRARIES)
