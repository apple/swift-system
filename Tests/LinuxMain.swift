import XCTest

import CodeGenTests
import SystemTests

var tests = [XCTestCaseEntry]()
tests += CodeGenTests.__allTests()
tests += SystemTests.__allTests()

XCTMain(tests)
