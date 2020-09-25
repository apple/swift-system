/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  public struct Component: Hashable {
    // NOTE: For now, we store a slice of FilePath's storage representation. We'd like to
    // have a small-slice representation in the future since the majority of path
    // components would easily fit in the 3 words of storage.
    //
    internal var slice: FilePath.Storage.SubSequence

    // TODO: It would be nice to have a ComponentKind. Prefix (Windows only)
    // is an important piece of information that has to be parsed from the
    // front of the path.

    internal init(_ slice: FilePath.Storage.SubSequence) {
      self.slice = slice
      self.invariantCheck()
    }
  }
  public struct ComponentView {
    internal var path: FilePath
  }

  public var components: ComponentView {
    get { ComponentView(path: self) }
    set { self = newValue.path }
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath.Component {
  // WARNING: Return value is dependent on self
  fileprivate var unsafeCChars: UnsafeBufferPointer<CChar> {
    // Array must implement wCSIA with stable address...
    // TODO: A stable address byte buffer (and slice) would work better here...
    slice.withContiguousStorageIfAvailable { $0 }!
  }

  // WARNING: Return value is dependent on self
  fileprivate var unsafeUInt8s: UnsafeBufferPointer<UInt8> {
    unsafeCChars._asUInt8
  }

  fileprivate var count: Int { slice.count }

  public var isRoot: Bool {
    if isSeparator(slice.first!) {
      assert(count == 1)
      return true
    }
    return false
  }

  // TODO: ensure this all gets easily optimized away in release...
  fileprivate func invariantCheck() {
    defer { _fixLifetime(self) }

    // TODO: should this be a debugPrecondition? One can make a component
    // explicitly from a string, or maybe it should be a hard precondition
    // inside the EBSL init and a assert/debug one here...
    assert(isRoot || unsafeCChars.allSatisfy { !isSeparator($0) } )

    // TODO: Are we forbidding interior null?
    assert(unsafeUInt8s.isEmpty || unsafeUInt8s.last != 0)
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension String {
  /// Creates a string by interpreting the path component's content as UTF-8.
  ///
  /// - Parameter component: The path component to be interpreted as UTF-8.
  ///
  /// If the content of the path component
  /// isn't a well-formed UTF-8 string,
  /// this initializer removes invalid bytes or replaces them with U+FFFD.
  /// This means that, depending on the semantics of the specific file system,
  /// conversion to a string and back to a path
  /// might result in a value that's different from the original path.
  public init(decoding component: FilePath.Component) {
    defer { _fixLifetime(component) }
    self.init(decoding: component.unsafeUInt8s, as: UTF8.self)
  }

  /// Creates a string from a path component, validating its UTF-8 contents.
  ///
  /// - Parameter component: The path component to be interpreted as UTF-8.
  ///
  /// If the contents of the path component
  /// isn't a well-formed UTF-8 string,
  /// this initializer returns `nil`.
  public init?(validatingUTF8 component: FilePath.Component) {
    // TODO: use a failing initializer for String when one is added...
    defer { _fixLifetime(component) }
    let str = String(decoding: component)
    guard str.utf8.elementsEqual(component.unsafeUInt8s) else { return nil }
    self = str
  }

  // TODO: Consider a init?(validating:), keeping the encoding agnostic in API and
  // dependent on file system.
}


// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath.Component: CustomStringConvertible, CustomDebugStringConvertible {

  /// A textual representation of the path component.
  @inline(never)
  public var description: String { String(decoding: self) }

  /// A textual representation of the path component, suitable for debugging.
  public var debugDescription: String { self.description.debugDescription }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath.Component: ExpressibleByStringLiteral {
  // TODO: Invariant that there's only one component...
  // Should we even do this, or rely on FilePath from a literal and overloads?
  //
  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }

  // TODO: Invariant that there's only one component...
  // Should we even do this, or rely on FilePath from a literal and overloads?
  //
  public init(_ string: String) {
    let path = FilePath(string)
    precondition(path.components.count == 1)
    self = path.components.first!
    self.invariantCheck()
  }
}


private var canonicalSeparator: CChar { Int8(bitPattern: UInt8(ascii: "/")) }

// TODO: For Windows, this becomes a little more complicated...
private func isSeparator(_ c: CChar) -> Bool { c == canonicalSeparator }


// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
private func separatedComponentBytes<C: Collection>(
  _ components: C, addLeadingSeparator: Bool = false, addTrailingSeparator: Bool = false
) -> Array<CChar> where C.Element == FilePath.Component {
  var result = addLeadingSeparator ? [canonicalSeparator] : []
  defer { _fixLifetime(components) }
  let normalized = components.lazy.filter { !$0.isRoot }.map { $0.unsafeCChars }.joined(separator: [canonicalSeparator])
  result.append(contentsOf: normalized)

  if addTrailingSeparator && (result.isEmpty || !isSeparator(result.last!)) {
    result.append(canonicalSeparator)
  }
  return result
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath.ComponentView: BidirectionalCollection {
  public typealias Element = FilePath.Component
  public struct Index: Comparable, Hashable {
    internal typealias Storage = FilePath.Storage.Index

    internal var _storage: Storage

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs._storage < rhs._storage }

    fileprivate init(_ idx: Storage) {
      self._storage = idx
    }
  }

  public var startIndex: Index { Index(path.bytes.startIndex) }

  // Use the index of the guaranteed null terminator
  public var endIndex: Index { Index(path.bytes.indices.last!) }

  // Find the end of the component starting at `i`.
  private func parseComponentEnd(startingAt i: Index.Storage) -> Index.Storage {
    if isSeparator(path.bytes[i]) {
      // Special case: leading separator signifies root
      assert(i == path.bytes.startIndex)
      return path.bytes.index(after: i)
    }

    return path.bytes[i...].firstIndex(where: { isSeparator($0) }) ?? endIndex._storage
  }

  // Find the start of the component after the end of the prior at `i`
  private func parseNextComponentStart(
    afterComponentEnd i: Index.Storage
  ) -> Index.Storage {
    assert(i != endIndex._storage)
    if !isSeparator(path.bytes[i]) {
      assert(i == path.bytes.index(after: path.bytes.startIndex))
      // TODO: what about when we're done parsing and we have null terminator?
    }
    return path.bytes[i...].firstIndex(where: { !isSeparator($0) }) ?? endIndex._storage
  }

  public func index(after i: Index) -> Index {
    let end = parseComponentEnd(startingAt: i._storage)
    if Index(end) == endIndex {
      return endIndex
    }
    return Index(parseNextComponentStart(afterComponentEnd: end))
  }

  // Find the start of the component prior to the  after the end of the prior at `i`
  private func parseComponentStart(
    endingAt i: Index.Storage
  ) -> Index.Storage {
    assert(i != startIndex._storage)

    return path.bytes[i...].firstIndex(where: { !isSeparator($0) }) ?? startIndex._storage
  }

  // Chew through separators until we get to a component end
  private func parseComponentEnd(fromStart i: Index) -> Index.Storage {
    let slice = path.bytes[..<i._storage]
    return slice.lastIndex(where: { isSeparator($0) }) ?? startIndex._storage
  }

  public func index(before i: Index) -> Index {
    var slice = path.bytes[..<i._storage]
    while let c = slice.last, isSeparator(c) {
      slice.removeLast()
    }
    while let c = slice.last, !isSeparator(c) {
      slice.removeLast()
    }

    return Index(slice.endIndex)
  }

  public subscript(position: Index) -> FilePath.Component {
    let i = position
    let end = parseComponentEnd(startingAt: i._storage)
    return FilePath.Component(path.bytes[i._storage ..< end])
  }
}

// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath.ComponentView: RangeReplaceableCollection {
  public init() {
    self.init(path: FilePath())
  }

  public mutating func replaceSubrange<C: Collection>(
    _ subrange: Range<Index>, with newElements: C
  ) where Element == C.Element {
    let (lowerBound, upperBound) = (subrange.lowerBound, subrange.upperBound)

    let pathRange = lowerBound._storage ..< upperBound._storage
    guard !newElements.isEmpty else {
      path.bytes.removeSubrange(pathRange)
      return
    }

    // Insertion skips roots
    let hasNewComponents = !newElements.lazy.filter { !$0.isRoot }.isEmpty

    // Explicitly add a trailing separator if
    //   not at end and next character is not a separator
    let atEnd = upperBound == endIndex
    let trailingSeparator = !atEnd && !isSeparator(path.bytes[upperBound._storage])

    // Explicitly add a preceding separator if
    //   replacing front with absolute components (unless redundant by trailing separator),
    //   preceding character is not a separator (which implies at the end)
    let atStart = lowerBound == startIndex
    let componentsAreAbsolute = newElements.first!.isRoot
    let leadingSeparator: Bool
    if atStart {
      leadingSeparator = componentsAreAbsolute && (path.isRelative || hasNewComponents)
    } else if !isSeparator(path.bytes[path.bytes.index(before: lowerBound._storage)]) {
      assert(lowerBound == endIndex) // precondition?
      leadingSeparator = hasNewComponents
    } else {
      leadingSeparator = false
    }

    let newBytes = separatedComponentBytes(
          newElements,
          addLeadingSeparator: leadingSeparator,
          addTrailingSeparator: trailingSeparator)

    path.bytes.replaceSubrange(pathRange, with: newBytes)
  }
}


// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FilePath {
  public init<C: Collection>(_ components: C) where C.Element == Component {
    self.init(byteContents: separatedComponentBytes(components, addLeadingSeparator: components.first?.isRoot ?? false))
  }

  // FIXME: Include `~` as an absolute path first component
  public var isAbsolute: Bool { components.first?.isRoot ?? false }

  public var isRelative: Bool { !isAbsolute }

  public mutating func append(_ other: FilePath) {
    // TODO: We can do a faster byte copy operation, after checking
    // for leading/trailing slashes...
    self.components.append(contentsOf: other.components)
  }

  public static func +(_ lhs: FilePath, _ rhs: FilePath) -> FilePath {
    var result = lhs
    result.append(rhs)
    return result
  }

  /* TODO:
  public mutating func push(_ component: FilePath.Component) {
  }
  public mutating func push(_ path: FilePath) {
  }
  public mutating func push<C: Collection>(
    contentsOf components: C
  ) where C.Element == FilePath.Component {
  }

  @discardableResult
  public mutating func pop() -> FilePath.Component? {
    ... or should this trap if empty?
  }
  @discardableResult
  public mutating func pop(_ n: Int) -> FilePath.Component? {
   ... or should this trap if empty?
  }
 */

}

