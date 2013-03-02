This is an example of using capemgr and devicetree overlays to configure
a pinmux on the BeagleBone. The same procedure could be followed to
load other drivers, but we should start with something simple.

We start by defining the two key sysfs entries we'll be using to check
the status. 'slots' is an interface to capemgr that enables us to tell
capemgr to load additional devicetree overlay fragments and for it to
tell us what it has already loaded. It designed to utilize the EEPROMs
on the cape plug-in boards to identify the board

	# export SLOTS=/sys/devices/bone_capemgr.8/slots
	# export PINS=/sys/kernel/debug/pinctrl/44e10800.pinmux/pins

Here is my first example devicetree overlay (pinmux-test-7.dts):

	/*
	 * Copyright (C) 2012 Texas Instruments Incorporated - http://www.ti.com/
	 *
	 * This program is free software; you can redistribute it and/or modify
	 * it under the terms of the GNU General Public License version 2 as
	 * published by the Free Software Foundation.
	 */
	/dts-v1/;
	/plugin/;
	
	/ {
		compatible = "ti,beaglebone", "ti,beaglebone-black";
	
		/* identification */
		part-number = "pinctrl-test-7";
	
		fragment@0 {
			target = <&am33xx_pinmux>;
			__overlay__ {
				pinctrl_test: pinctrl_test_7_pins {
					pinctrl-single,pins = <
						0x164 0x07	/* P9_42 muxRegOffset, OUTPUT | MODE7 */
					>;
				};
			};
		};
	
		fragment@1 {
			target = <&ocp>;
			__overlay__ {
				test_helper: helper {
					compatible = "bone-pinmux-helper";
					pinctrl-names = "default";
					pinctrl-0 = <&pinctrl_test>;
					status = "okay";
				};
			};
		};
	};

We'll compile the device tree fragments and install them in /lib/firmware.
Note that I'm doing this natively on the BeagleBone. I've pulled in the
kernel sources and simply built this tool natively.

	# dtc -O dtb -o pinctrl-test-7-00A0.dtbo -b 0 -@ pinctrl-test-7.dts
	# dtc -O dtb -o pinctrl-test-0-00A0.dtbo -b 0 -@ pinctrl-test-0.dts
	# cp pinctrl-test-7-00A0.dtbo /lib/firmware/
	# cp pinctrl-test-0-00A0.dtbo /lib/firmware/

Let's check out the starting point state.

	# cat $SLOTS
	 0: 54:PF--- 
	 1: 55:PF--- 
	 2: 56:PF--- 
	 3: 57:PF--- 
	 4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
	 5: ff:P-O-L Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI

With the above you can see that no capes are currently installed. There
are two "virtual" capes installed, one for the HDMI and one for the
eMMC. It makes sense to manage these as capes because both interfaces
consume pins on the cape bus.

Now, let's tell capemgr to load our devicetree overlay fragment that
configures our target pin's pinmux, take a look at the messages that
are produced by the kernel, check out the capemgr status and the status
of the pinmux.

	# echo pinctrl-test-7 > $SLOTS
	# dmesg | tail
	[   65.323606] bone-capemgr bone_capemgr.8: part_number 'pinctrl-test-7', version 'N/A'
	[   65.323744] bone-capemgr bone_capemgr.8: slot #6: generic override
	[   65.323794] bone-capemgr bone_capemgr.8: bone: Using override eeprom data at slot 6
	[   65.323845] bone-capemgr bone_capemgr.8: slot #6: 'Override Board Name,00A0,Override Manuf,pinctrl-test-7'
	[   65.324201] bone-capemgr bone_capemgr.8: slot #6: Requesting part number/version based 'pinctrl-test-7-00A0.dtbo
	[   65.325712] bone-capemgr bone_capemgr.8: slot #6: Requesting firmware 'pinctrl-test-7-00A0.dtbo' for board-name 'Override Board Name', version '00A0'
	[   65.326239] bone-capemgr bone_capemgr.8: slot #6: dtbo 'pinctrl-test-7-00A0.dtbo' loaded; converting to live tree
	[   65.327973] bone-capemgr bone_capemgr.8: slot #6: #2 overlays
	[   65.338533] bone-capemgr bone_capemgr.8: slot #6: Applied #2 overlays.
	# cat $SLOTS
	 0: 54:PF--- 
	 1: 55:PF--- 
	 2: 56:PF--- 
	 3: 57:PF--- 
	 4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
	 5: ff:P-O-L Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI
	 6: ff:P-O-L Override Board Name,00A0,Override Manuf,pinctrl-test-7
	# cat $PINS | grep 964
	pin 89 (44e10964) 00000007 pinctrl-single 

Now let's tell capemgr to unload that overlay so that we can load a new one.

	# A=`perl -pe 's/^.*(\d+):.*/$1/' $SLOTS | tail -1`
	# echo "-$A"
	-6
	# echo "-$A" > $SLOTS
	# dmesg | tail
	[   73.517002] bone-capemgr bone_capemgr.8: Removed slot #6
	[   73.517002] bone-capemgr bone_capemgr.8: Removed slot #6

And then tell capemgr to load an alternative overlay.

	# echo pinctrl-test-0 > $SLOTS
	# dmesg | tail
	[   73.663144] bone-capemgr bone_capemgr.8: part_number 'pinctrl-test-0', version 'N/A'
	[   73.663207] bone-capemgr bone_capemgr.8: slot #7: generic override
	[   73.663226] bone-capemgr bone_capemgr.8: bone: Using override eeprom data at slot 7
	[   73.663244] bone-capemgr bone_capemgr.8: slot #7: 'Override Board Name,00A0,Override Manuf,pinctrl-test-0'
	[   73.663340] bone-capemgr bone_capemgr.8: slot #7: Requesting part number/version based 'pinctrl-test-0-00A0.dtbo
	[   73.663357] bone-capemgr bone_capemgr.8: slot #7: Requesting firmware 'pinctrl-test-0-00A0.dtbo' for board-name 'Override Board Name', version '00A0'
	[   73.663602] bone-capemgr bone_capemgr.8: slot #7: dtbo 'pinctrl-test-0-00A0.dtbo' loaded; converting to live tree
	[   73.663857] bone-capemgr bone_capemgr.8: slot #7: #2 overlays
	[   73.674682] bone-capemgr bone_capemgr.8: slot #7: Applied #2 overlays.
	# cat $PINS | grep 964
	pin 89 (44e10964) 00000000 pinctrl-single 

There you go, we were able to load and unload drivers along with the required
pinmux settings or having a hot-pluggable bus with device discovery. This is
a big change for Linux and one that will drastically simplify development
with small embedded Linux computers. No longer will you need to rebuild the
kernel to get the driver you need loaded for your expansion pins. Of course,
the drivers still need to be available in the kernel or as modules, but
given the huge number of drivers available in the kernel, this is a huge
lift that could save a lot of people a lot of time!

Note that in this case, we've had to add a small driver that isn't in the
mainline kernel called pinmux-helper. This driver gives us something to
request the pins. Other drivers that already know about the pinctrl
interface won't need to use pinmux-helper and eventually it'll need to be
replaced by having all the drivers know how to use pinctrl, especially the
gpio driver we are using!
