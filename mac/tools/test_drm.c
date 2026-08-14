#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdarg.h>
#include <stdint.h>
#include <sys/mman.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>

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
    kmsg("TDRM: start");
    int fd = open("/dev/dri/card0", O_RDWR);
    kmsg("TDRM: open card0=%d", fd);
    if (fd < 0)
        return 1;
    drmModeRes *res = drmModeGetResources(fd);
    if (!res) {
        kmsg("TDRM: no resources errno=%d", errno);
        return 1;
    }
    kmsg("TDRM: res count_fbs=%d count_crtcs=%d count_connectors=%d",
        res->count_fbs, res->count_crtcs, res->count_connectors);
    int crtc_id = -1, conn_id = -1;
    for (int i = 0; i < res->count_connectors; i++) {
        drmModeConnector *conn = drmModeGetConnector(fd, res->connectors[i]);
        if (!conn)
            continue;
        kmsg("TDRM: conn %d type=%d connected=%d modes=%d",
            conn->connector_id, conn->connector_type, conn->connection, conn->count_modes);
        if (conn->connection == DRM_MODE_CONNECTED && conn->count_modes > 0) {
            conn_id = conn->connector_id;
            crtc_id = res->crtcs[0];
            kmsg("TDRM: use conn %d crtc %d mode %dx%d@%d",
                conn_id, crtc_id, conn->modes[0].hdisplay, conn->modes[0].vdisplay, conn->modes[0].vrefresh);
            drmModeFreeConnector(conn);
            break;
        }
        drmModeFreeConnector(conn);
    }
    if (conn_id < 0) {
        kmsg("TDRM: no connected connector");
        return 1;
    }
    drmModeConnector *conn = drmModeGetConnector(fd, conn_id);
    int w = conn->modes[0].hdisplay, h = conn->modes[0].vdisplay;
    uint32_t fmt = DRM_FORMAT_XRGB8888;
    uint32_t fb_id;
    struct drm_mode_create_dumb dm = {0};
    dm.width = w;
    dm.height = h;
    dm.bpp = 32;
    int ret = drmIoctl(fd, DRM_IOCTL_MODE_CREATE_DUMB, &dm);
    kmsg("TDRM: create_dumb ret=%d w=%d h=%d pitch=%d size=%d", ret, w, h, dm.pitch, dm.size);
    if (ret < 0)
        return 1;
    struct drm_mode_map_dumb mm = {0};
    mm.handle = dm.handle;
    ret = drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mm);
    kmsg("TDRM: map_dumb ret=%d offset=%llu", ret, (unsigned long long)mm.offset);
    void *map = mmap(NULL, dm.size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, mm.offset);
    kmsg("TDRM: mmap=%p errno=%d", map, errno);
    uint32_t *px = (uint32_t *)map;
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
            px[y * (dm.pitch / 4) + x] = 0x0000FF00; /* red */
    msync(map, dm.size, MS_SYNC);
    ret = drmModeAddFB(fd, w, h, 24, 32, dm.pitch, dm.handle, &fb_id);
    kmsg("TDRM: AddFB ret=%d fb=%d", ret, fb_id);
    if (ret < 0)
        return 1;
    ret = drmModeSetCrtc(fd, crtc_id, fb_id, 0, 0, (uint32_t *)&conn_id, 1, &conn->modes[0]);
    kmsg("TDRM: SetCrtc ret=%d errno=%d", ret, errno);
    kmsg("TDRM: keep alive, flipping frames");
    for (int f = 0; f < 120; f++) {
        uint32_t color = 0x0000FF00;
        if (f % 2) color = 0x000000FF;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
                px[y * (dm.pitch / 4) + x] = color;
        msync(map, dm.size, MS_SYNC);
        drmModePageFlip(fd, crtc_id, fb_id, DRM_MODE_PAGE_FLIP_EVENT, NULL);
        usleep(200000);
    }
    kmsg("TDRM: done");
    return 0;
}
