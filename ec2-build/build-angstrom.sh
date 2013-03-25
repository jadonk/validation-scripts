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
#sed -i '/PARALLEL_MAKE.*=.*".*"/PARALLEL_MAKE = "-j4"' $BUILD/oe/conf/local.conf
#sed -i '/BB_NUMBER_THREADS.*=.*"*"/BB_NUMBER_THREADS = "3"' $BUILD/oe/conf/local.conf
#time MACHINE=beaglebone ./oebb.sh update commit $TAG
source ~/.oe/environment-angstromv2012.12
time bitbake -k console-image
time bitbake -k cloud9-gnome-image
cd $BUILD/oe/build
time tar -cvzf sstate-cache.tgz sstate-cache
time tar -cvzf output.tgz tmp*-cache
date
echo !!!! COMPLETED build-angstrom.sh !!!!
