#!/bin/bash
# --- 基础系统设置 (IP/主机名) ---
CFG_FILE="package/base-files/files/bin/config_generate"
WRT_IP="10.0.0.1"
WRT_NAME="Pdx_Network"

if [ -f "$CFG_FILE" ]; then
    # 修改默认 IP 地址
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
    # 修改默认主机名
    sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
    sed -i "s/set system.@system\[0\].hostname=.*/set system.@system[0].hostname='$WRT_NAME'/g" $CFG_FILE    
    echo "基本配置已更新."
fi

# --- Wi-Fi 相关设置 (闭源驱动 mtwifi) ---
WRT_SSID="Pdx_Network"
WRT_WORD="cw010203"
WIFI_FILE="package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"

if [ -f "$WIFI_FILE" ]; then
    sed -i "s/ImmortalWrt/$WRT_SSID/g" $WIFI_FILE
    sed -i "s/encryption=.*/encryption='sae-mixed'/g" $WIFI_FILE
    sed -i "/set wireless.default_\${dev}.encryption='sae-mixed'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$WRT_WORD'" $WIFI_FILE
    echo "Wi-Fi 相关设置已更新."
fi

# --- UPnP 服务设置 ---
UPNP_FILE="feeds/luci/applications/luci-app-upnp/htdocs/luci-static/resources/view/upnp/upnp.js"
if [ -f "$UPNP_FILE" ]; then
    # 修改 UPnP 默认服务地址
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $UPNP_FILE
    echo "UPnP 服务地址已更新."
fi

# 修改512存储
DTS_FILE="target/linux/mediatek/dts/mt7986a-xiaomi-redmi-router-ax6000-ubootmod.dts"
if [ -f "$DTS_FILE" ]; then
    sed -i '/partition@600000/,/};/ { /reg =/ s/<0x[0-9a-fA-F]* 0x[0-9a-fA-F]*>/<0x600000 0x1ea00000>/; }' "$DTS_FILE"
    echo "Flash: 已成功修改 .dts 文件，适配 512MB 闪存布局。"
else
    echo "警告: 未找到 $DTS_FILE，请检查路径。"
fi

# 删除系统预制包
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/packages/lang/golang
rm -rf feeds/packages/net/v2ray-geodata

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
git_sparse_clone main https://github.com/sirpdboy/luci-app-lucky lucky luci-app-lucky
git clone https://github.com/eamonxg/luci-theme-shadcn package/luci-theme-shadcn
git clone https://github.com/eamonxg/luci-theme-aurora package/luci-theme-aurora
git clone https://github.com/eamonxg/luci-app-aurora-config package/luci-app-aurora-config
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
git clone https://github.com/vernesong/openclash.git OpenClash
mv OpenClash/luci-app-openclash feeds/luci/applications/luci-app-openclash
rm -rf OpenClash

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
change_name "feeds/luci/applications/luci-app-openclash/po/zh-cn/openclash.zh-cn.po" "OpenClash" "科学上网"
change_name "package/luci-app-lucky/po/zh_Hans/lucky.po" "Lucky" "路由助手"
change_name "package/luci-app-aurora-config/po/zh_Hans/aurora-config.po" "Aurora Settings" "主题设置"
change_name "package/mosdns/luci-app-mosdns/po/zh_Hans/mosdns.po" "MosDNS" "域名分流"

#修复Rust编译失败
RUST_FILE=$(find feeds/packages/lang/rust/ -maxdepth 2 -type f -name "Makefile" 2>/dev/null)
if [ -f "$RUST_FILE" ]; then
	echo "Found Rust Makefile at $RUST_FILE, fixing..."
	sed -i 's/ci-llvm=true/ci-llvm=false/g' "$RUST_FILE"
	echo "Rust 编译问题已修复！"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find feeds/packages/net/tailscale/ -maxdepth 2 -type f -name "Makefile" 2>/dev/null)
if [ -f "$TS_FILE" ]; then
	echo "Found TailScale Makefile at $TS_FILE, fixing..."
	sed -i '/\/files/d' "$TS_FILE"
	echo "TailScale 配置文件冲突已修复！"
fi

# 强行替换 libffi 为官方上游最新修复版本，规避 24.10 分支通配符 Bug
rm -rf feeds/packages/libs/libffi
git clone https://github.com/openwrt/packages.git tmp_packages --depth=1
cp -r tmp_packages/libs/libffi feeds/packages/libs/libffi
rm -rf tmp_packages

# 预置编译选项 (写入 .config)
cat >> .config <<EOF
CONFIG_CCACHE=y
CONFIG_FEED_video=n
CONFIG_TARGET_ROOTFS_INITRAMFS=n
CONFIG_LUCI_LANG_en=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_kmod-mtd-rw=y
CONFIG_PACKAGE_luci-theme-shadcn=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-app-airconnect=y
CONFIG_PACKAGE_luci-app-mosdns=y
EOF
