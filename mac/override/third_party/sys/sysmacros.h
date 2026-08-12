#ifndef _SYS_SYSMACROS_H_DARWIN_SHIM
#define _SYS_SYSMACROS_H_DARWIN_SHIM
/* darwin port shim: mac 无 sys/sysmacros.h
 * 注意: 该头同时被宿主编译(darwin)与交叉编译(aarch64-linux-ohos)使用,
 * 而 makedev/major/minor 的 dev_t 编码两种平台不同,必须按 __linux__ 区分。
 */
#include <sys/types.h>
#ifdef __linux__
#ifndef major
#define major(x) ((unsigned)((((x) >> 31) >> 1) & 0xfffff000) | (((x) >> 8) & 0x00000fff))
#endif
#ifndef minor
#define minor(x) ((unsigned)((((x) >> 12) & 0xffffff00) | ((x) & 0x000000ff)))
#endif
#ifndef makedev
#define makedev(x, y) ( \
	(((x) & 0xfffff000ULL) << 32) | \
	(((x) & 0x00000fffULL) << 8) | \
	(((y) & 0xffffff00ULL) << 12) | \
	(((y) & 0x000000ffULL)))
#endif
#else
#ifndef major
#define major(x) ((int32_t)((((uint32_t)(x) >> 24) & 0xff) | (((uint32_t)(x) >> 8) & 0xfff00)))
#endif
#ifndef minor
#define minor(x) ((int32_t)((((uint32_t)(x) >> 8) & 0xff) | (((uint32_t)(x) & 0xff00))))
#endif
#ifndef makedev
#define makedev(x, y) ((dev_t)((((uint32_t)(x) << 24) | ((uint32_t)(y) << 8))))
#endif
#endif
#endif
