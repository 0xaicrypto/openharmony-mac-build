#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (c) 2022 Huawei Device Co., Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
1. add {{ldflags}} and extend everyone in {{ldflags}} to -Clink-args=%s.
2. replace blank with newline in .rsp file because of rustc.
3. add {{rustenv}} and in order to avoid ninja can't incremental compiling,
   delete them from .d files.
"""

import os
import stat
import sys
import re
import shutil
import argparse
import pathlib
import subprocess

import rust_strip
sys.path.append(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts.util import build_utils  # noqa: E402


# darwin port: darwin rustc 通过 --extern name=path(.so/.dylib) 加载 proc-macro
# 时报 "unknown type", 必须用 lib<name>.dylib 文件名 (dlopen) 加载;
# ELF dylib (设备 rust 库) 依赖同样无法加载, 优先改用同名 rlib (cwd/输出目录)
# darwin port: -Ldependency 目录若只含 ELF dylib (darwin rustc 无法加载),
# 从去 lib.unstripped/ 前缀的模块目录补齐同名 rlib 副本
def fill_dependency_rlibs(tokens):
    i = 0
    while i < len(tokens):
        a = tokens[i]
        if a.startswith('-Ldependency='):
            d = a[len('-Ldependency='):]
            if 'lib.unstripped/' in d:
                alt = d.replace('/lib.unstripped/', '/', 1)
                if os.path.isdir(alt):
                    for f in os.listdir(alt):
                        if f.endswith('.rlib'):
                            target = os.path.join(d, f)
                            if not os.path.exists(target):
                                shutil.copy2(os.path.join(alt, f), target)
        i += 1
    return tokens


def convert_proc_macro_externs(tokens):
    out = []
    i = 0
    while i < len(tokens):
        a = tokens[i]
        if a == '--extern' and i + 1 < len(tokens):
            ext = tokens[i + 1]
            if '=' in ext:
                name, path = ext.split('=', 1)
                if path.endswith('.so') or path.endswith('.dylib'):
                    apath = os.path.abspath(path)
                    d = os.path.dirname(apath)
                    dirs = [d]
                    if d.startswith('lib.unstripped/'):
                        dirs.append(d[len('lib.unstripped/'):])
                    if '/lib.unstripped/' in d:
                        dirs.append(d.replace('/lib.unstripped/', '/', 1))
                    rlib_path = ''
                    for dd in dirs:
                        for cand in ('lib' + name + '.rlib',
                                     'lib' + name + '_static.rlib'):
                            p = os.path.join(dd, cand)
                            if os.path.exists(p):
                                rlib_path = p
                                break
                        if rlib_path:
                            break
                    if not rlib_path:
                        rlib_path = os.path.join(os.getcwd(),
                                                 'lib' + name + '.rlib')
                        if not os.path.exists(rlib_path):
                            rlib_path = ''
                    if rlib_path:
                        out += ['--extern', name + '=' + rlib_path]
                    else:
                        newpath = os.path.join(d, 'lib' + name + '.dylib')
                        if apath != os.path.abspath(newpath) and os.path.exists(apath):
                            shutil.copy2(apath, newpath)
                        out += ['--extern', name + '=' + newpath]
                    i += 2
                    continue
                if path.endswith('.rlib') or path.endswith('.rmeta'):
                    # darwin port: rlib 文件名必须是 lib<name>.rlib 形式,
                    # 否则 transitive 依赖 (rustix->libc_errno 等) 的 -L 搜索失败
                    apath = os.path.abspath(path)
                    base = os.path.basename(apath)
                    if not base.startswith('lib' + name):
                        newpath = os.path.join(os.path.dirname(apath),
                                               'lib' + name + '.rlib')
                        if os.path.exists(apath):
                            shutil.copy2(apath, newpath)
                        out += ['--extern', name + '=' + newpath]
                    else:
                        out += ['--extern', name + '=' + path]
                    i += 2
                    continue
        out.append(a)
        i += 1
    return out


def exec_formatted_command(args):
    remaining_args = args.args

    ldflags_index = remaining_args.index("LDFLAGS")
    rustenv_index = remaining_args.index("RUSTENV", ldflags_index)
    rustc_args = remaining_args[:ldflags_index]
    # darwin port: rustdeps 的裸 sysroot 目录 (gn 探测 cc sysroot 产生), rustc 不需要
    rustc_args = [a for a in rustc_args if not (os.path.isabs(a) and os.path.isdir(a))]
    # darwin port: 无 shell 环境, 还原 shell 转义的引号
    rustc_args = [a.replace('\\"', '"') for a in rustc_args]
    ldflags = remaining_args[ldflags_index + 1:rustenv_index]
    rustenv = remaining_args[rustenv_index + 1:]
    for arg in ldflags:
        if "cfi.versionscript" not in arg:
            rustc_args.append("-Clink-arg=%s" % arg)
    # darwin port: clippy-driver 吞掉 --cfg, 裸 feature="..." 参数会当 input, 直接删除
    rustc_args = [arg for arg in rustc_args if not arg.startswith('feature=')]
    # darwin port: proc-macro 依赖改为 -L 目录 + lib<name>.dylib
    rustc_args = convert_proc_macro_externs(rustc_args)
    fill_dependency_rlibs(rustc_args)
    if args.rsp:
        flags = os.O_WRONLY
        modes = stat.S_IWUSR | stat.S_IRUSR
        with open(args.rsp) as rspfile:
            rsp_content = [l.rstrip() for l in rspfile.read().split() if l.rstrip()]
        # darwin port: 过滤裸 sysroot 路径 (gn 探测 cc sysroot 产生, rustc 不需要)
        rsp_content = [l for l in rsp_content
                       if l.startswith('-') or '=' in l or l in ('proc_macro',)]
        rsp_content = convert_proc_macro_externs(rsp_content)
        with open(args.rsp, 'w') as rspfile:
            rspfile.write("\n".join(rsp_content))
        rustc_args.append(f'@{args.rsp}')

    env = os.environ.copy()
    fixed_env_vars = []
    for item in rustenv:
        (key, value) = item.split("=", 1)
        env[key] = value
        fixed_env_vars.append(key)

    # darwin port: darwin clippy-driver 注入 --cfg feature="cargo-clippy" 时拆引号
    # 导致 rustc 报 multiple input filenames, 直接使用 rustc 编译
    rustc_args.append("-A")
    rustc_args.append("unknown-lints")
    rustc_args.append("-C")
    rustc_args.append("link-arg=-Wno-error=unused-command-line-argument")
    if os.environ.get('RUSTC_WRAPPER_DEBUG'):
        with open('/tmp/wrapper_debug.txt', 'a') as f:
            f.write('ARGS: ' + ' |'.join(rustc_args) + '\n')
    ret = subprocess.run([args.rustc, *rustc_args], env=env, check=False)
    if ret.returncode != 0:
        sys.exit(ret.returncode)

    if args.depfile is not None:
        env_dep_re = re.compile("# env-dep:(.*)=.*")
        replacement_lines = []
        dirty = False
        with open(args.depfile, encoding="utf-8") as depfile:
            for line in depfile:
                matched = env_dep_re.match(line)
                if matched and matched.group(1) in fixed_env_vars:
                    dirty = True
                else:
                    replacement_lines.append(line)
        if dirty:
            with build_utils.atomic_output(args.depfile) as output:
                output.write("\n".join(replacement_lines).encode("utf-8"))
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--clippy-driver',
                        required=True,
                        type=pathlib.Path)
    parser.add_argument('--rustc',
                        required=True,
                        type=pathlib.Path)
    parser.add_argument('--depfile',
                        type=pathlib.Path)
    parser.add_argument('--rsp',
                        type=pathlib.Path)
    parser.add_argument('--strip',
                        help='The strip binary to run',
                        metavar='PATH')
    parser.add_argument('--unstripped-file',
                        help='Executable file produced by linking command',
                        metavar='FILE')
    parser.add_argument('--output',
                        help='Final output executable file',
                        metavar='FILE')
    parser.add_argument('--mini-debug',
                        action='store_true',
                        default=False,
                        help='Add .gnu_debugdata section for stripped sofile')
    parser.add_argument('--clang-base-dir', help='')

    parser.add_argument('args', metavar='ARG', nargs='+')

    args = parser.parse_args()

    result = exec_formatted_command(args)
    if result != 0:
        return result
    if args.strip:
        result = rust_strip.do_strip(args.strip, args.output, args.unstripped_file, args.mini_debug,
            args.clang_base_dir)
    return result


if __name__ == '__main__':
    sys.exit(main())
