var s3copy = require('./s3-copy');
var config = require('config');

var now = new Date();
var date = now.toJSON();

//s3copy.copy_to_s3(config, '/mnt/build/build.log', 'beagleboard', 'test-upload-' + date, oncomplete);
//s3copy.copy_to_s3(config, '/mnt/build/kernel/kernel/rootfs/modules.tgz', 'beagleboard', 'test-upload-' + date, oncomplete);
//s3copy.copy_to_s3(config, '/mnt/build/kernel/kernel/arch/arm/boot/uImage', 'beagleboard', 'test-upload-' + date, oncomplete);
//s3copy.copy_to_s3(config, '/mnt/build/kernel/kernel/arch/arm/boot/uImage-dtb.am335x-bone', 'beagleboard', 'test-upload-' + date, oncomplete);
//s3copy.copy_to_s3(config, '/mnt/build/kernel/kernel/arch/arm/boot/uImage-dtb.am335x-boneblack', 'beagleboard', 'test-upload-' + date, oncomplete);
//s3copy.copy_to_s3(config, '/mnt/build/kernel/kernel/arch/arm/boot/dts/dtb.tgz', 'beagleboard', 'test-upload-' + date, oncomplete);
s3copy.copy_to_s3(config, '/mnt/build/build.log', 'beagleboard', 'angstrom-' + date, oncomplete);
s3copy.copy_to_s3(config, '/mnt/build/oe/build', 'beagleboard', 'angstrom-' + date, oncomplete);

function oncomplete(err) {
 if(err) console.log("Error: " + err);
 console.log("Completed");
}
