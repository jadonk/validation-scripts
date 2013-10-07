#!/bin/sh
#set -e
set -x
BUILD=/mnt/build
OUTPUT=$BUILD/buildroot/output/images
DATE=`date +%F-%T`
echo $DATE
if [ ! -e $BUILD/buildroot ]
then
 time git clone git://github.com/jadonk/buildroot.git $BUILD/buildroot
fi
cd $BUILD/buildroot
time make beaglebone_defconfig
time make
echo !!!! COMPLETED build-buildroot !!!!

cd $OUTPUT
cat >index.html <<EOF
<html>
<head>
<title>Buildroot $DATE</title>
</head>
<body>
<h1>Buildroot $DATE</h1>
<ul>
<li><a href="build.log">build.log</a></li>
EOF
ls $OUTPUT | perl -pe 's/^(.*)$/<li><a href="$1">$1<\/a><\/li>/' >>index.html
echo "</ul></body></html>" >>index.html

node -pe "c=require('$HOME/config');require('fs').readFileSync('$BUILD/ec2-build/s3cfg').toString().replace(/_AK_/,c.client.accessKeyId).replace(/_SK_/,c.client.secretAccessKey);" > $HOME/.s3cfg
s3cmd sync $OUTPUT s3://beagle/buildroot/$DATE
s3cmd put $BUILD/build.log s3://beagle/buildroot/$DATE

