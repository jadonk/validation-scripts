var AWS = require('aws-sdk');
var fs = require('fs');

var s3 = null;

function copy_to_s3(config, source, bucket, dest, callback) {
 if(!s3) {
  try {
   AWS.config.update(config.client);
   s3 = new AWS.S3.Client({region:'us-east-1'});
  } catch(ex) {
   throw 'Error ' + ex;
  }
 }

 var pending = 0;
 var stop = 0;

 dive(source);

 function dive(dir) {
  if(stop) {
   return; // if we are already dead, we don't do anything
  }
  pending++;
  fs.readdir(dir, function(err, list) {
   if(stop) {
    return; // if we are already dead, we don't do anything
   }
   if (err) {
     fail(err); // if an error occured, let's fail
     return;
   }
   // iterate over the files
   list.forEach(function(file) {
    if(!dead) { // if we are already dead, we don't do anything
     var path = dir + "/" + file;
     pending++; // async operation starting after this line
     fs.stat(path, function(err, stat) {
      if(!dead) { // if we are already dead, we don't do anything
       if (err) {
        fail(err); // if an error occured, let's fail
       } else {
        if (stat && stat.isDirectory()) {
         dive(path); // it's a directory, let's explore recursively
        } else {
         copy(path, stat); // it's not a directory, just perform the action
        }
        pending--; checkSuccess(); // async operation complete
       }
      }
     });
    }
   });
   pending--;
   checkSuccess(); // async operations complete
  });
 }

 function copy(file, stat) {
  if(!stop) {
   try {
    var destFile = dest + file;
    do_copy(file, destFile);
   } catch(ex) {
    fail('Copy failed on ' + file + ': ' + ex);
   }
 }

 function do_copy(sourceFile, destFile) {
  fs.readFile(sourceFile, do_write);
  function do_write(err, data) {
   if (err) { throw err; }

   s3.client.putObject({
    Bucket: bucket,
    Key: destFile,
    Body: data,
    ACL: 'public-read'
   }, function (res) {
    winston.info('Successfully uploaded ' + sourceFile);
   });
  });
 }

 function checkSuccess() {
  if(!stop && !pending) {
   callback();
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
