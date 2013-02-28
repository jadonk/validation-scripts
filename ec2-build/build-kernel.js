var AWS = require('aws-sdk');
var config = require('./config');
var fs = require('fs');
var ec2build = require('./ec2-build');

var userData = fs.readFileSync('./build-kernel.txt', 'ascii').toString('base64');
userData = new Buffer(userData).toString('base64');
console.log('userData = ' + userData);

var instanceConfig = {
 'SpotPrice': '0.080000',
 'LaunchSpecification': {
  'ImageId': 'ami-0cdf4965',
  'InstanceType': 'm1.xlarge',
  'UserData': userData
 }
};

try {
 var instance = ec2build.run(instanceConfig, onRun);
 instance.on('error', onError);
} catch(ex) {
 console.log('ERROR: ' + ex);
 ec2build.stop();
}

function onError(err) {
 console.log("Error starting build");
 console.log("err = " + err);
 ec2build.stop();
};

var address = null;
function onRun(err, data) {
 console.log("Build running");
 console.log("err = " + err);
 console.log("name = " + data.name);
 console.log("address = " + data.address);
 console.log("data = " + JSON.stringify(data));
 if(err) {
  ec2build.stop();
 } else {
  // start checking status after a minute
  setTimeout(checkStatus, 60000);
 }
};

var timesChecked = 0;
function checkStatus() {
 // stop it after 15 minutes for now
 timesChecked++;
 if(timesChecked > 15) {
  ec2build.stop();
 }
 setTimeout(checkStatus, 60000);
}
