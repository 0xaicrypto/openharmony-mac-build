#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wgnu-folding-constant"
#define __must_check
#define __force
#define __user
#define __kernel
#define __bitwise
#define __safe
#define __private
#define __read_mostly
#define __ro_after_init
#define __malloc
#define __weak
#define __always_inline
#define __noreturn
#define __maybe_unused
#define __attribute_const__
#define EPOLL_CLOEXEC 02000000
int dup3(int oldfd, int newfd, int flags);
typedef long __kernel_long_t;
typedef unsigned long __kernel_ulong_t;
typedef int __kernel_pid_t;
typedef unsigned int __kernel_uid_t;
typedef unsigned int __kernel_gid_t;
typedef unsigned long __kernel_size_t;
typedef long __kernel_ssize_t;
typedef long __kernel_off_t;
typedef unsigned int __kernel_ino_t;
typedef unsigned int __kernel_mode_t;
typedef unsigned int __kernel_dev_t;
typedef int __kernel_time_t;
typedef int __kernel_suseconds_t;
#ifndef __cplusplus
#define bool _Bool
#endif
#ifndef AF_NETLINK
#define AF_NETLINK 16
#endif
#ifndef SOCK_CLOEXEC
#define SOCK_CLOEXEC 02000000
#endif
#ifndef SOCK_NONBLOCK
#define SOCK_NONBLOCK 04000
#endif
#ifndef AF_PACKET
#define AF_PACKET 17
#endif
#ifndef MAP_POPULATE
#define MAP_POPULATE 0x8000
#endif
#ifndef MS_BIND
#define MS_BIND 4096
#endif
#ifndef MS_REC
#define MS_REC 16384
#endif
#ifndef MS_PRIVATE
#define MS_PRIVATE 262144
#endif
#include <libgen.h>
#ifndef __NR_bpf
#define __NR_bpf 280
#endif
#ifndef __NR_perf_event_open
#define __NR_perf_event_open 241
#endif
#ifndef FTW_SKIP_SUBTREE
#define FTW_SKIP_SUBTREE 2
#endif
#ifndef FTW_SKIP_SIBLINGS
#define FTW_SKIP_SIBLINGS 3
#endif
#ifndef FTW_ACTIONRETVAL
#define FTW_ACTIONRETVAL 16
#endif
#ifndef CLOCK_BOOTTIME
#define CLOCK_BOOTTIME 7
#endif
#ifndef CLOCK_REALTIME_COARSE
#define CLOCK_REALTIME_COARSE 5
#endif
#ifndef CLOCK_MONOTONIC_COARSE
#define CLOCK_MONOTONIC_COARSE 6
#endif

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/epoll.h>

__attribute__((__weak__)) int dup3(int oldfd, int newfd, int flags)
{
	if (oldfd == newfd) {
		errno = EINVAL;
		return -1;
	}
	if (dup2(oldfd, newfd) < 0)
		return -1;
	if (flags & O_CLOEXEC) {
		if (fcntl(newfd, F_SETFD, FD_CLOEXEC) < 0)
			return -1;
	}
	return newfd;
}

__attribute__((__weak__)) int epoll_create1(int flags)
{
	(void)flags;
	errno = ENOSYS;
	return -1;
}

__attribute__((__weak__)) int epoll_ctl(int epfd, int op, int fd, struct epoll_event *ev)
{
	(void)epfd; (void)op; (void)fd; (void)ev;
	errno = ENOSYS;
	return -1;
}

__attribute__((__weak__)) int epoll_wait(int epfd, struct epoll_event *ev, int maxevents, int timeout)
{
	(void)epfd; (void)ev; (void)maxevents; (void)timeout;
	errno = ENOSYS;
	return -1;
}
