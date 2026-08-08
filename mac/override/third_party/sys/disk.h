#ifndef _OVERRIDE_SYS_DISK_H
#define _OVERRIDE_SYS_DISK_H
/* darwin cross-build shim: prefer the host SDK header, else minimal fallback */
#if __has_include_next(<sys/disk.h>)
#include_next <sys/disk.h>
#else
/* minimal fallback: DKIOC ioctl numbers for blkid */
#include <sys/ioctl.h>
#define DKIOCGETBLOCKCOUNT _IOR(0x64, 2, uint32_t)
#define DKIOCGETBLOCKSIZE _IOR(0x64, 0, uint32_t)

#endif
#endif
