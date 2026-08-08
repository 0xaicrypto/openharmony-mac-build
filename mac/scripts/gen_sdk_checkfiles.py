#!/usr/bin/env python3
"""为 SDK innerkits 接口检查重新生成 check.txt (从 out 输出目录)。

原因: OpenHarmony 仓库随附的 interface/innersdk/native/**/check.txt 是头文件
sha256 清单, 本移植树的仓库内容不完整。check.txt 必须与构建输出目录
(out/arm64_virt/innerkits/ohos-arm64/<origin>/<module>) 中的实际头文件一致,
因此需要在每次 gn gen + 头拷贝后重新生成。

用法: python3 gen_sdk_checkfiles.py [OUT_DIR]  (默认 out/arm64_virt)
"""
import glob
import hashlib
import json
import os
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else 'out/arm64_virt'
CHECK_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..',
                         'interface', 'innersdk', 'native')


def get_header_files(module_dir):
    files = []
    for root, _dirs, fs in os.walk(module_dir):
        for f in fs:
            if f.endswith('.h'):
                files.append(os.path.relpath(os.path.join(root, f), module_dir))
    return sorted(files)


def main():
    generated = 0
    for desc in glob.glob(os.path.join(OUT, 'obj', 'out', OUT.split('/')[-1],
                                       'build_configs', '**', '*_sdk_desc.json'),
                          recursive=True):
        try:
            entries = json.load(open(desc))
        except Exception:
            continue
        for e in entries:
            if e.get('type') != 'so':
                continue
            origin = e.get('origin_name')
            module = e.get('name')
            module_dir = os.path.join(OUT, 'innerkits', 'ohos-arm64', origin, module)
            if not os.path.isdir(module_dir):
                continue
            headers = get_header_files(module_dir)
            if not headers:
                continue
            lines = []
            for h in headers:
                sha = hashlib.sha256(
                    open(os.path.join(module_dir, h), 'rb').read()).hexdigest()
                lines.append(f'{h} {sha}')
            cf = os.path.join(CHECK_DIR, origin, module, 'check.txt')
            os.makedirs(os.path.dirname(cf), exist_ok=True)
            open(cf, 'w').write('\n'.join(lines))
            generated += 1
    print(f"regenerated {generated} check.txt")


if __name__ == '__main__':
    main()
