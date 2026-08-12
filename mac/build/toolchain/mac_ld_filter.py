#!/usr/bin/env python3
"""darwin port: clang_x64 (mac hack) 实际链接 Mach-O, 过滤 GNU ld 不支持的参数.

用法: mac_ld_filter.py <linker> [args...]
"""

import subprocess
import sys

UNSUPPORTED_PREFIXES = (
    "-Wl,-z,",
    "-Wl,--as-needed",
    "-Wl,--build-id",
    "-Wl,--icf",
    "-Wl,--gc-sections",
    "-Wl,--hash-style",
    "-Wl,--strip-debug",
    "-Wl,--pack-dyn-relocs",
    "-Wl,--color-diagnostics",
    "-Wl,--gdb-index",
    "-Wl,--no-rosegment",
    "-Wl,--fatal-warnings",
    "-Wl,--no-undefined",
    "-Wl,--start-group",
    "-Wl,--end-group",
    "-Wl,--whole-archive",
    "-Wl,--no-whole-archive",
    "-Wl,-rpath-link",
    "-Wl,--exclude-libs",
    "-Wl,--version-script",
    "-Wl,-soname",
    "-Wl,-h,",
    "-Wl,--disable-new-dtags",
    "-Wl,--enable-new-dtags",
    "-Wl,--no-as-needed",
    "-Wl,--copy-dt-needed-entries",
    "-Wl,--no-copy-dt-needed-entries",
    "-Wl,-rpath=$ORIGIN",
    "-Wl,--no-relax",
    "-Wl,--omagic",
    "-Wl,--nmagic",
    "-Wl,--warn-shared-textrel",
    "-Wl,--no-warn-shared-textrel",
    "-Wl,--fatal-warnings",
    "-Wl,--no-fatal-warnings",
    "-Wl,--allow-shlib-undefined",
    "-Wl,--no-allow-shlib-undefined",
    "-Wl,-z",
)

UNSUPPORTED_EXACT = (
    "-Wl,-z",
    "-rdynamic",
    "-pie",
    "-lpthread",
    "-latomic",
    "-ldl",
    "-lrt",
)


def main():
    args = sys.argv[1:]
    out = []
    i = 0
    while i < len(args):
        a = args[i]
        skip = a in UNSUPPORTED_EXACT or a.startswith(UNSUPPORTED_PREFIXES)
        if skip:
            i += 1
            continue
        out.append(a)
        i += 1
    return subprocess.run(out).returncode


if __name__ == "__main__":
    sys.exit(main())
