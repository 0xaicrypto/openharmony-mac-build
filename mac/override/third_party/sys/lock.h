#ifndef _OVERRIDE_SYS_LOCK_H
#define _OVERRIDE_SYS_LOCK_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/lock.h>)
#include_next <sys/lock.h>
#else
/* minimal fallback */

#endif
#endif
