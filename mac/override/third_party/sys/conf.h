#ifndef _OVERRIDE_SYS_CONF_H
#define _OVERRIDE_SYS_CONF_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/conf.h>)
#include_next <sys/conf.h>
#else
/* minimal fallback */

#endif
#endif
