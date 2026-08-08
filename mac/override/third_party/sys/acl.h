#ifndef _OVERRIDE_SYS_ACL_H
#define _OVERRIDE_SYS_ACL_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/acl.h>)
#include_next <sys/acl.h>
#else
/* minimal fallback */

#endif
#endif
