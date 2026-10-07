/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if compiler(>=6.2) && $Lifetimes
#if os(Linux)

import Testing

#if canImport(Glibc)
import CSystem
import Glibc
#elseif canImport(Musl)
import CSystem
import Musl
#endif

@testable import SystemSockets
import SystemPackage

/// Whether the environment can create an `IORing` at all.
private let ioRingAvailable: Bool = {
  do {
    _ = try IORing(queueDepth: 1)
    return true
  } catch {
    return false
  }
}()

/// Whether the kernel knows the operation of the given request.
///
/// The request has to target an invalid descriptor or argument. A kernel that
/// doesn't know the operation fails it with `EINVAL`, one that does fails it
/// with another error.
@available(System 199, *)
private func kernelSupports(_ request: IORing.Request) -> Bool {
  guard ioRingAvailable else { return false }
  do {
    var ring = try IORing(queueDepth: 1)
    guard try ring.submit(linkedRequests: request) else { return false }
    let completion = try ring.blockingConsumeCompletion(timeout: .seconds(5))
    return completion.error != .invalidArgument
  } catch {
    return false
  }
}

@available(System 199, *)
private let invalidSocket = SocketDescriptor(rawValue: -1)

@available(System 199, *)
private let socketSupported = kernelSupports(
  .socket(SocketDescriptor.Domain(rawValue: -1), .stream)
)

@available(System 199, *)
private let shutdownSupported = kernelSupports(.shutdown(invalidSocket, .write))

@available(System 199, *)
private let bindAndListenSupported = kernelSupports(.listen(invalidSocket, backlog: 1))

/// Whether the environment has an IPv6 loopback interface.
@available(System 199, *)
private let ipv6LoopbackAvailable: Bool = {
  do {
    let socket = try SocketDescriptor.open(.ipv6, .stream, protocol: .tcp)
    defer { try? socket.close() }
    try socket.bind(to: SocketAddress(ipv6: .loopback(port: 0)))
    return true
  } catch {
    return false
  }
}()

/// Consumes the given number of completions and returns their results by context.
private func consumeResults(
  _ count: Int,
  from ring: borrowing IORing
) throws -> [UInt64: Int32] {
  var results: [UInt64: Int32] = [:]
  for _ in 0..<count {
    let completion = try ring.blockingConsumeCompletion(timeout: .seconds(5))
    results[completion.context] = completion.result
  }
  return results
}

@Suite("IORing socket requests", .enabled(if: ioRingAvailable))
private struct IORingSocketTests {

  // MARK: - Helpers

  /// Creates a listening socket on the loopback interface.
  @available(System 199, *)
  private func makeListener() throws -> (SocketDescriptor, SocketAddress) {
    let listener = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    try listener.bind(to: SocketAddress(ipv4: .loopback(port: 0)))
    try listener.listen(backlog: 8)
    var address = SocketAddress()
    try listener.getLocalAddress(into: &address)
    return (listener, address)
  }

  /// Creates a connected pair of sockets on the loopback interface.
  @available(System 199, *)
  private func makeConnectedPair() throws -> (client: SocketDescriptor, server: SocketDescriptor) {
    let (listener, address) = try makeListener()
    defer { try? listener.close() }
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    try client.connect(to: address)
    let server = try listener.accept()
    return (client, server)
  }

  // MARK: - Tests

  @available(System 199, *)
  @Test(.enabled(if: socketSupported))
  func socketCreatesSocket() throws {
    var ring = try IORing(queueDepth: 4)
    let submitted = try ring.submit(linkedRequests:
      .socket(.ipv4, .stream, protocol: .tcp, flags: .closeOnExec, context: 1)
    )
    #expect(submitted)

    let completion = try ring.blockingConsumeCompletion(timeout: .seconds(5))
    #expect(completion.context == 1)
    #expect(completion.error == nil)

    let socket = SocketDescriptor(rawValue: completion.result)
    defer { try? socket.close() }
    #expect(fcntl(socket.rawValue, F_GETFD) & FD_CLOEXEC != 0)
  }

