#!/bin/sh
PREFIX="/home/lvniqi/桌面/openwrt/main"
ARCH=mips
KSRC="$PREFIX/build_dir/target-mips_34kc_uClibc-0.9.33.2/linux-ar71xx_generic/linux-3.18.7"
STAGING_DIR="$PREFIX/staging_dir"
TOOLCHAIN_DIR="$STAGING_DIR/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/bin"
CROSS_COMPILE="mips-openwrt-linux-"
 
export STAGING_DIR=$STAGING_DIR
export PATH=$TOOLCHAIN_DIR:$PATH
make clean
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE KSRC=$KSRC
