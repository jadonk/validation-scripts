var AWS = require('aws-sdk');
var config = require('./config');

AWS.config.update(config);

var ec2 = new AWS.EC2.Client();
