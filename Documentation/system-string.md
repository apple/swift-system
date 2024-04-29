# SystemString for OS-native string representations

* Authors: [Michael Ilseman](https://github.com/milseman)
* Implementation: PR (**TODO**)

## Introduction

We introduce `SystemString`, which supports OS-native string operations. `SystemString` is a bag-of-bytes type without a prescribed encoding. It is a collection `SystemChar`s, which is `UInt8` on Unix platforms and `UInt16` on Windows platforms.


## Motivation

`SystemString` is the backing storage representation for `FilePath`. `FilePath` normalizes its contents (e.g. `a//b -> a/b`), and so it is insufficient as a OS-preferred bag-of-bytes string representation.

**TODO**: It would be nice to ship with a few syscalls that make use of it.

**TODO**: A little more motivation on `SystemChar`. Also, let's make sure we have clarity on layout equivalence and demonstrate how to get from a null-`SystemChar`-termianted `UBP<SystemChar>` to null-terminated `UBP<UIntX>`.

## Proposed solution

**TODO**: Brief highlights


## Detailed design


## Source compatibility

This proposal is additive and source-compatible with existing code.

## ABI compatibility

This proposal is additive and ABI-compatible with existing code.


## Alternatives considered

**TODO**: Consider not having `SystemChar`

**TODO**: Consider separate `SystemByteString` and `SystemBytePairString` types.

**TODO**: Why we don't want to have a single-byte ASCII representation on Windows and have syscall wrapper adjust/dispatch appropriately.


## Future directions

**TODO**: Map out some future syscalls that this would (partially) unblock

## Acknowledgments

**TODO**


