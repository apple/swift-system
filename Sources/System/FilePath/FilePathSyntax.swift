/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// MARK: - Query API

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  /// Returns true if this path uniquely identifies the location of
  /// a file without reference to an additional starting location.
  ///
  /// On Unix platforms, absolute paths begin with a `/`. `isAbsolute` is
  /// equivalent to `root != nil`.
  ///
  /// On Windows, absolute paths are fully qualified paths. `isAbsolute` is
  /// _not_ equivalent to `root != nil` for traditional DOS paths
  /// (e.g. `C:foo` and `\bar` have roots but are not absolute). UNC paths
  /// and device paths are always absolute. Traditional DOS paths are
  /// absolute only if they begin with a volume or drive followed by
  /// a `:` and a separator.
  ///
  /// NOTE: This does not perform shell expansion or substitute
  /// environment variables; paths beginning with `~` are considered relative.
  ///
  /// Examples:
  /// * Unix:
  ///   * `/usr/local/bin`
  ///   * `/tmp/foo.txt`
  ///   * `/`
  /// * Windows:
  ///   * `C:\Users\`
  ///   * `\\?\UNC\server\share\bar.exe`
  ///   * `\\server\share\bar.exe`
  public var isAbsolute: Bool {
    self.root?.isAbsolute ?? false
  }

  /// Returns true if this path is not absolute (see `isAbsolute`).
  ///
  /// Examples:
  /// * Unix:
  ///   * `~/bar`
  ///   * `tmp/foo.txt`
  /// * Windows:
  ///   * `bar\baz`
  ///   * `C:Users\`
  ///   * `\Users`
  public var isRelative: Bool { !isAbsolute }

  // TODO(Windows docs): examples with roots, such as whether `\foo\bar`
  //   starts with `C:\foo`
  /// Returns whether `other` is a prefix of `self`, only considering
  /// whole path components.
  ///
  /// Example:
  ///
  ///     let path: FilePath = "/usr/bin/ls"
  ///     path.starts(with: "/")              // true
  ///     path.starts(with: "/usr/bin")       // true
  ///     path.starts(with: "/usr/bin/ls")    // true
  ///     path.starts(with: "/usr/bin/ls///") // true
  ///     path.starts(with: "/us")            // false
  public func starts(with other: FilePath) -> Bool {
    guard !other.isEmpty else { return true }
    return self.root == other.root && components.starts(
      with: other.components)
  }

  // TODO(Windows docs): examples with roots, such as whether `C:\foo\bar`
  //   ends with `C:bar`
  /// Returns whether `other` is a suffix of `self`, only considering
  /// whole path components.
  ///
  /// Example:
  ///
  ///     let path: FilePath = "/usr/bin/ls"
  ///     path.ends(with: "ls")             // true
  ///     path.ends(with: "bin/ls")         // true
  ///     path.ends(with: "usr/bin/ls")     // true
  ///     path.ends(with: "/usr/bin/ls///") // true
  ///     path.ends(with: "/ls")            // false
  public func ends(with other: FilePath) -> Bool {
    if other.root != nil {
      // TODO: anything tricky here for Windows?
      return self == other
    }

    return components.reversed().starts(
      with: other.components.reversed())
  }

  /// Whether this path is empty
  public var isEmpty: Bool { _storage.isEmpty }
}

