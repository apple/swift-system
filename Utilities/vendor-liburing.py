#!/usr/bin/env python3
# This source file is part of the Swift System open source project
# Copyright (c) 2026 Apple Inc. and the Swift System project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
# See https://swift.org/LICENSE.txt for license information

"""Regenerate the private io_uring UAPI header from a pinned upstream copy."""

import hashlib
from pathlib import Path
import re
import sys


upstream = Path(sys.argv[1]).read_bytes()
expected = "e8ba98eb8b9d6d554948179fc7eae59ef9b397fcd8a6732181c37ea408175366"
if hashlib.sha256(upstream).hexdigest() != expected:
    raise SystemExit("Expected the liburing-2.12 io_uring.h; see README-liburing.md")

header = upstream.decode()
start = header.index("#include <linux/fs.h>")
end = header.index("#ifdef __cplusplus", start)
header = header[:start] + """// Adapted for Swift System: use libc integer types without Linux headers.
#include <stdint.h>

struct swift_io_uring_kernel_timespec {
    int64_t tv_sec;
    int64_t tv_nsec;
};

""" + header[end:]

types = {
    "__u8": "uint8_t",
    "__u16": "uint16_t",
    "__u32": "uint32_t",
    "__u64": "uint64_t",
    "__s32": "int32_t",
    "__kernel_rwf_t": "int32_t",
    "__kernel_timespec": "swift_io_uring_kernel_timespec",
    "__aligned_u64": "uint64_t __attribute__((aligned(8)))",
}


def rename(match):
    identifier = match.group()
    if identifier in types:
        return types[identifier]
    if identifier == "LINUX_IO_URING_H":
        return "SWIFT_SYSTEM_VENDORED_IO_URING_H"
    if identifier.startswith("io_"):
        return "swift_" + identifier
    if identifier.startswith(("IORING_", "IOSQE_", "IO_URING_", "IO_WQ_", "IOU_", "SOCKET_URING_", "SPLICE_")):
        return "SWIFT_" + identifier
    return identifier


header = re.sub(r"\b[A-Za-z_][A-Za-z_0-9]*\b", rename, header)
output = Path(__file__).resolve().parents[1] / "Sources/CSystem/include/liburing/io_uring.h"
output.write_text(header)
