#!/usr/bin/env python3
"""e2fsprogs darwin 交叉编译兼容补丁。

问题: config.h 由 configure 在 mac 宿主机生成, 其 HAVE_*_H 宏反映的是
宿主机(mac SDK)的头可用性, 与交叉目标(musl sysroot)不一致:
  - 宿主机有、目标没有的头 (net/if_dl.h, sys/sockio.h...):
    HAVE_* 定义 -> 交叉编译错误 include
  - 目标有、宿主机没有的头 (sys/sysmacros.h, linux/fd.h...):
    HAVE_* 未定义 -> 交叉编译漏 include

方案: include 门改为按目标环境实际判断 __has_include(<x.h>),
不依赖宿主机生成的 config 宏。代码逻辑层(如 sa_len 分支)按 __APPLE__
判断宿主编译与目标编译。

用法: python3 patch_e2fsprogs_has_include.py [e2fsprogs目录]
"""
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'

PAT1 = re.compile(r'#ifdef (HAVE_[A-Z0-9_]+)\n#include <([^>]+)>')
PAT2 = re.compile(r'#if defined\((HAVE_[A-Z0-9_]+)\) \|\| __has_include\(<([^>]+)>\)')
PAT3 = re.compile(r'#if defined\((HAVE_[A-Z0-9_]+)\) && __has_include\(<([^>]+)>\)')
SA_LEN = re.compile(r'#ifdef HAVE_SA_LEN')

fixed = 0
for dirpath, dirnames, filenames in os.walk(ROOT):
    for f in filenames:
        if not f.endswith(('.c', '.h')):
            continue
        p = os.path.join(dirpath, f)
        with open(p, encoding='utf-8', errors='ignore') as fh:
            s = fh.read()
        ns = PAT1.sub(r'#if __has_include(<\2>)\n#include <\2>', s)
        ns = PAT2.sub(r'#if __has_include(<\2>)\n#include <\2>', ns)
        ns = PAT3.sub(r'#if __has_include(<\2>)\n#include <\2>', ns)
        if 'gen_uuid.c' in p:
            ns = SA_LEN.sub(r'#if defined(HAVE_SA_LEN) && defined(__APPLE__)', ns)
        if ns != s:
            with open(p, 'w') as fh:
                fh.write(ns)
            fixed += 1

print(f"patched {fixed} files")
