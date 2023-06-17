//
//  File.swift
//  
//
//  Created by Rauhul Varma on 6/16/23.
//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// FIXME: this is wrong and should be done with wrapping fcntrl
// FIXME: go through and figure out the right way to express `at` methods
// @available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension FileDescriptor {
  public struct ControlFlags {
    let rawValue: Int32
    // Test stub
    public static var none: ControlFlags = ControlFlags(rawValue: 0)
    // Out of scope of this sketch
  }
}
#endif
