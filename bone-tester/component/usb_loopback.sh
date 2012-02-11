#!/bin/bash

echo "USB loopback test"

set -e
set -x

BONETESTER_DIR=/var/lib/bone-tester/
COMPONENT_DIR=${BONETESTER_DIR}/component/
LIB_DIR=${BONETESTER_DIR}/lib/
source ${LIB_DIR}/utils.sh


G_FILE_STORAGE_NAME=${COMPONENT_DIR}/data/backing-file
G_FILE_BACKING_SIZE_M=20
G_FILE_BACKING_DEV=/dev/sda
G_FILE_BACKING_MNT=/media/BEAGLE_BONE/
TMPFS=/home/root/.tmpfs
# Check if backing file exists
if ! [ -e ${G_FILE_STORAGE_NAME} ] ; then
	bone_echo "Please reinstall the bone tester."
fi

mkdir -p ${TMPFS}
mount -t tmpfs nodev ${TMPFS}
dd if=/dev/urandom of=${TMPFS}/test-file bs=512k count=1

umount ${G_FILE_BACKING_DEV} || true
mkdir -p ${G_FILE_BACKING_MNT}
mount ${G_FILE_BACKING_DEV} ${G_FILE_BACKING_MNT}

bone_echo "Copying test file.."
cp ${TMPFS}/test-file ${G_FILE_BACKING_MNT}/

umount ${G_FILE_BACKING_MNT}
mount /dev/sda ${G_FILE_BACKING_MNT}

bone_echo "Check if file is copied properly.."
if [ "x$(diff ${G_FILE_BACKING_MNT}/test-file ${TMPFS}/test-file)" != "x" ] ; then
	bone_echo "Data copied onto Gadget FS not present or corrupt"
	exit 1
fi

umount ${TMPFS}
rm -rf ${TMPFS} || true

bone_echo "USB Host/Device Test Passed!"
