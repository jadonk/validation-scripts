#!/usr/bin/env node
var connect = require('connect');

var app = connect();
app.use(connect.favicon());
app.use(connect.logger('dev'));
app.use(connect.directory(process.cwd()));
app.use(connect.static(process.cwd()));

app.listen(8081);
