/*
 This source file is part of the Swift System open source project
 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 See https://swift.org/LICENSE.txt for license information
 */

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
/// hangup
@_alwaysEmitIntoClient
internal var _SIGHUP: CInterop.Signal { SIGHUP }
/// interrupt
@_alwaysEmitIntoClient
internal var _SIGINT: CInterop.Signal { SIGINT }
/// quit
@_alwaysEmitIntoClient
internal var _SIGQUIT: CInterop.Signal { SIGQUIT }
/// illegal instruction (not reset when caught)
@_alwaysEmitIntoClient
internal var _SIGILL: CInterop.Signal { SIGILL }
/// trace trap (not reset when caught)
@_alwaysEmitIntoClient
internal var _SIGTRAP: CInterop.Signal { SIGTRAP }
/// abort()
@_alwaysEmitIntoClient
internal var _SIGABRT: CInterop.Signal { SIGABRT }
#if false
/// pollable event
@_alwaysEmitIntoClient
internal var _SIGPOLL: CInterop.Signal { SIGPOLL }
#endif
/// compatibility
@_alwaysEmitIntoClient
internal var _SIGIOT: CInterop.Signal { SIGIOT }
/// EMT instruction
@_alwaysEmitIntoClient
internal var _SIGEMT: CInterop.Signal { SIGEMT }
/// floating point exception
@_alwaysEmitIntoClient
internal var _SIGFPE: CInterop.Signal { SIGFPE }
/// kill (cannot be caught or ignored)
@_alwaysEmitIntoClient
internal var _SIGKILL: CInterop.Signal { SIGKILL }
/// bus error
@_alwaysEmitIntoClient
internal var _SIGBUS: CInterop.Signal { SIGBUS }
/// segmentation violation
@_alwaysEmitIntoClient
internal var _SIGSEGV: CInterop.Signal { SIGSEGV }
/// bad argument to system call
@_alwaysEmitIntoClient
internal var _SIGSYS: CInterop.Signal { SIGSYS }
/// write on a pipe with no one to read it
@_alwaysEmitIntoClient
internal var _SIGPIPE: CInterop.Signal { SIGPIPE }
/// alarm clock
@_alwaysEmitIntoClient
internal var _SIGALRM: CInterop.Signal { SIGALRM }
/// software termination signal from kill
@_alwaysEmitIntoClient
internal var _SIGTERM: CInterop.Signal { SIGTERM }
/// urgent condition on IO channel
@_alwaysEmitIntoClient
internal var _SIGURG: CInterop.Signal { SIGURG }
/// sendable stop signal not from tty
@_alwaysEmitIntoClient
internal var _SIGSTOP: CInterop.Signal { SIGSTOP }
/// stop signal from tty
@_alwaysEmitIntoClient
internal var _SIGTSTP: CInterop.Signal { SIGTSTP }
/// continue a stopped process
@_alwaysEmitIntoClient
internal var _SIGCONT: CInterop.Signal { SIGCONT }
/// to parent on child stop or exit
@_alwaysEmitIntoClient
internal var _SIGCHLD: CInterop.Signal { SIGCHLD }
/// to readers pgrp upon background tty read
@_alwaysEmitIntoClient
internal var _SIGTTIN: CInterop.Signal { SIGTTIN }
/// like TTIN for output if (tp->t_local&LTOSTOP)
@_alwaysEmitIntoClient
internal var _SIGTTOU: CInterop.Signal { SIGTTOU }
/// input/output possible signal
@_alwaysEmitIntoClient
internal var _SIGIO: CInterop.Signal { SIGIO }
/// exceeded CPU time limit
@_alwaysEmitIntoClient
internal var _SIGXCPU: CInterop.Signal { SIGXCPU }
/// exceeded file size limit
@_alwaysEmitIntoClient
internal var _SIGXFSZ: CInterop.Signal { SIGXFSZ }
/// virtual time alarm
@_alwaysEmitIntoClient
internal var _SIGVTALRM: CInterop.Signal { SIGVTALRM }
/// profiling time alarm
@_alwaysEmitIntoClient
internal var _SIGPROF: CInterop.Signal { SIGPROF }
/// window size changes
@_alwaysEmitIntoClient
internal var _SIGWINCH: CInterop.Signal { SIGWINCH }
/// information request
@_alwaysEmitIntoClient
internal var _SIGINFO: CInterop.Signal { SIGINFO }
/// user defined signal 1
@_alwaysEmitIntoClient
internal var _SIGUSR1: CInterop.Signal { SIGUSR1 }
/// user defined signal 2
@_alwaysEmitIntoClient
internal var _SIGUSR2: CInterop.Signal { SIGUSR2 }
#endif
