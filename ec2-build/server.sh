#!/usr/bin/env node
var connect = require('connect');
var s3copy = require('./s3-copy');

var app = connect();
app.use(connect.favicon());
app.use(connect.logger('dev'));
app.use(connect.bodyParser());
app.use(s3CopyHandler);
app.use(connect.directory(process.cwd()));
app.use(connect.static(process.cwd()));

app.listen(8081);

function s3CopyHandler(req, res) {
 if(
  req.body["config"] &&
  req.body["source"] &&
  req.body["bucket"] &&
  req.body["dest"]
 ) {
  var config = req.body["config"];
  var source = req.body["source"];
  var bucket = req.body["bucket"];
  var dest = req.body["dest"];

  var now = new Date();
  var date = now.toJSON();

  s3copy.copy_to_s3(config, source, bucket, dest, oncomplete, onupdate);

  function onupdate(data) {
   res.write(data);
  }

  function oncomplete(err) {
   if(err) res.write("Error: " + err);
   res.write("Completed");
   res.end();
  }
 }
}
