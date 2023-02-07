/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
public struct Signal: RawRepresentable {
  /// The raw C signal value.
  @_alwaysEmitIntoClient
  public let rawValue: CInterop.Signal

  /// Creates a strongly typed signal from a raw C signal value.
  @_alwaysEmitIntoClient
  public init(rawValue: CInterop.Signal) { self.rawValue = rawValue }
}
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
extension Signal {
  /// The corresponding C signal is `SIGHUP`.
  @_alwaysEmitIntoClient
  internal static var hangup: Self { Self(rawValue: _SIGHUP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "hangup")
  internal static var SIGHUP: Self { hangup }

  /// The corresponding C signal is `SIGINT`.
  @_alwaysEmitIntoClient
  internal static var interrupt: Self { Self(rawValue: _SIGINT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "interrupt")
  internal static var SIGINT: Self { interrupt }

  /// The corresponding C signal is `SIGQUIT`.
  @_alwaysEmitIntoClient
  internal static var quit: Self { Self(rawValue: _SIGQUIT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "quit")
  internal static var SIGQUIT: Self { quit }

  /// The corresponding C signal is `SIGILL`.
  @_alwaysEmitIntoClient
  internal static var illegalInstruction: Self { Self(rawValue: _SIGILL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "illegalInstruction")
  internal static var SIGILL: Self { illegalInstruction }

  /// The corresponding C signal is `SIGTRAP`.
  @_alwaysEmitIntoClient
  internal static var trap: Self { Self(rawValue: _SIGTRAP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "trap")
  internal static var SIGTRAP: Self { trap }

  /// The corresponding C signal is `SIGABRT`.
  @_alwaysEmitIntoClient
  internal static var abort: Self { Self(rawValue: _SIGABRT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "abort")
  internal static var SIGABRT: Self { abort }

#if false
  /// The corresponding C signal is `SIGPOLL`.
  @_alwaysEmitIntoClient
  internal static var pollableEvent: Self { Self(rawValue: _SIGPOLL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "pollableEvent")
  internal static var SIGPOLL: Self { pollableEvent }
#endif

  /// The corresponding C signal is `SIGIOT`.
  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "abort")
  internal static var inputOutputTrap: Self { Self(rawValue: _SIGIOT) }

  @_alwaysEmitIntoClient
  @available(*, deprecated)
  @available(*, unavailable, renamed: "inputOutputTrap")
  internal static var SIGIOT: Self { inputOutputTrap }

  /// The corresponding C signal is `SIGEMT`.
  @_alwaysEmitIntoClient
  internal static var emulatorTrap: Self { Self(rawValue: _SIGEMT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "emulatorTrap")
  internal static var SIGEMT: Self { emulatorTrap }

  /// The corresponding C signal is `SIGFPE`.
  @_alwaysEmitIntoClient
  internal static var floatingPointException: Self { Self(rawValue: _SIGFPE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "floatingPointException")
  internal static var SIGFPE: Self { floatingPointException }

  /// The corresponding C signal is `SIGKILL`.
  @_alwaysEmitIntoClient
  internal static var kill: Self { Self(rawValue: _SIGKILL) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "kill")
  internal static var SIGKILL: Self { kill }

  /// The corresponding C signal is `SIGBUS`.
  @_alwaysEmitIntoClient
  internal static var busError: Self { Self(rawValue: _SIGBUS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "busError")
  internal static var SIGBUS: Self { busError }

  /// The corresponding C signal is `SIGSEGV`.
  @_alwaysEmitIntoClient
  internal static var segmentationViolation: Self { Self(rawValue: _SIGSEGV) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "segmentationViolation")
  internal static var SIGSEGV: Self { segmentationViolation }

  /// The corresponding C signal is `SIGSYS`.
  @_alwaysEmitIntoClient
  internal static var badSystemCall: Self { Self(rawValue: _SIGSYS) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "badSystemCall")
  internal static var SIGSYS: Self { badSystemCall }

  /// The corresponding C signal is `SIGPIPE`.
  @_alwaysEmitIntoClient
  internal static var brokenPipe: Self { Self(rawValue: _SIGPIPE) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "brokenPipe")
  internal static var SIGPIPE: Self { brokenPipe }

  /// The corresponding C signal is `SIGALRM`.
  @_alwaysEmitIntoClient
  internal static var alarm: Self { Self(rawValue: _SIGALRM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "alarm")
  internal static var SIGALRM: Self { alarm }

  /// The corresponding C signal is `SIGTERM`.
  @_alwaysEmitIntoClient
  internal static var terminationRequest: Self { Self(rawValue: _SIGTERM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "terminationRequest")
  internal static var SIGTERM: Self { terminationRequest }

  /// The corresponding C signal is `SIGURG`.
  @_alwaysEmitIntoClient
  internal static var urgentInputOutput: Self { Self(rawValue: _SIGURG) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "urgentInputOutput")
  internal static var SIGURG: Self { urgentInputOutput }

  /// The corresponding C signal is `SIGSTOP`.
  @_alwaysEmitIntoClient
  internal static var stop: Self { Self(rawValue: _SIGSTOP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "stop")
  internal static var SIGSTOP: Self { stop }

  /// The corresponding C signal is `SIGTSTP`.
  @_alwaysEmitIntoClient
  internal static var interactiveStop: Self { Self(rawValue: _SIGTSTP) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "interactiveStop")
  internal static var SIGTSTP: Self { interactiveStop }

  /// The corresponding C signal is `SIGCONT`.
  @_alwaysEmitIntoClient
  internal static var `continue`: Self { Self(rawValue: _SIGCONT) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "continue")
  internal static var SIGCONT: Self { `continue` }

  /// The corresponding C signal is `SIGCHLD`.
  @_alwaysEmitIntoClient
  internal static var childStopOrExit: Self { Self(rawValue: _SIGCHLD) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "childStopOrExit")
  internal static var SIGCHLD: Self { childStopOrExit }

  /// The corresponding C signal is `SIGTTIN`.
  @_alwaysEmitIntoClient
  internal static var backgroundRead: Self { Self(rawValue: _SIGTTIN) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "backgroundRead")
  internal static var SIGTTIN: Self { backgroundRead }

  /// The corresponding C signal is `SIGTTOU`.
  @_alwaysEmitIntoClient
  internal static var backgroundWrite: Self { Self(rawValue: _SIGTTOU) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "backgroundWrite")
  internal static var SIGTTOU: Self { backgroundWrite }

  /// The corresponding C signal is `SIGIO`.
  @_alwaysEmitIntoClient
  internal static var possibleInputOutput: Self { Self(rawValue: _SIGIO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "possibleInputOutput")
  internal static var SIGIO: Self { possibleInputOutput }

  /// The corresponding C signal is `SIGXCPU`.
  @_alwaysEmitIntoClient
  internal static var exceededCPUTimeLimit: Self { Self(rawValue: _SIGXCPU) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "exceededCPUTimeLimit")
  internal static var SIGXCPU: Self { exceededCPUTimeLimit }

  /// The corresponding C signal is `SIGXFSZ`.
  @_alwaysEmitIntoClient
  internal static var exceededFileSizeLimit: Self { Self(rawValue: _SIGXFSZ) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "exceededFileSizeLimit")
  internal static var SIGXFSZ: Self { exceededFileSizeLimit }

  /// The corresponding C signal is `SIGVTALRM`.
  @_alwaysEmitIntoClient
  internal static var virtualAlarm: Self { Self(rawValue: _SIGVTALRM) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "virtualAlarm")
  internal static var SIGVTALRM: Self { virtualAlarm }

  /// The corresponding C signal is `SIGPROF`.
  @_alwaysEmitIntoClient
  internal static var profilingAlarm: Self { Self(rawValue: _SIGPROF) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "profilingAlarm")
  internal static var SIGPROF: Self { profilingAlarm }

  /// The corresponding C signal is `SIGWINCH`.
  @_alwaysEmitIntoClient
  internal static var windowSizeChange: Self { Self(rawValue: _SIGWINCH) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "windowSizeChange")
  internal static var SIGWINCH: Self { windowSizeChange }

  /// The corresponding C signal is `SIGINFO`.
  @_alwaysEmitIntoClient
  internal static var informationRequest: Self { Self(rawValue: _SIGINFO) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "informationRequest")
  internal static var SIGINFO: Self { informationRequest }

  /// The corresponding C signal is `SIGUSR1`.
  @_alwaysEmitIntoClient
  internal static var userDefined1: Self { Self(rawValue: _SIGUSR1) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "userDefined1")
  internal static var SIGUSR1: Self { userDefined1 }

  /// The corresponding C signal is `SIGUSR2`.
  @_alwaysEmitIntoClient
  internal static var userDefined2: Self { Self(rawValue: _SIGUSR2) }

  @_alwaysEmitIntoClient
  @available(*, unavailable, renamed: "userDefined2")
  internal static var SIGUSR2: Self { userDefined2 }
}
#endif
