#ifndef _OVERRIDE_SYS_SOCKIO_H
#define _OVERRIDE_SYS_SOCKIO_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/sockio.h>)
#include_next <sys/sockio.h>
#else
/* minimal fallback */

#endif
#endif
