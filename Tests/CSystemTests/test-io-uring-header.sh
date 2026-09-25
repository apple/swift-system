#!/usr/bin/env bash
# This source file is part of the Swift System open source project
# Copyright (c) 2026 Apple Inc. and the Swift System project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
# See https://swift.org/LICENSE.txt for license information
set -euo pipefail

# Run on Linux with Clang, or pass Clang cross-compilation arguments.
# Example: CC=clang bash Tests/CSystemTests/test-io-uring-header.sh
root=$(cd "$(dirname "$0")/../.." && pwd)
compiler=${CC:-clang}
common=(-std=gnu11 -D_GNU_SOURCE -Werror -fsyntax-only -I"$root/Sources/CSystem/include")
test_file="$root/Tests/CSystemTests/IOUringHeader.c"

for order in INCLUDE_SYSTEM_FIRST INCLUDE_SYSTEM_LAST; do
  "$compiler" "$@" "${common[@]}" -D"$order" "$test_file"
  "$compiler" "$@" "${common[@]}" -D"$order" -DEXPECT_SUPPORTED=0 \
    -I"$root/Tests/CSystemTests/Inputs/liburing-0.7" "$test_file"
done

# Model SDKs without linux/io_uring.h, including the static Linux SDK.
"$compiler" "$@" "${common[@]}" -Wno-builtin-macro-redefined \
  '-D__has_include(header)=0' -DEXPECT_SUPPORTED=0 "$test_file"
# An unrelated header defining the marker must not enable a headerless SDK.
"$compiler" "$@" "${common[@]}" -Wno-builtin-macro-redefined \
  '-D__has_include(header)=0' -DIORING_TIMEOUT_BOOTTIME=4 \
  -DEXPECT_SUPPORTED=0 "$test_file"
echo "io_uring header compatibility checks passed"
