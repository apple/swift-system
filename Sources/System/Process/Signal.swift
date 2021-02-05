
public struct Signal: RawRepresentable, Hashable {
  public var rawValue: CInt
  public init(rawValue: CInt) { self.rawValue = rawValue }
  fileprivate init(_ rawValue: CInt) { self.init(rawValue: rawValue) }
}

// FIXME(DO NOT MERGE): Migrate these to the constants.swift file
import Darwin

extension Signal {
  #if os(Linux)
  public static var unused: Singal { Signal(SIGUNUSED) }
  #endif

  // TODO: better names

  /// SIGHUP (1): terminal line hangup (default behavior: terminate process)
  public static var hangup: Signal { Signal(SIGHUP) }

  /// SIGINT (2): interrupt program (default behavior: terminate process)
  public static var interrupt: Signal { Signal(SIGINT) }

  /// SIGQUIT (3): quit program (default behavior: create core image)
  public static var quit: Signal { Signal(SIGQUIT) }

  /// SIGILL (4): illegal instruction (default behavior: create core image)
  public static var illegalInsruction: Signal { Signal(SIGILL) }

  /// SIGTRAP (5): trace trap (default behavior: create core image)
  public static var traceTrap: Signal { Signal(SIGTRAP) }

  /// SIGABRT (6): abort program (formerly SIGIOT) (default behavior: create core image)
  public static var abort: Signal { Signal(SIGABRT) }

  /// SIGEMT (7): emulate instruction executed (default behavior: create core image)
  public static var emulatorTrap: Signal { Signal(SIGEMT) }

  /// SIGFPE (8): floating-point exception (default behavior: create core image)
  public static var floatingPointException: Signal { Signal(SIGFPE) }

  /// SIGKILL (9): kill program (default behavior: terminate process)
  public static var kill: Signal { Signal(SIGKILL) }

  /// SIGBUS (10): bus error (default behavior: create core image)
  public static var busError: Signal { Signal(SIGBUS) }

  /// SIGSEGV (11): segmentation violation (default behavior: create core image)
  public static var segfault: Signal { Signal(SIGSEGV) }

  /// SIGSYS (12): non-existent system call invoked (default behavior: create core image)
  public static var badSyscall: Signal { Signal(SIGSYS) }

  /// SIGPIPE (13): write on a pipe with no reader (default behavior: terminate process)
  public static var pipe: Signal { Signal(SIGPIPE) }

  /// SIGALRM (14): real-time timer expired (default behavior: terminate process)
  public static var alarm: Signal { Signal(SIGALRM) }

  /// SIGTERM (15): software termination signal (default behavior: terminate process)
  public static var terminate: Signal { Signal(SIGTERM) }

  /// SIGURG (16): urgent condition present on socket (default behavior: discard signal)
  public static var urgent: Signal { Signal(SIGURG) }

  /// SIGSTOP (17): stop (cannot be caught or ignored) (default behavior: stop process)
  public static var stop: Signal { Signal(SIGSTOP) }

  /// SIGTSTP (18): stop signal generated from keyboard (default behavior: stop process)
  public static var temporaryStop: Signal { Signal(SIGTSTP) }

  /// SIGCONT (19): continue after stop (default behavior: discard signal)
  public static var `continue`: Signal { Signal(SIGCONT) }

  /// SIGCHLD (20): child status has changed (default behavior: discard signal)
  public static var childProcessTerminate: Signal { Signal(SIGCHLD) }

  /// SIGTTIN (21): background read attempted from control terminal (default behavior: stop process)
  public static var ttyIn: Signal { Signal(SIGTTIN) }

  /// SIGTTOU (22): background write attempted to control terminal (default behavior: stop process)
  public static var ttyOut: Signal { Signal(SIGTTOU) }

  /// SIGIO (23): I/O is possible on a descriptor (see fcntl(2)) (default behavior: discard signal)
  public static var ioAvailable: Signal { Signal(SIGIO) }

  /// SIGXCPU (24): cpu time limit exceeded (see setrlimit(2)) (default behavior: terminate process)
  public static var cpuLimitExceeded: Signal { Signal(SIGXCPU) }

  /// SIGXFSZ (25): file size limit exceeded (see setrlimit(2)) (default behavior: terminate process)
  public static var fileSizeLimitExceeded: Signal { Signal(SIGXFSZ) }

  /// SIGVTALRM (26): virtual time alarm (see setitimer(2)) (default behavior: terminate process)
  public static var virtualAlarm: Signal { Signal(SIGVTALRM) }

  /// SIGPROF (27): profiling timer alarm (see setitimer(2)) (default behavior: terminate process)
  public static var profilingAlarm: Signal { Signal(SIGPROF) }

  /// SIGWINCH (28): Window size change (default behavior: discard signal)
  public static var windowSizeChange: Signal { Signal(SIGWINCH) }

  /// SIGINFO (29): status request from keyboard (default behavior: discard signal)
  public static var info: Signal { Signal(SIGINFO) }

  /// SIGUSR1 (30): User defined signal 1 (default behavior: terminate process)
  public static var user1: Signal { Signal(SIGUSR1) }

  /// SIGUSR2 (31): User defined signal 2 (default behavior: terminate process)
  public static var user2: Signal { Signal(SIGUSR2) }

}

// TODO: unavailable renamed

