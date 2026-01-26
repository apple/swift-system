/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

// MARK: - InputFlags

/// Input mode flags for terminal attributes.
///
/// These flags control preprocessing of input characters before they are
/// made available to a reading process.
@frozen
@available(System 99, *)
public struct InputFlags: OptionSet, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.TerminalFlags

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.TerminalFlags) {
    self.rawValue = rawValue
  }

  /// Signal interrupt on break condition.
  ///
  /// The corresponding C constant is \`BRKINT\`.
  @_alwaysEmitIntoClient
  public static var breakInterrupt: Self { Self(rawValue: _BRKINT) }

  /// Map carriage return to newline on input.
  ///
  /// The corresponding C constant is \`ICRNL\`.
  @_alwaysEmitIntoClient
  public static var mapCRToNL: Self { Self(rawValue: _ICRNL) }

  /// Ignore break condition.
  ///
  /// The corresponding C constant is \`IGNBRK\`.
  @_alwaysEmitIntoClient
  public static var ignoreBreak: Self { Self(rawValue: _IGNBRK) }

  /// Ignore carriage return on input.
  ///
  /// The corresponding C constant is \`IGNCR\`.
  @_alwaysEmitIntoClient
  public static var ignoreCR: Self { Self(rawValue: _IGNCR) }

  /// Ignore characters with parity errors.
  ///
  /// The corresponding C constant is \`IGNPAR\`.
  @_alwaysEmitIntoClient
  public static var ignoreParityErrors: Self { Self(rawValue: _IGNPAR) }

  /// Map newline to carriage return on input.
  ///
  /// The corresponding C constant is \`INLCR\`.
  @_alwaysEmitIntoClient
  public static var mapNLToCR: Self { Self(rawValue: _INLCR) }

  /// Enable input parity checking.
  ///
  /// The corresponding C constant is \`INPCK\`.
  @_alwaysEmitIntoClient
  public static var parityCheck: Self { Self(rawValue: _INPCK) }

  /// Strip the eighth bit from input characters.
  ///
  /// The corresponding C constant is \`ISTRIP\`.
  @_alwaysEmitIntoClient
  public static var stripHighBit: Self { Self(rawValue: _ISTRIP) }

  /// Enable any character to restart output.
  ///
  /// The corresponding C constant is \`IXANY\`.
  @_alwaysEmitIntoClient
  public static var restartAny: Self { Self(rawValue: _IXANY) }

  /// Enable start/stop input flow control.
  ///
  /// The corresponding C constant is \`IXOFF\`.
  @_alwaysEmitIntoClient
  public static var startStopInput: Self { Self(rawValue: _IXOFF) }

  /// Enable start/stop output flow control.
  ///
  /// The corresponding C constant is \`IXON\`.
  @_alwaysEmitIntoClient
  public static var startStopOutput: Self { Self(rawValue: _IXON) }

  /// Mark parity and framing errors in the input stream.
  ///
  /// The corresponding C constant is \`PARMRK\`.
  @_alwaysEmitIntoClient
  public static var markParityErrors: Self { Self(rawValue: _PARMRK) }

  /// Ring bell when input queue is full.
  ///
  /// The corresponding C constant is \`IMAXBEL\`.
  @_alwaysEmitIntoClient
  public static var ringBellOnFull: Self { Self(rawValue: _IMAXBEL) }

  /// Assume input is UTF-8 encoded for correct VERASE handling.
  ///
  /// The corresponding C constant is \`IUTF8\`.
  @_alwaysEmitIntoClient
  public static var utf8Input: Self { Self(rawValue: _IUTF8) }

  #if os(Linux)
  /// Map uppercase characters to lowercase on input.
  ///
  /// The corresponding C constant is \`IUCLC\`.
  @_alwaysEmitIntoClient
  public static var mapUpperToLower: Self { Self(rawValue: _IUCLC) }
  #endif
}

// MARK: - OutputFlags