// MARK: - Decompose a path
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  /// Returns the root of a path if there is one, otherwise `nil`.
  ///
  /// On Unix, this will return the leading `/` if the path is absolute
  /// and `nil` if the path is relative.
  ///
  /// On Windows, for traditional DOS paths, this will return
  /// the path prefix up to and including a root directory or
  /// a supplied drive or volume. Otherwise, if the path is relative to
  /// both the current directory and current drive, returns `nil`.
  ///
  /// On Windows, for UNC or device paths, this will return the path prefix
  /// up to and including the host and share for UNC paths or the volume for
  /// device paths followed by any subsequent separator.
  ///
  /// Examples:
  /// * Unix:
  ///   * `/foo/bar => /`
  ///   * `foo/bar  => nil`
  /// * Windows:
  ///   * `C:\foo\bar                => C:\`
  ///   * `C:foo\bar                 => C:`
  ///   * `\foo\bar                  => \ `
  ///   * `foo\bar                   => nil`
  ///   * `\\server\share\file       => \\server\share\`
  ///   * `\\?\UNC\server\share\file => \\?\UNC\server\share\`
  ///   * `\\.\device\folder         => \\.\device\`
  ///
  /// Setting the root to `nil` will remove the root and setting a new
  /// root will replace the root.
  ///
  /// Example:
  ///
  ///     var path: FilePath = "/foo/bar"
  ///     path.root = nil // path is "foo/bar"
  ///     path.root = "/" // path is "/foo/bar"
  ///
  /// Example (Windows):
  ///
  ///     var path: FilePath = #"\foo\bar"#
  ///     path.root = nil         // path is #"foo\bar"#
  ///     path.root = "C:"        // path is #"C:foo\bar"#
  ///     path.root = #"C:\"#     // path is #"C:\foo\bar"#
  public var root: FilePath.Root? {
    get {
      guard _hasRoot else { return nil }
      return Root(self, rootEnd: _relativeStart)
    }
    set {
      defer { _invariantCheck() }
      guard let r = newValue else {
        _storage.removeSubrange(..<_relativeStart)
        return
      }
      _storage.replaceSubrange(..<_relativeStart, with: r._slice)
    }
  }

  /// Creates a new path containing just the components, i.e. everything
  /// after `root`.
  ///
  /// Returns self if `root == nil`.
  ///
  /// Examples:
  /// * Unix:
  ///   * `/foo/bar => foo/bar`
  ///   * `foo/bar  => foo/bar`
  ///   * `/        => ""`
  /// * Windows:
  ///   * `C:\foo\bar                  => foo\bar`
  ///   * `foo\bar                     => foo\bar`
  ///   * `\\?\UNC\server\share\file   => file`
  ///   * `\\?\device\folder\file.exe  => folder\file.exe`
  ///   * `\\server\share\file         => file`
  ///   * `\                           => ""`
  public __consuming func removingRoot() -> FilePath {
    var copy = self
    copy.root = nil
    return copy
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  /// Returns the final component of the path.
  /// Returns `nil` if the path is empty or only contains a root.
  ///
  /// Note: Even if the final component is a special directory
  /// (`.` or `..`), it will still be returned. See `lexicallyNormalize()`.
  ///
  /// Examples:
  /// * Unix:
  ///   * `/usr/local/bin/ => bin`
  ///   * `/tmp/foo.txt    => foo.txt`
  ///   * `/tmp/foo.txt/.. => ..`
  ///   * `/tmp/foo.txt/.  => .`
  ///   * `/               => nil`
  /// * Windows:
  ///   * `C:\Users\                    => Users`
  ///   * `C:Users\                     => Users`
  ///   * `C:\                          => nil`
  ///   * `\Users\                      => Users`
  ///   * `\\?\UNC\server\share\bar.exe => bar.exe`
  ///   * `\\server\share               => nil`
  ///   * `\\?\UNC\server\share\        => nil`
  public var lastComponent: Component? { components.last }

  /// Creates a new path with everything up to but not including
  /// `lastComponent`.
  ///
  /// If the path only contains a root, returns `self`.
  /// If the path has no root and only includes a single component,
  /// returns an empty FilePath.
  ///
  /// Examples:
  /// * Unix:
  ///   * `/usr/bin/ls => /usr/bin`
  ///   * `/foo        => /`
  ///   * `/           => /`
  ///   * `foo         => ""`
  /// * Windows:
  ///   * `C:\foo\bar.exe                 => C:\foo`
  ///   * `C:\                            => C:\`
  ///   * `\\server\share\folder\file.txt => \\server\share\folder`
  ///   * `\\server\share\                => \\server\share\`
  public __consuming func removingLastComponent() -> FilePath {
    var copy = self
    copy.removeLastComponent()
    return copy
  }

  /// In-place mutating variant of `removingLastComponent`.
  ///
  /// If `self` only contains a root, does nothing and returns `false`.
  /// Otherwise removes `lastComponent` and returns `true`.
  ///
  /// Example:
  ///
  ///     var path = "/usr/bin"
  ///     path.removeLastComponent() == true  // path is "/usr"
  ///     path.removeLastComponent() == true  // path is "/"
  ///     path.removeLastComponent() == false // path is "/"
  @discardableResult
  public mutating func removeLastComponent() -> Bool {
    defer { _invariantCheck() }
    guard let lastRel = lastComponent else { return false }
    _storage.removeSubrange(lastRel._slice.indices)
    _removeTrailingSeparator()
    return true
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath.Component {
  /// The extension of this file or directory component.
  ///
  /// If `self` does not contain a `.` anywhere, or only
  /// at the start, returns `nil`. Otherwise, returns everything after the dot.
  ///
  /// Examples:
  ///   * `foo.txt    => txt`
  ///   * `foo.tar.gz => gz`
  ///   * `Foo.app    => app`
  ///   * `.hidden    => nil`
  ///   * `..         => nil`
  public var `extension`: String? {
    guard let range = _extensionRange() else { return nil }
    return _slice[range].string
  }

  /// The non-extension portion of this file or directory  component.
  ///
  /// Examples:
  ///   * `foo.txt => foo`
  ///   * `foo.tar.gz => foo.tar`
  ///   * `Foo.app => Foo`
  ///   * `.hidden => .hidden`
  ///   * `..      => ..`
  public var stem: String {
    _slice[_stemRange()].string
  }
}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {

  /// The extension of the file or directory last component.
  ///
  /// If `lastComponent` is `nil` or one of the special path components
  /// `.` or `..`, `get` returns `nil` and `set` does nothing.
  ///
  /// If `lastComponent` does not contain a `.` anywhere, or only
  /// at the start, `get` returns `nil` and `set` will append a
  /// `.` and `newValue` to `lastComponent`.
  ///
  /// Otherwise `get` returns everything after the last `.` and `set` will
  /// replace the extension.
  ///
  /// Examples:
  ///   * `/tmp/foo.txt                  => txt`
  ///   * `/Applications/Foo.app/        => app`
  ///   * `/Applications/Foo.app/bar.txt => txt`
  ///   * `/tmp/foo.tar.gz               => gz`
  ///   * `/tmp/.hidden                  => nil`
  ///   * `/tmp/.hidden.                 => ""`
  ///   * `/tmp/..                       => nil`
  ///
  /// Example:
  ///
  ///     var path = "/tmp/file"
  ///     path.extension = "txt" // path is "/tmp/file.txt"
  ///     path.extension = "o"   // path is "/tmp/file.o"
  ///     path.extension = nil    // path is "/tmp/file"
  ///     path.extension = ""     // path is "/tmp/file."
  public var `extension`: String? {
    get { lastComponent?.extension }
    set {
      defer { _invariantCheck() }
      guard let base = lastComponent, base.kind == .regular else { return }

      let suffix: SystemString
      if let ext = newValue {
        suffix = _makeExtension(ext)
      } else {
        suffix = SystemString()
      }

      let extRange = (
        base._extensionIndex() ?? base._slice.endIndex
      ) ..< base._slice.endIndex

      _storage.replaceSubrange(extRange, with: suffix)
    }
  }

  /// The non-extension portion of the file or directory last component.
  ///
  /// Returns `nil` if `lastComponent` is `nil`
  ///
  ///   * `/tmp/foo.txt                 => foo`
  ///   * `/Applications/Foo.app/        => Foo`
  ///   * `/Applications/Foo.app/bar.txt => bar`
  ///   * `/tmp/.hidden                 => .hidden`
  ///   * `/tmp/..                      => ..`
  ///   * `/                            => nil`
  public var stem: String? { lastComponent?.stem }

}

@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  /// Whether the path is in lexical-normal form, that is `.` and `..`
  /// components have been collapsed lexically (i.e. without following
  /// symlinks).
  ///
  /// Examples:
  /// * `"/usr/local/bin".isLexicallyNormal == true`
  /// * `"../local/bin".isLexicallyNormal   == true`
  /// * `"local/bin/..".isLexicallyNormal   == false`
  public var isLexicallyNormal: Bool {
    // `..` components are permitted at the front of a
    // relative path, otherwise there should be no special directories
    //
    // FIXME: Windows `C:..\foo\bar` should probably be lexically normal, but
    // `\..\foo\bar` should not.
    components.drop(
      while: { root == nil && $0.kind == .parentDirectory }
    ).allSatisfy { $0.kind == .regular }
  }

  /// Collapse `.` and `..` components lexically (i.e. without following
  /// symlinks).
  ///
  /// Examples:
  /// * `/usr/./local/bin/.. => /usr/local`
  /// * `/../usr/local/bin   => /usr/local/bin`
  /// * `../usr/local/../bin => ../usr/bin`
  public mutating func lexicallyNormalize() {
    defer { _invariantCheck() }
    _normalizeSpecialDirectories()
  }

  /// Returns a copy of `self` in lexical-normal form, that is `.` and `..`
  /// components have been collapsed lexically (i.e. without following
  /// symlinks). See `lexicallyNormalize`
  public __consuming func lexicallyNormalized() -> FilePath {
    var copy = self
    copy.lexicallyNormalize()
    return copy
  }

  /// Create a new `FilePath` by resolving `subpath` relative to `self`,
  /// ensuring that the result is lexically contained within `self`.
  ///
  /// `subpath` will be lexically normalized (see `lexicallyNormalize`) as
  /// part of resolution, meaning any contained `.` and `..` components will
  /// be collapsed without resolving symlinks. Any root in `subpath` will be
  /// ignored.
  ///
  /// Returns `nil` if the result would "escape" from `self` through use of
  /// the special directory component `..`.
  ///
  /// This is useful for protecting against arbitrary path traversal from an
  /// untrusted subpath: the result is guaranteed to be lexically contained
  /// within `self`. Since this operation does not consult the file system to
  /// resolve symlinks, any escaping symlinks nested inside of `self` can still
  /// be targeted by the result.
  ///
  /// Example:
  ///
  ///     let staticContent: FilePath = "/var/www/my-website/static"
  ///     let links: [FilePath] =
  ///       ["index.html", "/assets/main.css", "../../../../etc/passwd"]
  ///     links.map { staticContent.lexicallyResolving($0) }
  ///       // ["/var/www/my-website/static/index.html",
  ///       //  "/var/www/my-website/static/assets/main.css",
  ///       //  nil]
  public __consuming func lexicallyResolving(
    _ subpath: __owned FilePath
  ) -> FilePath? {
    let subpath = subpath.removingRoot().lexicallyNormalized()
    guard !subpath.isEmpty else { return self }
    guard subpath.components.first?.kind != .parentDirectory else {
      return nil
    }
    return self.appending(subpath.components)
  }
}

// Modification and concatenation API
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  // TODO(Windows docs): example with roots
  /// If `prefix` is a prefix of `self`, removes it and returns `true`.
  /// Otherwise returns `false`.
  ///
  /// Example:
  ///
  ///     var path: FilePath = "/usr/local/bin"
  ///     path.removePrefix("/usr/bin")   // false
  ///     path.removePrefix("/us")        // false
  ///     path.removePrefix("/usr/local") // true, path is "bin"
  public mutating func removePrefix(_ prefix: FilePath) -> Bool {
    defer { _invariantCheck() }
    // FIXME: Should Windows have more nuanced semantics?
    guard root == prefix.root else { return false }
    let (tail, remainder) = _dropCommonPrefix(components, prefix.components)
    guard remainder.isEmpty else { return false }
    self._storage.removeSubrange(..<tail.startIndex._storage)
    return true
  }

  // TODO(Windows docs): example with roots
  /// Append a `component` on to the end of this path.
  ///
  /// Example:
  ///
  ///     var path: FilePath = "/tmp"
  ///     let sub: FilePath = "foo/./bar/../baz/."
  ///     for comp in sub.components.filter({ $0.kind != .currentDirectory }) {
  ///       path.append(comp)
  ///     }
  ///     // path is "/tmp/foo/bar/../baz"
  public mutating func append(_ component: __owned FilePath.Component) {
    defer { _invariantCheck() }
    _append(unchecked: component._slice)
  }

  // TODO(Windows docs): example with roots
  /// Append `components` on to the end of this path.
  ///
  /// Example:
  ///
  ///     var path: FilePath = "/"
  ///     path.append(["usr", "local"])     // path is "/usr/local"
  ///     let otherPath: FilePath = "/bin/ls"
  ///     path.append(otherPath.components) // path is "/usr/local/bin/ls"
  public mutating func append<C: Collection>(
    _ components: __owned C
  ) where C.Element == FilePath.Component {
    defer { _invariantCheck() }
    for c in components {
      _append(unchecked: c._slice)
    }
  }

  // TODO(Windows docs): example with roots, should we rephrase this "spurious
  // roots"?
  /// Append the contents of `other`, ignoring any spurious leading separators.
  ///
  /// A leading separator is spurious if `self` is non-empty.
  ///
  /// Example:
  ///
  ///     var path: FilePath = ""
  ///     path.append("/var/www/website") // "/var/www/website"
  ///     path.append("static/assets") // "/var/www/website/static/assets"
  ///     path.append("/main.css") // "/var/www/website/static/assets/main.css"
  public mutating func append(_ other: __owned String) {
    defer { _invariantCheck() }
    guard !other.utf8.isEmpty else { return }
    guard !isEmpty else {
      self = FilePath(other)
      return
    }
    let otherPath = FilePath(other)
    _append(unchecked: otherPath._storage[otherPath._relativeStart...])
  }

  // TODO(Windows docs): example with roots
  /// Non-mutating version of `append(_:Component)`.
  public __consuming func appending(_ other: __owned Component) -> FilePath {
    var copy = self
    copy.append(other)
    return copy
  }

  // TODO(Windows docs): example with roots
  /// Non-mutating version of `append(_:C)`.
  public __consuming func appending<C: Collection>(
    _ components: __owned C
  ) -> FilePath where C.Element == FilePath.Component {
    var copy = self
    copy.append(components)
    return copy
  }

  // TODO(Windows docs): example with roots
  /// Non-mutating version of `append(_:String)`.
  public __consuming func appending(_ other: __owned String) -> FilePath {
    var copy = self
    copy.append(other)
    return copy
  }

  // TODO(Windows docs): examples and docs with roots, update/generalize doc
  // comment
  /// If `other` does not have a root, append each component of `other`. If
  /// `other` has a root, replaces `self` with other.
  ///
  /// This operation mimics traversing a directory structure (similar to the
  /// `cd` command), where pushing a relative path will append its components
  /// and pushing an absolute path will first clear `self`'s existing
  /// components.
  ///
  /// Example:
  ///
  ///     var path: FilePath = "/tmp"
  ///     path.push("dir/file.txt") // path is "/tmp/dir/file.txt"
  ///     path.push("/bin")         // path is "/bin"
  public mutating func push(_ other: __owned FilePath) {
    defer { _invariantCheck() }
    guard other.root == nil else {
      self = other
      return
    }
    // FIXME: Windows drive-relative roots, etc?
    _append(unchecked: other._storage[...])
  }

  // TODO(Windows docs): examples and docs with roots
  /// Non-mutating version of `push()`.
  public __consuming func pushing(_ other: __owned FilePath) -> FilePath {
    var copy = self
    copy.push(other)
    return copy
  }

  /// Remove the contents of the path, keeping the null terminator.
  public mutating func removeAll(keepingCapacity: Bool = false) {
    defer { _invariantCheck() }
    _storage.removeAll(keepingCapacity: keepingCapacity)
  }

  /// Reserve enough storage space to store `minimumCapacity` platform
  /// characters.
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    defer { _invariantCheck() }
    self._storage.reserveCapacity(minimumCapacity)
  }
}

// MARK - Renamed
@available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
extension FilePath {
  @available(*, unavailable, renamed: "removingLastComponent()")
  public var dirname: FilePath { removingLastComponent() }

  @available(*, unavailable, renamed: "lastComponent")
  public var basename: Component? { lastComponent }
}
