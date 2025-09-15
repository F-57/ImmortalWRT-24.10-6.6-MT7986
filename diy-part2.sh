#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

#主机变量
WRT_IP="10.0.0.1"
WRT_NAME="AX6000"
CFG_FILE="./package/base-files/files/bin/config_generate"

#修改默认IP地址 修改默认主机名
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#wifi相关变量
WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
WIFI_SSID="Ax6000"
WIFI_PASS="cw010203"

#修改WIFI信道自动 WIFI名称 修改WIFI加密 修改WIFI密码
sed -i "s/channel=.*/channel='auto'/g" $WIFI_FILE
sed -i "s/ImmortalWrt/$WIFI_SSID/g" $WIFI_FILE
sed -i "s/encryption=.*/encryption='sae-mixed'/g" $WIFI_FILE
sed -i "/set wireless.default_\${dev}.encryption='sae-mixed'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$WIFI_PASS'" $WIFI_FILE

# 512布局
# 24.10-5.4内核：
# sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1ea00000>/' target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7986a-xiaomi-redmi-router-ax6000.dts
# 24.10-6.6内核：名字看似是ubootmod，实则做了分区修改可以uboot放心刷入
sed -i 's/reg = <0x600000 0x6e00000>/reg = <0x600000 0x1ea00000>/' target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts

# 常用软件
git clone https://github.com/sirpdboy/luci-app-taskplan package/luci-app-taskplan
sed -i 's/control/services/g' package/luci-app-taskplan/luci-app-taskplan/luasrc/controller/taskplan.lua
sed -i 's/control/services/g' package/luci-app-taskplan/luci-app-taskplan/luasrc/view/taskplan/log.htm

