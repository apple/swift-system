/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

internal struct _ParsedWindowsRoot {
  var rootEnd: SystemString.Index

  // TODO: Remove when I normalize to always (except `C:`)
  // have trailing separator
  var relativeBegin: SystemString.Index

  var drive: SystemChar?
  var fullyQualified: Bool

  var deviceSigil: SystemChar?

  var host: Range<SystemString.Index>?
  var volume: Range<SystemString.Index>?
}

extension _ParsedWindowsRoot {
  static func traditional(
    drive: SystemChar?, fullQualified: Bool, endingAt idx: SystemString.Index
  ) -> _ParsedWindowsRoot {
    _ParsedWindowsRoot(
      rootEnd: idx,
      relativeBegin: idx,
      drive: drive,
      fullyQualified: fullQualified,
      deviceSigil: nil,
      host: nil,
      volume: nil)
  }

  static func unc(
    deviceSigil: SystemChar?,
    server: Range<SystemString.Index>,
    share: Range<SystemString.Index>,
    endingAt end: SystemString.Index,
    relativeBegin relBegin: SystemString.Index
  ) -> _ParsedWindowsRoot {
    _ParsedWindowsRoot(
      rootEnd: end,
      relativeBegin: relBegin,
      drive: nil,
      fullyQualified: true,
      deviceSigil: deviceSigil,
      host: server,
      volume: share)
  }

  static func device(
    deviceSigil: SystemChar,
    volume: Range<SystemString.Index>,
    endingAt end: SystemString.Index,
    relativeBegin relBegin: SystemString.Index
  ) -> _ParsedWindowsRoot {
    _ParsedWindowsRoot(
      rootEnd: end,
      relativeBegin: relBegin,
      drive: nil,
      fullyQualified: true,
      deviceSigil: deviceSigil,
      host: nil,
      volume: volume)
  }
}

struct _Lexer {
  var slice: Slice<SystemString>

  init(_ str: SystemString) {
    self.slice = str[...]
  }

  var backslash: SystemChar { .backslash }

  // Try to eat a backslash, returns false if nothing happened
  mutating func eatBackslash() -> Bool {
    slice._eat(.backslash) != nil
  }

  // Try to consume a drive letter and subsequent `:`.
  mutating func eatDrive() -> SystemChar? {
    let copy = slice
    if let d = slice._eat(if: { $0.isLetter }), slice._eat(.colon) != nil {
      return d
    }
    // Restore slice
    slice = copy
    return nil
  }

  // Try to consume a device sigil (stand-alone . or ?)
  mutating func eatSigil() -> SystemChar? {
    let copy = slice
    guard let sigil = slice._eat(.question) ?? slice._eat(.dot) else {
      return nil
    }

    // Check for something like .hidden or ?question
    guard isEmpty || slice.first == backslash else {
      slice = copy
      return nil
    }

    return sigil
  }

  // Try to consume an explicit "UNC" directory
  mutating func eatUNC() -> Bool {
    slice._eatSequence("UNC".unicodeScalars.lazy.map { SystemChar(ascii: $0) }) != nil
  }

  // Eat everything up to but not including a backslash or null
  mutating func eatComponent() -> Range<SystemString.Index> {
    let backslash = self.backslash
    let component = slice._eatWhile({ $0 != backslash })
      ?? slice[slice.startIndex ..< slice.startIndex]
    return component.indices
  }

  var isEmpty: Bool {
    return slice.isEmpty
  }

  var current: SystemString.Index { slice.startIndex }

  mutating func clear() {
    // TODO: Intern empty system string
    self = _Lexer(SystemString())
  }

  mutating func reset(to: SystemString, at: SystemString.Index) {
    self.slice = to[at...]
  }
}

internal struct WindowsRootInfo {
  // The "volume" of a root. For UNC paths, this is also known as the "share".
  internal enum Volume: Equatable {
    /// No volume specified
    ///
    /// * Traditional root relative to the current drive: `\`,
    /// * Omitted volume from other forms: `\\.\`, `\\.\UNC\server\\`, `\\server\\`
    case empty

    // TODO: NT paths? Admin paths using `$`?
    /// A specified drive.
    ///
    /// * Traditional disk: `C:\`, `C:`
    /// * Device disk: `\\.\C:\`, `\\?\C:\`
    /// * UNC: `\\server\e:\`, `\\?\UNC\server\e:\`
    case drive(Character)

