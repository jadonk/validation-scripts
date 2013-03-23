var AWS = require('aws-sdk');
var fs = require('fs');
var winston = require('winston');

var s3 = null;

function copy_to_s3(config, source, bucket, dest, callback, onupdate) {
 if(!s3) {
  try {
   AWS.config.update(config.client);
   s3 = new AWS.S3.Client(config.client);
  } catch(ex) {
   throw 'Error ' + ex;
  }
 }

 var stop = 0;
 var pendingDir = 0;
 var pendingFile = 0;
 var queueDir = [];
 var queueFile = [];
 var maxDir = 10;
 var maxFile = 30;

 explore(source);

 function explore(dir) {
  if(stop) {
   return; // if we are already dead, we don't do anything
  }
  if(pendingDir < maxDir) doDir(dir);
  else queueDir.push(dir);
 }

 function doDir(dir) {
  winston.info("Directory: " + dir);
  winston.debug("dir = " + dir);
  pendingDir++;
  fs.readdir(dir, onDir);

  function onDir(err, list) {
   if(err) fail(err);
   if(stop) return;
   winston.debug("dir = " + dir);

   // iterate over the files
   list.forEach(onFile);
   pendingDir--;
   if(queueDir.length > 0 && pendingDir < maxDir) {
    var newdir = queueDir.shift();
    doDir(newdir);
   }

   function onFile(file) {
    if(stop) return;
    winston.debug("dir = " + dir);
    if(pendingFile < maxFile) doFile(dir, file);
    else queueFile.push({dir:dir, file:file});
   }
  }
 }

 function doFile(dir, file) {
  pendingFile++;
  var path = dir + '/' + file;
  var destFile = dest.replace(/(\/)?$/, path.replace(/^(\/)?/, '/'));
  winston.info("Examining: " + path);
  fs.stat(path, onStat);
  function onStat(err, stat) {
   if(err) return;
   //if(err) fail(err);
   if(stop) return;
   if (stat && stat.isDirectory()) {
    explore(path);
   } else {
    winston.info("Copying: " + path);
    doS3Read(path, destFile);
   }
   pendingFile--;
   if(queueFile.length > 0 && pendingFile < maxFile) {
    var file = queueFile.shift();
    doFile(file.dir, file.file);
   }
  }
 }

 function doS3Read(sourceFile, destFile) {
  fs.readFile(sourceFile, function(err, data) {
   //if(err) fail(err);
   if(err) return;
   if(stop) return;
   s3.putObject({
    Bucket: bucket,
    Key: destFile,
    Body: data,
    ACL: 'public-read'
   }, onPut);
  });

  function onPut(err, data) {
   if(err) fail(err);
   if(stop) return;
   winston.info('Successfully uploaded ' + sourceFile + ' to ' + bucket + ' at ' + destFile);
   if(!pendingFile && !pendingDir) {
    callback();
   }
  }
 }

 function fail(err) {
  if(!stop) {
   stop = true;
   callback(err);
  }
 }
}

module.exports.copy_to_s3 = copy_to_s3;
