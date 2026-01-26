/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

import XCTest
import SystemPackage

final class TerminalTests: XCTestCase {

  // MARK: - TerminalDescriptor Initialization Tests

  func testTerminalDescriptorInitWithNonTerminal() throws {
    // Create a pipe - pipes are not terminals
    let fds = try FileDescriptor.pipe()
    defer {
      try? fds.readEnd.close()
      try? fds.writeEnd.close()
    }

    // Should return nil for non-terminal file descriptors
    XCTAssertNil(TerminalDescriptor(fds.readEnd))
    XCTAssertNil(TerminalDescriptor(fds.writeEnd))
    XCTAssertFalse(fds.readEnd.isTerminal)
    XCTAssertFalse(fds.writeEnd.isTerminal)
  }

  func testTerminalDescriptorUncheckedInit() throws {
    // Unchecked init doesn't validate - just wraps the descriptor
    let fd = FileDescriptor.standardInput
    let terminal = TerminalDescriptor(unchecked: fd)
    XCTAssertEqual(terminal.rawValue, fd.rawValue)
    XCTAssertEqual(terminal.fileDescriptor, fd)
  }

  func testFileDescriptorIsTerminalProperty() throws {
    // Test isTerminal property - may vary depending on test environment
    // Just verify it doesn't crash
    let _ = FileDescriptor.standardInput.isTerminal
    let _ = FileDescriptor.standardOutput.isTerminal
    let _ = FileDescriptor.standardError.isTerminal
  }

  func testFileDescriptorAsTerminalProperty() throws {
    // Create a pipe to ensure we have a non-terminal
    let fds = try FileDescriptor.pipe()
    defer {
      try? fds.readEnd.close()
      try? fds.writeEnd.close()
    }

    XCTAssertNil(fds.readEnd.asTerminal)
    XCTAssertNil(fds.writeEnd.asTerminal)
  }

  // MARK: - TerminalAttributes Basic Tests

  func testTerminalAttributesInit() {
    let attrs = TerminalAttributes()
    // Should create zero-initialized attributes
    XCTAssertNotNil(attrs)
  }

  func testTerminalAttributesEquatable() {
    let attrs1 = TerminalAttributes()
    let attrs2 = TerminalAttributes()

    XCTAssertEqual(attrs1, attrs2)

    var attrs3 = TerminalAttributes()
    attrs3.inputFlags.insert(.breakInterrupt)

    XCTAssertNotEqual(attrs1, attrs3)
  }

  func testTerminalAttributesHashable() {
    let attrs1 = TerminalAttributes()
    let attrs2 = TerminalAttributes()

    XCTAssertEqual(attrs1.hashValue, attrs2.hashValue)

    var set = Set<TerminalAttributes>()
    set.insert(attrs1)
    XCTAssertTrue(set.contains(attrs2))
  }

  // MARK: - Flag Tests

  func testInputFlags() {
    var flags = InputFlags()
    XCTAssertTrue(flags.isEmpty)

    flags.insert(.breakInterrupt)
    XCTAssertTrue(flags.contains(.breakInterrupt))
    XCTAssertFalse(flags.contains(.ignoreCR))

    flags.insert(.mapCRToNL)
    XCTAssertTrue(flags.contains(.breakInterrupt))
    XCTAssertTrue(flags.contains(.mapCRToNL))

    flags.remove(.breakInterrupt)
    XCTAssertFalse(flags.contains(.breakInterrupt))
    XCTAssertTrue(flags.contains(.mapCRToNL))

    // Test set operations
    let flags2: InputFlags = [.ignoreBreak, .ignoreCR]
    let union = flags.union(flags2)
    XCTAssertTrue(union.contains(.mapCRToNL))
    XCTAssertTrue(union.contains(.ignoreBreak))
    XCTAssertTrue(union.contains(.ignoreCR))
  }

  func testOutputFlags() {
    var flags = OutputFlags()
    XCTAssertTrue(flags.isEmpty)

    flags.insert(.postProcess)
    XCTAssertTrue(flags.contains(.postProcess))

    flags.insert(.mapNLToCRNL)
    XCTAssertTrue(flags.contains(.postProcess))
    XCTAssertTrue(flags.contains(.mapNLToCRNL))
  }

