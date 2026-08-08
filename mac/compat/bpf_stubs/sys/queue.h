#ifndef _SYS_QUEUE_STUB_H
#define _SYS_QUEUE_STUB_H

/* macOS <sys/queue.h> 定义 BSD 版 LIST_HEAD(name, type)，
 * 与 Linux tools/include/linux/list.h 的 LIST_HEAD(name) 冲突。
 * 引入真头后强制恢复 Linux 语义。 */

#include_next <sys/queue.h>

#ifdef LIST_HEAD
#undef LIST_HEAD
#endif
#define LIST_HEAD(name) struct list_head name = { &(name), &(name) }

#endif
