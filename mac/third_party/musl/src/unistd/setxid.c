#include <unistd.h>
#include <signal.h>
#include "syscall.h"
#include "libc.h"
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

struct ctx {
	int id, eid, sid;
	int nr, ret;
};

static void do_setxid(void *p)
{
	struct ctx *c = p;
	if (c->ret<0) return;
	{
		int kfd = open("/dev/kmsg", O_WRONLY);
		if (kfd >= 0) {
			char kb[128];
			int kn = snprintf(kb, sizeof kb, "<6>musl: do_setxid call nr=%d id=%d\n", c->nr, c->id);
			write(kfd, kb, kn);
			close(kfd);
		}
	}
	int ret = __syscall(c->nr, c->id, c->eid, c->sid);
	{
		int kfd = open("/dev/kmsg", O_WRONLY);
		if (kfd >= 0) {
			char kb[128];
			int kn = snprintf(kb, sizeof kb, "<6>musl: do_setxid done nr=%d ret=%d\n", c->nr, ret);
			write(kfd, kb, kn);
			close(kfd);
		}
	}
	if (ret && !c->ret) {
		/* If one thread fails to set ids after another has already
		 * succeeded, forcibly killing the process is the only safe
		 * thing to do. State is inconsistent and dangerous. Use
		 * SIGKILL because it is uncatchable. */
		__block_all_sigs(0);
		__syscall(SYS_kill, __syscall(SYS_getpid), SIGKILL);
	}
	c->ret = ret;
}

int __setxid(int nr, int id, int eid, int sid)
{
	{
		int kfd = open("/dev/kmsg", O_WRONLY);
		if (kfd >= 0) {
			char kb[128];
			int kn = snprintf(kb, sizeof kb, "<6>musl: setxid nr=%d id=%d\n", nr, id);
			write(kfd, kb, kn);
			close(kfd);
		}
	}
	/* ret is initially nonzero so that failure of the first thread does not
	 * trigger the safety kill above. */
	struct ctx c = { .nr = nr, .id = id, .eid = eid, .sid = sid, .ret = 1 };
	{
		int kfd = open("/dev/kmsg", O_WRONLY);
		if (kfd >= 0) {
			char kb[128];
			int kn = snprintf(kb, sizeof kb, "<6>musl: setxid before-synccall nr=%d t1=%d\n", nr, libc.threads_minus_1);
			write(kfd, kb, kn);
			close(kfd);
		}
	}
#ifdef __LITEOS_A__
	do_setxid(&c);
#else
	__synccall(do_setxid, &c);
#endif
	{
		int kfd = open("/dev/kmsg", O_WRONLY);
		if (kfd >= 0) {
			char kb[128];
			int kn = snprintf(kb, sizeof kb, "<6>musl: setxid after-synccall nr=%d ret=%d\n", nr, c.ret);
			write(kfd, kb, kn);
			close(kfd);
		}
	}
	return __syscall_ret(c.ret > 0 ? -EAGAIN : c.ret);
}
