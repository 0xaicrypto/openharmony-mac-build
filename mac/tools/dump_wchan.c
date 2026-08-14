#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <stdarg.h>

static void kmsg(const char *fmt, ...)
{
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    int fd = open("/dev/kmsg", O_WRONLY);
    if (fd >= 0) {
        write(fd, buf, n);
        write(fd, "\n", 1);
        close(fd);
    }
}

static void readfile(const char *path, char *out, size_t sz)
{
    out[0] = 0;
    int fd = open(path, O_RDONLY);
    if (fd < 0) return;
    int n = read(fd, out, sz - 1);
    if (n > 0) out[n] = 0;
    close(fd);
}

int main(void)
{
    sleep(80);
    DIR *d = opendir("/proc");
    if (!d) return 1;
    struct dirent *e;
    while ((e = readdir(d))) {
        if (e->d_name[0] < '0' || e->d_name[0] > '9') continue;
        char path[128];
        char st[512], wc[64], cmd[128];
        snprintf(path, sizeof path, "/proc/%s/status", e->d_name);
        readfile(path, st, sizeof st);
        unsigned long pid = strtoul(e->d_name, NULL, 10);
        char *uidline = strstr(st, "Uid:");
        char uidstr[64] = "?";
        if (uidline) {
            char *p = uidline + 4;
            while (*p == ' ' || *p == '\t') p++;
            char *e2 = p;
            while (*e2 && *e2 != '\n') e2++;
            int ul = (int)(e2 - p);
            if (ul > 0 && ul < 64) {
                memcpy(uidstr, p, ul);
                uidstr[ul] = 0;
            }
        }
        snprintf(path, sizeof path, "/proc/%s/cmdline", e->d_name);
        readfile(path, cmd, sizeof cmd);
        if (pid > 750 && pid < 850) {
            char tpath[256];
            DIR *td = opendir(tpath ? "/proc" : "/proc");
            snprintf(tpath, sizeof tpath, "/proc/%s/task", e->d_name);
            td = opendir(tpath);
            if (td) {
                struct dirent *te;
                while ((te = readdir(td))) {
                    if (te->d_name[0] < '0' || te->d_name[0] > '9') continue;
                    char tp[256], w2[64];
                    snprintf(tp, sizeof tp, "/proc/%s/task/%s/wchan", e->d_name, te->d_name);
                    readfile(tp, w2, sizeof w2);
                    kmsg("TASK: pid=%s tid=%s wchan=%s cmd=%s", e->d_name, te->d_name, w2, cmd);
                }
                closedir(td);
            }
        }
    }
    closedir(d);
    kmsg("WCHAN: done");
    return 0;
}
