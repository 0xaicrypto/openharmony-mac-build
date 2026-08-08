#ifndef _WINDOWS_STUB_H
#define _WINDOWS_STUB_H
/* darwin cross-build shim: 最小 Windows API 子集, 供 hilog 等 __WINDOWS__ 分支编译 */
#include <stdint.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

typedef uint32_t DWORD;
typedef int BOOL;
typedef unsigned short WORD;
typedef void *HANDLE;
typedef void *HMODULE;
typedef uint32_t ULONG;
typedef uint32_t UINT;
typedef uintptr_t SIZE_T;
typedef intptr_t SSIZE_T;
typedef char CHAR;
typedef unsigned char BYTE;

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef NULL
#define NULL 0
#endif

static inline DWORD GetCurrentProcessId(void)
{
	return (DWORD)getpid();
}

static inline DWORD GetCurrentThreadId(void)
{
	return (DWORD)gettid();
}

static inline int localtime_s(struct tm *_tm, const time_t *time)
{
	return localtime_r(time, _tm) ? 0 : 1;
}

static inline void Sleep(DWORD ms)
{
	usleep(ms * 1000);
}

#endif
