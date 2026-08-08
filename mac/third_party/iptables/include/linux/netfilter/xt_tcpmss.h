#ifndef _XT_TCPMSS_H_MAC
#define _XT_TCPMSS_H_MAC
#include_next <linux/netfilter/xt_tcpmss.h>
#ifndef XT_TCPMSS_CLAMP_PMTU
#define XT_TCPMSS_CLAMP_PMTU 0x02
#endif
struct xt_tcpmss_info {
	__u16 mss;
};
#endif