    // TODO: GUID type?
    /// A volume with a GUID in a non-traditional path
    ///
    /// * UNC: `\\host\Volume{0000-...}\`, `\\.\UNC\host\Volume{0000-...}\`
    /// * Device roots: `\\.\Volume{0000-...}\`, `\\?\Volume{000-...}\`
    case guid(String)

    // TODO: Legacy DOS devices, such as COM1?

    /// Device object or share name
    ///
    /// * Device roots: `\\.\BootPartition\`
    /// * UNC: `\\host\volume\`
    case volume(String)

    // TODO: Should legacy DOS devices be detected and/or converted at construction time?
    // TODO: What about NT paths: `\??\`
  }

  /// Represents the syntactic form of the path
  internal enum Form: Equatable {
    /// Traditional DOS roots: `C:\`, `C:`, and `\`
    case traditional(fullyQualified: Bool) // `C:\`, `C:`, `\`

    /// UNC syntactic form: `\\server\share\`
    case unc

    /// DOS device syntactic form: `\\?\BootPartition`, `\\.\C:\`, `\\?\UNC\server\share`
    case device(sigil: Character)

    // TODO: NT?
  }

  /// The host for UNC paths, else `nil`.
  internal var host: String?

  /// The specified volume (or UNC share) for the root
  internal var volume: Volume

  /// The syntactic form the root is in
  internal var form: Form

  init(host: String?, volume: Volume, form: Form) {
    self.host = host
    self.volume = volume
    self.form = form
    checkInvariants()
  }
}

extension _ParsedWindowsRoot {
  fileprivate func volumeInfo(_ root: SystemString) -> WindowsRootInfo.Volume {
    if let d = self.drive {
      return .drive(Character(d.asciiScalar!))
    }

    guard let vol = self.volume, !vol.isEmpty else { return .empty }

    // TODO: check for GUID
    // TODO: check for drive
    return .volume(root[vol].string)
  }
}

extension WindowsRootInfo {
  internal init(_ root: SystemString, _ parsed: _ParsedWindowsRoot) {
    self.volume = parsed.volumeInfo(root)

    if let host = parsed.host {
      self.host = root[host].string
    } else {
      self.host = nil
    }

    if let sig = parsed.deviceSigil {
      self.form = .device(sigil: Character(sig.asciiScalar!))
    } else if parsed.host != nil {
      assert(parsed.volume != nil)
      self.form = .unc
    } else {
      self.form = .traditional(fullyQualified: parsed.fullyQualified)
    }
  }
}

extension WindowsRootInfo {
  /// NOT `\foo\bar` nor `C:foo\bar`
  internal var isFullyQualified: Bool {
    return form != .traditional(fullyQualified: false)
  }

  ///
  /// `\\server\share\foo\bar.exe`, `\\.\UNC\server\share\foo\bar.exe`
  internal var isUNC: Bool {
    host != nil
  }

  ///
  /// `\foo\bar.exe`
  internal var isTraditionalRooted: Bool {
    form == .traditional(fullyQualified: false) && volume == .empty
  }

  ///
  /// `C:foo\bar.exe`
  internal var isTraditionalDriveRelative: Bool {
    switch (form, volume) {
    case (.traditional(fullyQualified: false), .drive(_)): return true
    default: return false
    }
  }

  // TODO: Should this be component?
  func formPath() -> FilePath {
    fatalError("Unimplemented")
  }

  //    static func traditional(
  //      drive: Character?, fullyQualified: Bool
  //    ) -> WindowsRootInfo {
  //      let vol: Volume
  //      if let d = Character {
  //        vol = .drive(d)
  //      } else {
  //        vol = .relative
  //      }
  //
  //      return WindowsRootInfo(
  //        volume: .relative, form: .traditional(fullyQualified: false))
  //    }

  internal func checkInvariants() {
    switch form {
    case .traditional(let qual):
      precondition(host == nil)
      switch volume {
      case .empty:
        precondition(!qual)
        break
      case .drive(_): break
      default: preconditionFailure()
      }
    case .unc:
      precondition(host != nil)
    case .device(_): break
    }
  }

}