  func testControlFlags() {
    var flags = ControlFlags()
    XCTAssertTrue(flags.isEmpty)

    flags.insert(.enableReceiver)
    XCTAssertTrue(flags.contains(.enableReceiver))

    flags.insert(.characterSize8)
    XCTAssertTrue(flags.contains(.characterSize8))
  }

  func testLocalFlags() {
    var flags = LocalFlags()
    XCTAssertTrue(flags.isEmpty)

    flags.insert(.echo)
    XCTAssertTrue(flags.contains(.echo))

    flags.insert(.canonical)
    XCTAssertTrue(flags.contains(.canonical))

    flags.remove(.echo)
    XCTAssertFalse(flags.contains(.echo))
    XCTAssertTrue(flags.contains(.canonical))
  }

  // MARK: - TerminalAttributes Flag Properties

  func testTerminalAttributesFlagProperties() {
    var attrs = TerminalAttributes()

    // Test input flags
    attrs.inputFlags.insert(.breakInterrupt)
    XCTAssertTrue(attrs.inputFlags.contains(.breakInterrupt))

    // Test output flags
    attrs.outputFlags.insert(.postProcess)
    XCTAssertTrue(attrs.outputFlags.contains(.postProcess))

    // Test control flags
    attrs.controlFlags.insert(.enableReceiver)
    XCTAssertTrue(attrs.controlFlags.contains(.enableReceiver))

    // Test local flags
    attrs.localFlags.insert(.echo)
    XCTAssertTrue(attrs.localFlags.contains(.echo))
  }

  // MARK: - Control Character Tests

  func testControlCharacterConstants() {
    // Just verify the constants exist and have distinct values
    XCTAssertNotEqual(ControlCharacter.endOfFile.rawValue, ControlCharacter.interrupt.rawValue)
    XCTAssertNotEqual(ControlCharacter.erase.rawValue, ControlCharacter.kill.rawValue)
  }

  func testControlCharactersSubscript() {
    var cc = ControlCharacters()

    // Test typed subscript
    cc[.interrupt] = 0x03  // Ctrl-C
    XCTAssertEqual(cc[.interrupt], 0x03)

    cc[.endOfFile] = 0x04  // Ctrl-D
    XCTAssertEqual(cc[.endOfFile], 0x04)

    // Test minimum/time for non-canonical mode
    cc[.minimum] = 1
    cc[.time] = 0
    XCTAssertEqual(cc[.minimum], 1)
    XCTAssertEqual(cc[.time], 0)
  }

  func testControlCharactersRawIndexSubscript() {
    var cc = ControlCharacters()

    // Test raw index subscript
    XCTAssertGreaterThan(ControlCharacters.count, 0)

    for i in 0..<ControlCharacters.count {
      cc[rawIndex: i] = UInt8(i)
      XCTAssertEqual(cc[rawIndex: i], UInt8(i))
    }
  }

  func testControlCharactersDisabled() {
    let disabled = ControlCharacters.disabled
    XCTAssertEqual(disabled, 0xFF)  // _POSIX_VDISABLE is typically 0xFF
  }

  func testControlCharactersHashable() {
    var cc1 = ControlCharacters()
    cc1[.interrupt] = 0x03

    var cc2 = ControlCharacters()
    cc2[.interrupt] = 0x03

    XCTAssertEqual(cc1, cc2)
    XCTAssertEqual(cc1.hashValue, cc2.hashValue)

    cc2[.endOfFile] = 0x04
    XCTAssertNotEqual(cc1, cc2)
  }

  // MARK: - Baud Rate Tests

  func testBaudRateConstants() {
    // Test common baud rates
    XCTAssertNotEqual(BaudRate.b9600.rawValue, BaudRate.b19200.rawValue)
    XCTAssertNotEqual(BaudRate.b115200.rawValue, BaudRate.b9600.rawValue)

    // Test special hangUp rate
    XCTAssertNotNil(BaudRate.hangUp)
  }

  func testBaudRateEquatable() {
    XCTAssertEqual(BaudRate.b9600, BaudRate.b9600)
    XCTAssertNotEqual(BaudRate.b9600, BaudRate.b19200)
  }

  func testTerminalAttributesBaudRates() {
    var attrs = TerminalAttributes()

    attrs.inputSpeed = .b9600
    attrs.outputSpeed = .b19200

    // Verify they were set (values might be platform-specific)
    XCTAssertNotNil(attrs.inputSpeed)
    XCTAssertNotNil(attrs.outputSpeed)
  }

