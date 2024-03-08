/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// Tests for PlatformString, SystemString, and FilePath's forwarding APIs

// TODO: Adapt test to Windows

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

private func makeRaw(
  _ str: String
) -> [CInterop.PlatformChar] {
  var str = str
#if os(Windows)
  var array = Array(str.utf16)
#else
  var array = str.withUTF8 { $0.withMemoryRebound(to: CChar.self, Array.init) }
#endif
  array.append(0)
  return array
}
private func makeStr(
  _ raw: [CInterop.PlatformChar]
) -> String {
  precondition((raw.last ?? 0) == 0)
  // FIXME: Unfortunately, this relies on some of the same mechanisms tested...
  return raw.withUnsafeBufferPointer {
    String(platformString: $0.baseAddress!)
  }
}

struct StringTest: TestCase {
  // The error-corrected string
  var string: String

  // The raw contents
  var raw: [CInterop.PlatformChar]

  var isValid: Bool

  var file: StaticString
  var line: UInt

  func runAllTests() {
    precondition((raw.last ?? 0) == 0, "invalid test case")

    // Test idempotence post-validation
    string.withPlatformString {
      if isValid {
        let len = system_platform_strlen($0)
        expectEqual(raw.count, 1+len, "Validation idempotence")
        expectEqualSequence(raw, UnsafeBufferPointer(start: $0, count: 1+len),
          "Validation idempotence")
      }

      let str = String(platformString: $0)
      expectEqualSequence(
        string.unicodeScalars, str.unicodeScalars, "Validation idempotence")

      let validStr = String(validatingPlatformString: $0)
      expectEqual(string, validStr, "Validation idempotence")
    }

    // Test String, SystemString, FilePath construction
    let sysStr = SystemString(string)
    expectEqualSequence(string.unicodeScalars, sysStr.string.unicodeScalars)
    expectEqual(string, String(decoding: sysStr))
    expectEqual(string, String(validating: sysStr))

    let sysRaw = raw.withUnsafeBufferPointer {
      SystemString(platformString: $0.baseAddress!)
    }
    expectEqual(string, String(decoding: sysRaw))
    expectEqual(isValid, nil != String(validating: sysRaw))
    expectEqual(isValid, sysStr == sysRaw)

    let strDecoded = raw.withUnsafeBufferPointer {
      String(platformString: $0.baseAddress!)
    }
    expectEqualSequence(string.unicodeScalars, strDecoded.unicodeScalars)

    let strValidated = raw.withUnsafeBufferPointer {
      String(validatingPlatformString: $0.baseAddress!)
    }
    expectEqual(isValid, strValidated != nil, "String(validatingPlatformString:)")
    expectEqual(isValid, strDecoded == strValidated,
      "String(validatingPlatformString:)")

    // Test null insertion
    let rawChars = raw.lazy.map { SystemChar($0) }
    expectEqual(sysRaw, SystemString(rawChars.dropLast()))
    sysRaw.withNullTerminatedSystemChars {
      expectEqualSequence(rawChars, $0, "rawChars")
    }

    // Whether the content has normalized separators
    let hasNormalSeparators: Bool = {
      var normalSys = sysRaw
      normalSys._normalizeSeparators()
      return normalSys == sysRaw
    }()

    let fpStr = FilePath(string)
    if hasNormalSeparators {
      expectEqualSequence(
        string.unicodeScalars, fpStr.string.unicodeScalars, "FilePath from string")
      expectEqual(string, String(decoding: fpStr), "FilePath from string")
      expectEqual(string, String(validating: fpStr), "FilePath from string")
      expectEqual(sysStr, fpStr._storage, "FilePath from string")
    }

    let fpRaw = FilePath(sysRaw)
    if hasNormalSeparators {
      expectEqual(string, String(decoding: fpRaw), "raw FilePath")
      expectEqual(isValid, nil != String(validating: fpRaw), "raw FilePath")
      expectEqual(sysRaw, fpRaw._storage, "raw FilePath")
      expectEqual(isValid, fpStr == fpRaw, "raw FilePath")
    }
    fpRaw.withPlatformString { fp0 in
      fpRaw._storage.withPlatformString { storage0 in
        expectEqual(fp0, storage0,
          "FilePath withPlatformString address forwarding")
      }
    }

    let isComponent = string == fpRaw.components.first?.string

    if hasNormalSeparators && isComponent {
      // Test FilePath.Component
      let compStr = FilePath.Component(string)!
      expectEqualSequence(
        string.unicodeScalars, compStr.string.unicodeScalars, "Component from string")
      expectEqual(string, String(decoding: compStr), "Component from string")
      expectEqual(string, String(validating: compStr), "Component from string")
      expectEqual(sysStr, compStr._slice.base, "Component from string")

      let compRaw = FilePath.Component(sysRaw)!
      expectEqual(string, String(decoding: compRaw), "raw Component")
      expectEqual(isValid, nil != String(validating: compRaw), "raw Component")
      expectEqual(sysRaw, compRaw._slice.base, "raw Component")
      expectEqual(isValid, compStr == compRaw, "raw Component")

      // TODO: Below works after we add last component optimization
      // compRaw.withPlatformString { fp0 in
      //   compRaw.slice.base.withPlatformString { storage0 in
      //     expectEqual(fp0, storage0,
      //       "Component withPlatformString address forwarding")
      //   }
      // }

    }

    sysRaw.withPlatformString {
      let len = system_platform_strlen($0)
      expectEqual(raw.count, 1+len, "SystemString.withPlatformString")
      expectEqualSequence(raw, UnsafeBufferPointer(start: $0, count: 1+len),
        "SystemString.withPlatformString")
      if hasNormalSeparators {
        expectEqual(sysRaw, FilePath(platformString: $0)._storage)
        if isComponent {
          expectEqual(
            sysRaw, FilePath.Component(platformString: $0)!._slice.base)
        }
      }
    }

  }
}

