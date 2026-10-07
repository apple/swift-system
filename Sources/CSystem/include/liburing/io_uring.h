/* SPDX-License-Identifier: (GPL-2.0 WITH Linux-syscall-note) OR MIT */
/*
 * Header file for the swift_io_uring interface.
 *
 * Copyright (C) 2019 Jens Axboe
 * Copyright (C) 2019 Christoph Hellwig
 */
#ifndef SWIFT_SYSTEM_VENDORED_IO_URING_H
#define SWIFT_SYSTEM_VENDORED_IO_URING_H

// Adapted for Swift System: use libc integer types without Linux headers.
#include <stdint.h>

struct swift_io_uring_kernel_timespec {
    int64_t tv_sec;
    int64_t tv_nsec;
};

#ifdef __cplusplus
extern "C" {
#endif

/*
 * IO submission data structure (Submission Queue Entry)
 */
struct swift_io_uring_sqe {
	uint8_t	opcode;		/* type of operation for this sqe */
	uint8_t	flags;		/* SWIFT_IOSQE_ flags */
	uint16_t	ioprio;		/* ioprio for the request */
	int32_t	fd;		/* file descriptor to do IO on */
	union {
		uint64_t	off;	/* offset into file */
		uint64_t	addr2;
		struct {
			uint32_t	cmd_op;
			uint32_t	__pad1;
		};
	};
	union {
		uint64_t	addr;	/* pointer to buffer or iovecs */
		uint64_t	splice_off_in;
		struct {
			uint32_t	level;
			uint32_t	optname;
		};
	};
	uint32_t	len;		/* buffer size or number of iovecs */
	union {
		int32_t	rw_flags;
		uint32_t		fsync_flags;
		uint16_t		poll_events;	/* compatibility */
		uint32_t		poll32_events;	/* word-reversed for BE */
		uint32_t		sync_range_flags;
		uint32_t		msg_flags;
		uint32_t		timeout_flags;
		uint32_t		accept_flags;
		uint32_t		cancel_flags;
		uint32_t		open_flags;
		uint32_t		statx_flags;
		uint32_t		fadvise_advice;
		uint32_t		splice_flags;
		uint32_t		rename_flags;
		uint32_t		unlink_flags;
		uint32_t		hardlink_flags;
		uint32_t		xattr_flags;
		uint32_t		msg_ring_flags;
		uint32_t		uring_cmd_flags;
		uint32_t		waitid_flags;
		uint32_t		futex_flags;
		uint32_t		install_fd_flags;
		uint32_t		nop_flags;
		uint32_t		pipe_flags;
	};
	uint64_t	user_data;	/* data to be passed back at completion time */
	/* pack this to avoid bogus arm OABI complaints */
	union {
		/* index into fixed buffers, if used */
		uint16_t	buf_index;
		/* for grouped buffer selection */
		uint16_t	buf_group;
	} __attribute__((packed));
	/* personality to use, if used */
	uint16_t	personality;
	union {
		int32_t	splice_fd_in;
		uint32_t	file_index;
		uint32_t	zcrx_ifq_idx;
		uint32_t	optlen;
		struct {
			uint16_t	addr_len;
			uint16_t	__pad3[1];
		};
	};
	union {
		struct {
			uint64_t	addr3;
			uint64_t	__pad2[1];
		};
		uint64_t	optval;
		/*
		 * If the ring is initialized with SWIFT_IORING_SETUP_SQE128, then
		 * this field is used for 80 bytes of arbitrary command data
		 */
		uint8_t	cmd[0];
	};
};

/*
 * If sqe->file_index is set to this for opcodes that instantiate a new
 * direct descriptor (like openat/openat2/accept), then swift_io_uring will allocate
 * an available direct descriptor instead of having the application pass one
 * in. The picked direct descriptor will be returned in cqe->res, or -ENFILE
 * if the space is full.
 */
#define SWIFT_IORING_FILE_INDEX_ALLOC		(~0U)

enum swift_io_uring_sqe_flags_bit {
	SWIFT_IOSQE_FIXED_FILE_BIT,
	SWIFT_IOSQE_IO_DRAIN_BIT,
	SWIFT_IOSQE_IO_LINK_BIT,
	SWIFT_IOSQE_IO_HARDLINK_BIT,
	SWIFT_IOSQE_ASYNC_BIT,
	SWIFT_IOSQE_BUFFER_SELECT_BIT,
	SWIFT_IOSQE_CQE_SKIP_SUCCESS_BIT,
};

/*
 * sqe->flags
 */
/* use fixed fileset */
#define SWIFT_IOSQE_FIXED_FILE	(1U << SWIFT_IOSQE_FIXED_FILE_BIT)
/* issue after inflight IO */
#define SWIFT_IOSQE_IO_DRAIN		(1U << SWIFT_IOSQE_IO_DRAIN_BIT)
/* links next sqe */
#define SWIFT_IOSQE_IO_LINK		(1U << SWIFT_IOSQE_IO_LINK_BIT)
/* like LINK, but stronger */
#define SWIFT_IOSQE_IO_HARDLINK	(1U << SWIFT_IOSQE_IO_HARDLINK_BIT)
/* always go async */
#define SWIFT_IOSQE_ASYNC		(1U << SWIFT_IOSQE_ASYNC_BIT)
/* select buffer from sqe->buf_group */
#define SWIFT_IOSQE_BUFFER_SELECT	(1U << SWIFT_IOSQE_BUFFER_SELECT_BIT)
/* don't post CQE if request succeeded */
#define SWIFT_IOSQE_CQE_SKIP_SUCCESS	(1U << SWIFT_IOSQE_CQE_SKIP_SUCCESS_BIT)

/*
 * swift_io_uring_setup() flags
 */
#define SWIFT_IORING_SETUP_IOPOLL	(1U << 0)	/* swift_io_context is polled */
#define SWIFT_IORING_SETUP_SQPOLL	(1U << 1)	/* SQ poll thread */
#define SWIFT_IORING_SETUP_SQ_AFF	(1U << 2)	/* sq_thread_cpu is valid */
#define SWIFT_IORING_SETUP_CQSIZE	(1U << 3)	/* app defines CQ size */
#define SWIFT_IORING_SETUP_CLAMP	(1U << 4)	/* clamp SQ/CQ ring sizes */
#define SWIFT_IORING_SETUP_ATTACH_WQ	(1U << 5)	/* attach to existing wq */
#define SWIFT_IORING_SETUP_R_DISABLED	(1U << 6)	/* start with ring disabled */
#define SWIFT_IORING_SETUP_SUBMIT_ALL	(1U << 7)	/* continue submit on error */
/*
 * Cooperative task running. When requests complete, they often require
 * forcing the submitter to transition to the kernel to complete. If this
 * flag is set, work will be done when the task transitions anyway, rather
 * than force an inter-processor interrupt reschedule. This avoids interrupting
 * a task running in userspace, and saves an IPI.
 */
#define SWIFT_IORING_SETUP_COOP_TASKRUN	(1U << 8)
/*
 * If COOP_TASKRUN is set, get notified if task work is available for
 * running and a kernel transition would be needed to run it. This sets
 * SWIFT_IORING_SQ_TASKRUN in the sq ring flags. Not valid with COOP_TASKRUN.
 */
#define SWIFT_IORING_SETUP_TASKRUN_FLAG	(1U << 9)
#define SWIFT_IORING_SETUP_SQE128		(1U << 10) /* SQEs are 128 byte */
#define SWIFT_IORING_SETUP_CQE32		(1U << 11) /* CQEs are 32 byte */
/*
 * Only one task is allowed to submit requests
 */
#define SWIFT_IORING_SETUP_SINGLE_ISSUER	(1U << 12)

/*
 * Defer running task work to get events.
 * Rather than running bits of task work whenever the task transitions
 * try to do it just before it is needed.
 */
#define SWIFT_IORING_SETUP_DEFER_TASKRUN	(1U << 13)

/*
 * Application provides the memory for the rings
 */
#define SWIFT_IORING_SETUP_NO_MMAP		(1U << 14)

/*
 * Register the ring fd in itself for use with
 * SWIFT_IORING_REGISTER_USE_REGISTERED_RING; return a registered fd index rather
 * than an fd.
 */
#define SWIFT_IORING_SETUP_REGISTERED_FD_ONLY	(1U << 15)

/*
 * Removes indirection through the SQ index array.
 */
#define SWIFT_IORING_SETUP_NO_SQARRAY		(1U << 16)

/* Use hybrid poll in iopoll process */
#define SWIFT_IORING_SETUP_HYBRID_IOPOLL	(1U << 17)

enum swift_io_uring_op {
	SWIFT_IORING_OP_NOP,
	SWIFT_IORING_OP_READV,
	SWIFT_IORING_OP_WRITEV,
	SWIFT_IORING_OP_FSYNC,
	SWIFT_IORING_OP_READ_FIXED,
	SWIFT_IORING_OP_WRITE_FIXED,
	SWIFT_IORING_OP_POLL_ADD,
	SWIFT_IORING_OP_POLL_REMOVE,
	SWIFT_IORING_OP_SYNC_FILE_RANGE,
	SWIFT_IORING_OP_SENDMSG,
	SWIFT_IORING_OP_RECVMSG,
	SWIFT_IORING_OP_TIMEOUT,
	SWIFT_IORING_OP_TIMEOUT_REMOVE,
	SWIFT_IORING_OP_ACCEPT,
	SWIFT_IORING_OP_ASYNC_CANCEL,
	SWIFT_IORING_OP_LINK_TIMEOUT,
	SWIFT_IORING_OP_CONNECT,
	SWIFT_IORING_OP_FALLOCATE,
	SWIFT_IORING_OP_OPENAT,
	SWIFT_IORING_OP_CLOSE,
	SWIFT_IORING_OP_FILES_UPDATE,
	SWIFT_IORING_OP_STATX,
	SWIFT_IORING_OP_READ,
	SWIFT_IORING_OP_WRITE,
	SWIFT_IORING_OP_FADVISE,
	SWIFT_IORING_OP_MADVISE,
	SWIFT_IORING_OP_SEND,
	SWIFT_IORING_OP_RECV,
	SWIFT_IORING_OP_OPENAT2,
	SWIFT_IORING_OP_EPOLL_CTL,
	SWIFT_IORING_OP_SPLICE,
	SWIFT_IORING_OP_PROVIDE_BUFFERS,
	SWIFT_IORING_OP_REMOVE_BUFFERS,
	SWIFT_IORING_OP_TEE,
	SWIFT_IORING_OP_SHUTDOWN,
	SWIFT_IORING_OP_RENAMEAT,
	SWIFT_IORING_OP_UNLINKAT,
	SWIFT_IORING_OP_MKDIRAT,
	SWIFT_IORING_OP_SYMLINKAT,
	SWIFT_IORING_OP_LINKAT,
	SWIFT_IORING_OP_MSG_RING,
	SWIFT_IORING_OP_FSETXATTR,
	SWIFT_IORING_OP_SETXATTR,
	SWIFT_IORING_OP_FGETXATTR,
	SWIFT_IORING_OP_GETXATTR,
	SWIFT_IORING_OP_SOCKET,
	SWIFT_IORING_OP_URING_CMD,
	SWIFT_IORING_OP_SEND_ZC,
	SWIFT_IORING_OP_SENDMSG_ZC,
	SWIFT_IORING_OP_READ_MULTISHOT,
	SWIFT_IORING_OP_WAITID,
	SWIFT_IORING_OP_FUTEX_WAIT,
	SWIFT_IORING_OP_FUTEX_WAKE,
	SWIFT_IORING_OP_FUTEX_WAITV,
	SWIFT_IORING_OP_FIXED_FD_INSTALL,
	SWIFT_IORING_OP_FTRUNCATE,
	SWIFT_IORING_OP_BIND,
	SWIFT_IORING_OP_LISTEN,
	SWIFT_IORING_OP_RECV_ZC,
	SWIFT_IORING_OP_EPOLL_WAIT,
	SWIFT_IORING_OP_READV_FIXED,
	SWIFT_IORING_OP_WRITEV_FIXED,
	SWIFT_IORING_OP_PIPE,

	/* this goes last, obviously */
	SWIFT_IORING_OP_LAST,
};

/*
 * sqe->uring_cmd_flags		top 8bits aren't available for userspace
 * SWIFT_IORING_URING_CMD_FIXED	use registered buffer; pass this flag
 *				along with setting sqe->buf_index.
 */
#define SWIFT_IORING_URING_CMD_FIXED	(1U << 0)
#define SWIFT_IORING_URING_CMD_MASK	SWIFT_IORING_URING_CMD_FIXED


/*
 * sqe->fsync_flags
 */
#define SWIFT_IORING_FSYNC_DATASYNC	(1U << 0)

/*
 * sqe->timeout_flags
 */
#define SWIFT_IORING_TIMEOUT_ABS		(1U << 0)
#define SWIFT_IORING_TIMEOUT_UPDATE		(1U << 1)
#define SWIFT_IORING_TIMEOUT_BOOTTIME		(1U << 2)
#define SWIFT_IORING_TIMEOUT_REALTIME		(1U << 3)
#define SWIFT_IORING_LINK_TIMEOUT_UPDATE	(1U << 4)
#define SWIFT_IORING_TIMEOUT_ETIME_SUCCESS	(1U << 5)
#define SWIFT_IORING_TIMEOUT_MULTISHOT	(1U << 6)
#define SWIFT_IORING_TIMEOUT_CLOCK_MASK	(SWIFT_IORING_TIMEOUT_BOOTTIME | SWIFT_IORING_TIMEOUT_REALTIME)
#define SWIFT_IORING_TIMEOUT_UPDATE_MASK	(SWIFT_IORING_TIMEOUT_UPDATE | SWIFT_IORING_LINK_TIMEOUT_UPDATE)
/*
 * sqe->splice_flags
 * extends splice(2) flags
 */
#define SWIFT_SPLICE_F_FD_IN_FIXED	(1U << 31) /* the last bit of uint32_t */

/*
 * POLL_ADD flags. Note that since sqe->poll_events is the flag space, the
 * command flags for POLL_ADD are stored in sqe->len.
 *
 * SWIFT_IORING_POLL_ADD_MULTI	Multishot poll. Sets SWIFT_IORING_CQE_F_MORE if
 *				the poll handler will continue to report
 *				CQEs on behalf of the same SQE.
 *
 * SWIFT_IORING_POLL_UPDATE		Update existing poll request, matching
 *				sqe->addr as the old user_data field.
 *
 * SWIFT_IORING_POLL_LEVEL		Level triggered poll.
 */
#define SWIFT_IORING_POLL_ADD_MULTI	(1U << 0)
#define SWIFT_IORING_POLL_UPDATE_EVENTS	(1U << 1)
#define SWIFT_IORING_POLL_UPDATE_USER_DATA	(1U << 2)
#define SWIFT_IORING_POLL_ADD_LEVEL		(1U << 3)

/*
 * ASYNC_CANCEL flags.
 *
 * SWIFT_IORING_ASYNC_CANCEL_ALL	Cancel all requests that match the given key
 * SWIFT_IORING_ASYNC_CANCEL_FD	Key off 'fd' for cancelation rather than the
 *				request 'user_data'
 * SWIFT_IORING_ASYNC_CANCEL_ANY	Match any request
 * SWIFT_IORING_ASYNC_CANCEL_FD_FIXED	'fd' passed in is a fixed descriptor
 * SWIFT_IORING_ASYNC_CANCEL_USERDATA	Match on user_data, default for no other key
 * SWIFT_IORING_ASYNC_CANCEL_OP	Match request based on opcode
 */
#define SWIFT_IORING_ASYNC_CANCEL_ALL	(1U << 0)
#define SWIFT_IORING_ASYNC_CANCEL_FD	(1U << 1)
#define SWIFT_IORING_ASYNC_CANCEL_ANY	(1U << 2)
#define SWIFT_IORING_ASYNC_CANCEL_FD_FIXED	(1U << 3)
#define SWIFT_IORING_ASYNC_CANCEL_USERDATA	(1U << 4)
#define SWIFT_IORING_ASYNC_CANCEL_OP	(1U << 5)

/*
 * send/sendmsg and recv/recvmsg flags (sqe->ioprio)
 *
 * SWIFT_IORING_RECVSEND_POLL_FIRST	If set, instead of first attempting to send
 *				or receive and arm poll if that yields an
 *				-EAGAIN result, arm poll upfront and skip
 *				the initial transfer attempt.
 *
 * SWIFT_IORING_RECV_MULTISHOT	Multishot recv. Sets SWIFT_IORING_CQE_F_MORE if
 *				the handler will continue to report
 *				CQEs on behalf of the same SQE.
 *
 * SWIFT_IORING_RECVSEND_FIXED_BUF	Use registered buffers, the index is stored in
 *				the buf_index field.
 *
 * SWIFT_IORING_SEND_ZC_REPORT_USAGE
 *				If set, SEND[MSG]_ZC should report
 *				the zerocopy usage in cqe.res
 *				for the SWIFT_IORING_CQE_F_NOTIF cqe.
 *				0 is reported if zerocopy was actually possible.
 *				SWIFT_IORING_NOTIF_USAGE_ZC_COPIED if data was copied
 *				(at least partially).
 *
 * SWIFT_IORING_RECVSEND_BUNDLE	Used with SWIFT_IOSQE_BUFFER_SELECT. If set, send or
 *				recv will grab as many buffers from the buffer
 *				group ID given and send them all. The completion
 *				result 	will be the number of buffers send, with
 *				the starting buffer ID in cqe->flags as per
 *				usual for provided buffer usage. The buffers
 *				will be	contiguous from the starting buffer ID.
 *
 * SWIFT_IORING_SEND_VECTORIZED	If set, SEND[_ZC] will take a pointer to a swift_io_vec
 *				to allow vectorized send operations.
 */
#define SWIFT_IORING_RECVSEND_POLL_FIRST	(1U << 0)
#define SWIFT_IORING_RECV_MULTISHOT		(1U << 1)
#define SWIFT_IORING_RECVSEND_FIXED_BUF	(1U << 2)
#define SWIFT_IORING_SEND_ZC_REPORT_USAGE	(1U << 3)
#define SWIFT_IORING_RECVSEND_BUNDLE		(1U << 4)
#define SWIFT_IORING_SEND_VECTORIZED		(1U << 5)

/*
 * cqe.res for SWIFT_IORING_CQE_F_NOTIF if
 * SWIFT_IORING_SEND_ZC_REPORT_USAGE was requested
 *
 * It should be treated as a flag, all other
 * bits of cqe.res should be treated as reserved!
 */
#define SWIFT_IORING_NOTIF_USAGE_ZC_COPIED    (1U << 31)

/*
 * accept flags stored in sqe->ioprio
 */
#define SWIFT_IORING_ACCEPT_MULTISHOT	(1U << 0)
#define SWIFT_IORING_ACCEPT_DONTWAIT	(1U << 1)
#define SWIFT_IORING_ACCEPT_POLL_FIRST	(1U << 2)

/*
 * SWIFT_IORING_OP_MSG_RING command types, stored in sqe->addr
 */
enum swift_io_uring_msg_ring_flags {
	SWIFT_IORING_MSG_DATA,	/* pass sqe->len as 'res' and off as user_data */
	SWIFT_IORING_MSG_SEND_FD,	/* send a registered fd to another ring */
};

/*
 * SWIFT_IORING_OP_MSG_RING flags (sqe->msg_ring_flags)
 *
 * SWIFT_IORING_MSG_RING_CQE_SKIP	Don't post a CQE to the target ring. Not
 *				applicable for SWIFT_IORING_MSG_DATA, obviously.
 */
#define SWIFT_IORING_MSG_RING_CQE_SKIP	(1U << 0)
/* Pass through the flags from sqe->file_index to cqe->flags */
#define SWIFT_IORING_MSG_RING_FLAGS_PASS	(1U << 1)

/*
 * SWIFT_IORING_OP_FIXED_FD_INSTALL flags (sqe->install_fd_flags)
 *
 * SWIFT_IORING_FIXED_FD_NO_CLOEXEC	Don't mark the fd as O_CLOEXEC
 */
#define SWIFT_IORING_FIXED_FD_NO_CLOEXEC	(1U << 0)

/*
 * SWIFT_IORING_OP_NOP flags (sqe->nop_flags)
 *
 * SWIFT_IORING_NOP_INJECT_RESULT	Inject result from sqe->result
 */
#define SWIFT_IORING_NOP_INJECT_RESULT	(1U << 0)

/*
 * IO completion data structure (Completion Queue Entry)
 */
struct swift_io_uring_cqe {
	uint64_t	user_data;	/* sqe->user_data value passed back */
	int32_t	res;		/* result code for this event */
	uint32_t	flags;

	/*
	 * If the ring is initialized with SWIFT_IORING_SETUP_CQE32, then this field
	 * contains 16-bytes of padding, doubling the size of the CQE.
	 */
	uint64_t big_cqe[];
};

/*
 * cqe->flags
 *
 * SWIFT_IORING_CQE_F_BUFFER	If set, the upper 16 bits are the buffer ID
 * SWIFT_IORING_CQE_F_MORE	If set, parent SQE will generate more CQE entries
 * SWIFT_IORING_CQE_F_SOCK_NONEMPTY	If set, more data to read after socket recv
 * SWIFT_IORING_CQE_F_NOTIF	Set for notification CQEs. Can be used to distinct
 * 			them from sends.
 * SWIFT_IORING_CQE_F_BUF_MORE If set, the buffer ID set in the completion will get
 *			more completions. In other words, the buffer is being
 *			partially consumed, and will be used by the kernel for
 *			more completions. This is only set for buffers used via
 *			the incremental buffer consumption, as provided by
 *			a ring buffer setup with SWIFT_IOU_PBUF_RING_INC. For any
 *			other provided buffer type, all completions with a
 *			buffer passed back is automatically returned to the
 *			application.
 */
#define SWIFT_IORING_CQE_F_BUFFER		(1U << 0)
#define SWIFT_IORING_CQE_F_MORE		(1U << 1)
#define SWIFT_IORING_CQE_F_SOCK_NONEMPTY	(1U << 2)
#define SWIFT_IORING_CQE_F_NOTIF		(1U << 3)
#define SWIFT_IORING_CQE_F_BUF_MORE		(1U << 4)

#define SWIFT_IORING_CQE_BUFFER_SHIFT		16

/*
 * Magic offsets for the application to mmap the data it needs
 */
#define SWIFT_IORING_OFF_SQ_RING		0ULL
#define SWIFT_IORING_OFF_CQ_RING		0x8000000ULL
#define SWIFT_IORING_OFF_SQES			0x10000000ULL
#define SWIFT_IORING_OFF_PBUF_RING		0x80000000ULL
#define SWIFT_IORING_OFF_PBUF_SHIFT		16
#define SWIFT_IORING_OFF_MMAP_MASK		0xf8000000ULL

/*
 * Filled with the offset for mmap(2)
 */
struct swift_io_sqring_offsets {
	uint32_t head;
	uint32_t tail;
	uint32_t ring_mask;
	uint32_t ring_entries;
	uint32_t flags;
	uint32_t dropped;
	uint32_t array;
	uint32_t resv1;
	uint64_t user_addr;
};

/*
 * sq_ring->flags
 */
#define SWIFT_IORING_SQ_NEED_WAKEUP	(1U << 0) /* needs swift_io_uring_enter wakeup */
#define SWIFT_IORING_SQ_CQ_OVERFLOW	(1U << 1) /* CQ ring is overflown */
#define SWIFT_IORING_SQ_TASKRUN	(1U << 2) /* task should enter the kernel */

struct swift_io_cqring_offsets {
	uint32_t head;
	uint32_t tail;
	uint32_t ring_mask;
	uint32_t ring_entries;
	uint32_t overflow;
	uint32_t cqes;
	uint32_t flags;
	uint32_t resv1;
	uint64_t user_addr;
};

/*
 * cq_ring->flags
 */

/* disable eventfd notifications */
#define SWIFT_IORING_CQ_EVENTFD_DISABLED	(1U << 0)

/*
 * swift_io_uring_enter(2) flags
 */
#define SWIFT_IORING_ENTER_GETEVENTS		(1U << 0)
#define SWIFT_IORING_ENTER_SQ_WAKEUP		(1U << 1)
#define SWIFT_IORING_ENTER_SQ_WAIT		(1U << 2)
#define SWIFT_IORING_ENTER_EXT_ARG		(1U << 3)
#define SWIFT_IORING_ENTER_REGISTERED_RING	(1U << 4)
#define SWIFT_IORING_ENTER_ABS_TIMER		(1U << 5)
#define SWIFT_IORING_ENTER_EXT_ARG_REG	(1U << 6)
#define SWIFT_IORING_ENTER_NO_IOWAIT		(1U << 7)

/*
 * Passed in for swift_io_uring_setup(2). Copied back with updated info on success
 */
struct swift_io_uring_params {
	uint32_t sq_entries;
	uint32_t cq_entries;
	uint32_t flags;
	uint32_t sq_thread_cpu;
	uint32_t sq_thread_idle;
	uint32_t features;
	uint32_t wq_fd;
	uint32_t resv[3];
	struct swift_io_sqring_offsets sq_off;
	struct swift_io_cqring_offsets cq_off;
};

/*
 * swift_io_uring_params->features flags
 */
#define SWIFT_IORING_FEAT_SINGLE_MMAP		(1U << 0)
#define SWIFT_IORING_FEAT_NODROP		(1U << 1)
#define SWIFT_IORING_FEAT_SUBMIT_STABLE	(1U << 2)
#define SWIFT_IORING_FEAT_RW_CUR_POS		(1U << 3)
#define SWIFT_IORING_FEAT_CUR_PERSONALITY	(1U << 4)
#define SWIFT_IORING_FEAT_FAST_POLL		(1U << 5)
#define SWIFT_IORING_FEAT_POLL_32BITS 	(1U << 6)
#define SWIFT_IORING_FEAT_SQPOLL_NONFIXED	(1U << 7)
#define SWIFT_IORING_FEAT_EXT_ARG		(1U << 8)
#define SWIFT_IORING_FEAT_NATIVE_WORKERS	(1U << 9)
#define SWIFT_IORING_FEAT_RSRC_TAGS		(1U << 10)
#define SWIFT_IORING_FEAT_CQE_SKIP		(1U << 11)
#define SWIFT_IORING_FEAT_LINKED_FILE		(1U << 12)
#define SWIFT_IORING_FEAT_REG_REG_RING	(1U << 13)
#define SWIFT_IORING_FEAT_RECVSEND_BUNDLE	(1U << 14)
#define SWIFT_IORING_FEAT_MIN_TIMEOUT		(1U << 15)
#define SWIFT_IORING_FEAT_RW_ATTR		(1U << 16)
#define SWIFT_IORING_FEAT_NO_IOWAIT		(1U << 17)

/*
 * swift_io_uring_register(2) opcodes and arguments
 */
enum swift_io_uring_register_op {
	SWIFT_IORING_REGISTER_BUFFERS			= 0,
	SWIFT_IORING_UNREGISTER_BUFFERS		= 1,
	SWIFT_IORING_REGISTER_FILES			= 2,
	SWIFT_IORING_UNREGISTER_FILES			= 3,
	SWIFT_IORING_REGISTER_EVENTFD			= 4,
	SWIFT_IORING_UNREGISTER_EVENTFD		= 5,
	SWIFT_IORING_REGISTER_FILES_UPDATE		= 6,
	SWIFT_IORING_REGISTER_EVENTFD_ASYNC		= 7,
	SWIFT_IORING_REGISTER_PROBE			= 8,
	SWIFT_IORING_REGISTER_PERSONALITY		= 9,
	SWIFT_IORING_UNREGISTER_PERSONALITY		= 10,
	SWIFT_IORING_REGISTER_RESTRICTIONS		= 11,
	SWIFT_IORING_REGISTER_ENABLE_RINGS		= 12,

	/* extended with tagging */
	SWIFT_IORING_REGISTER_FILES2			= 13,
	SWIFT_IORING_REGISTER_FILES_UPDATE2		= 14,
	SWIFT_IORING_REGISTER_BUFFERS2		= 15,
	SWIFT_IORING_REGISTER_BUFFERS_UPDATE		= 16,

	/* set/clear io-wq thread affinities */
	SWIFT_IORING_REGISTER_IOWQ_AFF		= 17,
	SWIFT_IORING_UNREGISTER_IOWQ_AFF		= 18,

	/* set/get max number of io-wq workers */
	SWIFT_IORING_REGISTER_IOWQ_MAX_WORKERS	= 19,

	/* register/unregister swift_io_uring fd with the ring */
	SWIFT_IORING_REGISTER_RING_FDS		= 20,
	SWIFT_IORING_UNREGISTER_RING_FDS		= 21,

	/* register ring based provide buffer group */
	SWIFT_IORING_REGISTER_PBUF_RING		= 22,
	SWIFT_IORING_UNREGISTER_PBUF_RING		= 23,

	/* sync cancelation API */
	SWIFT_IORING_REGISTER_SYNC_CANCEL		= 24,

	/* register a range of fixed file slots for automatic slot allocation */
	SWIFT_IORING_REGISTER_FILE_ALLOC_RANGE	= 25,

	/* return status information for a buffer group */
	SWIFT_IORING_REGISTER_PBUF_STATUS		= 26,

	/* set/clear busy poll settings */
	SWIFT_IORING_REGISTER_NAPI			= 27,
	SWIFT_IORING_UNREGISTER_NAPI			= 28,

	SWIFT_IORING_REGISTER_CLOCK			= 29,

	/* clone registered buffers from source ring to current ring */
	SWIFT_IORING_REGISTER_CLONE_BUFFERS		= 30,

	/* send MSG_RING without having a ring */
	SWIFT_IORING_REGISTER_SEND_MSG_RING		= 31,

	/* register a netdev hw rx queue for zerocopy */
	SWIFT_IORING_REGISTER_ZCRX_IFQ		= 32,

	/* resize CQ ring */
	SWIFT_IORING_REGISTER_RESIZE_RINGS		= 33,

	SWIFT_IORING_REGISTER_MEM_REGION		= 34,

	/* this goes last */
	SWIFT_IORING_REGISTER_LAST,

	/* flag added to the opcode to use a registered ring fd */
	SWIFT_IORING_REGISTER_USE_REGISTERED_RING	= 1U << 31
};

/* io-wq worker categories */
enum swift_io_wq_type {
	SWIFT_IO_WQ_BOUND,
	SWIFT_IO_WQ_UNBOUND,
};

/* deprecated, see struct swift_io_uring_rsrc_update */
struct swift_io_uring_files_update {
	uint32_t offset;
	uint32_t resv;
	uint64_t __attribute__((aligned(8))) /* int32_t * */ fds;
};

enum {
	/* initialise with user provided memory pointed by user_addr */
	SWIFT_IORING_MEM_REGION_TYPE_USER		= 1,
};

struct swift_io_uring_region_desc {
	uint64_t user_addr;
	uint64_t size;
	uint32_t flags;
	uint32_t id;
	uint64_t mmap_offset;
	uint64_t __resv[4];
};

enum {
	/* expose the region as registered wait arguments */
	SWIFT_IORING_MEM_REGION_REG_WAIT_ARG		= 1,
};

struct swift_io_uring_mem_region_reg {
	uint64_t region_uptr; /* struct swift_io_uring_region_desc * */
	uint64_t flags;
	uint64_t __resv[2];
};

/*
 * Register a fully sparse file space, rather than pass in an array of all
 * -1 file descriptors.
 */
#define SWIFT_IORING_RSRC_REGISTER_SPARSE	(1U << 0)

struct swift_io_uring_rsrc_register {
	uint32_t nr;
	uint32_t flags;
	uint64_t resv2;
	uint64_t __attribute__((aligned(8))) data;
	uint64_t __attribute__((aligned(8))) tags;
};

struct swift_io_uring_rsrc_update {
	uint32_t offset;
	uint32_t resv;
	uint64_t __attribute__((aligned(8))) data;
};

struct swift_io_uring_rsrc_update2 {
	uint32_t offset;
	uint32_t resv;
	uint64_t __attribute__((aligned(8))) data;
	uint64_t __attribute__((aligned(8))) tags;
	uint32_t nr;
	uint32_t resv2;
};

/* Skip updating fd indexes set to this value in the fd table */
#define SWIFT_IORING_REGISTER_FILES_SKIP	(-2)

#define SWIFT_IO_URING_OP_SUPPORTED	(1U << 0)

struct swift_io_uring_probe_op {
	uint8_t op;
	uint8_t resv;
	uint16_t flags;	/* SWIFT_IO_URING_OP_* flags */
	uint32_t resv2;
};

struct swift_io_uring_probe {
	uint8_t last_op;	/* last opcode supported */
	uint8_t ops_len;	/* length of ops[] array below */
	uint16_t resv;
	uint32_t resv2[3];
	struct swift_io_uring_probe_op ops[];
};

struct swift_io_uring_restriction {
	uint16_t opcode;
	union {
		uint8_t register_op; /* SWIFT_IORING_RESTRICTION_REGISTER_OP */
		uint8_t sqe_op;      /* SWIFT_IORING_RESTRICTION_SQE_OP */
		uint8_t sqe_flags;   /* SWIFT_IORING_RESTRICTION_SQE_FLAGS_* */
	};
	uint8_t resv;
	uint32_t resv2[3];
};

struct swift_io_uring_clock_register {
	uint32_t	clockid;
	uint32_t	__resv[3];
};

enum {
	SWIFT_IORING_REGISTER_SRC_REGISTERED	= (1U << 0),
	SWIFT_IORING_REGISTER_DST_REPLACE	= (1U << 1),
};

struct swift_io_uring_clone_buffers {
	uint32_t	src_fd;
	uint32_t	flags;
	uint32_t	src_off;
	uint32_t	dst_off;
	uint32_t	nr;
	uint32_t	pad[3];
};

struct swift_io_uring_buf {
	uint64_t	addr;
	uint32_t	len;
	uint16_t	bid;
	uint16_t	resv;
};

struct swift_io_uring_buf_ring {
	union {
		/*
		 * To avoid spilling into more pages than we need to, the
		 * ring tail is overlaid with the swift_io_uring_buf->resv field.
		 */
		struct {
			uint64_t	resv1;
			uint32_t	resv2;
			uint16_t	resv3;
			uint16_t	tail;
		};
		struct swift_io_uring_buf	bufs[0];
	};
};

/*
 * Flags for SWIFT_IORING_REGISTER_PBUF_RING.
 *
 * SWIFT_IOU_PBUF_RING_MMAP:	If set, kernel will allocate the memory for the ring.
 *			The application must not set a ring_addr in struct
 *			swift_io_uring_buf_reg, instead it must subsequently call
 *			mmap(2) with the offset set as:
 *			SWIFT_IORING_OFF_PBUF_RING | (bgid << SWIFT_IORING_OFF_PBUF_SHIFT)
 *			to get a virtual mapping for the ring.
 * SWIFT_IOU_PBUF_RING_INC:	If set, buffers consumed from this buffer ring can be
 *			consumed incrementally. Normally one (or more) buffers
 *			are fully consumed. With incremental consumptions, it's
 *			feasible to register big ranges of buffers, and each
 *			use of it will consume only as much as it needs. This
 *			requires that both the kernel and application keep
 *			track of where the current read/recv index is at.
 */
enum swift_io_uring_register_pbuf_ring_flags {
	SWIFT_IOU_PBUF_RING_MMAP	= 1,
	SWIFT_IOU_PBUF_RING_INC	= 2,
};

/* argument for SWIFT_IORING_(UN)REGISTER_PBUF_RING */
struct swift_io_uring_buf_reg {
	uint64_t	ring_addr;
	uint32_t	ring_entries;
	uint16_t	bgid;
	uint16_t	flags;
	uint64_t	resv[3];
};

/* argument for SWIFT_IORING_REGISTER_PBUF_STATUS */
struct swift_io_uring_buf_status {
	uint32_t	buf_group;	/* input */
	uint32_t	head;		/* output */
	uint32_t	resv[8];
};

/* argument for SWIFT_IORING_(UN)REGISTER_NAPI */
struct swift_io_uring_napi {
	uint32_t	busy_poll_to;
	uint8_t	prefer_busy_poll;
	uint8_t	pad[3];
	uint64_t	resv;
};

/*
 * swift_io_uring_restriction->opcode values
 */
enum swift_io_uring_register_restriction_op {
	/* Allow an swift_io_uring_register(2) opcode */
	SWIFT_IORING_RESTRICTION_REGISTER_OP		= 0,

	/* Allow an sqe opcode */
	SWIFT_IORING_RESTRICTION_SQE_OP		= 1,

	/* Allow sqe flags */
	SWIFT_IORING_RESTRICTION_SQE_FLAGS_ALLOWED	= 2,

	/* Require sqe flags (these flags must be set on each submission) */
	SWIFT_IORING_RESTRICTION_SQE_FLAGS_REQUIRED	= 3,

	SWIFT_IORING_RESTRICTION_LAST
};

enum {
	SWIFT_IORING_REG_WAIT_TS		= (1U << 0),
};

/*
 * Argument for swift_io_uring_enter(2) with
 * SWIFT_IORING_GETEVENTS | SWIFT_IORING_ENTER_EXT_ARG_REG set, where the actual argument
 * is an index into a previously registered fixed wait region described by
 * the below structure.
 */
struct swift_io_uring_reg_wait {
	struct swift_io_uring_kernel_timespec	ts;
	uint32_t				min_wait_usec;
	uint32_t				flags;
	uint64_t				sigmask;
	uint32_t				sigmask_sz;
	uint32_t				pad[3];
	uint64_t				pad2[2];
};

/*
 * Argument for swift_io_uring_enter(2) with SWIFT_IORING_GETEVENTS | SWIFT_IORING_ENTER_EXT_ARG
 */
struct swift_io_uring_getevents_arg {
	uint64_t	sigmask;
	uint32_t	sigmask_sz;
	uint32_t	min_wait_usec;
	uint64_t	ts;
};

/*
 * Argument for SWIFT_IORING_REGISTER_SYNC_CANCEL
 */
struct swift_io_uring_sync_cancel_reg {
	uint64_t				addr;
	int32_t				fd;
	uint32_t				flags;
	struct swift_io_uring_kernel_timespec	timeout;
	uint8_t				opcode;
	uint8_t				pad[7];
	uint64_t				pad2[3];
};

/*
 * Argument for SWIFT_IORING_REGISTER_FILE_ALLOC_RANGE
 * The range is specified as [off, off + len)
 */
struct swift_io_uring_file_index_range {
	uint32_t	off;
	uint32_t	len;
	uint64_t	resv;
};

struct swift_io_uring_recvmsg_out {
	uint32_t namelen;
	uint32_t controllen;
	uint32_t payloadlen;
	uint32_t flags;
};

/*
 * Argument for SWIFT_IORING_OP_URING_CMD when file is a socket
 */
enum swift_io_uring_socket_op {
	SWIFT_SOCKET_URING_OP_SIOCINQ		= 0,
	SWIFT_SOCKET_URING_OP_SIOCOUTQ,
	SWIFT_SOCKET_URING_OP_GETSOCKOPT,
	SWIFT_SOCKET_URING_OP_SETSOCKOPT,
	SWIFT_SOCKET_URING_OP_TX_TIMESTAMP,
};

/*
 * SWIFT_SOCKET_URING_OP_TX_TIMESTAMP definitions
 */

#define SWIFT_IORING_TIMESTAMP_HW_SHIFT	16
/* The cqe->flags bit from which the timestamp type is stored */
#define SWIFT_IORING_TIMESTAMP_TYPE_SHIFT	(SWIFT_IORING_TIMESTAMP_HW_SHIFT + 1)
/* The cqe->flags flag signifying whether it's a hardware timestamp */
#define SWIFT_IORING_CQE_F_TSTAMP_HW		((uint32_t)1 << SWIFT_IORING_TIMESTAMP_HW_SHIFT)

struct swift_io_timespec {
	uint64_t		tv_sec;
	uint64_t		tv_nsec;
};

/* Zero copy receive refill queue entry */
struct swift_io_uring_zcrx_rqe {
	uint64_t	off;
	uint32_t	len;
	uint32_t	__pad;
};

struct swift_io_uring_zcrx_cqe {
	uint64_t	off;
	uint64_t	__pad;
};

/* The bit from which area id is encoded into offsets */
#define SWIFT_IORING_ZCRX_AREA_SHIFT	48
#define SWIFT_IORING_ZCRX_AREA_MASK	(~(((uint64_t)1 << SWIFT_IORING_ZCRX_AREA_SHIFT) - 1))

struct swift_io_uring_zcrx_offsets {
	uint32_t	head;
	uint32_t	tail;
	uint32_t	rqes;
	uint32_t	__resv2;
	uint64_t	__resv[2];
};

enum swift_io_uring_zcrx_area_flags {
	SWIFT_IORING_ZCRX_AREA_DMABUF		= 1,
};

struct swift_io_uring_zcrx_area_reg {
	uint64_t	addr;
	uint64_t	len;
	uint64_t	rq_area_token;
	uint32_t	flags;
	uint32_t	dmabuf_fd;
	uint64_t	__resv2[2];
};

/*
 * Argument for SWIFT_IORING_REGISTER_ZCRX_IFQ
 */
struct swift_io_uring_zcrx_ifq_reg {
	uint32_t	if_idx;
	uint32_t	if_rxq;
	uint32_t	rq_entries;
	uint32_t	flags;

	uint64_t	area_ptr; /* pointer to struct swift_io_uring_zcrx_area_reg */
	uint64_t	region_ptr; /* struct swift_io_uring_region_desc * */

	struct swift_io_uring_zcrx_offsets offsets;
	uint32_t	zcrx_id;
	uint32_t	__resv2;
	uint64_t	__resv[3];
};

#ifdef __cplusplus
}
#endif

#endif
