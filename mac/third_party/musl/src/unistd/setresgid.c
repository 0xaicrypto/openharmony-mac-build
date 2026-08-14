#define _GNU_SOURCE
#include <unistd.h>
#include "syscall.h"
#include "libc.h"

int setresgid(gid_t rgid, gid_t egid, gid_t sgid)
{
	return __syscall_ret(__syscall(SYS_setresgid, rgid, egid, sgid));
}