extension StringTest {

  static func valid(
    _ str: String,
    file: StaticString = #file, line: UInt = #line
  ) -> StringTest {
    StringTest(
      string: str,
      raw: makeRaw(str),
      isValid: true,
      file: file, line: line)
  }

  static func invalid(
    _ raw: [CInterop.PlatformChar],
    file: StaticString = #file, line: UInt = #line
  ) -> StringTest {
    StringTest(
      string: makeStr(raw),
      raw: raw,
      isValid: false,
      file: file, line: line)
  }
}

final class SystemStringTest: XCTestCase {

  let validCases: Array<StringTest> = [
    .valid(""),
    .valid("a"),
    .valid("abc"),
    .valid("/あ/🧟‍♀️"),
    .valid("/あ\\🧟‍♀️"),
    .valid("/あ\\🧟‍♀️///"),
    .valid("あ_🧟‍♀️"),
    .valid("/a/b/c"),
    .valid("/a/b/c//"),
    .valid(#"\a\b\c\\"#),
    .valid("_a_b_c"),
  ]

  #if os(Windows)
  let invalidCases: Array<StringTest> = [
    // TODO: Unpaired surrogates
  ]
  #else
  let invalidCases: Array<StringTest> = [
    .invalid([CChar(bitPattern: 0x80), 0]),
    .invalid([CChar(bitPattern: 0xFF), 0]),
    .invalid([0x2F, 0x61, 0x2F, 0x62, 0x2F, CChar(bitPattern: 0x83), 0]),
  ]
  #endif

  func testPlatformString() {
    for test in validCases {
      test.runAllTests()
    }
    for test in invalidCases {
      test.runAllTests()
    }
  }

  // TODO: More exhaustive RAC+RRC SystemString tests

  func testAdHoc() {
    var str: SystemString = "abc"
    str.append(SystemChar(ascii: "d"))
    XCTAssert(str == "abcd")
    XCTAssert(str.count == 4)
    XCTAssert(str.count == str.length)

    str.reserveCapacity(100)
    XCTAssert(str == "abcd")
  }

  func testStringProperty() {
    let source: [CInterop.PlatformChar] = [0x61, 0x62, 0, 0x63]
    let str = SystemString(platformString: source)
    XCTAssertEqual(str.string, str[...].string)
  }
}

extension SystemStringTest {
  func test_String_initWithArrayConversion() {
    let source: [CInterop.PlatformChar] = [0x61, 0x62, 0, 0x63]
    let str = String(platformString: source)
    source.withUnsafeBufferPointer {
      XCTAssertEqual(str, String(platformString: $0.baseAddress!))
    }
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_String_initWithStringConversion() {
    let source = "ab\0c"
    var str: String
    str = String(platformString: source)
    source.withPlatformString {
      XCTAssertEqual(str, String(platformString: $0))
    }
    str = String(platformString: "")
    XCTAssertEqual(str.isEmpty, true)
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_String_initWithInoutConversion() {
    var c: CInterop.PlatformChar = 0
    let str = String(platformString: &c)
    // Any other value of `c` would violate the null-terminated precondition
    XCTAssertEqual(str.isEmpty, true)
  }

  func test_String_validatingPlatformStringWithArrayConversion() {
    var source: [CInterop.PlatformChar] = [0x61, 0x62, 0, 0x63]
    var str: String?
    str = String(validatingPlatformString: source)
    source.withUnsafeBufferPointer {
      XCTAssertEqual(str, String(validatingPlatformString: $0.baseAddress!))
    }
    source[1] = CInterop.PlatformChar(truncatingIfNeeded: 0xdfff)
    str = String(validatingPlatformString: source)
    XCTAssertNil(str)
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_String_validatingPlatformStringWithStringConversion() {
    let source = "ab\0c"
    var str: String?
    str = String(validatingPlatformString: source)
    XCTAssertNotNil(str)
    source.withPlatformString {
      XCTAssertEqual(str, String.init(validatingPlatformString: $0))
    }
    str = String(validatingPlatformString: "")
    XCTAssertNotNil(str)
    XCTAssertEqual(str?.isEmpty, true)
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_String_validatingPlatformStringWithInoutConversion() {
    var c: CInterop.PlatformChar = 0
    let str = String(validatingPlatformString: &c)
    // Any other value of `c` would violate the null-terminated precondition
    XCTAssertNotNil(str)
    XCTAssertEqual(str?.isEmpty, true)
  }

  func test_FilePath_initWithArrayConversion() {
    let source: [CInterop.PlatformChar] = [0x61, 0x62, 0, 0x63]
    let path = FilePath(platformString: source)
    source.withUnsafeBufferPointer {
      XCTAssertEqual(path, FilePath(platformString: $0.baseAddress!))
    }
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_FilePath_initWithStringConversion() {
    let source = "ab\0c"
    var path: FilePath
    path = FilePath(platformString: source)
    source.withPlatformString {
      XCTAssertEqual(path, FilePath(platformString: $0))
    }
    path = FilePath(platformString: "")
    XCTAssertEqual(path.string.isEmpty, true)
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_FilePath_initWithInoutConversion() {
    var c: CInterop.PlatformChar = 0
    let path = FilePath(platformString: &c)
    // Any other value of `c` would violate the null-terminated precondition
    XCTAssertEqual(path.string.isEmpty, true)
  }

  func test_FilePathComponent_initWithArrayConversion() {
    var source: [CInterop.PlatformChar] = [0x61, 0x62, 0, 0x63]
    var component: FilePath.Component?
    component = FilePath.Component(platformString: source)
    source.withUnsafeBufferPointer {
      XCTAssertEqual(component, .init(platformString: $0.baseAddress!))
    }
    source[1] = CInterop.PlatformChar(truncatingIfNeeded: 0xffff)
    component = FilePath.Component(platformString: source)
    source.withUnsafeBufferPointer {
      XCTAssertEqual(component, .init(platformString: $0.baseAddress!))
    }
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_FilePathComponent_initWithStringConversion() {
    let source = "ab\0c"
    var component: FilePath.Component?
    component = FilePath.Component(platformString: source)
    source.withPlatformString {
      XCTAssertEqual(component, FilePath.Component(platformString: $0))
    }
    component = FilePath.Component(platformString: "")
    XCTAssertNil(component)
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_FilePathComponent_initWithInoutConversion() {
    var c: CInterop.PlatformChar = 0
    let component = FilePath.Component(platformString: &c)
    XCTAssertNil(component)
  }

  func test_FilePathRoot_initWithArrayConversion() {
    let source: [CInterop.PlatformChar]
    #if os(Windows)
    source = [0x41, 0x3a, 0x5c, 0, 0x7f]
    #else // unix
    source = [0x2f, 0, 0x7f]
    #endif
    var root: FilePath.Root?
    root = FilePath.Root(platformString: source)
    source.withUnsafeBufferPointer {
      XCTAssertEqual(root, FilePath.Root(platformString: $0.baseAddress!))
    }
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_FilePathRoot_initWithStringConversion() {
    #if os(Windows)
    let source = "C:\\\0 and the rest"
    #else // unix
    let source = "/\0 and the rest"
    #endif
    var root: FilePath.Root?
    root = FilePath.Root(platformString: source)
    source.withPlatformString {
      XCTAssertEqual(root, FilePath.Root(platformString: $0))
    }
    root = FilePath.Root(platformString: "")
    XCTAssertNil(root)
  }

  @available(*, deprecated) // silence the warning for using a deprecated api
  func test_FilePathRoot_initWithInoutConversion() {
    var c: CInterop.PlatformChar = 0
    let root = FilePath.Root(platformString: &c)
    XCTAssertNil(root)
  }
}
