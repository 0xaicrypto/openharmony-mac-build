#ifndef _XT_DSCP_H_MAC
#define _XT_DSCP_H_MAC
#include <linux/types.h>
#define XT_DSCP_MAX 63
struct xt_DSCP_info {
	__u8 dscp;
	__u8 invert;
};
struct xt_dscp_info {
	__u8 dscp;
	__u8 invert;
};
struct xt_tos_match_info {
	__u8 tos_mask;
	__u8 tos_value;
	__u8 invert;
};
#endif
