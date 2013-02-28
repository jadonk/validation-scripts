#!/bin/sh
set -x
set -e
export SLOTS=/sys/devices/bone_capemgr.8/slots
export PINS=/sys/kernel/debug/pinctrl/44e10800.pinmux/pins
dtc -O dtb -o pinctrl-test-7-00A0.dtbo -b 0 -@ pinctrl-test-7.dts
dtc -O dtb -o pinctrl-test-0-00A0.dtbo -b 0 -@ pinctrl-test-0.dts
cp pinctrl-test-7-00A0.dtbo /lib/firmware/
cp pinctrl-test-0-00A0.dtbo /lib/firmware/
cat $SLOTS
echo pinctrl-test-7 > $SLOTS
dmesg | tail
cat $SLOTS
cat $PINS | grep 964
A=`perl -pe 's/^.*(\d+):.*/$1/' $SLOTS | tail -1`
echo "-$A"
echo "-$A" > $SLOTS
dmesg | tail
echo pinctrl-test-0 > $SLOTS
dmesg | tail
cat $PINS | grep 964
