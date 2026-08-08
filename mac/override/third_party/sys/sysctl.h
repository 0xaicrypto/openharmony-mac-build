#ifndef _OVERRIDE_SYS_SYSCTL_H
#define _OVERRIDE_SYS_SYSCTL_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/sysctl.h>)
#include_next <sys/sysctl.h>
#else
#include <sys/sysctl.h>

#endif
#endif
