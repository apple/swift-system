/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/

import Testing
#if SYSTEM_PACKAGE
@testable import SystemPackage
#else
@testable import System
#endif

// Equality, hashing, and ordering. `_StdlibFilePath` is meant to serve as a
// Dictionary key and to sort, so this is load-bearing. Every expected value
// here is derived from SE-0529, not from running the implementation:
//   * Equality: two paths are equal iff they have identical anchors, identical
//     component sequences, and the same suffix (trailing separator or resource
//     fork). Equality is purely syntactic: equal precisely when they print the
//     same. (SE-0529, "Printing, comparing, and hashing".)
//   * Darwin anchor canonicalization: `/.resolve/1/` => `/.nofollow/`, and
//     `/.vol/NNNN/2/` => `/.vol/NNNN/@/`.
//   * Ordering: lexicographic over the normalized byte representation: anchor,
//     then components, then the suffix as the final tiebreaker.

extension AllTests.EqualityTests {

  // MARK: - Encoding-difference equality

  // Repeated separators and interior `.` are meaningless encoding differences;
  // such spellings normalize to the same bytes and compare equal. Holds on
  // every platform (separator coalescing + dot normalization).
  @Test
  func encodingDifferencesAreEqual() {
    expectEqual(_StdlibFilePath("a///b"), _StdlibFilePath("a/b"), "a///b == a/b")
    expectEqual(_StdlibFilePath("a/./b"), _StdlibFilePath("a/b"), "a/./b == a/b")
    expectEqual(_StdlibFilePath("/./foo"), _StdlibFilePath("/foo"), "/./foo == /foo")
  }

  // MARK: - Suffix significance

  @Test
  func trailingSeparatorIsSignificant() {
    // "/tmp/foo" vs "/tmp/foo/": the trailing separator is meaningful.
    expectNotEqual(_StdlibFilePath("/tmp/foo"), _StdlibFilePath("/tmp/foo/"),
      "trailing separator differs")
  }

  @Test
  func currentDirectoryIsNotEmpty() {
    // "." has one component; "" is empty.
    expectNotEqual(_StdlibFilePath("."), _StdlibFilePath(""), "\".\" != \"\"")
  }

  // MARK: - Anchor significance

  @Test(.darwinOnly)
  func darwinAnchorIsSignificant() {
    // The do-not-follow-symlinks flag is part of the path's directions to
    // the kernel, so it is significant for ==.
    expectNotEqual(_StdlibFilePath("/.nofollow/foo/bar"), _StdlibFilePath("/foo/bar"),
      "differing Darwin anchors")
}

