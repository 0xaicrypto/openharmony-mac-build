#ifndef _OVERRIDE_SYS_EVENT_H
#define _OVERRIDE_SYS_EVENT_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/event.h>)
#include_next <sys/event.h>
#else
/* minimal fallback */

#endif
#endif
