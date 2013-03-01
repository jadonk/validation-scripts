#!/bin/sh
set -e
set -x
BUILD=/mnt/build
PATH=$BUILD/u-boot/tools:$PATH
TOOLS=arm-linux-gnueabi-
node --version
git clone git://github.com/jadonk/kernel.git $BUILD/kernel
git clone git://github.com/jadonk/u-boot.git $BUILD/u-boot
git clone git://github.com/jadonk/am33x-cm3.git $BUILD/am33x-cm3
cd $BUILD/u-boot
make -j16 tools
cd $BUILD/kernel
git checkout beaglebone-3.2
./patch.sh
cp $BUILD/kernel/configs/beaglebone $BUILD/kernel/kernel/arch/arm/configs/beaglebone_defconfig
cp $BUILD/am33x-cm3/bin/am335x-pm-firmware.bin $BUILD/kernel/kernel/firmware/am335x-pm-firmware.bin
mkdir -p $BUILD/kernel/kernel/rootfs
cd $BUILD/kernel/kernel
make ARCH=arm CROSS_COMPILE=$TOOLS beaglebone_defconfig
make ARCH=arm CROSS_COMPILE=$TOOLS -j16 uImage dtbs
make ARCH=arm CROSS_COMPILE=$TOOLS -j16 modules
make ARCH=arm CROSS_COMPILE=$TOOLS INSTALL_MOD_PATH=$BUILD/kernel/kernel/rootfs modules_install
make ARCH=arm CROSS_COMPILE=$TOOLS uImage-dtb.am335x-bone
make ARCH=arm CROSS_COMPILE=$TOOLS uImage-dtb.am335x-bonelt
cd $BUILD/kernel/kernel/rootfs
tar -cvzf modules.tgz lib
