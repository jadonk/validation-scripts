var s3copy = require('./s3-copy');
var config = require('config');

var now = new Date();
var date = now.toJSON();

s3copy.copy_to_s3(config, '/mnt/build', 'beagleboard', 'test-upload-' + date, oncomplete);
function oncomplete(err) {
 if(err) console.log("Error: " + err);
 console.log("Completed");
}

