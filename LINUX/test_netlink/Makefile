#
# Copyright (C) 2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=netlink_test
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/netlink_test
  SUBMENU:=DSO NETLINK TEST modules
  TITLE:=TEST NETLINK modules
  DEPENDS:=@TARGET_ar71xx
  FILES:=$(PKG_BUILD_DIR)/netlink_test.ko
  KCONFIG:=
  AUTOLOAD:=$(call AutoLoad,50,netlink_test)
endef

define KernelPackage/netlink_test/description
  DSO NETLINK TEST modules
endef

EXTRA_KCONFIG:= \
	CONFIG_NETLINK_TEST=m

EXTRA_CFLAGS:= \
	$(patsubst CONFIG_%, -DCONFIG_%=1, $(patsubst %=m,%,$(filter %=m,$(EXTRA_KCONFIG)))) \
	$(patsubst CONFIG_%, -DCONFIG_%=1, $(patsubst %=y,%,$(filter %=y,$(EXTRA_KCONFIG)))) \

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)" \
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	$(EXTRA_KCONFIG)

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,netlink_test))
