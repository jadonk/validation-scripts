#!/bin/sh
set -e
set -x
PATH=/usr/local/angstrom/arm/bin:/mnt/u-boot/tools:$PATH
node --version
git clone git://github.com/jadonk/kernel.git /mnt/build/kernel
git clone git://github.com/jadonk/u-boot.git /mnt/build/u-boot
git clone git://github.com/jadonk/am33x-cm3.git /mnt/build/am33x-cm3
cd /mnt/build/u-boot
make -j16 tools
cd /mnt/build/kernel
git checkout 3.2
./patch.sh
cp configs/beaglebone kernel/arch/arm/configs/beaglebone_defconfig
cp /mnt/am33x-cm3/bin/am335x-pm-firmware.bin kernel/firmware/am335x-pm-firmware.bin
cd kernel
mkdir rootfs
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- beaglebone_defconfig
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- -j16 uImage dtbs
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- -j16 modules
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- INSTALL_MOD_PATH=$HOME/kernel/kernel/rootfs modules_install
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- uImage-dtb.am335x-bone
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- uImage-dtb.am335x-bonelt
