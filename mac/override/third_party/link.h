#ifndef _LINK_H_DARWIN_STUB
#define _LINK_H_DARWIN_STUB
/* darwin port stub: Linux <link.h> 的 ElfW 宏 (unwinder 宿主工具用) */
#include <elf.h>

#ifdef __LP64__
#define __ELF_NATIVE_CLASS 64
#else
#define __ELF_NATIVE_CLASS 32
#endif

#define ElfW(type) _ElfW(Elf, __ELF_NATIVE_CLASS, type)
#define _ElfW(e, w, t) _ElfW_1(e, w, t)
#define _ElfW_1(e, w, t) e##w##_##t
#endif
