#ifndef _OVERRIDE_SYS_KERN_CONTROL_H
#define _OVERRIDE_SYS_KERN_CONTROL_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/kern_control.h>)
#include_next <sys/kern_control.h>
#else
/* minimal fallback */

#endif
#endif
