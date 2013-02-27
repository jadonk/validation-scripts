#!/bin/sh
set -e
set -x
PATH=/usr/local/angstrom/arm/bin:$PATH
git clone git://github.com/jadonk/kernel.git /mnt/kernel
git config --global user.name "Jason Kridner"
git config --global user.email jdk@ti.com
cd /mnt/kernel
git checkout 3.8
./patch.sh
cp configs/beaglebone kernel/arch/arm/configs/beaglebone_defconfig
wget http://arago-project.org/git/projects/?p=am33x-cm3.git\;a=blob_plain\;f=bin/am335x-pm-firmware.bin\;hb=HEAD -O kernel/firmware/am335x-pm-firmware.bin
cd kernel
mkdir rootfs
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- beaglebone_defconfig
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- -j4 uImage dtbs
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- -j4 modules
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- INSTALL_MOD_PATH=$HOME/kernel/kernel/rootfs modules_install
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- uImage-dtb.am335x-bone
make ARCH=arm CROSS_COMPILE=arm-angstrom-linux-gnueabi- uImage-dtb.am335x-bonelt
