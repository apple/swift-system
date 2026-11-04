#[[
This source file is part of the Swift System open source project

Copyright (c) 2020 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_subdirectory(CSystem)
if(CMAKE_SYSTEM_NAME STREQUAL Linux)
  add_subdirectory(CSystemStatFS)
endif()
add_subdirectory(System)