/// Output mode flags for terminal attributes.
///
/// These flags control postprocessing of output characters.
@frozen
@available(System 99, *)
public struct OutputFlags: OptionSet, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.TerminalFlags

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.TerminalFlags) {
    self.rawValue = rawValue
  }

  /// Enable output processing.
  ///
  /// The corresponding C constant is \`OPOST\`.
  @_alwaysEmitIntoClient
  public static var postProcess: Self { Self(rawValue: _OPOST) }

  /// Map newline to carriage return-newline on output.
  ///
  /// The corresponding C constant is \`ONLCR\`.
  @_alwaysEmitIntoClient
  public static var mapNLToCRNL: Self { Self(rawValue: _ONLCR) }

  /// Map carriage return to newline on output.
  ///
  /// The corresponding C constant is \`OCRNL\`.
  @_alwaysEmitIntoClient
  public static var mapCRToNL: Self { Self(rawValue: _OCRNL) }

  /// Don't output carriage return at column 0.
  ///
  /// The corresponding C constant is \`ONOCR\`.
  @_alwaysEmitIntoClient
  public static var noCRAtColumn0: Self { Self(rawValue: _ONOCR) }

  /// Newline performs carriage return function.
  ///
  /// The corresponding C constant is \`ONLRET\`.
  @_alwaysEmitIntoClient
  public static var nlPerformsCR: Self { Self(rawValue: _ONLRET) }

  /// Use fill characters for delay.
  ///
  /// The corresponding C constant is \`OFILL\`.
  @_alwaysEmitIntoClient
  public static var useFillCharacters: Self { Self(rawValue: _OFILL) }

  /// Fill character is DEL (0x7F), otherwise NUL (0x00).
  ///
  /// The corresponding C constant is \`OFDEL\`.
  @_alwaysEmitIntoClient
  public static var fillIsDEL: Self { Self(rawValue: _OFDEL) }

  /// Newline delay mask.
  ///
  /// The corresponding C constant is \`NLDLY\`.
  @_alwaysEmitIntoClient
  public static var newlineDelayMask: Self { Self(rawValue: _NLDLY) }

  /// Newline delay type 0 (no delay).
  ///
  /// The corresponding C constant is \`NL0\`.
  @_alwaysEmitIntoClient
  public static var newlineDelay0: Self { Self(rawValue: _NL0) }

  /// Newline delay type 1.
  ///
  /// The corresponding C constant is \`NL1\`.
  @_alwaysEmitIntoClient
  public static var newlineDelay1: Self { Self(rawValue: _NL1) }

  /// Carriage return delay mask.
  ///
  /// The corresponding C constant is \`CRDLY\`.
  @_alwaysEmitIntoClient
  public static var crDelayMask: Self { Self(rawValue: _CRDLY) }

  /// Carriage return delay type 0 (no delay).
  ///
  /// The corresponding C constant is \`CR0\`.
  @_alwaysEmitIntoClient
  public static var crDelay0: Self { Self(rawValue: _CR0) }

  /// Carriage return delay type 1.
  ///
  /// The corresponding C constant is \`CR1\`.
  @_alwaysEmitIntoClient
  public static var crDelay1: Self { Self(rawValue: _CR1) }

  /// Carriage return delay type 2.
  ///
  /// The corresponding C constant is \`CR2\`.
  @_alwaysEmitIntoClient
  public static var crDelay2: Self { Self(rawValue: _CR2) }

  /// Carriage return delay type 3.
  ///
  /// The corresponding C constant is \`CR3\`.
  @_alwaysEmitIntoClient
  public static var crDelay3: Self { Self(rawValue: _CR3) }

  /// Horizontal tab delay mask.
  ///
  /// The corresponding C constant is \`TABDLY\`.
  @_alwaysEmitIntoClient
  public static var tabDelayMask: Self { Self(rawValue: _TABDLY) }

  /// Horizontal tab delay type 0 (no delay).
  ///
  /// The corresponding C constant is \`TAB0\`.
  @_alwaysEmitIntoClient
  public static var tabDelay0: Self { Self(rawValue: _TAB0) }

  /// Horizontal tab delay type 1.
  ///
  /// The corresponding C constant is \`TAB1\`.
  @_alwaysEmitIntoClient
  public static var tabDelay1: Self { Self(rawValue: _TAB1) }

  /// Horizontal tab delay type 2.
  ///
  /// The corresponding C constant is \`TAB2\`.
  @_alwaysEmitIntoClient
  public static var tabDelay2: Self { Self(rawValue: _TAB2) }

  #if SYSTEM_PACKAGE_DARWIN
  /// Expand tabs to spaces.
  ///
  /// The corresponding C constant is \`TAB3\`.
  @_alwaysEmitIntoClient
  public static var expandTabs: Self { Self(rawValue: _TAB3) }
  #elseif os(Linux)
  /// Expand tabs to spaces.
  ///
  /// The corresponding C constant is \`XTABS\`.
  @_alwaysEmitIntoClient
  public static var expandTabs: Self { Self(rawValue: _XTABS) }
  #endif

  /// Backspace delay mask.
  ///
  /// The corresponding C constant is \`BSDLY\`.
  @_alwaysEmitIntoClient
  public static var backspaceDelayMask: Self { Self(rawValue: _BSDLY) }

  /// Backspace delay type 0 (no delay).
  ///
  /// The corresponding C constant is \`BS0\`.
  @_alwaysEmitIntoClient
  public static var backspaceDelay0: Self { Self(rawValue: _BS0) }

  /// Backspace delay type 1.
  ///
  /// The corresponding C constant is \`BS1\`.
  @_alwaysEmitIntoClient
  public static var backspaceDelay1: Self { Self(rawValue: _BS1) }

  /// Vertical tab delay mask.
  ///
  /// The corresponding C constant is \`VTDLY\`.
  @_alwaysEmitIntoClient
  public static var vtabDelayMask: Self { Self(rawValue: _VTDLY) }

  /// Vertical tab delay type 0 (no delay).
  ///
  /// The corresponding C constant is \`VT0\`.
  @_alwaysEmitIntoClient
  public static var vtabDelay0: Self { Self(rawValue: _VT0) }

  /// Vertical tab delay type 1.
  ///
  /// The corresponding C constant is \`VT1\`.
  @_alwaysEmitIntoClient
  public static var vtabDelay1: Self { Self(rawValue: _VT1) }

  /// Form feed delay mask.
  ///
  /// The corresponding C constant is \`FFDLY\`.
  @_alwaysEmitIntoClient
  public static var formFeedDelayMask: Self { Self(rawValue: _FFDLY) }

  /// Form feed delay type 0 (no delay).
  ///
  /// The corresponding C constant is \`FF0\`.
  @_alwaysEmitIntoClient
  public static var formFeedDelay0: Self { Self(rawValue: _FF0) }

  /// Form feed delay type 1.
  ///
  /// The corresponding C constant is \`FF1\`.
  @_alwaysEmitIntoClient
  public static var formFeedDelay1: Self { Self(rawValue: _FF1) }

  #if canImport(Darwin)
  /// Expand tabs to spaces (Darwin-specific name for TAB3).
  ///
  /// The corresponding C constant is \`OXTABS\`.
  @_alwaysEmitIntoClient
  public static var oxtabs: Self { Self(rawValue: _OXTABS) }

  /// Discard EOT (^D) characters on output.
  ///
  /// The corresponding C constant is \`ONOEOT\`.
  @_alwaysEmitIntoClient
  public static var discardEOT: Self { Self(rawValue: _ONOEOT) }
  #endif

  #if os(Linux)
  /// Map lowercase characters to uppercase on output.
  ///
  /// The corresponding C constant is \`OLCUC\`.
  @_alwaysEmitIntoClient
  public static var mapLowerToUpper: Self { Self(rawValue: _OLCUC) }
  #endif
}

