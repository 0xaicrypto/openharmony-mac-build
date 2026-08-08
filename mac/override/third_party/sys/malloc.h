#ifndef _OVERRIDE_SYS_MALLOC_H
#define _OVERRIDE_SYS_MALLOC_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/malloc.h>)
#include_next <sys/malloc.h>
#else
/* minimal fallback */

#endif
#endif
