/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

private var _pathOffset: Int {
  // FIXME: If this isn't just a constant, use `offsetof` in C.
  MemoryLayout<CInterop.SockAddrUn>.offset(of: \CInterop.SockAddrUn.sun_path)!
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  public struct Local {
    internal let _path: FilePath

    public init(_ path: FilePath) {
      self._path = path
    }

    public init?(_ address: SocketAddress) {
      guard address.family == .local else { return nil }
      let path: FilePath? = address.withUnsafeBytes { buffer in
        guard buffer.count >= _pathOffset + 1 else {
          return nil
        }
        let path = (buffer.baseAddress! + _pathOffset)
          .assumingMemoryBound(to: CInterop.PlatformChar.self)
        return FilePath(platformString: path)
      }
      guard path != nil else { return nil }
      self._path = path!
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress {
  public init(_ local: Local) {
    let offset = _pathOffset
    let length = offset + local._path.length + 1
    self.init(unsafeUninitializedCapacity: length) { target in
      let addr = target.baseAddress!.assumingMemoryBound(to: CInterop.SockAddr.self)
      addr.pointee.sa_len = UInt8(exactly: length) ?? 255
      addr.pointee.sa_family = CInterop.SAFamily(Family.local.rawValue)
      // FIXME: It shouldn't be this difficult to get a null-terminated
      // UBP<CChar> out of a FilePath
      let path = (target.baseAddress! + offset)
        .assumingMemoryBound(to: SystemChar.self)
      local._path._storage.nullTerminatedStorage.withUnsafeBufferPointer { source in
        assert(source.count == length - offset)
        path.initialize(from: source.baseAddress!, count: source.count)
      }
      return length
    }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.Local {
  public var path: FilePath { _path }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.Local: Hashable {
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension SocketAddress.Local: CustomStringConvertible {
  public var description: String {
    _path.description
  }
}
