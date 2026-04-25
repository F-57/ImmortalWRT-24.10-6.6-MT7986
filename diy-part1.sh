#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# 自动查找luci-app-ttyd并清理，同时打印被修改的文件名
echo "--- Cleaning up luci-app-ttyd dependencies ---"
# 查找所有 Makefile，如果包含 +luci-app-ttyd 就打印并修改
find ./package ./feeds -name Makefile -type f -exec grep -l "+luci-app-ttyd" {} + | while read -r file; do
    echo "Patching: $file"
    sed -i -E 's/[[:space:]]*\+luci-app-ttyd([[:space:]]|$)//g' "$file"
done
# 修改完后必须清理 tmp 目录，否则编译索引不会更新
rm -rf tmp/
echo "--- All done! ---"
