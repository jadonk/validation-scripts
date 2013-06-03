Introduction
============
This is an example of using capemgr and devicetree overlays to configure
a pinmux on the BeagleBone. The same procedure could be followed to
load other drivers, but we should start with something simple.

Rationale and benefits of devicetree
------------------------------------
With the massive numbers of processors within the ARM family, Linus Torvalds,
the primary developer and maintainer of the Linux kernel pushed back on having
a huge amount of software logic to distinguish the various features on the
different processors.  Instead, he asked for ARM developers to leverage a
feature that has been used by PowerPC developers for years to describe their
processors using data structures, called devicetrees, eliminated all of the
highly specialized logic introduced by every processor maker and making his
job of maintaining the Linux kernel easlier.  An added benefit is that all
ARM-architecture devices who make use of this infrastructure can potentially
all use the same binary kernel, since compile-time options are largely
eliminated by using these devicetrees to specify at boot time all of the
various processor peripheral.

For the PowerPC world, introduction of devicetree had great benefits in
reducing the support burden in the Linux kernel for supporting a large
number of devices.  Because these PowerPC devices were typically used in
infrastructure projects, defining the connected peripherals at boot time
was largely sufficient.  With a product like BeagleBone, however, where
end-users seek to rapidly prototype with new hardware and new hardware
configurations, specifying everything at boot time is highly limiting.
In the BeagleBone environment, the ability to provide userspace interactions
when defining the connected hardware becomes an absolute necessity.

Introduction of devicetree overlays
-----------------------------------
Fortunately, Pantellis has offered us a solution with devicetree overlays
that greatly simplifies development for BeagleBone users as well as users
of other architectures, such as FPGAs (or FPGAs connected to BeagleBones
for that matter) in being able to initiate loads of devicetree fragements
during or after boot.  His proposal was reviewed by the devicetree
maintainers and the rationale was written up by Grant Likely [1].  Pantelis
further introduced a capemgr [2] to assist with the activity of updating
the devicetree information on a BeagleBone at boot and during run-time.

Some of the real power of this can be explored by looking at the existing
set of devicetree bindings available to developers [3].  Instead of
altering the kernel source and rebuilding, it is possible for users to
simply specify the driver to instantiate and provide all of the information
needed to configure the driver in the devicetree overlay fragement, as long
as the driver or driver module is already built and included.

References
----------
* [1] https://lkml.org/lkml/2012/11/5/615
* [2] https://lkml.org/lkml/2013/1/7/366
* [3] http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/Documentation/devicetree/bindings/
* [4] http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/Documentation/devicetree/usage-model.txt
* [5] [https://docs.google.com/document/d/17P54kZkZO_-JtTjrFuVz-Cp_RMMg7GB_8W9JK9sLKfA/edit?hl=en&forcehl=1#heading=h.j4ega7pcz5c Beaglebone and the 3.8 Kernel]
* [6] http://elinux.org/Capemgr

Example
=======
We start by defining the two key sysfs entries we'll be using to check
the status. 'slots' is an interface to capemgr that enables us to tell
capemgr to load additional devicetree overlay fragments and for it to
tell us what it has already loaded. It designed to utilize the EEPROMs
on the cape plug-in boards to identify the board

````sh
export SLOTS=/sys/devices/bone_capemgr.8/slots
export PINS=/sys/kernel/debug/pinctrl/44e10800.pinmux/pins
````

Here is my first example devicetree overlay (pinmux-test-7.dts):

````
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
````

We'll compile the device tree fragments and install them in /lib/firmware.
Note that I'm doing this natively on the BeagleBone. I've pulled in the
kernel sources and simply built this tool natively.

````sh
dtc -O dtb -o pinctrl-test-7-00A0.dtbo -b 0 -@ pinctrl-test-7.dts
dtc -O dtb -o pinctrl-test-0-00A0.dtbo -b 0 -@ pinctrl-test-0.dts
cp pinctrl-test-7-00A0.dtbo /lib/firmware/
cp pinctrl-test-0-00A0.dtbo /lib/firmware/
````

Let's check out the starting point state.

	# cat $SLOTS
	 0: 54:PF--- 
	 1: 55:PF--- 
	 2: 56:PF--- 
	 3: 57:PF--- 
	 4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
	 5: ff:P-O-L Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI

Slots 0-3 get assigned by EEPROM IDs on the capes. There are 4 possible
addresses for the EEPROMs (typically determined by switches on the boards)
enabling up to 4 boards to be stacked, depending on what functions they
use. Additional slots are "virtual", added incrementally and are triggered
in other ways.

With the above you can see that no capes are currently installed. There
are two "virtual" capes installed, one for the HDMI and one for the
eMMC. It makes sense to manage these as capes because both interfaces
consume pins on the cape bus. These two "virtual" capes are triggered
because this is the next-generation BeagleBone that includes the eMMC and
HDMI on the board. Disabling these capes would enable other capes to make
use of their pins.

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

The $PINS file is a debug entry for the pinctrl kernel module. Looking at it
tells us the state of the pinmux. To look at the pin state that I want, I
grep for the lower bits of the address where the pinmux control register is
for my pin of interest. Let's take a look and see that the mux mode is now 7.

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

And what does the pinmux look like now?

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
