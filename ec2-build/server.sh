#!/usr/bin/env node
var express = require('express');
var s3copy = require('./s3-copy');

var app = express();
app.use(express());
app.use(express('dev'));
app.use(express());
app.post('/s3copy', s3CopyHandler);
app.use(express(process.cwd()));
app.use(express(process.cwd()));
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
