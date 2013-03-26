#!/bin/sh
set -e
set -x
BUILD=/mnt/build
PATH=$BUILD/u-boot/tools:$PATH
TOOLS=arm-linux-gnueabi-
REPO=beagleboard
BRANCH=3.8
node --version || true
date
time git clone git://github.com/$REPO/kernel.git $BUILD/kernel
time git clone git://github.com/jadonk/u-boot.git $BUILD/u-boot
time git clone git://github.com/jadonk/am33x-cm3.git $BUILD/am33x-cm3
cd $BUILD/u-boot
time make -j16 tools
cd $BUILD/kernel
time git checkout $BRANCH
git show
date
time ./patch.sh
date
cp $BUILD/kernel/configs/beaglebone $BUILD/kernel/kernel/arch/arm/configs/beaglebone_defconfig
cp $BUILD/am33x-cm3/bin/am335x-pm-firmware.bin $BUILD/kernel/kernel/firmware/am335x-pm-firmware.bin
mkdir -p $BUILD/kernel/kernel/rootfs
cd $BUILD/kernel/kernel
time make ARCH=arm CROSS_COMPILE=$TOOLS beaglebone_defconfig
time make ARCH=arm CROSS_COMPILE=$TOOLS -j16 uImage
time make ARCH=arm CROSS_COMPILE=$TOOLS -j16 dtbs
time make ARCH=arm CROSS_COMPILE=$TOOLS -j16 modules
time make ARCH=arm CROSS_COMPILE=$TOOLS INSTALL_MOD_PATH=$BUILD/kernel/kernel/rootfs modules_install
time make ARCH=arm CROSS_COMPILE=$TOOLS uImage-dtb.am335x-bone
time make ARCH=arm CROSS_COMPILE=$TOOLS uImage-dtb.am335x-boneblack
cd $BUILD/kernel/kernel/rootfs
time tar -cvzf modules.tgz lib
cd $BUILD/kernel/kernel/arch/arm/boot/dts
time tar -cvzf dtb.tgz *.dtb
cd $BUILD/kernel
time tar -cvzf kernel-sources.tgz kernel
date
echo !!!! COMPLETED build-kernel.sh !!!!
