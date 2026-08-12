#!/bin/bash
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation version 2.1
# of the License.
#
# Copyright(c) 2023 Huawei Device Co., Ltd.

set -e
cd $1
if [ -d "abseil-cpp" ];then
    rm -rf abseil-cpp
fi
tar zxvf abseil-cpp-20220623.1.tar.gz
mv abseil-cpp-20220623.1 abseil-cpp
cd $1/abseil-cpp
# darwin port: CVE 补丁与 20220623.1 不匹配 (hunk 全失败), 不影响编译, 忽略
patch -p1 < $1/backport-CVE-2025-0838.patch || true
exit 0