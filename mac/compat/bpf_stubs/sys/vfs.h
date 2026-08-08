#ifndef _SYS_VFS_STUB_H
#define _SYS_VFS_STUB_H

/* macOS 无 <sys/vfs.h>；sys/mount.h 提供 struct statfs + statfs/fstatfs，
 * 且 struct statfs 含 f_type 字段（libbpf/bpftool 仅用 f_type）。 */

#include <sys/mount.h>

#endif
