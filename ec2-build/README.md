config.js:

client.accessKeyId = 'XXXXXXXXXXXXXXXXXXXX';
client.secretAccessKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
client.region = 'us-east-1';

var instance = {};
instance.LaunchSpecification = {};
instance.LaunchSpecification.KeyName = 'keypair';

var sshkey = {};
sshkey.file = "$HOME/.ssh/keypair";

exports.client = client;
exports.instance = instance;
exports.sshkey = sshkey;
