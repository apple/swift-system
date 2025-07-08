#include <unistd.h>
#include <sys/syscall.h>
#include <sys/uio.h>

#include <signal.h>
#include <linux/io_uring.h>

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

//This was #defines in older headers, so we redeclare it to get a consistent import
typedef enum : __u32 {
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

	/* this goes last */
	SWIFT_IORING_REGISTER_LAST
} SWIFT_IORING_REGISTER_OPS;

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
