#ifndef _SYS_MMAN_H_DARWIN_PATCH
#define _SYS_MMAN_H_DARWIN_PATCH
/* darwin port: mac SDK 缺 linux MREMAP_* 宏, include_next 到 mac 真头后补齐 */
#include_next <sys/mman.h>
#ifndef MREMAP_MAYMOVE
#define MREMAP_MAYMOVE 1
#endif
#ifndef MREMAP_FIXED
#define MREMAP_FIXED 2
#endif
#endif
