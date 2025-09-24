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

# Theme
git clone https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat

# 主题高级设置
git clone https://github.com/sirpdboy/luci-app-advancedplus package/luci-app-advancedplus

# adguardhome
git clone https://github.com/sirpdboy/luci-app-adguardhome package/luci-app-adguardhome

# 安装 mosdns
rm -rf feeds/packages/lang/golang
rm -rf feeds/packages/net/mosdns
rm -rf package/feeds/packages/mosdns
rm -rf feeds/packages/net/v2ray-geodata
rm -rf package/feeds/packages/v2ray-geodata
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# 安装 luci-app-openlist2 
git clone https://github.com/sbwml/luci-app-openlist2 package/openlist

# 安装隔空播放luci-app-airconnect
git clone https://github.com/sbwml/luci-app-airconnect package/airconnect

# 安装lucky
git clone https://github.com/sirpdboy/luci-app-lucky package/lucky

# 安装 OpenClash
git clone --depth 1 https://github.com/vernesong/openclash.git OpenClash
rm -rf feeds/luci/applications/luci-app-openclash
mv OpenClash/luci-app-openclash feeds/luci/applications/luci-app-openclash

# 更改菜单名字
echo -e "\nmsgid \"OpenClash\"" >> feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po
echo -e "msgstr \"科学上网\"" >> feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po

echo -e "\nmsgid \"MosDNS\"" >> package/mosdns/luci-app-mosdns/po/zh_Hans/mosdns.po
echo -e "msgstr \"转发分流\"" >> package/mosdns/luci-app-mosdns/po/zh_Hans/mosdns.po

echo -e "\nmsgid \"Lucky\"" >> package/lucky/luci-app-lucky/po/zh_Hans/lucky.po
echo -e "msgstr \"大吉大利\"" >> package/lucky/luci-app-lucky/po/zh_Hans/lucky.po

echo -e "\nmsgid \"OpenList\"" >> package/openlist/luci-app-openlist2/po/zh_Hans/openlist2.po
echo -e "msgstr \"聚合网盘\"" >> package/openlist/luci-app-openlist2/po/zh_Hans/openlist2.po

echo -e "\nmsgid \"UPnP IGD & PCP\"" >> feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po
echo -e "msgstr \"即插即用\"" >> feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po

echo -e "\nmsgid \"AdGuardHome\"" >> package/luci-app-adguardhome/luci-app-adguardhome/po/zh_Hans/adguardhome.po
echo -e "msgstr \"DNS过滤\"" >> package/luci-app-adguardhome/luci-app-adguardhome/po/zh_Hans/adguardhome.po

# 软件包与配置
echo "CONFIG_CCACHE=y" >> .config
echo "CONFIG_PACKAGE_luci-theme-kucat=y" >> .config
echo "CONFIG_PACKAGE_luci-app-advancedplus=y" >> .config
#echo "CONFIG_PACKAGE_luci-app-openlist2=y" >> .config
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
#echo "CONFIG_PACKAGE_luci-app-mosdns=y" >> .config
#echo "CONFIG_PACKAGE_luci-app-lucky=y" >> .config
echo "CONFIG_PACKAGE_luci-app-airconnect=y" >> .config
#echo "CONFIG_PACKAGE_luci-app-wechatpush=y" >> .config
echo "CONFIG_PACKAGE_luci-app-upnp=y" >> .config
echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> .config
