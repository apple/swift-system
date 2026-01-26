/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

#if !os(Windows)

import Testing

#if SYSTEM_PACKAGE_DARWIN
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#else
#error("Unsupported Platform")
#endif

@testable import SystemSockets
@testable import SystemPackage

@Suite("Socket Message Operations")
private struct SocketMessagesTests {

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func sendReceiveMessageBasic() throws {
    // Test basic sendMessage/receiveMessage with TCP sockets
    let server = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? server.close() }

    let serverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try server.bind(to: serverAddr)
    try server.listen(backlog: 1)

    var boundAddr = SocketAddress()
    try server.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    let client = try SocketDescriptor.open(.ipv4, .stream, protocol: .tcp)
    defer { try? client.close() }

    let connectAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    try client.connect(to: connectAddr)

    let accepted = try server.accept()
    defer { try? accepted.close() }

    // Send message without ancillary data
    let message = "Hello via sendMessage!"
    let messageBytes = Array(message.utf8)
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try client.sendMessage(span)
    }
    #expect(sent == messageBytes.count)

    // Receive message
    var buffer = [UInt8](repeating: 0, count: 1024)
    var recvAncillary = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 256)
    var sender: SocketAddress? = SocketAddress()

    let received = try buffer.withUnsafeMutableBytes { buf in
      var recvOutput = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try accepted.receiveMessage(
        into: &recvOutput,
        ancillaryMessages: &recvAncillary,
        sender: &sender
      )
    }
    #expect(received == messageBytes.count)
    // Note: For TCP connections, recvmsg doesn't populate msg_name with the peer address
    // Use getpeername() instead for connection-oriented sockets

    let receivedMessage = String(decoding: buffer.prefix(received), as: UTF8.self)
    #expect(receivedMessage == message)
  }

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func sendReceiveMessageUDP() throws {
    // Test sendMessage/receiveMessage with UDP datagram sockets
    let receiver = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    defer { try? receiver.close() }

    let receiverAddr = SocketAddress(ipv4: IPv4Address.loopback(port: 0))
    try receiver.bind(to: receiverAddr)

    var boundAddr = SocketAddress()
    try receiver.getLocalAddress(into: &boundAddr)
    let port = boundAddr.ipv4!.port

    let sender = try SocketDescriptor.open(.ipv4, .datagram, protocol: .udp)
    defer { try? sender.close() }

    // Send datagram via sendMessage
    let message = "UDP via sendMessage"
    let messageBytes = Array(message.utf8)
    let targetAddr = SocketAddress(ipv4: IPv4Address.loopback(port: port))
    let sent = try messageBytes.withUnsafeBytes { bytes in
      let span = RawSpan(_unsafeBytes: bytes)
      return try sender.sendMessage(span, to: targetAddr)
    }
    #expect(sent == messageBytes.count)

    // Get sender's actual local address for verification
    var senderLocalAddr = SocketAddress()
    try sender.getLocalAddress(into: &senderLocalAddr)

    // Receive datagram
    var buffer = [UInt8](repeating: 0, count: 1024)
    var recvAncillary = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 256)
    var fromAddr: SocketAddress? = SocketAddress()

    let received = try buffer.withUnsafeMutableBytes { buf in
      var recvOutput = OutputRawSpan(buffer: buf, initializedCount: 0)
      return try receiver.receiveMessage(
        into: &recvOutput,
        ancillaryMessages: &recvAncillary,
        sender: &fromAddr
      )
    }
    #expect(received == messageBytes.count)

    // Verify the sender address was correctly populated by recvmsg
    #expect(fromAddr?.family == .ipv4)
    let fromIPv4 = try #require(fromAddr?.ipv4, "Sender address should be populated for UDP")
    let senderIPv4 = try #require(senderLocalAddr.ipv4, "Sender socket should have IPv4 address")

    // Verify the port matches the sender's ephemeral port
    #expect(fromIPv4.port == senderIPv4.port)

    let receivedMessage = String(decoding: buffer.prefix(received), as: UTF8.self)
    #expect(receivedMessage == message)
  }

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func sendReceiveMessageWithFileDescriptor() throws {
    try withTemporaryFilePath(basename: "socket-fd-test") { tempDir in
      // Test file descriptor passing via SCM_RIGHTS over Unix domain sockets
      let server = try SocketDescriptor.open(.local, .stream)
      defer { try? server.close() }

      let client = try SocketDescriptor.open(.local, .stream)
      defer { try? client.close() }

      let socketPath = tempDir.appending("test.sock")
      let unixAddr = UnixAddress(socketPath.string)!
      let address = SocketAddress(unix: unixAddr)
      try server.bind(to: address)
      try server.listen(backlog: 1)

      try client.connect(to: address)
      let accepted = try server.accept()
      defer { try? accepted.close() }

      // Create a temporary file to send
      let tempFile = tempDir.appending("test-data.txt")
      let fd = try FileDescriptor.open(
        tempFile,
        .writeOnly,
        options: [.create, .truncate],
        permissions: [.ownerReadWrite]
      )

      // Write test data to the file
      let testData = "File descriptor test data"
      _ = try testData.utf8.withContiguousStorageIfAvailable { buffer in
        try fd.write(UnsafeRawBufferPointer(buffer))
      }
      try fd.close()

      // Reopen for reading to send
      let fileToSend = try FileDescriptor.open(tempFile, .readOnly)

      // Build ancillary message with SCM_RIGHTS
      var ancillary = SocketDescriptor.AncillaryMessageBuffer()
      withUnsafeBytes(of: fileToSend.rawValue) { bytes in
        let span = RawSpan(_unsafeBytes: bytes)
        ancillary.appendMessage(
          level: SocketDescriptor.ProtocolID(rawValue: SOL_SOCKET),
          type: .init(rawValue: CInt(SCM_RIGHTS)),
          bytes: span
        )
      }

      // Send message with file descriptor
      let message = "FD attached"
      let messageBytes = Array(message.utf8)
      let sent = try messageBytes.withUnsafeBytes { bytes in
        let span = RawSpan(_unsafeBytes: bytes)
        return try client.sendMessage(span, ancillaryMessages: ancillary)
      }
      #expect(sent == messageBytes.count)

      // Receive message and file descriptor
      var buffer = [UInt8](repeating: 0, count: 1024)
      var recvAncillary = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 256)
      var sender: SocketAddress? = nil

      let received = try buffer.withUnsafeMutableBytes { buf in
        var recvOutput = OutputRawSpan(buffer: buf, initializedCount: 0)
        return try accepted.receiveMessage(
          into: &recvOutput,
          ancillaryMessages: &recvAncillary,
          sender: &sender
        )
      }
      #expect(received == messageBytes.count)

      // Extract the received file descriptor using CMSG_FIRSTHDR/CMSG_NXTHDR pattern
      var receivedFD: CInt? = nil
      recvAncillary._withUnsafeBytes { controlData in
        guard controlData.count >= MemoryLayout<CInterop.CMsgHdr>.size else { return }

        let header = controlData.baseAddress!.assumingMemoryBound(to: CInterop.CMsgHdr.self)
        if header.pointee.cmsg_level == SOL_SOCKET &&
           header.pointee.cmsg_type == CInt(SCM_RIGHTS) {
          let dataOffset = MemoryLayout<CInterop.CMsgHdr>.size
          let fdPtr = (controlData.baseAddress! + dataOffset).assumingMemoryBound(to: CInt.self)
          receivedFD = fdPtr.pointee
        }
      }

      let receivedFd = try #require(receivedFD, "Should have received a file descriptor")
      let receivedFile = FileDescriptor(rawValue: receivedFd)
      defer { try? receivedFile.close() }

      // Verify we can read from the received file descriptor
      var readBuffer = [UInt8](repeating: 0, count: 1024)
      let bytesRead = try readBuffer.withUnsafeMutableBytes { buf in
        try receivedFile.read(into: buf)
      }

      let fileContent = String(decoding: readBuffer.prefix(bytesRead), as: UTF8.self)
      #expect(fileContent == testData, "File content should match")

      try fileToSend.close()
    }
  }

  @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
  @Test func sendReceiveMessageWithMultipleFileDescriptors() throws {
    try withTemporaryFilePath(basename: "socket-multi-fd") { tempDir in
      // Test passing multiple file descriptors at once
      let server = try SocketDescriptor.open(.local, .stream)
      defer { try? server.close() }

      let client = try SocketDescriptor.open(.local, .stream)
      defer { try? client.close() }

      let socketPath = tempDir.appending("test.sock")
      let unixAddr = UnixAddress(socketPath.string)!
      let address = SocketAddress(unix: unixAddr)
      try server.bind(to: address)
      try server.listen(backlog: 1)

      try client.connect(to: address)
      let accepted = try server.accept()
      defer { try? accepted.close() }

      // Create three temporary files
      let file1 = tempDir.appending("file1.txt")
      let file2 = tempDir.appending("file2.txt")
      let file3 = tempDir.appending("file3.txt")

      // Write different content to each file
      let testData1 = "First file"
      let testData2 = "Second file"
      let testData3 = "Third file"

      for (path, data) in [(file1, testData1), (file2, testData2), (file3, testData3)] {
        let fd = try FileDescriptor.open(path, .writeOnly, options: [.create, .truncate], permissions: [.ownerReadWrite])
        _ = try data.utf8.withContiguousStorageIfAvailable { buffer in
          try fd.write(UnsafeRawBufferPointer(buffer))
        }
        try fd.close()
      }

      // Open all three for reading to send
      let fd1 = try FileDescriptor.open(file1, .readOnly)
      let fd2 = try FileDescriptor.open(file2, .readOnly)
      let fd3 = try FileDescriptor.open(file3, .readOnly)

      // Build ancillary message with three FDs
      var ancillary = SocketDescriptor.AncillaryMessageBuffer()
      let fds = [fd1.rawValue, fd2.rawValue, fd3.rawValue]
      fds.withUnsafeBytes { bytes in
        let span = RawSpan(_unsafeBytes: bytes)
        ancillary.appendMessage(
          level: SocketDescriptor.ProtocolID(rawValue: SOL_SOCKET),
          type: .init(rawValue: CInt(SCM_RIGHTS)),
          bytes: span
        )
      }

      // Send message with three file descriptors
      let message = "Three FDs attached"
      let messageBytes = Array(message.utf8)
      let sent = try messageBytes.withUnsafeBytes { bytes in
        let span = RawSpan(_unsafeBytes: bytes)
        return try client.sendMessage(span, ancillaryMessages: ancillary)
      }
      #expect(sent == messageBytes.count)

      // Receive message and file descriptors
      var buffer = [UInt8](repeating: 0, count: 1024)
      var recvAncillary = SocketDescriptor.AncillaryMessageBuffer(minimumCapacity: 256)
      var sender: SocketAddress? = nil

      let received = try buffer.withUnsafeMutableBytes { buf in
        var recvOutput = OutputRawSpan(buffer: buf, initializedCount: 0)
        return try accepted.receiveMessage(
          into: &recvOutput,
          ancillaryMessages: &recvAncillary,
          sender: &sender
        )
      }
      #expect(received == messageBytes.count)

      // Extract the three received file descriptors
      var receivedFDs: [CInt] = []
      recvAncillary._withUnsafeBytes { controlData in
        guard controlData.count >= MemoryLayout<CInterop.CMsgHdr>.size else { return }

        let header = controlData.baseAddress!.assumingMemoryBound(to: CInterop.CMsgHdr.self)
        if header.pointee.cmsg_level == SOL_SOCKET &&
           header.pointee.cmsg_type == CInt(SCM_RIGHTS) {
          let dataOffset = MemoryLayout<CInterop.CMsgHdr>.size
          let dataSize = Int(header.pointee.cmsg_len) - dataOffset
          let fdCount = dataSize / MemoryLayout<CInt>.size

          let fdsPtr = (controlData.baseAddress! + dataOffset).assumingMemoryBound(to: CInt.self)
          for i in 0..<fdCount {
            receivedFDs.append(fdsPtr[i])
          }
        }
      }

      #expect(receivedFDs.count == 3, "Should have received 3 file descriptors")

      // Verify we can read correct content from each FD
      for (index, fdValue) in receivedFDs.enumerated() {
        let receivedFile = FileDescriptor(rawValue: fdValue)
        defer { try? receivedFile.close() }

        var readBuffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = try readBuffer.withUnsafeMutableBytes { buf in
          try receivedFile.read(into: buf)
        }

        let fileContent = String(decoding: readBuffer.prefix(bytesRead), as: UTF8.self)
        let expectedContent = [testData1, testData2, testData3][index]
        #expect(fileContent == expectedContent, "FD \(index) content should match")
      }

      try fd1.close()
      try fd2.close()
      try fd3.close()
    }
  }
}

#endif