// MARK: - ControlFlags

/// Control mode flags for terminal attributes.
///
/// These flags control hardware characteristics of the terminal.
@frozen
@available(System 99, *)
public struct ControlFlags: OptionSet, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.TerminalFlags

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.TerminalFlags) {
    self.rawValue = rawValue
  }

  /// Enable the receiver.
  ///
  /// The corresponding C constant is \`CREAD\`.
  @_alwaysEmitIntoClient
  public static var enableReceiver: Self { Self(rawValue: _CREAD) }

  /// Use two stop bits (instead of one).
  ///
  /// The corresponding C constant is \`CSTOPB\`.
  @_alwaysEmitIntoClient
  public static var twoStopBits: Self { Self(rawValue: _CSTOPB) }

  /// Hang up the modem connection on last close.
  ///
  /// The corresponding C constant is \`HUPCL\`.
  @_alwaysEmitIntoClient
  public static var hangUpOnClose: Self { Self(rawValue: _HUPCL) }

  /// Ignore modem status lines.
  ///
  /// The corresponding C constant is \`CLOCAL\`.
  @_alwaysEmitIntoClient
  public static var local: Self { Self(rawValue: _CLOCAL) }

  /// Enable parity generation and detection.
  ///
  /// The corresponding C constant is \`PARENB\`.
  @_alwaysEmitIntoClient
  public static var parityEnable: Self { Self(rawValue: _PARENB) }

  /// Use odd parity (instead of even).
  ///
  /// The corresponding C constant is \`PARODD\`.
  @_alwaysEmitIntoClient
  public static var oddParity: Self { Self(rawValue: _PARODD) }

  /// Mask for character size bits.
  ///
  /// The corresponding C constant is \`CSIZE\`.
  @_alwaysEmitIntoClient
  public static var characterSizeMask: Self { Self(rawValue: _CSIZE) }

  /// 5-bit characters.
  ///
  /// The corresponding C constant is \`CS5\`.
  @_alwaysEmitIntoClient
  public static var characterSize5: Self { Self(rawValue: _CS5) }

  /// 6-bit characters.
  ///
  /// The corresponding C constant is \`CS6\`.
  @_alwaysEmitIntoClient
  public static var characterSize6: Self { Self(rawValue: _CS6) }

  /// 7-bit characters.
  ///
  /// The corresponding C constant is \`CS7\`.
  @_alwaysEmitIntoClient
  public static var characterSize7: Self { Self(rawValue: _CS7) }

  /// 8-bit characters.
  ///
  /// The corresponding C constant is \`CS8\`.
  @_alwaysEmitIntoClient
  public static var characterSize8: Self { Self(rawValue: _CS8) }

  #if canImport(Darwin)
  /// CTS flow control of output.
  ///
  /// The corresponding C constant is \`CCTS_OFLOW\`.
  @_alwaysEmitIntoClient
  public static var ctsOutputFlowControl: Self { Self(rawValue: _CCTS_OFLOW) }

  /// RTS flow control of input.
  ///
  /// The corresponding C constant is \`CRTS_IFLOW\`.
  @_alwaysEmitIntoClient
  public static var rtsInputFlowControl: Self { Self(rawValue: _CRTS_IFLOW) }

  /// DTR flow control of input.
  ///
  /// The corresponding C constant is \`CDTR_IFLOW\`.
  @_alwaysEmitIntoClient
  public static var dtrInputFlowControl: Self { Self(rawValue: _CDTR_IFLOW) }

  /// DSR flow control of output.
  ///
  /// The corresponding C constant is \`CDSR_OFLOW\`.
  @_alwaysEmitIntoClient
  public static var dsrOutputFlowControl: Self { Self(rawValue: _CDSR_OFLOW) }

  /// DCD (Carrier Detect) flow control of output.
  ///
  /// The corresponding C constant is \`CCAR_OFLOW\`.
  @_alwaysEmitIntoClient
  public static var carrierFlowControl: Self { Self(rawValue: _CCAR_OFLOW) }

  /// Enable RTS/CTS (hardware) full-duplex flow control.
  ///
  /// The corresponding C constant is \`CRTSCTS\`.
  @_alwaysEmitIntoClient
  public static var hardwareFlowControl: Self { Self(rawValue: _CRTSCTS) }
  #endif

  #if os(Linux)
  /// Enable RTS/CTS (hardware) flow control.
  ///
  /// The corresponding C constant is \`CRTSCTS\`.
  @_alwaysEmitIntoClient
  public static var hardwareFlowControl: Self { Self(rawValue: _CRTSCTS) }

  /// Use "stick" (mark/space) parity.
  ///
  /// The corresponding C constant is \`CMSPAR\`.
  @_alwaysEmitIntoClient
  public static var markSpaceParity: Self { Self(rawValue: _CMSPAR) }
  #endif
}

