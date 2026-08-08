#ifndef _BYTESWAP_STUB_H
#define _BYTESWAP_STUB_H
#include <stdint.h>
#define __LITTLE_ENDIAN 1234
#define __BIG_ENDIAN 4321
#define __BYTE_ORDER __LITTLE_ENDIAN
static inline uint16_t __bswap_16(uint16_t x){ return (uint16_t)((x<<8)|(x>>8));}
static inline uint32_t __bswap_32(uint32_t x){return __builtin_bswap32(x);}
static inline uint64_t __bswap_64(uint64_t x){return __builtin_bswap64(x);}
#define __bswap_constant_16(x) ((uint16_t)((((uint16_t)(x)&0xffu)<<8)|(((uint16_t)(x)&0xff00u)>>8)))
#define __bswap_constant_32(x) ((((uint32_t)(x)&0xffu)<<24)|(((uint32_t)(x)&0xff00u)<<8)|(((uint32_t)(x)&0xff0000u)>>8)|(((uint32_t)(x)&0xff000000u)>>24))
#define __bswap_constant_64(x) (_Generic((x), default: __bswap_64)) /* unused */
#define bswap_16(x) (__builtin_constant_p(x)?__bswap_constant_16(x):__bswap_16(x))
#define bswap_32(x) (__builtin_constant_p(x)?__bswap_constant_32(x):__bswap_32(x))
#define bswap_64(x) __bswap_64(x)
#endif

#ifndef __LITTLE_ENDIAN__
#define __LITTLE_ENDIAN__
#endif
#ifndef __LITTLE_ENDIAN
#define __LITTLE_ENDIAN 1234
#endif
