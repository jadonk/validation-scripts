Usage:

```sh
./build.sh angstrom|kernel
```

You'll need to create config.js first:

config.js:

```javascript
var client = {};
client.accessKeyId = 'XXXXXXXXXXXXXXXXXXXX';
client.secretAccessKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
client.region = 'us-east-1';

var instance = {};
instance.LaunchSpecification = {};
instance.LaunchSpecification.KeyName = 'keypair';

var sshkey = {};
sshkey.file = "/home/test/.ssh/keypair";

exports.client = client;
exports.instance = instance;
exports.sshkey = sshkey;
```