// MARK: - LocalFlags

/// Local mode flags for terminal attributes.
///
/// These flags control terminal functions that affect local processing.
@frozen
@available(System 99, *)
public struct LocalFlags: OptionSet, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.TerminalFlags

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.TerminalFlags) {
    self.rawValue = rawValue
  }

  /// Enable echo of input characters.
  ///
  /// The corresponding C constant is \`ECHO\`.
  @_alwaysEmitIntoClient
  public static var echo: Self { Self(rawValue: _ECHO) }

  /// Echo the ERASE character as backspace-space-backspace.
  ///
  /// The corresponding C constant is \`ECHOE\`.
  @_alwaysEmitIntoClient
  public static var echoErase: Self { Self(rawValue: _ECHOE) }

  /// Echo newline after the KILL character.
  ///
  /// The corresponding C constant is \`ECHOK\`.
  @_alwaysEmitIntoClient
  public static var echoKill: Self { Self(rawValue: _ECHOK) }

  /// Echo newline even if ECHO is not set.
  ///
  /// The corresponding C constant is \`ECHONL\`.
  @_alwaysEmitIntoClient
  public static var echoNL: Self { Self(rawValue: _ECHONL) }

  /// Enable canonical (line-buffered) input mode.
  ///
  /// The corresponding C constant is \`ICANON\`.
  @_alwaysEmitIntoClient
  public static var canonical: Self { Self(rawValue: _ICANON) }

  /// Enable extended input character processing.
  ///
  /// The corresponding C constant is \`IEXTEN\`.
  @_alwaysEmitIntoClient
  public static var extendedInput: Self { Self(rawValue: _IEXTEN) }

  /// Enable signal generation.
  ///
  /// The corresponding C constant is \`ISIG\`.
  @_alwaysEmitIntoClient
  public static var signals: Self { Self(rawValue: _ISIG) }

  /// Disable flushing after interrupt or quit.
  ///
  /// The corresponding C constant is \`NOFLSH\`.
  @_alwaysEmitIntoClient
  public static var noFlushAfterInterrupt: Self { Self(rawValue: _NOFLSH) }

  /// Send SIGTTOU for background output.
  ///
  /// The corresponding C constant is \`TOSTOP\`.
  @_alwaysEmitIntoClient
  public static var stopBackgroundOutput: Self { Self(rawValue: _TOSTOP) }

  /// Echo control characters as ^X.
  ///
  /// The corresponding C constant is \`ECHOCTL\`.
  @_alwaysEmitIntoClient
  public static var echoControl: Self { Self(rawValue: _ECHOCTL) }

  /// Visual erase for line kill.
  ///
  /// The corresponding C constant is \`ECHOKE\`.
  @_alwaysEmitIntoClient
  public static var echoKillErase: Self { Self(rawValue: _ECHOKE) }

  /// Visual erase mode for hardcopy terminals.
  ///
  /// The corresponding C constant is \`ECHOPRT\`.
  @_alwaysEmitIntoClient
  public static var echoPrint: Self { Self(rawValue: _ECHOPRT) }

  /// Output is being flushed (read-only state flag).
  ///
  /// The corresponding C constant is \`FLUSHO\`.
  @_alwaysEmitIntoClient
  public static var flushingOutput: Self { Self(rawValue: _FLUSHO) }

  /// Retype pending input at next read (state flag).
  ///
  /// The corresponding C constant is \`PENDIN\`.
  @_alwaysEmitIntoClient
  public static var retypePending: Self { Self(rawValue: _PENDIN) }

  #if canImport(Darwin)
  /// Use alternate word erase algorithm.
  ///
  /// The corresponding C constant is \`ALTWERASE\`.
  @_alwaysEmitIntoClient
  public static var alternateWordErase: Self { Self(rawValue: _ALTWERASE) }

  /// External processing (for pseudo-terminals).
  ///
  /// The corresponding C constant is \`EXTPROC\`.
  @_alwaysEmitIntoClient
  public static var externalProcessing: Self { Self(rawValue: _EXTPROC) }

  /// Disable kernel status message from VSTATUS character.
  ///
  /// The corresponding C constant is \`NOKERNINFO\`.
  @_alwaysEmitIntoClient
  public static var noKernelInfo: Self { Self(rawValue: _NOKERNINFO) }
  #endif

  #if os(Linux)
  /// External processing (for pseudo-terminals).
  ///
  /// The corresponding C constant is \`EXTPROC\`.
  @_alwaysEmitIntoClient
  public static var externalProcessing: Self { Self(rawValue: _EXTPROC) }
  #endif
}

#endif
