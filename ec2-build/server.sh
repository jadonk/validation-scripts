#!/usr/bin/env node
var express = require('express');
var s3copy = require('./s3-copy');
var socketio = require('socket.io');
var http = require('http');

var app = express();
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.post('/s3copy', s3CopyHandler);
app.use(express.directory(process.cwd()));
app.use(express.static(process.cwd()));
var server = http.createServer(app);
var io = socketio.listen(server);
app.listen(8081);

io.sockets.on('connection', onConnection);
function onConnection(socket) {
 socket.on('s3copy', onS3copy);
 function onS3copy(data) {
  console.log('s3copy: ' + data);
  s3copy.copy_to_s3(data.config, data.source, data.bucket, data.dest, oncomplete, onupdate);
  function oncomplete(data) {
   socket.emit('s3copy-complete', data);
  }
  function onupdate(data) {
   socket.emit('s3copy-update', data);
  }
 }
}

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
