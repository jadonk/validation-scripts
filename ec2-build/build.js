#!/usr/bin/env node
if(process.argv.length < 3) {
 console.log("Usage: ./build.js kernel|angstrom|buildroot [-s]");
 return;
}
var target = process.argv[2];
var nostop = false;
if(process.argv.length == 4 && process.argv[3] == '-s') { nostop=true; }

var config = require(process.env["HOME"] + '/config');
var fs = require('fs');
var ec2build = require('./ec2-build');
var winston = require('winston');
var http = require('http');
var child_process = require('child_process');

var stop = 0;

winston.setLevels(winston.config.syslog.levels);
var winstonFileParams = {
 filename: 'build-' + target + '.log',
 //level: 'debug'
};
winston.add(winston.transports.File, winstonFileParams);

winston.info("building " + target);

var userData = fs.readFileSync('./build-' + target + '.txt', 'ascii').toString('base64');
userData = new Buffer(userData).toString('base64');
winston.debug('userData = ' + userData);

config.instance.SpotPrice = '0.080000';
config.instance.LaunchSpecification.ImageId = 'ami-0cdf4965';
config.instance.LaunchSpecification.InstanceType = 'c1.xlarge';
config.instance.LaunchSpecification.UserData = userData;


// Wait 30 minutes to get an instance
var startupTimeout = setTimeout(onTimeoutError, 30*60*1000);

function onTimeoutError() {
 onError("Timeout");
}

function onInstanceError(err) {
 onError("Instance error: " + err);
}

function onUncaughtExceptionError(err) {
 //onError("Uncaught exception error: " + err);
 winston.error("Uncaught exception error: " + err);
}

try {
 var instance = ec2build.run(config, onRun);
 process.on('SIGINT', onKill);
 process.on('uncaughtException', onUncaughtExceptionError);
 instance.on('error', onInstanceError);
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
 callback();
 return;
}
 
function stopBuild() {
 if(nostop) doExit();
 ec2build.stop(doExit);
}

var address = null;
function onRun(err, data) {
 if(stop) return;
 clearTimeout(startupTimeout);
 winston.info("Build running");
 winston.info("name = " + data.name);
 winston.info("address = " + data.address);
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
 try {
  var request = http.get("http://" + address + "/build.log", currentLog);
  request.on('error', statusError);
 } catch(ex) {
  winstion.debug('Request error: ' + ex);
 }

 // stop it after 30 minutes of no updates for now
 timesChecked++;
 winston.debug("timesChecked = " + timesChecked);
 if(timesChecked > 30) {
  onTimeoutError();
 } else {
  setTimeout(checkLog, 60000);
 }
}

function currentLog(response) {
 winston.info("Got response: " + response.statusCode);
 response.on('data', collectLog);
 response.on('end', printLog);
}

function collectLog(data) {
 log += data;
}

var needConfig = true;
function printLog() {
 if(log != previousLog) {
  try {
   log = log.replace(previousLog, "");
  } catch(ex) {
   winston.debug("Unable to trim log");
  }
  winston.debug(log);
  previousLog += log;
  timesChecked = 0;
  if(needConfig) {
   needConfig = false;
   var myexec = 'scp -o "StrictHostKeyChecking no" -i ' + config.sshkey.file + ' ' + config.config.file +' ubuntu@' + address + ':';
   try {
    winston.info('Exec: ' + myexec);
    child_process.exec(myexec, execNullHandler);
    function execNullHandler() {}
   } catch(ex) {
    winston.error('Exec: ' + myexec);
    winston.error('Exec failed: ' + ex);
   }
  }
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
 try {
  winston.info('Exiting', { seriously: true }, function (err, level, msg, meta) {
   process.exit();
  });
 } catch(ex) {
  process.exit();
 }
};

