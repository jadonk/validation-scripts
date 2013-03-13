#!/usr/bin/env node
var connect = require('connect');

var app = connect();
app.use(connect.favicon());
app.use(connect.logger('dev'));
app.use(connect.directory(__dirname));
app.use(connect.static(__dirname));

app.listen(80);
