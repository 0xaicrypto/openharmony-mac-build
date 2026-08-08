#ifndef _OVERRIDE_SYS_FILIO_H
#define _OVERRIDE_SYS_FILIO_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/filio.h>)
#include_next <sys/filio.h>
#else
/* minimal fallback */

#endif
#endif
