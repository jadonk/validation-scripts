#!/bin/bash

# BeagleBone automatic tester
# 
# This script should run automatically during init and run a setup of sub tasks
# each of which will test a specific component of the board.
# It is expected to be run with the board plugged into the test board.
# Test results should be displayed and/or reported to the testboard through GPIO

# IGNOREPIN=true
# NOHALT=true

BONETESTER_DIR=/var/lib/bone-tester/
COMPONENT_DIR=${BONETESTER_DIR}/component/
LIB_DIR=${BONETESTER_DIR}/lib/

source ${LIB_DIR}/utils.sh

x=5
while [ $x != 0 ] ; do 
	if [ -e /dev/ttyUSB0 ] ; then break; fi
	echo "Checking for USB device, attempt $x"
	x=$(($x-1))
	sleep 1
done

if [ $x -eq 0 ] ; then
	echo "died waiting for usb-serial device"
	exit
fi

stty -F /dev/ttyUSB0 115200

bone_echo "bone tester: starting"

if [ $IGNOREPIN ]; then
	bone_echo "bone tester: skipping test for GPIO 1_6 (P8_3)"
else
	if [ "x$(read_gpio 38)" != "x0" ] ; then
		bone_echo "bone tester: GPIO 1_6 (P8_3) is not grounded, not running tests"
		exit 0
	fi
fi

run_test() {
	if [ -z "$1" ] ; then
		bone_echo "run_test: Missing parameter"
		return 1
	fi
	time $COMPONENT_DIR/$1.sh
}

delete_uenv() {
	set -e
	mkdir /tmp/mnt
	mount /dev/mmcblk0p1 /tmp/mnt
	rm -f /tmp/mnt/uEnv.txt
	umount /tmp/mnt
	set +e
}

run_tests() {
	unset FAIL
	run_led_command init_leds
	run_led_command toggle_timer 3 300
	for test in $* ; do
		bone_echo "Running test: ${test}"
		run_test $test
		if [ $? -ne 0 ] ; then
			bone_echo "TEST FAILED: $test"
			# run_led_command flash_all
			# run_led_command turn_off_all
			FAIL=true
			# return $?
		fi
		bone_echo "---------------------------------------------------"
	done
	if [ $FAIL ]; then
		run_led_command turn_off_all
		bone_echo "One or more tests failed"
		if [ ! $NOHALT ]; then 
			halt
		fi
	else
		run_led_command turn_on_all
		bone_echo "All tests succeeded"
	fi
}

function run_led_command() {
	${BONETESTER_DIR}/lib/leds.sh $*
}

run_led_command stop_led_function

bone_echo "***************************************************"
run_tests \
    usb_loopback \
    ethernet \
    eeprom \
    memory 
bone_echo "***************************************************"

if [ ! $NOHALT ]; then 
	halt
fi
