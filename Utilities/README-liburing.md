# Vendored io_uring UAPI

`Sources/CSystem/include/liburing/io_uring.h` is derived from the MIT-licensed
io_uring interface in liburing 2.12, commit
`e907d6a342e80b70874f93abd440b92b8a40b7bc`:

https://github.com/axboe/liburing/blob/e907d6a342e80b70874f93abd440b92b8a40b7bc/src/include/liburing/io_uring.h

The original copyright and dual-license SPDX notice are retained. Swift System
uses the MIT option; its license is installed alongside the header.

Original header SHA-256: `e8ba98eb8b9d6d554948179fc7eae59ef9b397fcd8a6732181c37ea408175366`.

To reproduce the local copy, download that exact header and run:

```sh
python3 Utilities/vendor-liburing.py /path/to/upstream/io_uring.h
```

The script verifies the original SHA-256 and makes only these adaptations:

- Prefix public identifiers and the include guard to coexist with system headers.
- Replace Linux integer types with fixed-width libc types, retaining explicit
  eight-byte alignment for `__aligned_u64` fields.
- Replace Linux header dependencies with `<stdint.h>` and the fixed-width
  `__kernel_timespec` layout, so static SDKs need no Linux UAPI headers.

The project uses these definitions consistently, regardless of the installed
`linux/io_uring.h`. The existing support gate is deliberately unchanged: builds
whose system headers lack `IORING_TIMEOUT_BOOTTIME` still reject IORing
initialization with `ENOTSUP`. Vendoring fixes build compatibility; it does not
add support for older kernels. Determining support from the running kernel
instead of build-time headers is a separate change.

The regression check runs in CI:

```sh
bash Tests/CSystemTests/test-io-uring-header.sh
```

It checks old and current system headers in both include orders, simulates a
missing system header, and asserts the sizes and offsets used across the kernel
ABI. Clang target/sysroot arguments may be passed to the script when cross
compiling. Actual IORing runtime tests still require Linux with io_uring enabled.
