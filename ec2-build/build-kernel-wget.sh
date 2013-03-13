#!/bin/sh
wget $1/build.log
wget $1/kernel/kernel/rootfs/modules.tgz
wget $1/kernel/kernel/arch/arm/boot/uImage
wget $1/kernel/kernel/arch/arm/boot/uImage-dtb.am335x-bone
wget $1/kernel/kernel/arch/arm/boot/uImage-dtb.am335x-bonelt
wget $1/kernel/kernel/arch/arm/boot/dts/dtb.tgz
