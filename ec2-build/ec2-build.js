var AWS = require('aws-sdk');
var config = require('./config');

function run(instanceConfig, runCallback) {
 AWS.config.update(config);
 var ec2 = new AWS.EC2.Client({region:'us-east-1'});

 ec2.requestSpotInstances(instanceConfig, hRequestSpotInstances);

 function hRequestSpotInstances(err, data) {
  console.log("err = " + err);
  console.log("data = " + JSON.stringify(data));
  if(err) throw(err);
  var doCall = make_callDescribeSpotInstanceRequests(data);
  setTimeout(doCall, 1000);

  var requestId = data.SpotInstanceRequests[0].SpotInstanceRequestId;
  var params = {SpotInstanceRequestIds:[requestId]};
  var callback = hDescribeSpotInstanceRequests;
  ec2.describeSpotInstanceRequests(params, callback);
 };
 
 function make_callDescribeSpotInstanceRequests(data) {
  var requestId = data.SpotInstanceRequests[0].SpotInstanceRequestId;
  var params = {SpotInstanceRequestIds:[requestId]};
  function doCall() {
   ec2.describeSpotInstanceRequests(params, handler);
  };
  function handler(err, data) {
   console.log("err = " + err);
   console.log("data = " + JSON.stringify(data));
   if(err) throw(err);
   // check for states "open" and "active"
   var state = data.SpotInstanceRequests[0].State;
   if(state == "open") setTimeout(doCall, 1000);
   else if(state == "active") {
    var nextCall = make_callDescribeInstanceStatus(data);
    nextCall();
   }
   else throw(err);
  }
  return(doCall);
 };
 
 function make_callDescribeInstanceStatus(data) {
  var instanceId = data.SpotInstanceRequests[0].InstanceId;
  var params = {InstanceIds:[instanceId]};
  function handler(err, data) {
   console.log("err = " + err);
   console.log("data = " + JSON.stringify(data));
   setTimeout(doCall, 2000);
  };
  function doCall() {
   //ec2.describeInstanceStatus(params, handler);
   ec2.describeInstances(params, handler);
  };
  return(doCall);
 };
};

exports.run = run;
