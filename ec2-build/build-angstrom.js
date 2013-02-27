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
var make_callDescribeSpotInstanceRequests = function(data) {
 var requestId = data.SpotInstanceRequests[0].SpotInstanceRequestId;
 var params = {SpotInstanceRequestIds:[requestId]};
 function doCall() {
  ec2.describeSpotInstanceRequests(params, handler);
 };
 function handler(err, data) {
  console.log("err = " + err);
  console.log("data = " + JSON.stringify(data));
  if(err) throw(err);
  setTimeout(doCall, 1000);
 }
 return(doCall);
};
var hRequestSpotInstances = function(err, data) {
 console.log("err = " + err);
 console.log("data = " + JSON.stringify(data));
 if(err) throw(err);
 var doCall = make_callDescribeSpotInstanceRequests(data);
 setTimeout(doCall, 1000);

 var requestId = data.SpotInstanceRequests[0].SpotInstanceRequestId;
 var params = {SpotInstanceRequestIds:[requestId]};
 var callback = hDescribeSpotInstanceRequests;
 k
 ec2.describeSpotInstanceRequests(params, callback);
};
ec2.requestSpotInstances(instanceConfig, hRequestSpotInstances);

