#!/bin/bash
# --- 基础系统设置 (IP/主机名) ---
CFG_FILE="package/base-files/files/bin/config_generate"
WRT_IP="10.0.0.1"
WRT_NAME="AX6000"

if [ -f "$CFG_FILE" ]; then
    # 修改默认 IP 地址
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
    # 修改默认主机名
    sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
    sed -i "s/set system.@system\[0\].hostname=.*/set system.@system[0].hostname='$WRT_NAME'/g" $CFG_FILE    
    echo "基本配置已更新."
fi

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
    echo "Wi-Fi 配置已更新."
fi

# --- 512MB 大分区布局适配 (ubootmod) ---
# 针对 6.6 内核及更高版本：将起始地址设为 0x600000，长度设为 490MB (0x1ea00000)
DTS_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts"

if [ -f "$DTS_FILE" ]; then
    # 只要是包含 "ubi" 标签的分区块，都强制修正为 6MB 起始 + 490MB 长度
    sed -i '/label = "ubi"/,/reg =/ s/reg = <0x[0-9a-fA-F]* 0x[0-9a-fA-F]*>/reg = <0x600000 0x1ea00000>/' $DTS_FILE
    echo "512MB 大分区布局."
fi

# 修复Coremark编译失败
sed -i 's/\tmkdir/\tmkdir -p/g' feeds/packages/utils/coremark/Makefile

# Theme
git clone https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
git clone https://github.com/sirpdboy/luci-app-kucat-config package/luci-app-kucat-config

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

# 安装 mosdns
# 需要 Go 语言 1.26.x 或更高版本
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
git clone https://github.com/sbwml/luci-app-mosdns -b openwrt-21.02 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata


# 更改菜单名字
echo -e "\nmsgid \"KuCat Config\"" >> package/luci-app-kucat-config/po/zh_Hans/kucat-config.po
echo -e "msgstr \"主题设置\"" >> package/luci-app-kucat-config/po/zh_Hans/kucat-config.po

echo -e "\nmsgid \"OpenList\"" >> package/openlist/luci-app-openlist2/po/zh_Hans/openlist2.po
echo -e "msgstr \"聚合网盘\"" >> package/openlist/luci-app-openlist2/po/zh_Hans/openlist2.po

echo -e "\nmsgid \"Lucky\"" >> package/lucky/luci-app-lucky/po/zh_Hans/lucky.po
echo -e "msgstr \"大吉大利\"" >> package/lucky/luci-app-lucky/po/zh_Hans/lucky.po

echo -e "\nmsgid \"OpenClash\"" >> feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po
echo -e "msgstr \"科学上网\"" >> feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po

echo -e "\nmsgid \"MosDNS\"" >> package/mosdns/luci-app-mosdns/po/zh_Hans/mosdns.po
echo -e "msgstr \"转发分流\"" >> package/mosdns/luci-app-mosdns/po/zh_Hans/mosdns.po

echo -e "\nmsgid \"UPnP IGD & PCP\"" >> feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po
echo -e "msgstr \"即插即用\"" >> feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po

echo -e "\nmsgid \"MultiWAN Manager\"" >> feeds/luci/applications/luci-app-mwan3/po/zh_Hans/mwan3.po
echo -e "msgstr \"负载均衡\"" >> feeds/luci/applications/luci-app-mwan3/po/zh_Hans/mwan3.po

# 软件包与配置
echo "CONFIG_LUCI_LANG_en=y" >> .config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> .config

echo "CONFIG_PACKAGE_luci-app-upnp=y" >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y" >> .config
echo "CONFIG_PACKAGE_luci-app-mwan3=y" >> .config

echo "CONFIG_PACKAGE_luci-app-argon=y" >> .config
echo "CONFIG_PACKAGE_luci-theme-kucat=y" >> .config
echo "CONFIG_PACKAGE_luci-app-kucat-config=y" >> .config
echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> .config
echo "CONFIG_PACKAGE_luci-app-airconnect=y" >> .config
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
echo "CONFIG_PACKAGE_luci-app-openlist2=y" >> .config
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> .config
echo "CONFIG_PACKAGE_luci-app-mosdns=y" >> .config

# 性能与体积优化
echo "CONFIG_KERNEL_DEBUG_INFO=n" >> .config
echo "CONFIG_OPENSSL_OPTIMIZE_SPEED=y" >> .config
# 既然是 AX6000 512MB 版，建议再加一个提高插件运行效率的
echo "CONFIG_STRIP_KERNEL_EXPORTS=y" >> .config
