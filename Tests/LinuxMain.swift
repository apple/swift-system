/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

import SystemTests

var tests = [XCTestCaseEntry]()
tests += SystemTests.__allTests()

XCTMain(tests)
