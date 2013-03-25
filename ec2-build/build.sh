#!/usr/bin/env node
if(process.argv.length < 3) {
 console.log("Usage: build.sh kernel|angstrom");
 return;
}
var target = process.argv[2];

var config = require('./config');
var fs = require('fs');
var ec2build = require('./ec2-build');
var winston = require('winston');
var http = require('http');
var child_process = require('child_process')

var stop = 0;

winston.setLevels(winston.config.syslog.levels);
var winstonFileParams = {
 filename: 'build-' + target + '.log',
 level: 'debug'
};
winston.add(winston.transports.File, winstonFileParams);

winston.info("building " + target);

var userData = fs.readFileSync('./build-' + target + '.txt', 'ascii').toString('base64');
userData = new Buffer(userData).toString('base64');
winston.debug('userData = ' + userData);

//config.instance.SpotPrice = '0.080000';
//config.instance.LaunchSpecification.ImageId = 'ami-02df496b';
//config.instance.LaunchSpecification.InstanceType = 'cc1.4xlarge';
config.instance.SpotPrice = '0.080000';
config.instance.LaunchSpecification.ImageId = 'ami-0cdf4965';
//config.instance.LaunchSpecification.ImageId = 'ami-de0d9eb7';
config.instance.LaunchSpecification.InstanceType = 'c1.xlarge';
config.instance.LaunchSpecification.UserData = userData;

// Wait 30 minutes to get an instance
var startupTimeout = setTimeout(onTimeoutError, 30*60*1000);

function onTimeoutError() {
 onError("Timeout");
};

try {
 var instance = ec2build.run(config, onRun);
 process.on('SIGINT', onKill);
 instance.on('error', onError);
} catch(ex) {
 onError("Error invoking ec2build.run: " + ex);
}

function onError(err) {
 if(stop) return;
 stop = true;
 winston.error("ERROR!!!");
 winston.error("err = " + err);
 if(startupTimeout) clearTimeout(startupTimeout);
 saveWork(stopBuild);
};

function saveWork(callback) {
 try {
  var now = new Date();
  var datestr = now.toJSON();
  var body = JSON.stringify({
   'config': config.client,
   'source': "/mnt/build",
   'bucket': "beagleboard",
   'dest': "build-" + target + "-" + datestr
  });
  var options = {
   hostname: address,
   method: 'POST',
   path: '/s3copy',
   headers: {
    "Content-Type": "application/json",
    "Content-Length": body.length
   }
  };
  var request = http.request(options, showSaveResponse);
  request.on('error', callback);
  request.end(body);
  function showSaveResponse(response) {
   response.on('data', function() {});
   response.on('end', callback);
  }
 } catch(ex) {
  callback(ex);
 }
}
 
function stopBuild() {
 ec2build.stop(doExit);
}

var address = null;
function onRun(err, data) {
 if(stop) return;
 clearTimeout(startupTimeout);
 winston.info("Build running");
 winston.info("name = " + data.name);
 winston.debug("address = " + data.address);
 winston.debug("data = " + JSON.stringify(data));
 address = data.address;
 if(err) {
  onError(err);
  return;
 }
 // start checking status after a minute
 setTimeout(checkLog, 60000);
};

var timesChecked = 0;
var log = "";
var previousLog = "";

function checkLog() {
 if(stop) return;
 log = "";
 var request = http.get("http://" + address + "/build.log", currentLog);
 request.on('error', statusError);

 // stop it after 30 minutes of no updates for now
 timesChecked++;
 winston.debug("timesChecked = " + timesChecked);
 if(timesChecked > 30) {
  onTimeoutError();
 } else {
  setTimeout(checkLog, 60000);
 }
};

function currentLog(response) {
 winston.info("Got response: " + response.statusCode);
 response.on('data', collectLog);
 response.on('end', printLog);
};

function collectLog(data) {
 log += data
};

var configCopied = 0;
function printLog(data) {
 if(log != previousLog) {
  if(!configCopied) {
   configCopied = 1;
   child_process.exec('scp -i ' + config.sshkey.file + ' config.js ubuntu@' + address + ':');
  }
  log = log.replace(previousLog, "");
  winston.info(log);
  previousLog += log;
  timesChecked = 0;
 }
 if(log.match(/!!!! COMPLETED/)) {
  saveWork(stopBuild);
 }
};

function statusError(e) {
 winston.debug("Got error: " + e.message);
};

function onKill() {
 if(stop) doExit();
 onError("Shutting down from SIGINT (Crtl-C)");
};

function doExit() {
 winston.transports.File.flush();
 process.exit();
};
