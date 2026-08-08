#ifndef _SYS_SOCKET_H_
#define _SYS_SOCKET_H_

#include <linux/types.h>
#include <stdint.h>

typedef unsigned short sa_family_t;
typedef unsigned int socklen_t;

#define AF_UNSPEC 0
#define AF_INET 2
#define AF_INET6 10

struct sockaddr {
	sa_family_t sa_family;
	char        sa_data[14];
};

#endif