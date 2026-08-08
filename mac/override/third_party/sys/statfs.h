#ifndef _SYS_STATFS_H_DARWIN_SHIM
#define _SYS_STATFS_H_DARWIN_SHIM
/* darwin cross-build shim: mac 无 <sys/statfs.h> */
#ifdef __APPLE__
/* 宿主: mac 的 statfs 在 sys/mount.h */
#include <sys/mount.h>
#else
/* 目标(musl): 用 statvfs 映射 */
#include <sys/statvfs.h>
struct statfs {
	long f_type;
	long f_bsize;
	unsigned long f_blocks;
	unsigned long f_bfree;
	unsigned long f_bavail;
	unsigned long f_files;
	unsigned long f_ffree;
	unsigned long f_namelen;
};
static inline int statfs(const char *path, struct statfs *buf)
{
	struct statvfs v;
	if (statvfs(path, &v))
		return -1;
	buf->f_type = 0;
	buf->f_bsize = v.f_frsize ? v.f_frsize : v.f_bsize;
	buf->f_blocks = v.f_blocks;
	buf->f_bfree = v.f_bfree;
	buf->f_bavail = v.f_bavail;
	buf->f_files = v.f_files;
	buf->f_ffree = v.f_ffree;
	buf->f_namelen = v.f_namemax;
	return 0;
}
#endif
#endif
