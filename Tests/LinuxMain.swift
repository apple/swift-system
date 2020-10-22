import XCTest

import SystemTests

var tests = [XCTestCaseEntry]()
tests += SystemTests.__allTests()

XCTMain(tests)
