#ifndef _OVERRIDE_SYS_IOCCOM_H
#define _OVERRIDE_SYS_IOCCOM_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/ioccom.h>)
#include_next <sys/ioccom.h>
#else
/* minimal fallback */

#endif
#endif
