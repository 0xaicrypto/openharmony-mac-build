#ifndef _ENDIAN_H
#define _ENDIAN_H
#include <stdint.h>

static inline uint16_t bswap16(uint16_t x) { return (uint16_t)((x << 8) | (x >> 8)); }
static inline uint32_t bswap32(uint32_t x)
{
    return ((x & 0xff000000u) >> 24) | ((x & 0x00ff0000u) >> 8) |
           ((x & 0x0000ff00u) << 8) | ((x & 0x000000ffu) << 24);
}
static inline uint64_t bswap64(uint64_t x)
{
    return ((uint64_t)bswap32((uint32_t)(x >> 32))) |
           ((uint64_t)bswap32((uint32_t)x) << 32);
}

#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define le16toh(x) (x)
#define le32toh(x) (x)
#define le64toh(x) (x)
#define be16toh(x) bswap16(x)
#define be32toh(x) bswap32(x)
#define be64toh(x) bswap64(x)
#else
#define be16toh(x) (x)
#define be32toh(x) (x)
#define be64toh(x) (x)
#define le16toh(x) bswap16(x)
#define le32toh(x) bswap32(x)
#define le64toh(x) bswap64(x)
#endif

#endif
