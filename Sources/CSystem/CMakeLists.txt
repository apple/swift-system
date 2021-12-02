#[[
This source file is part of the Swift System open source project

Copyright (c) 2020 Apple Inc. and the Swift System project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(CSystem INTERFACE)
target_include_directories(CSystem INTERFACE
  include)


install(FILES
  include/CSystemLinux.h
  include/CSystemWindows.h
  include/module.modulemap
  DESTINATION include/CSystem)
set_property(GLOBAL APPEND PROPERTY SWIFT_SYSTEM_EXPORTS CSystem)
