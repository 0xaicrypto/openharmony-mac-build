#include "selinux_internal.h"

#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <dlfcn.h>
#include <sys/mount.h>


#ifndef HAVE_STRLCPY
size_t strlcpy(char *dest, const char *src, size_t size)
{
	size_t ret = strlen(src);

	if (size) {
		size_t len = (ret >= size) ? size - 1 : ret;
		memcpy(dest, src, len);
		dest[len] = '\0';
	}
	return ret;
}
#endif /* HAVE_STRLCPY */

/* darwin port: host (mac) 构建无 musl/glibc/linux 的以下函数, 提供等价实现 */

int __fsetlocking(FILE *f, int type)
{
	(void)f;
	(void)type;
	return 0;
}

char *fgets_unlocked(char *s, int size, FILE *stream)
{
	return fgets(s, size, stream);
}

/* mac 无 lgetxattr/lsetxattr 符号, 用 getxattr/setxattr (mac 上不跟随符号链接) */
typedef ssize_t (*mac_xattr_t)(const char *, const char *, void *, size_t,
			       unsigned int, int);

static ssize_t mac_getxattr_wrap(const char *path, const char *name,
				 void *value, size_t size)
{
	static mac_xattr_t real;
	if (!real)
		real = (mac_xattr_t)dlsym(RTLD_DEFAULT, "getxattr");
	if (real)
		return real(path, name, value, size, 0, 0);
	errno = ENOSYS;
	return -1;
}

static int mac_setxattr_wrap(const char *path, const char *name,
			     const void *value, size_t size, int flags)
{
	static mac_xattr_t real;
	if (!real)
		real = (mac_xattr_t)dlsym(RTLD_DEFAULT, "setxattr");
	if (real)
		return real(path, name, (void *)value, size, 0, flags);
	errno = ENOSYS;
	return -1;
}

int lgetxattr(const char *path, const char *name, void *value, size_t size)
{
	ssize_t ret = mac_getxattr_wrap(path, name, value, size);
	if (ret < 0)
		return -1;
	return (int)ret;
}

int lsetxattr(const char *path, const char *name, const void *value,
	      size_t size, int flags)
{
	return mac_setxattr_wrap(path, name, value, size, flags);
}

int strverscmp(const char *l, const char *r)
{
	const unsigned char *a = (const unsigned char *)l;
	const unsigned char *b = (const unsigned char *)r;
	while (*a && *b) {
		if (*a != *b) {
			if ((*a >= '0' && *a <= '9') && (*b >= '0' && *b <= '9')) {
				while (a[1] >= '0' && a[1] <= '9')
					a++;
				while (b[1] >= '0' && b[1] <= '9')
					b++;
				return (*a > *b) ? 1 : -1;
			}
			return (*a > *b) ? 1 : -1;
		}
		a++;
		b++;
	}
	if (*a == *b)
		return 0;
	return (*a > *b) ? 1 : -1;
}

int umount(const char *target)
{
	return unmount(target, 0);
}

int umount2(const char *target, int flags)
{
	return unmount(target, flags);
}
