include $(TOPDIR)/rules.mk

LUCI_TITLE:=Meta 配置与服务管理面板
LUCI_DESCRIPTION:=mihomo(Clash.Meta) 配置与服务轻量管理面板
LUCI_DEPENDS:=+luci-base +mihomo +rpcd +jshn +jsonfilter +curl
LUCI_PKGARCH:=all

PKG_LICENSE:=MIT
PKG_NAME:=luci-app-meta
PKG_VERSION:=1.0
PKG_RELEASE:=1

# 允许外部环境变量或 SDK 覆盖版本号
ifneq ($(LUCI_META_VERSION),)
  PKG_VERSION:=$(LUCI_META_VERSION)
endif

define Build/Prepare/luci-app-meta
	chmod 0755 $(PKG_BUILD_DIR)/root/usr/libexec/rpcd/luci.mihomo \
		$(PKG_BUILD_DIR)/root/usr/libexec/mihomo-panel-worker
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
