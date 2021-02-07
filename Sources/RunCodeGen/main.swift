
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import CodeGen

print("Populating platform constants")
try populatePlatformConstants(
  constantsPath: platformConstantsPath, testsPath: platformTestsPath)

print("Platform constants written to \(platformConstantsPath)")
print("Constants test written to \(platformTestsPath)")
