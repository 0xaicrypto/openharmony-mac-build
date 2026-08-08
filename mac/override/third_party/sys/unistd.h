#ifndef _OVERRIDE_SYS_UNISTD_H
#define _OVERRIDE_SYS_UNISTD_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/unistd.h>)
#include_next <sys/unistd.h>
#else
/* minimal fallback */

#endif
#endif
