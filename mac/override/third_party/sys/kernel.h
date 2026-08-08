#ifndef _OVERRIDE_SYS_KERNEL_H
#define _OVERRIDE_SYS_KERNEL_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/kernel.h>)
#include_next <sys/kernel.h>
#else
/* minimal fallback */

#endif
#endif
