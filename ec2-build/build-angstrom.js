var AWS = require('aws-sdk');
var config = require('./config');
var fs = require('fs');

AWS.config.update(config);

var ec2 = new AWS.EC2.Client({region:'us-east-1'});

var userData = fs.readFileSync('./user_data.txt', 'ascii').toString('base64');
userData = new Buffer(userData).toString('base64');
console.log('userData = ' + userData);

var instanceConfig = {
 'SpotPrice': '0.500000',
 'LaunchSpecification': {
  'ImageId': 'ami-02df496b',
  'InstanceType': 'cc1.4xlarge',
  'UserData': userData
 }
};
var handleSpotInstances = function(err, data) {
 console.log("err = " + err);
 console.log("data = " + JSON.stringify(data));
};
ec2.requestSpotInstances(instanceConfig, handleSpotInstances);
