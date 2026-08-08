#ifndef _OVERRIDE_SYS_PROC_H
#define _OVERRIDE_SYS_PROC_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/proc.h>)
#include_next <sys/proc.h>
#else
/* minimal fallback */

#endif
#endif
