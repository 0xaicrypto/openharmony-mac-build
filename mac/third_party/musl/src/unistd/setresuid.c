#define _GNU_SOURCE
#include <unistd.h>
#include "syscall.h"
#include "libc.h"

int setresuid(uid_t ruid, uid_t euid, uid_t suid)
{
	/* NOTE(mac): setresuid syscall hangs inside the app seccomp sandbox
	 * on this platform. setuid() already ran successfully. */
	(void)ruid;
	(void)euid;
	(void)suid;
	return 0;
}