  @available(System 199, *)
  @Test(.enabled(if: bindAndListenSupported))
  func bindAndListen() throws {
    let socket = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? socket.close() }

    var ring = try IORing(queueDepth: 4)
    let submitted = try ring.submit(linkedRequests:
      .bind(socket, to: SocketAddress(ipv4: .loopback(port: 0)), context: 1),
      .listen(socket, backlog: 8, context: 2)
    )
    #expect(submitted)
    let results = try consumeResults(2, from: ring)
    #expect(results[1] == 0)
    #expect(results[2] == 0)

    // A client can connect, so the socket is listening.
    var address = SocketAddress()
    try socket.getLocalAddress(into: &address)
    #expect(address.ipv4?.port != 0)
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }
    try client.connect(to: address)
  }

  @available(System 199, *)
  @Test(.enabled(if: shutdownSupported))
  func acceptConnectSendReceiveAndShutdown() throws {
    let (listener, address) = try makeListener()
    defer { try? listener.close() }
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }

    var ring = try IORing(queueDepth: 8)
    let acceptPrepared = ring.prepare(request: .accept(listener, flags: .closeOnExec, context: 1))
    #expect(acceptPrepared)
    let connectPrepared = ring.prepare(request: .connect(client, to: address, context: 2))
    #expect(connectPrepared)
    try ring.submitPreparedRequests()
    let connected = try consumeResults(2, from: ring)
    #expect(connected[2] == 0)
    let acceptedFD = try #require(connected[1])
    #expect(acceptedFD >= 0)
    let server = SocketDescriptor(rawValue: acceptedFD)
    defer { try? server.close() }

    let message: [UInt8] = Array("Hello, io_uring!".utf8)
    var received = [UInt8](repeating: 0, count: 64)
    let exchanged = try message.withUnsafeBytes { sendBuffer in
      try received.withUnsafeMutableBytes { receiveBuffer in
        let sendPrepared = ring.prepare(request: .send(sendBuffer, to: client, context: 3))
        #expect(sendPrepared)
        let receivePrepared = ring.prepare(request: .receive(server, into: receiveBuffer, context: 4))
        #expect(receivePrepared)
        try ring.submitPreparedRequests()
        return try consumeResults(2, from: ring)
      }
    }
    #expect(exchanged[3] == Int32(message.count))
    #expect(exchanged[4] == Int32(message.count))
    #expect(Array(received.prefix(message.count)) == message)

    // Once the client shuts down writing, the server reads the end of the stream.
    let endOfStream = try received.withUnsafeMutableBytes { receiveBuffer in
      let shutdownSubmitted = try ring.submit(linkedRequests: .shutdown(client, .write, context: 5))
      #expect(shutdownSubmitted)
      let receiveSubmitted = try ring.submit(linkedRequests: .receive(server, into: receiveBuffer, context: 6))
      #expect(receiveSubmitted)
      return try consumeResults(2, from: ring)
    }
    #expect(endOfStream[5] == 0)
    #expect(endOfStream[6] == 0)
  }

  @available(System 199, *)
  @Test func acceptWritesPeerAddress() throws {
    let (listener, address) = try makeListener()
    defer { try? listener.close() }
    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }

    // The kernel writes the peer's address when the accept completes, so both
    // pointers have to stay valid until the completion is consumed.
    var peerStorage = sockaddr_storage()
    var peerLength = CInterop.SockLen(MemoryLayout<sockaddr_storage>.size)
    let acceptedFD = try withUnsafeMutablePointer(to: &peerLength) { peerAddressLength in
      try withUnsafeMutablePointer(to: &peerStorage) { storage in
        try storage.withMemoryRebound(to: CInterop.SockAddr.self, capacity: 1) { peerAddress in
          var ring = try IORing(queueDepth: 4)
          let submitted = try ring.submit(linkedRequests: .accept(
            listener, peerAddress: peerAddress, peerAddressLength: peerAddressLength, context: 1
          ))
          #expect(submitted)
          try client.connect(to: address)
          let completion = try ring.blockingConsumeCompletion(timeout: .seconds(5))
          #expect(completion.context == 1)
          return completion.result
        }
      }
    }
    #expect(acceptedFD >= 0)
    try? SocketDescriptor(rawValue: acceptedFD).close()

    var clientAddress = SocketAddress()
    try client.getLocalAddress(into: &clientAddress)
    let peer = withUnsafePointer(to: &peerStorage) { storage in
      storage.withMemoryRebound(to: CInterop.SockAddr.self, capacity: 1) {
        SocketAddress(address: $0, length: peerLength)
      }
    }
    #expect(peer.ipv4?.port == clientAddress.ipv4?.port)
  }

  @available(System 199, *)
  @Test func sendDoesNotRaiseSigpipe() throws {
    let (client, server) = try makeConnectedPair()
    defer {
      try? client.close()
      try? server.close()
    }
    // Writing to a socket that is shut down for writing raises `SIGPIPE`. A
    // send request doesn't, since io_uring sets `MSG_NOSIGNAL` for it, even
    // without passing `.noSignal`.
    try client.shutdown(.write)

    // The test process might ignore `SIGPIPE`, which would hide it. Blocking
    // it on this thread keeps a raised `SIGPIPE` pending, so we can check
    // for it. The send fails right away, so it runs on this thread.
    var sigpipe = sigset_t()
    sigemptyset(&sigpipe)
    sigaddset(&sigpipe, SIGPIPE)
    var previousMask = sigset_t()
    pthread_sigmask(SIG_BLOCK, &sigpipe, &previousMask)
    defer {
      // Consume a pending `SIGPIPE` so that it isn't delivered once unblocked.
      var noWait = timespec()
      while sigtimedwait(&sigpipe, nil, &noWait) == SIGPIPE {}
      pthread_sigmask(SIG_SETMASK, &previousMask, nil)
    }

    var ring = try IORing(queueDepth: 4)
    let message: [UInt8] = [1, 2, 3]
    let results = try message.withUnsafeBytes { buffer in
      let submitted = try ring.submit(linkedRequests: .send(buffer, to: client, context: 1))
      #expect(submitted)
      return try consumeResults(1, from: ring)
    }
    #expect(results[1] == -Errno.brokenPipe.rawValue)

    var pending = sigset_t()
    sigpending(&pending)
    #expect(sigismember(&pending, SIGPIPE) == 0, "the send raised SIGPIPE")
  }

  // An IPv6 address is longer than an IPv4 one, so this checks that connect
  // passes the length of the given address.
  @available(System 199, *)
  @Test(.enabled(if: ipv6LoopbackAvailable))
  func connectOverIPv6() throws {
    let listener = try SocketDescriptor.open(.ipv6, .stream, protocol: .tcp)
    defer { try? listener.close() }
    try listener.bind(to: SocketAddress(ipv6: .loopback(port: 0)))
    try listener.listen(backlog: 8)
    var address = SocketAddress()
    try listener.getLocalAddress(into: &address)

    let client = try SocketDescriptor.open(.ipv6, .stream, protocol: .tcp)
    defer { try? client.close() }
    var ring = try IORing(queueDepth: 4)
    let submitted = try ring.submit(linkedRequests: .connect(client, to: address, context: 1))
    #expect(submitted)
    let completion = try ring.blockingConsumeCompletion(timeout: .seconds(5))
    #expect(completion.context == 1)
    // Accepting blocks, so it only runs once the client is connected.
    try #require(completion.error == nil)

    let server = try listener.accept()
    try server.close()
  }

  @available(System 199, *)
  @Test func connectToClosedPortFails() throws {
    // Bind a socket to get a free port, then close it so nothing listens there.
    let (listener, address) = try makeListener()
    try listener.close()

    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }
    var ring = try IORing(queueDepth: 4)
    let submitted = try ring.submit(linkedRequests: .connect(client, to: address, context: 7))
    #expect(submitted)
    let completion = try ring.blockingConsumeCompletion(timeout: .seconds(5))
    #expect(completion.context == 7)
    #expect(completion.error == .connectionRefused)
  }
}
#endif // os(Linux)
#endif // compiler(>=6.2) && $Lifetimes
