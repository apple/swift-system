//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if os(Windows)
/// A namespace for Win32 APIs on Windows.
///
/// The types and functions nested here wrap the Win32 base API, the
/// documented, ABI-stable system interface for desktop Windows.
@frozen
@available(System 199, *)
public enum Win32 {}
#elseif SYSTEM_PACKAGE
// Package builds on other platforms get unavailable stubs for `Win32` and
// `Win32Error`. Non-package builds omit them to avoid exporting ABI symbols.
@available(*, unavailable, message: "Win32 APIs are only available on Windows.")
public enum Win32 {}

@available(*, unavailable, message: "Win32 APIs are only available on Windows.")
public struct Win32Error: Error {}
#endif
