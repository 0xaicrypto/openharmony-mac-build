#ifndef _OVERRIDE_SYS_PROTOSW_H
#define _OVERRIDE_SYS_PROTOSW_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/protosw.h>)
#include_next <sys/protosw.h>
#else
/* minimal fallback */

#endif
#endif
