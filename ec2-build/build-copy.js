var config = require('./config');
var http = require('http');

if(process.argv.length < 3) {
 console.log("Usage: node build-copy.js <address>");
 return;
}

var address = process.argv[1];

saveWork(function(err) {
 if(err) console.log("Error: " + err);
 console.log("Completed");
});

function saveWork(callback) {
 var now = new Date();
 var date = now.toJSON();
 var body = JSON.stringify({
  config: config.client,
  source: "/mnt/build",
  bucket: "beagleboard",
  dest: "build-" + date
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
}
