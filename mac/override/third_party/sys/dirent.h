#ifndef _OVERRIDE_SYS_DIRENT_H
#define _OVERRIDE_SYS_DIRENT_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/dirent.h>)
#include_next <sys/dirent.h>
#else
#include <dirent.h>

#endif
#endif
