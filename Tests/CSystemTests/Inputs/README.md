`liburing-0.7/linux/io_uring.h` is an unmodified historical io_uring UAPI header
from liburing 0.7. It lacks `IORING_ENTER_EXT_ARG`, `IORING_TIMEOUT_BOOTTIME`,
and the SQE `file_index` field, exercising the old-header case from issue #385.
It is not a copy of a distribution's complete kernel headers.

Source: https://github.com/axboe/liburing/blob/45f0735219a615ae848033c47c7e2d85d101d43e/src/include/liburing/io_uring.h

SHA-256: `2f4816329959eb59831cf33083c4898c5e9d9bda5b1178f378b7435d2d9bf2ba`.

The original copyright and dual-license SPDX notice are retained. This fixture
uses the MIT option; the full license is in `liburing-0.7/LICENSE.txt`.