  func testTerminalAttributesSetSpeed() {
    var attrs = TerminalAttributes()
    attrs.setSpeed(.b115200)

    // After setSpeed, both input and output should be the same
    XCTAssertEqual(attrs.inputSpeed, attrs.outputSpeed)
  }

  // MARK: - Serial Port Convenience Properties

  func testCharacterSize() {
    var attrs = TerminalAttributes()

    // Test character size get/set
    attrs.characterSize = .bits8
    XCTAssertEqual(attrs.characterSize, .bits8)

    attrs.characterSize = .bits7
    XCTAssertEqual(attrs.characterSize, .bits7)

    // Verify CSIZE mask is being cleared correctly
    attrs.characterSize = .bits5
    XCTAssertEqual(attrs.characterSize, .bits5)
  }

  func testParity() {
    var attrs = TerminalAttributes()

    attrs.parity = .none
    XCTAssertEqual(attrs.parity, .none)

    attrs.parity = .even
    XCTAssertEqual(attrs.parity, .even)

    attrs.parity = .odd
    XCTAssertEqual(attrs.parity, .odd)
  }

  func testStopBits() {
    var attrs = TerminalAttributes()

    attrs.stopBits = .one
    XCTAssertEqual(attrs.stopBits, .one)

    attrs.stopBits = .two
    XCTAssertEqual(attrs.stopBits, .two)
  }

  // MARK: - Raw Mode Tests

  func testMakeRaw() {
    var attrs = TerminalAttributes()

    // Set some flags that makeRaw should clear
    attrs.localFlags.insert([.canonical, .echo, .signals])
    attrs.inputFlags.insert(.breakInterrupt)
    attrs.outputFlags.insert(.postProcess)

    attrs.makeRaw()

    // Verify raw mode flags are set correctly
    XCTAssertFalse(attrs.localFlags.contains(.canonical))
    XCTAssertFalse(attrs.localFlags.contains(.echo))
    XCTAssertFalse(attrs.localFlags.contains(.signals))
    XCTAssertFalse(attrs.inputFlags.contains(.breakInterrupt))
    XCTAssertFalse(attrs.outputFlags.contains(.postProcess))

    // Verify character size is 8 bits
    XCTAssertTrue(attrs.controlFlags.contains(.characterSize8))

    // Verify MIN and TIME are set for immediate single-character reads
    XCTAssertEqual(attrs.controlCharacters[.minimum], 1)
    XCTAssertEqual(attrs.controlCharacters[.time], 0)
  }

  func testRawMethod() {
    var attrs = TerminalAttributes()
    attrs.localFlags.insert(.canonical)

    let rawAttrs = attrs.raw()

    // Original should be unchanged
    XCTAssertTrue(attrs.localFlags.contains(.canonical))

    // New copy should be in raw mode
    XCTAssertFalse(rawAttrs.localFlags.contains(.canonical))
  }

  // MARK: - SetAction Tests

  func testSetActionConstants() {
    XCTAssertNotNil(TerminalAttributes.SetAction.now)
    XCTAssertNotNil(TerminalAttributes.SetAction.afterDrain)
    XCTAssertNotNil(TerminalAttributes.SetAction.afterFlush)

    #if canImport(Darwin)
    XCTAssertNotNil(TerminalAttributes.SetAction.soft)
    #endif
  }

  // MARK: - Queue and FlowAction Tests

  func testQueueConstants() {
    XCTAssertNotNil(TerminalDescriptor.Queue.input)
    XCTAssertNotNil(TerminalDescriptor.Queue.output)
    XCTAssertNotNil(TerminalDescriptor.Queue.both)
  }

  func testFlowActionConstants() {
    XCTAssertNotNil(TerminalDescriptor.FlowAction.suspendOutput)
    XCTAssertNotNil(TerminalDescriptor.FlowAction.resumeOutput)
    XCTAssertNotNil(TerminalDescriptor.FlowAction.sendStop)
    XCTAssertNotNil(TerminalDescriptor.FlowAction.sendStart)
  }

  // MARK: - WindowSize Tests

