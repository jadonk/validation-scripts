#!/bin/sh
set -e
set -x
BUILD=/mnt/build
BRANCH=angstrom-v2012.12-yocto1.3
#TAG=f6fe4ce6f4f82be5b2185b12ccadb163a61e512e
date
#time git clone git://github.com/jadonk/setup-scripts.git /mnt/build/oe
time git clone git://github.com/Angstrom-distribution/setup-scripts.git /mnt/build/oe
cd $BUILD/oe
time git checkout -b $BRANCH origin/$BRANCH
time MACHINE=beaglebone ./oebb.sh config beaglebone
sed -i 's/^#PARALLEL/PARALLEL/g' $BUILD/oe/conf/local.conf
#time MACHINE=beaglebone ./oebb.sh update commit $TAG
source ~/.oe/environment-angstromv2012.12
time MACHINE=beaglebone ./oebb.sh bitbake -k console-image
time MACHINE=beaglebone ./oebb.sh bitbake -k cloud9-gnome-image
date
echo !!!! COMPLETED build-angstrom.sh !!!!
