/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketDescriptor {
  /// A reusable collection of variable-sized ancillary messages
  /// sent or received over a socket. These represent protocol control
  /// related messages or other miscellaneous ancillary data.
  ///
  /// Corresponds to a buffer of `struct cmsghdr` messages in C, as used
  /// by `sendmsg` and `recmsg`.
  public struct AncillaryMessageBuffer {
    internal var _buffer: _RawBuffer
    internal var _endOffset: Int

    /// Initialize a new empty ancillary message buffer with no preallocated
    /// storage.
    public init() {
      _buffer = _RawBuffer()
      _endOffset = 0
    }

    /// Initialize a new empty ancillary message buffer of the
    /// specified minimum capacity (in bytes).
    internal init(minimumCapacity: Int) {
      let headerSize = MemoryLayout<CInterop.CMsgHdr>.size
      let capacity = Swift.max(headerSize + 1, minimumCapacity)
      _buffer = _RawBuffer(minimumCapacity: capacity)
      _endOffset = 0
    }

    internal var _headerSize: Int { MemoryLayout<CInterop.CMsgHdr>.size }
    internal var _capacity: Int { _buffer.capacity }

    /// Remove all messages currently in this buffer, preserving storage
    /// capacity.
    ///
    /// This invalidates all indices in the collection.
    ///
    /// - Complexity: O(1). Does not reallocate the buffer.
    public mutating func removeAll() {
      _endOffset = 0
    }

    /// Reserve enough storage capacity to hold `minimumCapacity` bytes' worth
    /// of messages without having to reallocate storage.
    ///
    /// This does not invalidate any indices.
    ///
    /// - Complexity: O(max(`minimumCapacity`, `capacity`)), where `capacity` is
    ///     the current storage capacity. This potentially needs to reallocate
    ///     the buffer and copy existing messages.
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
      _buffer.ensureUnique(capacity: minimumCapacity)
    }

    /// Append a message with the specified data to the end of this buffer,
    /// resizing it if necessary.
    ///
    /// This does not invalidate any existing indices, but it updates `endIndex`.
    ///
    /// - Complexity: Amortized O(`data.count`), when averaged over multiple
    ///    calls. This method reallocates the buffer if there isn't enough
    ///    capacity or if the storage is shared with another value.
    public mutating func appendMessage(
      level: SocketDescriptor.ProtocolID,
      type: SocketDescriptor.Option,
      bytes: UnsafeRawBufferPointer
    ) {
      appendMessage(
        level: level,
        type: type,
        unsafeUninitializedCapacity: bytes.count
      ) { buffer in
        assert(buffer.count >= bytes.count)
        if bytes.count > 0 {
          buffer.baseAddress!.copyMemory(
            from: bytes.baseAddress!,
            byteCount: bytes.count)
        }
        return bytes.count
      }
    }

    /// Append a message with the supplied data to the end of this buffer,
    /// resizing it if necessary. The message payload is initialized with the
    /// supplied closure, which needs to return the final message length.
    ///
    /// This does not invalidate any existing indices, but it updates `endIndex`.
    ///
    /// - Complexity: Amortized O(`data.count`), when averaged over multiple
    ///    calls. This method reallocates the buffer if there isn't enough
    ///    capacity or if the storage is shared with another value.
    public mutating func appendMessage(
      level: SocketDescriptor.ProtocolID,
      type: SocketDescriptor.Option,
      unsafeUninitializedCapacity capacity: Int,
      initializingWith body: (UnsafeMutableRawBufferPointer) throws -> Int
    ) rethrows {
      precondition(capacity >= 0)
      let headerSize = _headerSize
      let delta = _headerSize + capacity
      _buffer.ensureUnique(capacity: _endOffset + delta)
      let messageLength: Int = try _buffer.withUnsafeMutableBytes { buffer in
        assert(buffer.count >= _endOffset + delta)
        let p = buffer.baseAddress! + _endOffset
        let header = p.bindMemory(to: CInterop.CMsgHdr.self, capacity: 1)
        header.pointee = CInterop.CMsgHdr()
        header.pointee.cmsg_level = level.rawValue
        header.pointee.cmsg_type = type.rawValue
        let length = try body(
          UnsafeMutableRawBufferPointer(start: p + headerSize, count: capacity))
        precondition(length >= 0 && length <= capacity)
        header.pointee.cmsg_len = CInterop.SockLen(headerSize + length)
        return headerSize + length
      }
      _endOffset += messageLength
    }

    internal func _withUnsafeBytes<R>(
      _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R {
      try _buffer.withUnsafeBytes { buffer in
        assert(buffer.count >= _endOffset)
        let buffer = UnsafeRawBufferPointer(rebasing: buffer.prefix(_endOffset))
        return try body(buffer)
      }
    }

    internal mutating func _withUnsafeMutableBytes<R>(
      entireCapacity: Bool,
      _ body: (UnsafeMutableRawBufferPointer) throws -> R
    ) rethrows -> R {
      return try _buffer.withUnsafeMutableBytes { buffer in
        assert(buffer.count >= _endOffset)
        if entireCapacity {
          return try body(buffer)
        } else {
          return try body(.init(rebasing: buffer.prefix(_endOffset)))
        }
      }
    }

    internal mutating func _withMutableCInterop<R>(
      entireCapacity: Bool,
      _ body: (UnsafeMutableRawPointer?, inout CInterop.SockLen) throws -> R
    ) rethrows -> R {
      let (result, length): (R, Int) = try _withUnsafeMutableBytes(
        entireCapacity: entireCapacity
      ) { buffer in
        var length = CInterop.SockLen(buffer.count)
        let result = try body(buffer.baseAddress, &length)
        precondition(length >= 0 && length <= buffer.count)
        return (result, Int(length))
      }
      _endOffset = length
      return result
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketDescriptor.AncillaryMessageBuffer: Collection {
  /// The index type in an ancillary message buffer.
  @frozen
  public struct Index: Comparable, Hashable {
    @usableFromInline
    var _offset: Int

    @inlinable
    internal init(_offset: Int) {
      self._offset = _offset
    }

    @inlinable
    public static func == (left: Self, right: Self) -> Bool {
      left._offset == right._offset
    }

    @inlinable
    public static func < (left: Self, right: Self) -> Bool {
      left._offset < right._offset
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
      hasher.combine(_offset)
    }
  }

  /// An individual message inside an ancillary message buffer.
  ///
  /// Note that this is merely a reference to a slice of the underlying buffer,
  /// so it contains a shared copy of its entire storage. To prevent buffer
  /// reallocations due to copy-on-write copies, do not save instances
  /// of this type. Instead, immediately copy out any data you need to hold onto
  /// into standalone buffers.
  public struct Message {
    internal var _base: SocketDescriptor.AncillaryMessageBuffer
    internal var _offset: Int

    internal init(_base: SocketDescriptor.AncillaryMessageBuffer, offset: Int) {
      self._base = _base
      self._offset = offset
    }
  }

  /// The index of the first message in the collection, or `endIndex` if
  /// the collection contains no messages.
  ///
  /// This roughly corresponds to the C macro `CMSG_FIRSTHDR`.
  public var startIndex: Index { Index(_offset: 0) }

  /// The index after the last message in the collection.
  public var endIndex: Index { Index(_offset: _endOffset) }

  /// True if the collection contains no elements.
  public var isEmpty: Bool { _endOffset == 0 }

  /// Return the length (in bytes) of the message at the specified index, or
  /// nil if the index isn't valid, or it addresses a corrupt message.
  internal func _length(at i: Index) -> Int? {
    _withUnsafeBytes { buffer in
      guard i._offset >= 0 && i._offset + _headerSize <= buffer.count else {
        return nil
      }
      let p = (buffer.baseAddress! + i._offset)
        .assumingMemoryBound(to: CInterop.CMsgHdr.self)
      let length = Int(p.pointee.cmsg_len)

      // Cut the list short at the first sign of corrupt data.
      // Messages must not be shorter than their header, and they must fit
      // entirely in the buffer.
      if length < _headerSize || i._offset + length > buffer.count {
        return nil
      }
      return length
    }
  }

  /// Returns the index immediately following `i` in the collection.
  ///
  /// This roughly corresponds to the C macro `CMSG_NXTHDR`.
  ///
  /// - Complexity: O(1)
  public func index(after i: Index) -> Index {
    precondition(i._offset != _endOffset, "Can't advance past endIndex")
    precondition(i._offset >= 0 && i._offset + _headerSize <= _endOffset,
                 "Invalid index")
    guard let length = _length(at: i) else { return endIndex }
    return Index(_offset: i._offset + length)
  }

  /// Returns the message at the given position, which must be a valid index
  /// in this collection.
  ///
  /// The returned value merely refers to a slice of the entire buffer, so
  /// it contains a shared regerence to it.
  ///
  /// To reduce memory use and to prevent unnecessary copy-on-write copying, do
  /// not save `Message` values -- instead, copy out the data you need to hold
  /// on to into standalone storage.
  public subscript(position: Index) -> Message {
    guard let _ = _length(at: position) else {
      preconditionFailure("Invalid index")
    }
    return Element(_base: self, offset: position._offset)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketDescriptor.AncillaryMessageBuffer.Message {
  internal var _header: CInterop.CMsgHdr {
    _base._withUnsafeBytes { buffer in
      assert(_offset + _base._headerSize <= buffer.count)
      let p = buffer.baseAddress! + _offset
      let header = p.assumingMemoryBound(to: CInterop.CMsgHdr.self)
      return header.pointee
    }
  }

  /// The protocol level of the message. Socket-level command messages
  /// use the special protocol value `SocketDescriptor.ProtocolID.socketOption`.
  public var level: SocketDescriptor.ProtocolID {
    .init(rawValue: _header.cmsg_level)
  }

  /// The protocol-specific type of the message.
  public var type: SocketDescriptor.Option {
    .init(rawValue: _header.cmsg_type)
  }

  /// Calls `body` with an unsafe raw buffer pointer containing the
  /// message payload.
  ///
  /// This roughly corresponds to the C macro `CMSG_DATA`.
  ///
  /// - Note: The buffer passed to `body` does not include storage reserved
  ///    for holding the message header, such as the `level` and `type` values.
  ///    To access header information, you have to use the corresponding
  ///    properties.
  public func withUnsafeBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    try _base._withUnsafeBytes { buffer in
      let headerSize = _base._headerSize
      assert(_offset + headerSize <= buffer.count)
      let p = buffer.baseAddress! + _offset
      let header = p.assumingMemoryBound(to: CInterop.CMsgHdr.self)
      let data = p + headerSize
      let count = Swift.min(Int(header.pointee.cmsg_len) - headerSize,
                            buffer.count)
      return try body(UnsafeRawBufferPointer(start: data, count: count))
    }
  }
}
