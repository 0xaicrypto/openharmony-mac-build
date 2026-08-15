#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/uio.h>
#include <asm/ptrace.h>
#include <signal.h>
#include <errno.h>
#include <elf.h>

static void kmsg(const char *fmt, ...)
{
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(buf, sizeof buf, fmt, ap);
    va_end(ap);
    int fd = open("/dev/kmsg", O_WRONLY);
    if (fd >= 0) { write(fd, buf, n); write(fd, "\n", 1); close(fd); }
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
    pid_t tpid = 0;
    DIR *pd = opendir("/proc");
    if (!pd) return 1;
    struct dirent *pe;
    while ((pe = readdir(pd))) {
        if (pe->d_name[0] < '0' || pe->d_name[0] > '9') continue;
        char pcmd[128], pp[128];
        snprintf(pp, sizeof pp, "/proc/%s/cmdline", pe->d_name);
        readfile(pp, pcmd, sizeof pcmd);
        if (strcmp(pcmd, "composer_host") == 0) { tpid = atoi(pe->d_name); break; }
    }
    closedir(pd);
    if (!tpid) { kmsg("PT: composer not found"); return 0; }
    kmsg("PT: attach pid=%d", tpid);
    long ret = ptrace(PTRACE_ATTACH, tpid, 0, 0);
    kmsg("PT: attach ret=%ld errno=%d", ret, errno);
    if (ret == 0) {
        int st = 0;
        pid_t wr = waitpid(tpid, &st, 0);
        kmsg("PT: waitpid ret=%d st=%x", wr, st);
        struct user_pt_regs regs;
        struct iovec iov = { &regs, sizeof(regs) };
        ret = ptrace(PTRACE_GETREGSET, tpid, (void *)NT_PRSTATUS, &iov);
        kmsg("PT: getregset ret=%ld pc=%lx lr=%lx sp=%lx fp=%lx x0=%lx", ret,
            (unsigned long)regs.pc, (unsigned long)regs.regs[30],
            (unsigned long)regs.sp, (unsigned long)regs.regs[29],
            (unsigned long)regs.regs[0]);
        {
            unsigned long fps[16], rets[16];
            int nf = 0;
            unsigned long fp = (unsigned long)regs.regs[29];
            for (int i = 0; i < 12 && fp > 0x1000 && fp < 0xffff000000000000UL; i++) {
                unsigned long pv = ptrace(PTRACE_PEEKDATA, tpid, (void *)fp, 0);
                unsigned long lr2 = ptrace(PTRACE_PEEKDATA, tpid, (void *)(fp + 8), 0);
                fps[nf] = fp; rets[nf] = lr2; nf++;
                kmsg("PTFRAME: [%d] fp=%lx prev_fp=%lx ret=%lx", i, fp, pv, lr2);
                fp = pv;
            }
            char mpath[128];
            snprintf(mpath, sizeof mpath, "/proc/%d/maps", tpid);
            int mfd = open(mpath, O_RDONLY);
            if (mfd >= 0) {
                char all[131072];
                int n = 0, nr;
                while (n < (int)sizeof(all) - 1 && (nr = read(mfd, all + n, sizeof(all) - 1 - n)) > 0) n += nr;
                close(mfd);
                if (n > 0) {
                    all[n] = 0;
                    kmsg("PTMAPSZ: %d", n);
                    for (int i = 0; i < nf; i++) {
                        char *p = all;
                        while (*p) {
                            char *nl = strchr(p, '\n');
                            char save = 0;
                            if (nl) { save = *nl; *nl = 0; }
                            unsigned long a, b;
                            if (sscanf(p, "%lx-%lx", &a, &b) == 2 && rets[i] >= a && rets[i] < b) {
                                char *path = strstr(p, "/");
                                kmsg("PTLIB: ret[%d]=%lx -> %s", i, rets[i], path ? path : "?");
                                break;
                            }
                            if (!nl) break;
                            *nl = save;
                            p = nl + 1;
                        }
                    }
                }
            }
        }
        char maps[4096] = "";
        char mpath[128];
        snprintf(mpath, sizeof mpath, "/proc/%d/maps", tpid);
        int mfd = open(mpath, O_RDONLY);
        if (mfd >= 0) {
            int n = read(mfd, maps, sizeof(maps) - 1);
            if (n > 0) maps[n] = 0;
            close(mfd);
            char line[512], *p = maps;
            int got = 0;
            unsigned long pc = (unsigned long)regs.pc;
            while (*p && got < 4) {
                char *nl = strchr(p, '\n');
                char save = 0;
                if (nl) { save = *nl; *nl = 0; }
                unsigned long a, b;
                if (sscanf(p, "%lx-%lx", &a, &b) == 2 && pc >= a && pc < b) {
                    kmsg("PTMAP: %s", p);
                    got++;
                }
                if (!nl) break;
                *nl = save;
                p = nl + 1;
            }
        }
        long ins = ptrace(PTRACE_PEEKTEXT, tpid, (void *)regs.pc, 0);
        kmsg("PTINS: pc=%lx ins=%lx", (unsigned long)regs.pc, (unsigned long)ins);
        long ins2 = ptrace(PTRACE_PEEKTEXT, tpid, (void *)(regs.pc - 4), 0);
        kmsg("PTINS2: ins=%lx", (unsigned long)ins2);
        {
            unsigned long sp = (unsigned long)regs.sp;
            for (int i = 0; i < 12; i++) {
                unsigned long word = ptrace(PTRACE_PEEKDATA, tpid, (void *)(sp + i * 8), 0);
                kmsg("PTSTACK: [%d] %lx", i, word);
            }
        }
        ptrace(PTRACE_DETACH, tpid, 0, 0);
    }
    return 0;
}
