#include <unistd.h>
#include <sys/syscall.h>
#include <sys/uio.h>
#include <signal.h>

#define __SWIFT_IORING_SQE_FALLBACK_STRUCT { \
    __u8    opcode; \
    __u8    flags; \
    __u16   ioprio; \
    __s32   fd; \
    union { \
        __u64   off; \
        __u64   addr2; \
        struct { \
            __u32   cmd_op; \
            __u32   __pad1; \
        }; \
    }; \
    union { \
        __u64   addr; \
        __u64   splice_off_in; \
        struct { \
            __u32   level; \
            __u32   optname; \
        }; \
    }; \
    __u32   len; \
    union { \
        __kernel_rwf_t  rw_flags; \
        __u32           fsync_flags; \
        __u16           poll_events; \
        __u32           poll32_events; \
        __u32           sync_range_flags; \
        __u32           msg_flags; \
        __u32           timeout_flags; \
        __u32           accept_flags; \
        __u32           cancel_flags; \
        __u32           open_flags; \
        __u32           statx_flags; \
        __u32           fadvise_advice; \
        __u32           splice_flags; \
        __u32           rename_flags; \
        __u32           unlink_flags; \
        __u32           hardlink_flags; \
        __u32           xattr_flags; \
        __u32           msg_ring_flags; \
        __u32           uring_cmd_flags; \
        __u32           waitid_flags; \
        __u32           futex_flags; \
        __u32           install_fd_flags; \
        __u32           nop_flags; \
    }; \
    __u64   user_data; \
    union { \
        __u16   buf_index; \
        __u16   buf_group; \
    } __attribute__((packed)); \
    __u16   personality; \
    union { \
        __s32   splice_fd_in; \
        __u32   file_index; \
        __u32   optlen; \
        struct { \
            __u16   addr_len; \
            __u16   __pad3[1]; \
        }; \
    }; \
    union { \
        struct { \
            __u64   addr3; \
            __u64   __pad2[1]; \
        }; \
        __u64   optval; \
        __u8    cmd[0]; \
    }; \
}

#if __has_include(<linux/io_uring.h>)
#include <linux/io_uring.h>

#ifdef IORING_TIMEOUT_BOOTTIME
// Kernel version >= 5.15, io_uring_sqe has file_index
// and all current Swift operations are supported.
#define __SWIFT_IORING_SUPPORTED true
typedef struct io_uring_sqe swift_io_uring_sqe;
#else
// io_uring_sqe is missing properties that IORequest expects.
// This configuration is not supported for now.
//
// Define a fallback struct to avoid build errors, but IORing
// will throw ENOTSUP on initialization.
#define __SWIFT_IORING_SUPPORTED false
typedef struct __SWIFT_IORING_SQE_FALLBACK_STRUCT swift_io_uring_sqe;
#endif

// We can define more specific availability later

#ifdef IORING_FEAT_RW_CUR_POS
// Kernel version >= 5.6, io_uring_sqe has open_flags
#endif

#ifdef IORING_FEAT_NODROP
// Kernel version >= 5.5, io_uring_sqe has cancel_flags
#endif

#else
// Minimal fallback definitions when linux/io_uring.h is not available (e.g. static SDK)
#include <stdint.h>

#define __SWIFT_IORING_SUPPORTED false

#define IORING_OFF_SQ_RING      0ULL
#define IORING_OFF_CQ_RING      0x8000000ULL
#define IORING_OFF_SQES         0x10000000ULL

#define IORING_ENTER_GETEVENTS  (1U << 0)

