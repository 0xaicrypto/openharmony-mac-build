#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdarg.h>
#include <stdint.h>
#include <sys/mman.h>
#include <linux/fb.h>
#include <sys/ioctl.h>

static void kmsg(const char *fmt, ...)
{
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    int fd = open("/dev/kmsg", O_WRONLY);
    if (fd >= 0) {
        write(fd, buf, n);
        write(fd, "\n", 1);
        close(fd);
    }
}

int main(void)
{
    kmsg("TFB: start");
    int fd = open("/dev/graphics/fb0", O_RDWR);
    kmsg("TFB: open fb0=%d errno=%d", fd, errno);
    if (fd < 0)
        return 1;
    struct fb_var_screeninfo vi;
    if (ioctl(fd, FBIOGET_VSCREENINFO, &vi) < 0) {
        kmsg("TFB: GET_VSCREENINFO failed errno=%d", errno);
        return 1;
    }
    kmsg("TFB: %dx%d bpp=%d", vi.xres, vi.yres, vi.bits_per_pixel);
    long screensize = vi.xres * vi.yres * vi.bits_per_pixel / 8;
    void *map = mmap(NULL, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    kmsg("TFB: mmap=%p errno=%d size=%ld", map, errno, screensize);
    if (map == MAP_FAILED)
        return 1;
    for (int i = 0; i < screensize / 4; i++)
        ((uint32_t *)map)[i] = 0x0000FF00; /* red */
    msync(map, screensize, MS_SYNC);
    kmsg("TFB: painted red");
    uint32_t v0 = ((uint32_t *)map)[0];
    uint32_t v1 = ((uint32_t *)map)[screensize / 4 / 2];
    kmsg("TFB: readback[0]=0x%x [mid]=0x%x", v0, v1);
    /* also try write() syscall */
    lseek(fd, 0, SEEK_SET);
    char *buf = malloc(screensize);
    memset(buf, 0, screensize);
    for (int i = 0; i < screensize / 4; i++)
        ((uint32_t *)buf)[i] = 0x000000FF; /* blue */
    ssize_t wr = write(fd, buf, screensize);
    kmsg("TFB: write()=%zd errno=%d", wr, errno);
    sleep(30);
    kmsg("TFB: done");
    return 0;
}
