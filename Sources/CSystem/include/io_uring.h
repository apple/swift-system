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
