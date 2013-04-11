DTBO_PWM = am33xx_pwm
DTBO_PINS = \
	bone_pwm_P8_13 \
	bone_pwm_P8_19 \
	bone_pwm_P8_34 \
	bone_pwm_P8_36 \
	bone_pwm_P8_45 \
	bone_pwm_P8_46 \
	bone_pwm_P9_14 \
	bone_pwm_P9_16 \
	bone_pwm_P9_21 \
	bone_pwm_P9_22 \
	bone_pwm_P9_29 \
	bone_pwm_P9_31
DTBO = $(DTBO_PWM) $(DTBO_PINS)
DTBO_FILES = $(foreach device,$(DTBO),$(device)-00A0.dtbo)
SLOTS=$(shell ls /sys/devices/bone_capemgr.*/slots)

all:	$(DTBO_FILES)

clean:
	rm $(DTBO_FILES)

install:
	install -m 0644 $(DTBO_FILES) /lib/firmware

test:
	echo $(DTBO_PWM) > $(SLOTS)
	for dtbo_pin in $(DTBO_PINS) ; do \
		echo $$dtbo_pin > $(SLOTS) ; \
	done;
	cat $(SLOTS)

%.dtbo:	%.dts
	dtc -O dtb -o $@ -b 0 -@ $<
