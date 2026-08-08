#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (c) 2023 Huawei Device Co., Ltd.
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

import argparse
import sys
import subprocess
import shutil
import os


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--kernel-dir', help='kerner dir')
    parser.add_argument('--kernel-out-dir', help='header file out dir')
    parser.add_argument('--target-cpu', help='target cpu')
    parser.add_argument('--kernel-tools-dir', help='kernel tools dir')
    options = parser.parse_args()
    make_tools_inc_dir = os.path.join(options.kernel_out_dir, 'bpf')
    if not os.path.exists(make_tools_inc_dir):
        shutil.copytree(options.kernel_tools_dir, make_tools_inc_dir)
    make_uapi_cmd = ['make', '-C', options.kernel_dir, '-sj', 'headers',
                     'O={}'.format(options.kernel_out_dir),
                     'ARCH={}'.format(options.target_cpu)]
    make_tools_uapi_cmd = ['make', '-C', options.kernel_tools_dir,
                           'O={}'.format(make_tools_inc_dir),
                           'ARCH={}'.format(options.target_cpu)]
    env = os.environ.copy()
    if sys.platform == 'darwin':
        env['CFLAGS'] = '{} -I/opt/homebrew/opt/libelf/include -I/opt/homebrew/opt/libelf/include/libelf'.format(env.get('CFLAGS', ''))
        env['LDFLAGS'] = '{} -L/opt/homebrew/opt/libelf/lib'.format(env.get('LDFLAGS', ''))
        env['LIBS'] = '{} -lelf'.format(env.get('LIBS', ''))
        env['LDLIBS'] = '{} -lelf'.format(env.get('LDLIBS', ''))
    subprocess.run(make_uapi_cmd, env=env, check=True)
    if sys.platform == 'darwin':
        bpf_helpers_dir = os.path.join(options.kernel_out_dir, 'bpf')
        bpf_helpers_defs = os.path.join(bpf_helpers_dir, 'bpf_helper_defs.h')
        if not os.path.exists(bpf_helpers_defs):
            with open(bpf_helpers_defs, 'w') as f:
                subprocess.run(
                    [os.path.join(options.kernel_dir, 'scripts/bpf_helpers_doc.py'),
                     '--header',
                     '--file', os.path.join(options.kernel_dir, 'tools/include/uapi/linux/bpf.h')],
                    stdout=f, check=True)
    else:
        subprocess.run(make_tools_uapi_cmd, env=env, check=True)

if __name__ == '__main__':
    sys.exit(main())
