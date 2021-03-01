/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import XCTest

#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
final class SocketAddressTest: XCTestCase {
  func test_addressWithArbitraryData() {
    for length in MemoryLayout<CInterop.SockAddr>.size ... 255 {
      let range = 0 ..< UInt8(truncatingIfNeeded: length)
      let data = Array<UInt8>(range)
      data.withUnsafeBytes { source in
        let address = SocketAddress(source)
        address.withUnsafeBytes { copy in
          XCTAssertEqual(copy.count, length)
          XCTAssertTrue(range.elementsEqual(copy), "\(length)")
        }
      }
    }
  }

  func test_addressWithSockAddr() {
    for length in MemoryLayout<CInterop.SockAddr>.size ... 255 {
      let range = 0 ..< UInt8(truncatingIfNeeded: length)
      let data = Array<UInt8>(range)
      data.withUnsafeBytes { source in
        let p = source.baseAddress!.assumingMemoryBound(to: CInterop.SockAddr.self)
        let address = SocketAddress(
          address: p,
          length: CInterop.SockLen(source.count))
        address.withUnsafeBytes { copy in
          XCTAssertEqual(copy.count, length)
          XCTAssertTrue(range.elementsEqual(copy), "\(length)")
        }
      }
    }
  }

  func test_description() {
    let ipv4 = SocketAddress(SocketAddress.IPv4(address: "1.2.3.4", port: 80)!)
    let desc4 = "\(ipv4)"
    XCTAssertEqual(desc4, "SocketAddress(family: ipv4, address: 1.2.3.4:80)")

    let ipv6 = SocketAddress(SocketAddress.IPv6(address: "1234::ff", port: 80)!)
    let desc6 = "\(ipv6)"
    XCTAssertEqual(desc6, "SocketAddress(family: ipv6, address: [1234::ff]:80)")

    let local = SocketAddress(SocketAddress.Local("/tmp/test.sock"))
    let descl = "\(local)"
    XCTAssertEqual(descl, "SocketAddress(family: local, address: /tmp/test.sock)")
  }

  // MARK: IPv4

  func test_addressWithIPv4Address() {
    let ipv4 = SocketAddress.IPv4(address: "1.2.3.4", port: 42)!
    let address = SocketAddress(ipv4)
    if case .large = address._variant {
      XCTFail("IPv4 address in big representation")
    }
    XCTAssertEqual(address.family, .ipv4)
    if let extracted = SocketAddress.IPv4(address) {
      XCTAssertEqual(extracted, ipv4)
    } else {
      XCTFail("Cannot extract IPv4 address")
    }
  }

  func test_ipv4_address_string_conversions() {
    typealias Address = SocketAddress.IPv4.Address

    func check(
      _ string: String,
      _ value: UInt32?,
      file: StaticString = #file,
      line: UInt = #line
    ) {
      switch (Address(string), value) {
      case let (address?, value?):
        XCTAssertEqual(address.rawValue, value, file: file, line: line)
      case let (address?, nil):
        let s = String(address.rawValue, radix: 16)
        XCTFail("Got \(s), expected nil", file: file, line: line)
      case let (nil, value?):
        let s = String(value, radix: 16)
        XCTFail("Got nil, expected \(s), file: file, line: line")
      case (nil, nil):
        // OK
        break
      }

      if let value = value {
        let address = Address(rawValue: value)
        let actual = "\(address)"
        XCTAssertEqual(
          actual, string,
          "Mismatching description. Expected: \(string), actual: \(actual)",
          file: file, line: line)
      }
    }
    check("0.0.0.0", 0)
    check("0.0.0.1", 1)
    check("1.2.3.4", 0x01020304)
    check("255.255.255.255", 0xFFFFFFFF)
    check("apple.com", nil)
    check("256.0.0.0", nil)
  }

  func test_ipv4_description() {
    let a1 = SocketAddress.IPv4(address: "1.2.3.4", port: 42)!
    XCTAssertEqual("\(a1)", "1.2.3.4:42")

    let a2 = SocketAddress.IPv4(address: "192.168.1.1", port: 80)!
    XCTAssertEqual("\(a2)", "192.168.1.1:80")
  }

  // MARK: IPv6

  func test_addressWithIPv6Address() {
    let ipv6 = SocketAddress.IPv6(address: "2001:db8::", port: 42)!
    let address = SocketAddress(ipv6)
    if case .large = address._variant {
      XCTFail("IPv6 address in big representation")
    }
    XCTAssertEqual(address.family, .ipv6)
    if let extracted = SocketAddress.IPv6(address) {
      XCTAssertEqual(extracted, ipv6)
    } else {
      XCTFail("Cannot extract IPv6 address")
    }
  }

  func test_ipv6_address_string_conversions() {
    typealias Address = SocketAddress.IPv6.Address

    func check(
      _ string: String,
      _ value: [UInt8]?,
      file: StaticString = #file,
      line: UInt = #line
    ) {
      let value = value.map { value in
        value.withUnsafeBytes { bytes in
          Address(bytes: bytes)
        }
      }
      switch (Address(string), value) {
      case let (address?, value?):
        XCTAssertEqual(address, value, file: file, line: line)
      case let (address?, nil):
        XCTFail("Got \(address), expected nil", file: file, line: line)
      case let (nil, value?):
        XCTFail("Got nil, expected \(value), file: file, line: line")
      case (nil, nil):
        // OK
        break
      }
    }
    check(
      "::",
      [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
       0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    check(
      "0011:2233:4455:6677:8899:aabb:ccdd:eeff",
      [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
       0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff])
    check(
      "1:203:405:607:809:a0b:c0d:e0f",
      [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
       0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])
    check("1.2.3.4", nil)
    check("apple.com", nil)
  }

  func test_ipv6_description() {
    let a1 = SocketAddress.IPv6(address: "2001:db8:85a3:8d3:1319:8a2e:370:7348", port: 42)!
    XCTAssertEqual("\(a1)", "[2001:db8:85a3:8d3:1319:8a2e:370:7348]:42")

    let a2 = SocketAddress.IPv6(address: "2001::42", port: 80)!
    XCTAssertEqual("\(a2)", "[2001::42]:80")
  }

  // MARK: Local

  func test_addressWithLocalAddress_smol() {
    let smolLocal = SocketAddress.Local("/tmp/test.sock")
    let smol = SocketAddress(smolLocal)
    if case .large = smol._variant {
      XCTFail("Local address with short path in big representation")
    }
    XCTAssertEqual(smol.family, .local)
    if let extracted = SocketAddress.Local(smol) {
      XCTAssertEqual(extracted, smolLocal)
    } else {
      XCTFail("Cannot extract Local address")
    }
  }

  func test_addressWithLocalAddress_large() {
    let largeLocal = SocketAddress.Local(
      "This is a really long filename, it almost doesn't fit on one line.sock")
    let large = SocketAddress(largeLocal)
    if case .small = large._variant {
      XCTFail("Local address with long path in small representation")
    }
    XCTAssertEqual(large.family, .local)
    if let extracted = SocketAddress.Local(large) {
      XCTAssertEqual(extracted, largeLocal)
    } else {
      XCTFail("Cannot extract Local address")
    }
  }

}
