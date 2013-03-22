var AWS = require('aws-sdk');

var s3 = null;

function copy_to_s3(config, source, bucket, dest, callback) {
 try {
  AWS.config.update(config.client);
  s3 = new AWS.S3.Client({region:'us-east-1'});
 } catch(ex2) {
  emitter.emit('error', s3);
 }

function () {
fs.readFile(sourceFile, function (err, data) {
    if (err) { throw err; }

    s3.client.putObject({
        Bucket: bucketName,
        Key: 'Folder/image.jpg',
        Body: data,
        ACL:'public-read'
    }, function (res) {
            console.log('Successfully uploaded file.');
        })

});
}

module.exports.copy_to_s3 = copy_to_s3;