  @Test(.windowsOnly)
  func windowsAnchorIsSignificant() {
    // Device-namespace `\\.\C:\` vs drive `C:\` are different anchors.
    expectNotEqual(_StdlibFilePath(#"\\.\C:\foo\bar"#), _StdlibFilePath(#"C:\foo\bar"#),
      "differing Windows anchors")
}

  // MARK: - Darwin canonicalization equality

  @Test(.darwinOnly)
  func darwinCanonicalizationEquality() {
    // /.resolve/1/ canonicalizes to /.nofollow/ (same XNU flag).
    expectEqual(_StdlibFilePath("/.resolve/1/foo"), _StdlibFilePath("/.nofollow/foo"),
      "/.resolve/1/foo == /.nofollow/foo")
    // /.vol/NNNN/2/ canonicalizes to /.vol/NNNN/@/ (inode 2 is the root @).
    expectEqual(_StdlibFilePath("/.vol/1234/2/x"), _StdlibFilePath("/.vol/1234/@/x"),
      "/.vol/1234/2/x == /.vol/1234/@/x")
    // Combined anchor: both canonicalizations fire on
    // the same input: `/.resolve/1/.vol/N/2/` and `/.nofollow/.vol/N/@/`
    // are two spellings of the same anchor.
    expectEqual(
      _StdlibFilePath("/.resolve/1/.vol/1234/2/x"),
      _StdlibFilePath("/.nofollow/.vol/1234/@/x"),
      "/.resolve/1/.vol/1234/2/x == /.nofollow/.vol/1234/@/x")
    // Combined anchor with only the FILEID rule firing (resolve/3 is not
    // canonicalizing).
    expectEqual(
      _StdlibFilePath("/.resolve/3/.vol/1234/2/x"),
      _StdlibFilePath("/.resolve/3/.vol/1234/@/x"),
      "/.resolve/3/.vol/1234/2/x == /.resolve/3/.vol/1234/@/x")
}

  // MARK: - Hash agrees with equality (equal direction only)

  // Hashable's contract: equal values must hash equal. Assert that for every
  // pair we asserted equal above. (We do not assert unequal values hash
  // differently, which is not required.)
  @Test
  func hashAgreesWithEquality() {
    expectEqual(_StdlibFilePath("a///b").hashValue, _StdlibFilePath("a/b").hashValue,
      "hash(a///b) == hash(a/b)")
    expectEqual(_StdlibFilePath("a/./b").hashValue, _StdlibFilePath("a/b").hashValue,
      "hash(a/./b) == hash(a/b)")
    expectEqual(_StdlibFilePath("/./foo").hashValue, _StdlibFilePath("/foo").hashValue,
      "hash(/./foo) == hash(/foo)")
    withPlatform(.darwin) {
      expectEqual(_StdlibFilePath("/.resolve/1/foo").hashValue,
                  _StdlibFilePath("/.nofollow/foo").hashValue,
        "hash canonicalization (resolve)")
      expectEqual(_StdlibFilePath("/.vol/1234/2/x").hashValue,
                  _StdlibFilePath("/.vol/1234/@/x").hashValue,
        "hash canonicalization (vol)")
    }
  }

  // MARK: - Comparable ordering

  // Ordering is lexicographic over the normalized byte representation: anchor
  // bytes first, then component bytes, then the suffix as a tiebreaker. The
  // three tests below isolate a single axis each.

  @Test(.darwinOnly)
  func orderingDistinguishesOnAnchor() {
    // Same components ["foo"], same (no) suffix; differ only by anchor.
    // Normalized bytes "/.nofollow/foo" vs "/foo" first differ at index 1
    // ('.' 0x2E < 'f' 0x66), so the anchored path sorts first.
    expectTrue(_StdlibFilePath("/.nofollow/foo") < _StdlibFilePath("/foo"),
      "/.nofollow/foo < /foo")
    expectFalse(_StdlibFilePath("/foo") < _StdlibFilePath("/.nofollow/foo"),
      "not /foo < /.nofollow/foo")
}

  @Test
  func orderingDistinguishesOnComponents() {
    // Same (no) anchor, same suffix; differ only in component bytes.
    expectTrue(_StdlibFilePath("foo/aaa") < _StdlibFilePath("foo/bbb"),
      "foo/aaa < foo/bbb")
    expectFalse(_StdlibFilePath("foo/bbb") < _StdlibFilePath("foo/aaa"),
      "not foo/bbb < foo/aaa")
  }

  @Test
  func orderingDistinguishesOnSuffix() {
    // Same anchor, same components; differ only by trailing separator.
    // The unsuffixed path is a proper prefix of the suffixed one, so it
    // sorts first: the suffix is the final tiebreaker.
    expectTrue(_StdlibFilePath("/tmp/foo") < _StdlibFilePath("/tmp/foo/"),
      "/tmp/foo < /tmp/foo/")
    expectFalse(_StdlibFilePath("/tmp/foo/") < _StdlibFilePath("/tmp/foo"),
      "not /tmp/foo/ < /tmp/foo")
  }

  @Test
  func orderingIsStrictTotalOnThreeElements() {
    // Sorted order is "a" < "a/b" < "b":
    //   "a"   is a proper prefix of "a/b"          => "a"   < "a/b"
    //   "a/b" vs "b" first differ at 'a' < 'b'     => "a/b" < "b"
    let p1 = _StdlibFilePath("a")
    let p2 = _StdlibFilePath("a/b")
    let p3 = _StdlibFilePath("b")

    // irreflexivity
    expectFalse(p1 < p1, "irreflexive p1")
    expectFalse(p2 < p2, "irreflexive p2")
    expectFalse(p3 < p3, "irreflexive p3")

    // the order itself
    expectTrue(p1 < p2, "p1 < p2")
    expectTrue(p2 < p3, "p2 < p3")

    // antisymmetry (a < b implies not b < a)
    expectFalse(p2 < p1, "antisymmetry p1/p2")
    expectFalse(p3 < p2, "antisymmetry p2/p3")

    // transitivity (p1 < p2 and p2 < p3 implies p1 < p3)
    expectTrue(p1 < p3, "transitivity p1 < p3")
  }

  // MARK: - Component equality / ordering (brief)

  @Test
  func componentEqualityAndOrdering() {
    expectEqual(_StdlibFilePath.Component("foo"), _StdlibFilePath.Component("foo"),
      "foo == foo")
    expectNotEqual(_StdlibFilePath.Component("foo"), _StdlibFilePath.Component("bar"),
      "foo != bar")
    expectEqual(_StdlibFilePath.Component("foo").hashValue,
                _StdlibFilePath.Component("foo").hashValue,
      "equal components hash equal")
    expectTrue(_StdlibFilePath.Component("a") < _StdlibFilePath.Component("b"),
      "component a < b")
    // A proper prefix sorts first.
    expectTrue(_StdlibFilePath.Component("a") < _StdlibFilePath.Component("ab"),
      "component a < ab")
  }

  // MARK: - Anchor equality / ordering (brief)

  @Test(.darwinOnly)
  func anchorEqualityAndOrdering() {
    // Canonicalization collapses these to the same anchor bytes.
    expectEqual(_StdlibFilePath.Anchor("/.resolve/1/"), _StdlibFilePath.Anchor("/.nofollow/"),
      "/.resolve/1/ anchor == /.nofollow/ anchor")
    expectEqual(_StdlibFilePath.Anchor("/.resolve/1/").hashValue,
                _StdlibFilePath.Anchor("/.nofollow/").hashValue,
      "canonical anchors hash equal")
    expectNotEqual(_StdlibFilePath.Anchor("/"), _StdlibFilePath.Anchor("/.nofollow/"),
      "/ anchor != /.nofollow/ anchor")
    // "/.nofollow/" vs "/.vol/1234/5678" first differ at index 2
    // ('n' 0x6E < 'v' 0x76).
    expectTrue(
      _StdlibFilePath.Anchor("/.nofollow/") < _StdlibFilePath.Anchor("/.vol/1234/5678"),
      "/.nofollow/ < /.vol/1234/5678")
}
}
