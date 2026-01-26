/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */

#if !os(Windows)

/// A terminal baud rate.
///
/// POSIX defines baud rates as symbolic constants rather than numeric values.
/// On modern systems, these typically correspond directly to the bits-per-second
/// rate (e.g., `b9600` represents 9600 bps). The API uses symbolic constants for
/// portability across platforms.
///
/// Use the predefined static constants rather than constructing arbitrary values.
///
/// **Platform Notes:**
/// - Darwin supports rates up to `b230400` via symbolic constants. Higher rates
///   can be set using numeric values passed directly to `cfsetspeed()`.
/// - Linux defines symbolic constants for rates up to 4 Mbps (`b4000000`).
///
/// See also: [POSIX termios.h](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/termios.h.html)
@frozen
@available(System 99, *)
public struct BaudRate: RawRepresentable, Hashable, Sendable {
  @_alwaysEmitIntoClient
  public var rawValue: CInterop.SpeedT

  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.SpeedT) {
    self.rawValue = rawValue
  }

  /// Hang up (zero baud rate).
  ///
  /// Setting the output speed to this value causes the modem to hang up.
  ///
  /// The corresponding C constant is `B0`.
  @_alwaysEmitIntoClient
  public static var hangUp: BaudRate { BaudRate(rawValue: _B0) }

  /// 50 baud.
  ///
  /// The corresponding C constant is `B50`.
  @_alwaysEmitIntoClient
  public static var b50: BaudRate { BaudRate(rawValue: _B50) }

  /// 75 baud.
  ///
  /// The corresponding C constant is `B75`.
  @_alwaysEmitIntoClient
  public static var b75: BaudRate { BaudRate(rawValue: _B75) }

  /// 110 baud.
  ///
  /// The corresponding C constant is `B110`.
  @_alwaysEmitIntoClient
  public static var b110: BaudRate { BaudRate(rawValue: _B110) }

  /// 134.5 baud.
  ///
  /// The corresponding C constant is `B134`.
  @_alwaysEmitIntoClient
  public static var b134: BaudRate { BaudRate(rawValue: _B134) }

  /// 150 baud.
  ///
  /// The corresponding C constant is `B150`.
  @_alwaysEmitIntoClient
  public static var b150: BaudRate { BaudRate(rawValue: _B150) }

  /// 200 baud.
  ///
  /// The corresponding C constant is `B200`.
  @_alwaysEmitIntoClient
  public static var b200: BaudRate { BaudRate(rawValue: _B200) }

  /// 300 baud.
  ///
  /// The corresponding C constant is `B300`.
  @_alwaysEmitIntoClient
  public static var b300: BaudRate { BaudRate(rawValue: _B300) }

  /// 600 baud.
  ///
  /// The corresponding C constant is `B600`.
  @_alwaysEmitIntoClient
  public static var b600: BaudRate { BaudRate(rawValue: _B600) }

  /// 1200 baud.
  ///
  /// The corresponding C constant is `B1200`.
  @_alwaysEmitIntoClient
  public static var b1200: BaudRate { BaudRate(rawValue: _B1200) }

  /// 1800 baud.
  ///
  /// The corresponding C constant is `B1800`.
  @_alwaysEmitIntoClient
  public static var b1800: BaudRate { BaudRate(rawValue: _B1800) }

  /// 2400 baud.
  ///
  /// The corresponding C constant is `B2400`.
  @_alwaysEmitIntoClient
  public static var b2400: BaudRate { BaudRate(rawValue: _B2400) }

  /// 4800 baud.
  ///
  /// The corresponding C constant is `B4800`.
  @_alwaysEmitIntoClient
  public static var b4800: BaudRate { BaudRate(rawValue: _B4800) }

  /// 9600 baud.
  ///
  /// The corresponding C constant is `B9600`.
  @_alwaysEmitIntoClient
  public static var b9600: BaudRate { BaudRate(rawValue: _B9600) }

  /// 19200 baud.
  ///
  /// The corresponding C constant is `B19200`.
  @_alwaysEmitIntoClient
  public static var b19200: BaudRate { BaudRate(rawValue: _B19200) }

  /// 38400 baud.
  ///
  /// The corresponding C constant is `B38400`.
  @_alwaysEmitIntoClient
  public static var b38400: BaudRate { BaudRate(rawValue: _B38400) }

  /// 57600 baud.
  ///
  /// The corresponding C constant is `B57600`.
  @_alwaysEmitIntoClient
  public static var b57600: BaudRate { BaudRate(rawValue: _B57600) }

  /// 115200 baud.
  ///
  /// The corresponding C constant is `B115200`.
  @_alwaysEmitIntoClient
  public static var b115200: BaudRate { BaudRate(rawValue: _B115200) }

  /// 230400 baud.
  ///
  /// The corresponding C constant is `B230400`.
  @_alwaysEmitIntoClient
  public static var b230400: BaudRate { BaudRate(rawValue: _B230400) }

  #if canImport(Darwin)
  /// 7200 baud.
  ///
  /// This is a Darwin-specific extension.
  ///
  /// The corresponding C constant is `B7200`.
  @_alwaysEmitIntoClient
  public static var b7200: BaudRate { BaudRate(rawValue: _B7200) }

  /// 14400 baud.
  ///
  /// This is a Darwin-specific extension.
  ///
  /// The corresponding C constant is `B14400`.
  @_alwaysEmitIntoClient
  public static var b14400: BaudRate { BaudRate(rawValue: _B14400) }

  /// 28800 baud.
  ///
  /// This is a Darwin-specific extension.
  ///
  /// The corresponding C constant is `B28800`.
  @_alwaysEmitIntoClient
  public static var b28800: BaudRate { BaudRate(rawValue: _B28800) }

  /// 76800 baud.
  ///
  /// This is a Darwin-specific extension.
  ///
  /// The corresponding C constant is `B76800`.
  @_alwaysEmitIntoClient
  public static var b76800: BaudRate { BaudRate(rawValue: _B76800) }
  #endif

  #if os(Linux)
  /// 460800 baud.
  ///
  /// The corresponding C constant is `B460800`.
  @_alwaysEmitIntoClient
  public static var b460800: BaudRate { BaudRate(rawValue: _B460800) }

  /// 500000 baud.
  ///
  /// The corresponding C constant is `B500000`.
  @_alwaysEmitIntoClient
  public static var b500000: BaudRate { BaudRate(rawValue: _B500000) }

  /// 576000 baud.
  ///
  /// The corresponding C constant is `B576000`.
  @_alwaysEmitIntoClient
  public static var b576000: BaudRate { BaudRate(rawValue: _B576000) }

  /// 921600 baud.
  ///
  /// The corresponding C constant is `B921600`.
  @_alwaysEmitIntoClient
  public static var b921600: BaudRate { BaudRate(rawValue: _B921600) }

  /// 1000000 baud (1 Mbps).
  ///
  /// The corresponding C constant is `B1000000`.
  @_alwaysEmitIntoClient
  public static var b1000000: BaudRate { BaudRate(rawValue: _B1000000) }

  /// 1152000 baud.
  ///
  /// The corresponding C constant is `B1152000`.
  @_alwaysEmitIntoClient
  public static var b1152000: BaudRate { BaudRate(rawValue: _B1152000) }

  /// 1500000 baud (1.5 Mbps).
  ///
  /// The corresponding C constant is `B1500000`.
  @_alwaysEmitIntoClient
  public static var b1500000: BaudRate { BaudRate(rawValue: _B1500000) }

  /// 2000000 baud (2 Mbps).
  ///
  /// The corresponding C constant is `B2000000`.
  @_alwaysEmitIntoClient
  public static var b2000000: BaudRate { BaudRate(rawValue: _B2000000) }

  /// 2500000 baud (2.5 Mbps).
  ///
  /// The corresponding C constant is `B2500000`.
  @_alwaysEmitIntoClient
  public static var b2500000: BaudRate { BaudRate(rawValue: _B2500000) }

  /// 3000000 baud (3 Mbps).
  ///
  /// The corresponding C constant is `B3000000`.
  @_alwaysEmitIntoClient
  public static var b3000000: BaudRate { BaudRate(rawValue: _B3000000) }

  /// 3500000 baud (3.5 Mbps).
  ///
  /// The corresponding C constant is `B3500000`.
  @_alwaysEmitIntoClient
  public static var b3500000: BaudRate { BaudRate(rawValue: _B3500000) }

  /// 4000000 baud (4 Mbps).
  ///
  /// The corresponding C constant is `B4000000`.
  @_alwaysEmitIntoClient
  public static var b4000000: BaudRate { BaudRate(rawValue: _B4000000) }
  #endif
}

#endif