#define IORING_FEAT_SINGLE_MMAP         (1U << 0)
#define IORING_FEAT_NODROP              (1U << 1)
#define IORING_FEAT_SUBMIT_STABLE       (1U << 2)
#define IORING_FEAT_RW_CUR_POS          (1U << 3)
#define IORING_FEAT_CUR_PERSONALITY     (1U << 4)
#define IORING_FEAT_FAST_POLL           (1U << 5)
#define IORING_FEAT_POLL_32BITS         (1U << 6)
#define IORING_FEAT_SQPOLL_NONFIXED     (1U << 7)
#define IORING_FEAT_EXT_ARG             (1U << 8)
#define IORING_FEAT_NATIVE_WORKERS      (1U << 9)
#define IORING_FEAT_RSRC_TAGS           (1U << 10)
#define IORING_FEAT_CQE_SKIP            (1U << 11)
#define IORING_FEAT_LINKED_FILE         (1U << 12)
#define IORING_FEAT_REG_REG_RING        (1U << 13)
#define IORING_FEAT_RECVSEND_BUNDLE     (1U << 14)
#define IORING_FEAT_MIN_TIMEOUT         (1U << 15)
#define IORING_FEAT_RW_ATTR             (1U << 16)
#define IORING_FEAT_NO_IOWAIT           (1U << 17)

#if !defined(_ASM_GENERIC_INT_LL64_H) && !defined(_ASM_GENERIC_INT_L64_H) && !defined(_UAPI_ASM_GENERIC_INT_LL64_H) && !defined(_UAPI_ASM_GENERIC_INT_L64_H)
typedef uint8_t  __u8;
typedef uint16_t __u16;
typedef uint32_t __u32;
typedef uint64_t __u64;
typedef int32_t  __s32;
#endif

#ifndef __kernel_rwf_t
typedef int __kernel_rwf_t;
#endif

typedef struct __SWIFT_IORING_SQE_FALLBACK_STRUCT swift_io_uring_sqe;

struct io_uring_cqe {
    __u64   user_data;
    __s32   res;
    __u32   flags;
};

struct io_sqring_offsets {
    __u32 head;
    __u32 tail;
    __u32 ring_mask;
    __u32 ring_entries;
    __u32 flags;
    __u32 dropped;
    __u32 array;
    __u32 resv1;
    __u64 user_addr;
};

struct io_cqring_offsets {
    __u32 head;
    __u32 tail;
    __u32 ring_mask;
    __u32 ring_entries;
    __u32 overflow;
    __u32 cqes;
    __u32 flags;
    __u32 resv1;
    __u64 user_addr;
};

struct io_uring_params {
    __u32 sq_entries;
    __u32 cq_entries;
    __u32 flags;
    __u32 sq_thread_cpu;
    __u32 sq_thread_idle;
    __u32 features;
    __u32 wq_fd;
    __u32 resv[3];
    struct io_sqring_offsets sq_off;
    struct io_cqring_offsets cq_off;
};
#endif // __has_include(<linux/io_uring.h>)

#ifndef SWIFT_IORING_C_WRAPPER
#define SWIFT_IORING_C_WRAPPER

# ifndef __NR_io_uring_setup
#  define __NR_io_uring_setup		425
# endif
# ifndef __NR_io_uring_enter
#  define __NR_io_uring_enter		426
# endif
# ifndef __NR_io_uring_register
#  define __NR_io_uring_register	427
# endif

/*
struct io_uring_getevents_arg {
	__u64	sigmask;
	__u32	sigmask_sz;
	__u32	min_wait_usec; //used to be called `pad`. This compatibility wrapper avoids dealing with that.
	__u64	ts;
};
*/
struct swift_io_uring_getevents_arg {
	__u64	sigmask;
	__u32	sigmask_sz;
	__u32	min_wait_usec;
	__u64	ts;
};

static inline int io_uring_register(int fd, unsigned int opcode, void *arg,
		      unsigned int nr_args)
{
	return syscall(__NR_io_uring_register, fd, opcode, arg, nr_args);
}

static inline int io_uring_setup(unsigned int entries, struct io_uring_params *p)
{
	return syscall(__NR_io_uring_setup, entries, p);
}

static inline int io_uring_enter2(int fd, unsigned int to_submit, unsigned int min_complete,
		   unsigned int flags, void *args, size_t sz)
{
	return syscall(__NR_io_uring_enter, fd, to_submit, min_complete,
			flags, args, _NSIG / 8);
}

static inline int io_uring_enter(int fd, unsigned int to_submit, unsigned int min_complete,
		   unsigned int flags, sigset_t *sig)
{
	return io_uring_enter2(fd, to_submit, min_complete, flags, sig, _NSIG / 8);
}

#endif
