#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 更改默认IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

#添加软件包
rm -rf feeds/luci/applications/luci-app-openclash
git clone -b master --single-branch --filter=blob:none https://github.com/vernesong/OpenClash.git feeds/luci/applications/luci-app-openclash

#修改sysguarde备份列表
mkdir -p files/etc

cat <<EOF > files/etc/sysupgrade.conf
## This file contains files and directories that should
## be preserved during an upgrade.

# /etc/example.conf
# /etc/openvpn/
/www/luci-static/argon/background/
/root/backup_openwrt.sh
/root/sshpass
EOF

chmod 0644 files/etc/sysupgrade.conf

# 修改固件MD5值
# 生成VerMagic文件
echo "c5f84ade92103ce978361a1c59890df1" > vermagic
# 检查VerMagic文件是否生成成功
if [ ! -f "vermagic" ]; then
    echo "VerMagic文件生成失败！"
    exit 1
fi

# 修改include/kernel-defaults.mk
# 设置变量
pattern="grep '=[ym]' \$(LINUX_DIR)/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)/.vermagic"
replacement="cp \$(TOPDIR)/vermagic \$(LINUX_DIR)/.vermagic"
# 对pattern中的特殊字符进行转义处理
escaped_pattern=$(printf '%s\n' "$pattern" | sed -e 's/[][\/$*.^|[]/\\&/g')
# 使用sed命令替换整段语句
sed -i "s|$escaped_pattern|$replacement|g" include/kernel-defaults.mk
# 检查替换是否成功
if [ $? -ne 0 ]; then
    echo "include/kernel-defaults.mk 替换失败！"
    exit 1
fi

# 修改package/kernel/linux/Makefile
sed -i 's/STAMP_BUILT:=$(STAMP_BUILT)_$(shell $(SCRIPT_DIR)\/kconfig.pl $(LINUX_DIR)\/.config | $(MKHASH) md5)/STAMP_BUILT:=$(STAMP_BUILT)_$(shell cat $(LINUX_DIR)\/.vermagic)/g' package/kernel/linux/Makefile
# 检查替换是否成功
if [ $? -ne 0 ]; then
    echo "package/kernel/linux/Makefile 替换失败！"
    exit 1
fi

# 输出成功信息
echo "替换成功！"
