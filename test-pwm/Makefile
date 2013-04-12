PWM = am33xx_pwm
PINS_A = \
	P9_22 \
	P9_21 \
	P9_14 \
	P9_16 \
	P8_19 \
	P8_13 \
	P9_42 \
	P9_28 \

PINS_B = \
	P9_31 \
	P9_29 \
	P8_34 \
	P8_36 \
	P8_45 \
	P8_46 \

DTBO_FILES_A = $(foreach device,$(PINS_A),bone_pwm_$(device)-00A0.dtbo)
DTBO_FILES_B = $(foreach device,$(PINS_B),bone_pwm_$(device)-00A0.dtbo)
DTBO_FILES = $(PWM)-00A0.dtbo $(DTBO_FILES_A) $(DTBO_FILES_B)
SLOTS=$(shell ls /sys/devices/bone_capemgr.*/slots)

all:	$(DTBO_FILES)

clean:
	rm $(DTBO_FILES)

load_a:
	echo $(PWM) > $(SLOTS)
	for pin in $(PINS_A) ; do \
		echo bone_pwm_$$pin > $(SLOTS) ; \
	done;

load_b:
	echo $(PWM) > $(SLOTS)
	for pin in $(PINS_B) ; do \
		echo bone_pwm_$$pin > $(SLOTS) ; \
	done;

install:
	install -m 0644 $(DTBO_FILES) /lib/firmware

%.dtbo:	%.dts
	dtc -O dtb -o $@ -b 0 -@ $<
