#define _GNU_SOURCE
#include <unistd.h>
#include "syscall.h"
#include "libc.h"

int setresgid(gid_t rgid, gid_t egid, gid_t sgid)
{
	/* NOTE(mac): hangs inside app seccomp sandbox */
	(void)rgid;
	(void)egid;
	(void)sgid;
	return 0;
}
