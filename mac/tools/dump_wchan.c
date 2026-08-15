#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <stdarg.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/uio.h>
#include <elf.h>
#include <signal.h>
#include <errno.h>
#include <asm/ptrace.h>

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
    {
        /* ptrace read user PC of composer_host main thread */
        pid_t tpid = 0;
        DIR *pd = opendir("/proc");
        if (pd) {
            struct dirent *pe;
            while ((pe = readdir(pd))) {
                if (pe->d_name[0] < '0' || pe->d_name[0] > '9') continue;
                char pcmd[128], pp[128];
                snprintf(pp, sizeof pp, "/proc/%s/cmdline", pe->d_name);
                readfile(pp, pcmd, sizeof pcmd);
                if (strcmp(pcmd, "composer_host") == 0) {
                    tpid = (pid_t)atoi(pe->d_name);
                    break;
                }
            }
            closedir(pd);
        }
        if (tpid) {
            long ret = ptrace(PTRACE_ATTACH, tpid, 0, 0);
            if (ret == 0) {
                int st = 0;
                waitpid(tpid, &st, 0);
                struct user_pt_regs regs;
                ret = ptrace(PTRACE_GETREGSET, tpid, (void *)NT_PRSTATUS, &regs);
                if (ret == 0) {
                    kmsg("PTRACE: pid=%d pc=%lx lr=%lx sp=%lx", tpid,
                        (unsigned long)regs.pc, (unsigned long)regs.regs[30], (unsigned long)regs.sp);
                }
                ptrace(PTRACE_DETACH, tpid, 0, 0);
            }
        }
    }
    {
        const char *probes[] = { "/data/devhost_probe_composer_host", "/data/devhost_probe_wifi_host",
            "/data/devhost_probe_power_host", "/dev/devhost_probe_composer_host",
            "/tmp/devhost_probe_composer_host", "/vendor/devhost_probe_composer_host" };
        for (int pi = 0; pi < 6; pi++) {
            int pfd = open(probes[pi], O_RDONLY);
            if (pfd >= 0) {
                char pb[1024];
                int pr = read(pfd, pb, sizeof(pb) - 1);
                close(pfd);
                if (pr > 0) { pb[pr] = 0; kmsg("PROBE: %s -> %s", probes[pi], pb); }
            }
        }
    }
retry_loop:
    sleep(60);
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
        if (pid >= 1 && pid < 1500) {
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
                    char exe[128] = "?";
                    snprintf(tp, sizeof tp, "/proc/%s/exe", e->d_name);
                    int exn = readlink(tp, exe, sizeof(exe) - 1);
                    if (exn > 0) exe[exn] = 0;
                    char sc[256] = "?";
                    snprintf(tp, sizeof tp, "/proc/%s/task/%s/syscall", e->d_name, te->d_name);
                    readfile(tp, sc, sizeof sc);
                    if (strcmp(te->d_name, e->d_name) == 0) {
                        char mp[1024] = "";
                        unsigned long faddr = 0;
                        /* parse syscall args: 98 futex => arg1 = addr */
                        char *f = strstr(sc, "0x");
                        if (f) faddr = strtoul(f, NULL, 16);
                        snprintf(tp, sizeof tp, "/proc/%s/maps", e->d_name);
                        int mfd = open(tp, O_RDONLY);
                        if (mfd >= 0) {
                            int got = 0;
                            char line[512];
                            int rl = 0;
                            while ((rl = read(mfd, line, sizeof(line) - 1)) > 0 && got < 6) {
                                line[rl] = 0;
                                char *p = line;
                                while (*p && got < 6) {
                                    char *nl = strchr(p, '\n');
                                    char save = 0;
                                    if (nl) { save = *nl; *nl = 0; }
                                    unsigned long a, b;
                                    if (sscanf(p, "%lx-%lx", &a, &b) == 2 &&
                                        (faddr == 0 || (faddr >= a && faddr < b))) {
                                        strncat(mp, p, sizeof(mp) - strlen(mp) - 1);
                                        strncat(mp, "|", sizeof(mp) - strlen(mp) - 1);
                                        got++;
                                    }
                                    if (!nl) break;
                                    *nl = save;
                                    p = nl + 1;
                                }
                                if (rl < (int)sizeof(line) - 1) break;
                            }
                            close(mfd);
                            kmsg("MAPS: pid=%s %s", e->d_name, mp);
                        }
                        {
                            char fdlist[1024] = "";
                            snprintf(tp, sizeof tp, "/proc/%s/fd", e->d_name);
                            DIR *fd = opendir(tp);
                            if (fd) {
                                struct dirent *fe;
                                int fn = 0;
                                while ((fe = readdir(fd)) && fn < 20) {
                                    if (fe->d_name[0] < '0' || fe->d_name[0] > '9') continue;
                                    char fdp[256], lk[128] = "?";
                                    snprintf(fdp, sizeof fdp, "%s/%s", tp, fe->d_name);
                                    int ln = readlink(fdp, lk, sizeof(lk) - 1);
                                    if (ln > 0) lk[ln] = 0;
                                    char tmp[140];
                                    snprintf(tmp, sizeof tmp, "%s=%s|", fe->d_name, lk);
                                    strncat(fdlist, tmp, sizeof(fdlist) - strlen(fdlist) - 1);
                                    fn++;
                                }
                                closedir(fd);
                            }
                            kmsg("FDS: pid=%s %s", e->d_name, fdlist);
                        }
                        if (faddr) {
                            char mt[256] = "";
                            snprintf(tp, sizeof tp, "/proc/%s/mem", e->d_name);
                            int mfd2 = open(tp, O_RDONLY);
                            if (mfd2 >= 0) {
                                off_t off = (off_t)faddr;
                                char buf[64];
                                ssize_t rr = pread(mfd2, buf, sizeof(buf), off);
                                if (rr > 0) {
                                    snprintf(mt, sizeof mt, "MEM: pid=%s addr=%lx ", e->d_name, faddr);
                                    for (int i = 0; i < rr && i < 32; i++) {
                                        char tmp[8];
                                        snprintf(tmp, sizeof tmp, "%02x", (unsigned char)buf[i]);
                                        strncat(mt, tmp, sizeof(mt) - strlen(mt) - 1);
                                    }
                                    kmsg("%s", mt);
                                }
                                close(mfd2);
                            }
                        }
                    }
                    kmsg("TASK: pid=%s tid=%s wchan=%s cmd=%s exe=%s syscall=%s", e->d_name, te->d_name, w2, cmd, exe, sc);
                }
                closedir(td);
            }
        }
    }
    closedir(d);
    kmsg("WCHAN: done");
    goto retry_loop;
}
