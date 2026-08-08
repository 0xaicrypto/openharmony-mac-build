#ifndef _ASM_BYTEORDER_STUB_H
#define _ASM_BYTEORDER_STUB_H
#include <byteswap.h>
#define __LITTLE_ENDIAN_BITFIELD
#define __constant_cpu_to_le64(x) __bswap_constant_64(x)
#define __constant_cpu_to_le32(x) __bswap_constant_32(x)
#define __constant_cpu_to_le16(x) __bswap_constant_16(x)
#define __cpu_to_le64(x) bswap_64(x)
#define __cpu_to_le32(x) bswap_32(x)
#define __cpu_to_le16(x) bswap_16(x)
#define __cpu_to_be64(x) ((uint64_t)(x))
#define __cpu_to_be32(x) ((uint32_t)(x))
#define __cpu_to_be16(x) ((uint16_t)(x))
#define __le64_to_cpu(x) bswap_64(x)
#define __le32_to_cpu(x) bswap_32(x)
#define __le16_to_cpu(x) bswap_16(x)
#define __be64_to_cpu(x) ((uint64_t)(x))
#define __be32_to_cpu(x) ((uint32_t)(x))
#define __be16_to_cpu(x) ((uint16_t)(x))
#define cpu_to_le64 __cpu_to_le64
#define cpu_to_le32 __cpu_to_le32
#define cpu_to_le16 __cpu_to_le16
#define cpu_to_be64 __cpu_to_be64
#define cpu_to_be32 __cpu_to_be32
#define cpu_to_be16 __cpu_to_be16
#define le64_to_cpu __le64_to_cpu
#define le32_to_cpu __le32_to_cpu
#define le16_to_cpu __le16_to_cpu
#define be64_to_cpu __be64_to_cpu
#define be32_to_cpu __be32_to_cpu
#define be16_to_cpu __be16_to_cpu
#endif
