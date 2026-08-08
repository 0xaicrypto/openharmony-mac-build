#ifndef _OVERRIDE_SYS_SYS_DOMAIN_H
#define _OVERRIDE_SYS_SYS_DOMAIN_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/sys_domain.h>)
#include_next <sys/sys_domain.h>
#else
/* minimal fallback */

#endif
#endif
