#!/bin/sh
#set -e
set -x
BUILD=/mnt/build
OUTPUT=$BUILD/buildroot/output/images
DATE=`date +%F-%T`
BUILDROOT_TREE=
BUILDROOT_TAG=
echo $DATE
if [ ! -e $BUILD/buildroot ]
then
 if [ xx$BUILDROOT_TREE != xx ]; then
  time git checkout $BUILDROOT_TREE $BUILD/buildroot
 else
  time git clone git://git.busybox.net/buildroot $BUILD/buildroot
 fi
 if [ xx$BUILDROOT_TAG != xx ]; then git checkout $BUILDROOT_TAG; fi
fi
cd $BUILD/buildroot
time make beaglebone_defconfig
time make

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
s3cmd sync -P $OUTPUT/ s3://beagle/buildroot/$DATE/
s3cmd put -P $BUILD/build.log s3://beagle/buildroot/$DATE/

node -pe "c=require('$HOME/config');a=require('aws-sdk');a.config.update(c.client);s=new a.SES.Client(c.client);s.sendEmail({Source:c.email.from,Destination:{ToAddresses:c.email.to},Message:{Subject:{Data:'[beagle-validation] Completed build-buildroot.sh'},Body:{Text:{Data:'http://beagle.s3.amazonaws.com/buildroot/$DATE/index.html\nhttp://github.com/jadonk/validation-scripts/ec2-build'}}}},function(err){console.log('err = ' + err);});"

echo !!!! COMPLETED build-buildroot !!!!
