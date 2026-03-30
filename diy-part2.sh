#!/bin/bash

# --- 主机变量设置 ---
WRT_IP="10.0.0.1"
WRT_NAME="AX6000"
CFG_FILE="package/base-files/files/bin/config_generate"

# 修改默认 IP 地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE

# 修改默认主机名 (兼容不同源码格式)
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
sed -i "s/set system.@system\[0\].hostname=.*/set system.@system[0].hostname='$WRT_NAME'/g" $CFG_FILE


# --- Wi-Fi 相关设置 (闭源驱动 mtwifi) ---
WIFI_FILE="package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
WIFI_SSID="Ax6000"
WIFI_PASS="cw010203"

if [ -f "$WIFI_FILE" ]; then
    # 修改 Wi-Fi 信道为自动
    sed -i "s/channel=.*/channel='auto'/g" $WIFI_FILE
    # 修改默认 SSID (将默认的 ImmortalWrt 替换为你的变量)
    sed -i "s/ImmortalWrt/$WIFI_SSID/g" $WIFI_FILE
    # 修改加密方式为 WPA3/WPA2 混合 (sae-mixed)
    sed -i "s/encryption=.*/encryption='sae-mixed'/g" $WIFI_FILE
    # 在加密方式行后插入 Wi-Fi 密码
    sed -i "/set wireless.default_\${dev}.encryption='sae-mixed'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$WIFI_PASS'" $WIFI_FILE
    echo "Wi-Fi configuration updated."
fi


# --- 512MB 大分区布局适配 (ubootmod) ---
# 针对 6.6 内核及更高版本：将起始地址设为 0x600000，长度设为 490MB (0x1ea00000)
DTS_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts"

if [ -f "$DTS_FILE" ]; then
    # 只要是包含 "ubi" 标签的分区块，都强制修正为 6MB 起始 + 490MB 长度
    sed -i '/label = "ubi"/,/reg =/ s/reg = <0x[0-9a-fA-F]* 0x[0-9a-fA-F]*>/reg = <0x600000 0x1ea00000>/' $DTS_FILE
fi

# 修复Coremark编译失败
sed -i 's/\tmkdir/\tmkdir -p/g' feeds/packages/utils/coremark/Makefile

# Theme
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
git clone https://github.com/sbwml/luci-theme-argon -b openwrt-24.10 package/argon

# adguardhome
git clone https://github.com/F-57/luci-app-adguardhome package/luci-app-adguardhome

# 安装 luci-app-openlist2 
git clone https://github.com/sbwml/luci-app-openlist2 package/openlist

# 安装隔空播放luci-app-airconnect
git clone https://github.com/sbwml/luci-app-airconnect package/airconnect

# 安装lucky
git clone https://github.com/sirpdboy/luci-app-lucky package/lucky

# 安装OpenClash
git clone --depth 1 https://github.com/vernesong/openclash.git OpenClash
rm -rf feeds/luci/applications/luci-app-openclash
mv OpenClash/luci-app-openclash feeds/luci/applications/luci-app-openclash

# 更改菜单名字
echo -e "\nmsgid \"OpenList\"" >> package/openlist/luci-app-openlist2/po/zh_Hans/openlist2.po
echo -e "msgstr \"聚合网盘\"" >> package/openlist/luci-app-openlist2/po/zh_Hans/openlist2.po

echo -e "\nmsgid \"Lucky\"" >> package/lucky/luci-app-lucky/po/zh_Hans/lucky.po
echo -e "msgstr \"大吉大利\"" >> package/lucky/luci-app-lucky/po/zh_Hans/lucky.po

echo -e "\nmsgid \"OpenClash\"" >> feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po
echo -e "msgstr \"科学上网\"" >> feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po

#echo -e "\nmsgid \"UPnP IGD & PCP\"" >> feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po
#echo -e "msgstr \"即插即用\"" >> feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po

# 软件包与配置
echo "CONFIG_LUCI_LANG_en=y" >> .config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> .config

echo "CONFIG_PACKAGE_luci-app-upnp=y" >> .config
echo "CONFIG_PACKAGE_luci-app-argon=y" >> .config
echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> .config
echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> .config
echo "CONFIG_PACKAGE_luci-app-airconnect=y" >> .config
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
echo "CONFIG_PACKAGE_luci-app-openlist2=y" >> .config
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> .config

# 注入编译加速选项
echo "CONFIG_CCACHE=y" >> .config
echo "CONFIG_KERNEL_DEBUG_INFO=n" >> .config
echo "CONFIG_OPENSSL_OPTIMIZE_SPEED=y" >> .config
