#ifndef _SYS_EPOLL_STUB_H
#define _SYS_EPOLL_STUB_H
#include <stdint.h>
typedef union epoll_data { void *ptr; int fd; uint32_t u32; uint64_t u64; } epoll_data_t;
struct epoll_event { uint32_t events; epoll_data_t data; };
#define EPOLLIN 0x01
#define EPOLLPRI 0x02
#define EPOLLOUT 0x04
#define EPOLLERR 0x08
#define EPOLLHUP 0x10
#define EPOLLRDHUP 0x2000
#define EPOLLET 0x80000000
#define EPOLL_CTL_ADD 1
#define EPOLL_CTL_DEL 2
#define EPOLL_CTL_MOD 3
int epoll_ctl(int, int, int, struct epoll_event *);
int epoll_wait(int, struct epoll_event *, int, int);
int epoll_pwait(int, struct epoll_event *, int, int, const void *);
int epoll_create1(int);
int epoll_create(int);
#endif