  func testWindowSizeInit() {
    let size = TerminalDescriptor.WindowSize(rows: 24, columns: 80)
    XCTAssertEqual(size.rows, 24)
    XCTAssertEqual(size.columns, 80)
  }

  func testWindowSizeProperties() {
    var size = TerminalDescriptor.WindowSize(rows: 24, columns: 80)

    size.rows = 40
    size.columns = 120

    XCTAssertEqual(size.rows, 40)
    XCTAssertEqual(size.columns, 120)
  }

  func testWindowSizeEquatable() {
    let size1 = TerminalDescriptor.WindowSize(rows: 24, columns: 80)
    let size2 = TerminalDescriptor.WindowSize(rows: 24, columns: 80)
    let size3 = TerminalDescriptor.WindowSize(rows: 40, columns: 120)

    XCTAssertEqual(size1, size2)
    XCTAssertNotEqual(size1, size3)
  }

  func testWindowSizeHashable() {
    let size1 = TerminalDescriptor.WindowSize(rows: 24, columns: 80)
    let size2 = TerminalDescriptor.WindowSize(rows: 24, columns: 80)

    XCTAssertEqual(size1.hashValue, size2.hashValue)

    var set = Set<TerminalDescriptor.WindowSize>()
    set.insert(size1)
    XCTAssertTrue(set.contains(size2))
  }

  // MARK: - Integration Tests (require actual terminal)

  func testTerminalAttributesRoundtrip() throws {
    // Only run if we actually have a terminal
    guard let terminal = TerminalDescriptor(.standardInput) else {
      throw XCTSkip("stdin is not a terminal")
    }

    // Get current attributes
    let original = try terminal.attributes()

    // Verify we can read them back
    let readBack = try terminal.attributes()
    XCTAssertEqual(original, readBack)
  }

  func testTerminalSetAttributes() throws {
    guard let terminal = TerminalDescriptor(.standardInput) else {
      throw XCTSkip("stdin is not a terminal")
    }

    let original = try terminal.attributes()
    defer {
      // Always restore original attributes
      try? terminal.setAttributes(original, when: .now)
    }

    // Make a modification
    var modified = original
    modified.localFlags.insert(.echoNL)

    // Set the modified attributes
    try terminal.setAttributes(modified, when: .now)

    // Read them back
    let readBack = try terminal.attributes()
    XCTAssertTrue(readBack.localFlags.contains(.echoNL))
  }

  func testWithAttributes() throws {
    guard let terminal = TerminalDescriptor(.standardInput) else {
      throw XCTSkip("stdin is not a terminal")
    }

    let original = try terminal.attributes()

    // Modify attributes within scope
    try terminal.withAttributes({ attrs in
      attrs.localFlags.insert(.echoNL)
    }) {
      // Inside the block, attributes should be modified
      let current = try terminal.attributes()
      XCTAssertTrue(current.localFlags.contains(.echoNL))
    }

    // After the block, attributes should be restored
    let restored = try terminal.attributes()
    XCTAssertEqual(original.localFlags, restored.localFlags)
  }

  func testWithRawMode() throws {
    guard let terminal = TerminalDescriptor(.standardInput) else {
      throw XCTSkip("stdin is not a terminal")
    }

    let original = try terminal.attributes()

    try terminal.withRawMode {
      // Inside raw mode
      let current = try terminal.attributes()
      XCTAssertFalse(current.localFlags.contains(.canonical))
      XCTAssertFalse(current.localFlags.contains(.echo))
    }

    // After exiting raw mode
    let restored = try terminal.attributes()
    XCTAssertEqual(original.localFlags, restored.localFlags)
  }

  func testWindowSizeOperation() throws {
    guard let terminal = TerminalDescriptor(.standardOutput) else {
      throw XCTSkip("stdout is not a terminal")
    }

    // Just verify we can get window size without crashing
    let size = try terminal.windowSize()
    XCTAssertGreaterThan(size.rows, 0)
    XCTAssertGreaterThan(size.columns, 0)
  }

  func testTerminalOperationsDontCrash() throws {
    guard let terminal = TerminalDescriptor(.standardOutput) else {
      throw XCTSkip("stdout is not a terminal")
    }

    // These should not crash, though they may fail with errors
    // We're just testing they're callable
    try? terminal.drain()
    try? terminal.flush(.output)
    try? terminal.flow(.resumeOutput)
  }
}

#endif