extension SystemString {
  // TODO: Or, should I always inline this to remove some of the bookeeping?
  private func _parseWindowsRootInternal() -> _ParsedWindowsRoot? {
    assert(_windowsPaths)

    /*
      Windows root: device or UNC or DOS
        device: (`\\.` or `\\?`) `\` (drive or guid or UNC-link)
          drive: letter `:`
          guid: `Volume{` (hex-digit or `-`)* `}`
          UNC-link: `UNC\` UNC-volume
        UNC: `\\` UNC-volume
          UNC-volume: server `\` share
        DOS: fully-qualified or legacy-device or drive or `\`
          full-qualified: drive `\`

     TODO: What is \\?\server1\e:\utilities\\filecomparer\ from the docs?
     TODO: What about admin use of `$` instead of `:`? E.g. \\system07\C$\

     NOTE: Legacy devices are not handled by System at a library level, but
     are deferred to the relevant syscalls.
    */

    var lexer = _Lexer(self)

    // Helper to parse a UNC root
    func parseUNC(deviceSigil: SystemChar?) -> _ParsedWindowsRoot {
      let serverRange = lexer.eatComponent()
      guard lexer.eatBackslash() else {
        fatalError("expected normalized root to contain backslash")
      }
      let shareRange = lexer.eatComponent()
      let rootEnd = lexer.current
      _ = lexer.eatBackslash()
      return .unc(
        deviceSigil: deviceSigil,
        server: serverRange, share: shareRange,
        endingAt: rootEnd, relativeBegin: lexer.current)
    }


    // `C:` or `C:\`
    if let d = lexer.eatDrive() {
      // `C:\` - fully qualified
      let fullyQualified = lexer.eatBackslash()
      return .traditional(
        drive: d, fullQualified: fullyQualified, endingAt: lexer.current)
    }

    // `\` or else it's just a rootless relative path
    guard lexer.eatBackslash() else { return nil }

    // `\\` or else it's just a current-drive rooted traditional path
    guard lexer.eatBackslash() else {
      return .traditional(
        drive: nil, fullQualified: false, endingAt: lexer.current)
    }

    // `\\.` or `\\?` (device paths) or else it's just UNC
    guard let sigil = lexer.eatSigil() else {
      return parseUNC(deviceSigil: nil)
    }
    _ = sigil // suppress warnings

    guard lexer.eatBackslash() else {
      fatalError("expected normalized root to contain backslash")
    }

    if lexer.eatUNC() {
      guard lexer.eatBackslash() else {
        fatalError("expected normalized root to contain backslash")
      }
      return parseUNC(deviceSigil: sigil)
    }

    let device = lexer.eatComponent()
    let rootEnd = lexer.current
    _ = lexer.eatBackslash()

    return .device(
      deviceSigil: sigil, volume: device,
      endingAt: rootEnd, relativeBegin: lexer.current)
  }

  @inline(never)
  internal func _parseWindowsRoot() -> (
    rootEnd: SystemString.Index, relativeBegin: SystemString.Index
  ) {
    guard let parsed = _parseWindowsRootInternal() else {
      return (startIndex, startIndex)
    }
    return (parsed.rootEnd, parsed.relativeBegin)
  }
}

extension SystemString {
  // UNC and device roots can have multiple repeated roots that are meaningful,
  // and extra backslashes may need to be inserted for partial roots (e.g. empty
  // volume).
  //
  // Returns the point where `_normalizeSeparators` should resume.
  internal mutating func _prenormalizeWindowsRoots() -> Index {
    assert(_windowsPaths)
    assert(!self.contains(.slash), "only valid after separator conversion")

    var lexer = _Lexer(self)

    // Only relevant for UNC or device paths
    guard lexer.eatBackslash(), lexer.eatBackslash() else {
      return lexer.current
    }

    // Parse a backslash, inserting one if needed
    func expectBackslash() {
      if lexer.eatBackslash() { return }

      // A little gross, but we reset the lexer because the lexer
      // holds a strong reference to `self`.
      //
      // TODO: Intern the empty SystemString. Right now, this is
      // along an uncommon/pathological case, but we want to in
      // general make empty strings without allocation
      let idx = lexer.current
      lexer.clear()
      self.insert(.backslash, at: idx)
      lexer.reset(to: self, at: idx)
      let p = lexer.eatBackslash()
      assert(p)
    }
    // Parse a component and subsequent backslash, insering one if needed
    func expectComponent() {
      _ = lexer.eatComponent()
      expectBackslash()
    }

    // Check for `\\.` style paths
    if lexer.eatSigil() != nil {
      expectBackslash()
      if lexer.eatUNC() {
        expectBackslash()
        expectComponent()
        expectComponent()
        return lexer.current
      }
      expectComponent()
      return lexer.current
    }

    expectComponent()
    expectComponent()
    return lexer.current
  }
}
