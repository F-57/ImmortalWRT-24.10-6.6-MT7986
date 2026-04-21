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

# 定义文件路径
DTS_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts"
DTSI_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000.dtsi"

# --- 1. 512MB 闪存大分区布局适配 (修改 .dts) ---
if [ -f "$DTS_FILE" ]; then
    # 修正 UBI 分区起始地址为 6MB (0x600000)，长度扩展为 490MB (0x1ea00000)
    sed -i '/partition@600000/,/};/ { /reg =/ s/<0x[0-9a-fA-F]* 0x[0-9a-fA-F]*>/<0x600000 0x1ea00000>/; }' "$DTS_FILE"
    echo "Flash: 已成功修改 .dts 文件，适配 512MB 闪存布局。"
else
    echo "警告: 未找到 $DTS_FILE，请检查路径。"
fi

# --- 2. 1GB 内存适配 (修改 .dtsi) ---
if [ -f "$DTSI_FILE" ]; then
    # 将 memory 块中的长度从 512MB (0x20000000) 修正为 1GB (0x40000000)
    sed -i 's/<0 0x40000000 0 0x20000000>/<0 0x40000000 0 0x40000000>/g' $DTSI_FILE
    echo "RAM: 已成功修改 .dtsi 文件，适配 1GB 内存。"
    sed -i 's/mediatek,mtd-eeprom = <&factory 0x0>;/mediatek,mtd-eeprom = <&factory 0x0000>, <&factory 0x8000>;/g' "$DTSI_FILE"
    echo "WiFi: 5G EEPROM 偏移量 (0x8000) 修正完成。"
    sed -i '/bootargs =/ s/";/ swiotlb=512";/' "$DTSI_FILE"
    echo "Kernel: 已添加 swiotlb=512 参数。"
else
    echo "警告: 未找到 $DTSI_FILE，请检查路径。"
fi

# 进入 turboacc 插件目录，强行删除对 luci-app-ttyd 的依赖要求
sed -i 's/+luci-app-ttyd//g' package/mtk/applications/luci-app-turboacc-mtk/Makefile

# 删除系统预制包
rm -rf feeds/luci/themes/luci-theme-argon

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mkdir -p ../package
  for dir in "$@"; do
    rm -rf "../package/$dir"
    mv -f "$dir" ../package/
  done
  cd ..
  rm -rf "$repodir"
}

# --- 插件集成 ---
git_sparse_clone main https://github.com/F-57/luci-app luci-app-adguardhome airconnect luci-app-airconnect
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth 1 https://github.com/papagaye744/luci-theme-design package/luci-theme-design

# 更改菜单名字 参数1是文件路径，参数2是原始文字，参数3是目标文字
change_name() {
    local file=$1
    local id=$2
    local str=$3
    if [ -f "$file" ]; then
        # 匹配 msgid 后的下一行 msgstr 并进行替换
        sed -i "/msgid \"$id\"/{n;s/msgstr \".*\"/msgstr \"$str\"/}" "$file"
        echo "已修改 $id 为 $str"
    else
        echo "跳过：未找到文件 $file"
    fi
}

change_name "feeds/luci/modules/luci-base/po/zh_Hans/base.po" "Processes" "系统进程"
change_name "feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po" "UPnP IGD & PCP" "端口映射"

# 修改upnp服务地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" feeds/luci/applications/luci-app-upnp/htdocs/luci-static/resources/view/upnp/upnp.js

# 预置编译选项 (写入 .config)
cat >> .config <<EOF
CONFIG_CCACHE=y
CONFIG_KERNEL_DEBUG_INFO=n
CONFIG_OPENSSL_OPTIMIZE_SPEED=y
CONFIG_OPENSSL_kmod-mtd-rw=y
CONFIG_LUCI_LANG_en=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-design=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-app-airconnect=y
EOF
