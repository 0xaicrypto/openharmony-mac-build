#include "pthread_impl.h"
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

void __wait(volatile int *addr, volatile int *waiters, int val, int priv)
{
	int selfpid = (int)__syscall(SYS_getpid);
	if (selfpid >= 600) {
		char kb[160];
		int kn = snprintf(kb, sizeof kb, "<6>musl: fwait pid=%d addr=%p val=%d\n",
			selfpid, (void*)addr, val);
		int fd = __syscall(SYS_openat, -100, "/dev/kmsg", 1);
		if (fd >= 0) { __syscall(SYS_write, fd, kb, kn); __syscall(SYS_close, fd); }
	}
	int spins=100;
	if (priv) priv = FUTEX_PRIVATE;
	while (spins-- && (!waiters || !*waiters)) {
		if (*addr==val) a_spin();
		else return;
	}
	if (waiters) a_inc(waiters);
	int waits = 0;
	while (*addr==val) {
		if (++waits == 2000000) {
			int halive = __syscall(SYS_tgkill, __syscall(SYS_getpid), val, 0);
			char kb[160];
			int kn = snprintf(kb, sizeof kb, "<6>musl: futex-stuck pid=%d addr=%p val=%d holder_alive=%d self_tid=%d\n",
				(int)__syscall(SYS_getpid), (void*)addr, val, halive, (int)__syscall(SYS_gettid));
			int fd = __syscall(SYS_openat, AT_FDCWD, "/dev/kmsg", O_WRONLY);
			if (fd >= 0) { __syscall(SYS_write, fd, kb, kn); __syscall(SYS_close, fd); }
			waits = 0;
		}
#ifdef __LITEOS_A__
		__syscall(SYS_futex, addr, FUTEX_WAIT|priv, val, 0xffffffffu) != -ENOSYS
		|| __syscall(SYS_futex, addr, FUTEX_WAIT, val, 0xffffffffu);
#else
		__syscall(SYS_futex, addr, FUTEX_WAIT|priv, val, 0) != -ENOSYS
		|| __syscall(SYS_futex, addr, FUTEX_WAIT, val, 0);
#endif
	}
	if (waiters) a_dec(waiters);
}
