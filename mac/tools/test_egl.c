#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdarg.h>
#include <dlfcn.h>
#include <EGL/egl.h>
#include <signal.h>
#include <ucontext.h>

static void sig_handler(int sig, siginfo_t *info, void *ctx)
{
    ucontext_t *uc = (ucontext_t *)ctx;
    char buf[256];
    int n = snprintf(buf, sizeof buf, "TEGL: signal %d pc=0x%llx addr=0x%llx lr=0x%llx\n",
        sig, (unsigned long long)uc->uc_mcontext.pc,
        (unsigned long long)(uintptr_t)info->si_addr,
        (unsigned long long)uc->uc_mcontext.regs[30]);
    int fd = open("/dev/kmsg", O_WRONLY);
    if (fd >= 0) { write(fd, buf, n); close(fd); }
    FILE *m = fopen("/proc/self/maps", "r");
    if (m) {
        char line[512];
        while (fgets(line, sizeof(line), m)) {
            unsigned long long start, end;
            if (sscanf(line, "%llx-%llx", &start, &end) == 2 &&
                ((unsigned long long)uc->uc_mcontext.pc >= start && (unsigned long long)uc->uc_mcontext.pc < end)) {
                fd = open("/dev/kmsg", O_WRONLY);
                if (fd >= 0) {
                    char out[600];
                    int on = snprintf(out, sizeof out, "TEGL: PC in: %s", line);
                    while (on > 0 && (out[on-1] == '\n' || out[on-1] == ' ')) on--;
                    write(fd, out, on); write(fd, "\n", 1); close(fd);
                }
            }
            if (sscanf(line, "%llx-%llx", &start, &end) == 2 &&
                ((unsigned long long)uc->uc_mcontext.regs[30] >= start && (unsigned long long)uc->uc_mcontext.regs[30] < end)) {
                fd = open("/dev/kmsg", O_WRONLY);
                if (fd >= 0) {
                    char out[600];
                    int on = snprintf(out, sizeof out, "TEGL: LR in: %s", line);
                    while (on > 0 && (out[on-1] == '\n' || out[on-1] == ' ')) on--;
                    write(fd, out, on); write(fd, "\n", 1); close(fd);
                }
            }
        }
        fclose(m);
    }
    _exit(1);
}

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
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = sig_handler;
    sa.sa_flags = SA_SIGINFO;
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGBUS, &sa, NULL);
    int kfd = open("/dev/kmsg", O_WRONLY);
    if (kfd >= 0)
        dup2(kfd, 2);
    kmsg("TEGL: start");
    /* DRM check */
    int dfd = open("/dev/dri/card0", O_RDWR);
    kmsg("TEGL: open /dev/dri/card0 = %d errno=%d", dfd, errno);
    if (dfd >= 0) {
        char buf[4096];
        int u = open("/sys/class/drm/card0/device/uevent", O_RDONLY);
        if (u >= 0) {
            int r = read(u, buf, sizeof(buf) - 1);
            if (r > 0) {
                buf[r] = 0;
                kmsg("TEGL: uevent: %s", buf);
            }
            close(u);
        }
        close(dfd);
    }
    void *egl = dlopen("libEGL.so", RTLD_NOW | RTLD_GLOBAL);
    kmsg("TEGL: dlopen libEGL.so = %p dlerror=%s", egl, egl ? "ok" : (dlerror() ? dlerror() : "noerr"));
    if (!egl)
        return 1;
    EGLDisplay dpy = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    kmsg("TEGL: eglGetDisplay = %p", (void *)dpy);
    if (dpy == EGL_NO_DISPLAY) {
        kmsg("TEGL: eglGetDisplay failed err=%d", eglGetError());
        return 1;
    }
    EGLint major, minor;
    EGLBoolean ok = eglInitialize(dpy, &major, &minor);
    kmsg("TEGL: eglInitialize = %d (%d.%d) err=%d", ok, major, minor, eglGetError());
    if (!ok)
        return 1;
    kmsg("TEGL: vendor=%s", eglQueryString(dpy, EGL_VENDOR));
    kmsg("TEGL: done");
    return 0;
}
