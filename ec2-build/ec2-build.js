var AWS = require('aws-sdk');
var config = require('./config');
var events = require('events');

var instanceId = null;

function run(instanceConfig, runCallback) {
 var emitter = new events.EventEmitter;
 try {
  AWS.config.update(config);
  var ec2 = new AWS.EC2.Client({region:'us-east-1'});

  ec2.requestSpotInstances(instanceConfig, hRequestSpotInstances);
 } catch(ex2) {
  emitter.emit('error', ex2);
 }

 try {
  function hRequestSpotInstances(err, data) {
   try {
    console.log("requestSpotInstances:");
    console.log("err = " + err);
    console.log("data = " + JSON.stringify(data));
    if(err) throw(err);
    var doCall = make_callDescribeSpotInstanceRequests(data);
    setTimeout(doCall, 1000);
   } catch(ex3) {
    emitter.emit('error', ex3);
   }
  };
 
  function make_callDescribeSpotInstanceRequests(data) {
   try {
    var requestId = data.SpotInstanceRequests[0].SpotInstanceRequestId;
    var params = {SpotInstanceRequestIds:[requestId]};
    function doCall() {
     try {
      ec2.describeSpotInstanceRequests(params, handler);
     } catch(ex4) {
      emitter.emit('error', ex4);
     }
    };
    function handler(err, data) {
     try {
      console.log("describeSpotInstanceRequests:");
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
     } catch(ex4) {
      emitter.emit('error', ex4);
     }
    }
   } catch(ex3) {
    emitter.emit('error', ex3);
   }
   return(doCall);
  };
 
  function make_callDescribeInstanceStatus(data) {
   try {
    instanceId = data.SpotInstanceRequests[0].InstanceId;
    var params = {InstanceIds:[instanceId]};
    function doCall() {
     try {
      ec2.describeInstances(params, handler);
     } catch(ex4) {
      emitter.emit('error', ex4);
     }
    };
    function handler(err, data) {
     try {
      console.log("describeInstances:");
      console.log("err = " + err);
      console.log("data = " + JSON.stringify(data));
      var state = data.Reservations[0].Instances[0].State.Name;
      console.log("state = " + state);
      if(state == "running") {
       var name = data.Reservations[0].Instances[0].PublicDnsName;
       var address = data.Reservations[0].Instances[0].PublicIpAddress;
       data.name = name;
       data.address = address;
       runCallback(err, data);
      } else {
       setTimeout(doCall, 2000);
      }
     } catch(ex4) {
      emitter.emit('error', ex4);
     }
    };
   } catch(ex3) {
    emitter.emit('error', ex3);
   }
   return(doCall);
  };
 } catch(ex2) {
  emitter.emit('error', ex2);
 }
 return(emitter);
};

function stop() {
 if(instanceId) {
  var params = {InstanceIds:[instanceId]};
  ec2.stopInstances(params, handler);
  function handler(err, data) {
   console.log("stopInstances:");
   console.log("err = " + err);
   console.log("data = " + JSON.stringify(data));
   if(err) throw(err);
  };
 } else {
  throw("stop: No running instances found");
 }
};

module.exports.run = run;
module.exports.stop = stop;
