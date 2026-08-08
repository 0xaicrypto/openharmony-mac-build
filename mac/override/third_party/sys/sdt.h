#ifndef _OVERRIDE_SYS_SDT_H
#define _OVERRIDE_SYS_SDT_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/sdt.h>)
#include_next <sys/sdt.h>
#else
/* minimal fallback */

#endif
#endif
