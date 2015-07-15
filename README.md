# Readme

     ,-----.,--.                  ,--. ,---.   ,--.,------.  ,------.
    '  .--./|  | ,---. ,--.,--. ,-|  || o   \  |  ||  .-.  \ |  .---'
    |  |    |  || .-. ||  ||  |' .-. |`..'  |  |  ||  |  \  :|  `--, 
    '  '--'\|  |' '-' ''  ''  '\ `-' | .'  /   |  ||  '--'  /|  `---.
     `-----'`--' `---'  `----'  `---'  `--'    `--'`-------' `------'
    ----------------------------------------------------------------- 

## Introduction
The code contained in this repo is a modified version of a tutorial by [uploaders](https://github.com/uploaders). Most of the code used here stems directly from the tutorial found [here](https://github.com/uploaders/aws-sdk-rails-4.2)

The intention was to modify the code in order to
- host the app (with all it's code) on Cloud9 publicly, while hiding the AWS Environment Variables
- demonstrate how to secure the secret variables inside an 'external' json file.
- Use AWS for Ruby Version 2, not Version 1 as outlined in the above referenced tutorial

## Rails
- ruby 2.2.1
- rails 4.2.1

## hiding files from public cloud9 app:
If you don't want your file to be visible by the public, it has to live outside of the *workspace* directory in Cloud9.
I created a file called *secrets.json* and placed it in a folder called sensitive_data in teh root directory of C9.
![alt tag](https://cloud.githubusercontent.com/assets/3217286/8709503/a280504c-2b10-11e5-916c-d27529bfe050.JPG)

secrets.json contains the following code:
```javascript
/*
//INSTRUCTIONS ON HOW TO READ THESE INTO config/environment.rb
    file = File.read('../sensitive_data/secrets.json')
    data_hash = JSON.parse(file)
    data_hash['AWS']['someKey']
*/

{"AWS":{"aws_access_key_id":"InsertAWSKeyID","aws_secret_access_key":"InsertAWSSecretKey"}}
```

##using the AWS V2 SDK
If you follow the tutorial mentioned [above](https://github.com/uploaders/aws-sdk-rails-4.2), you will create a file called aws.rb in /config/initializers. 

The file should contain the following code, in order to work with the newer version of the AWS Ruby SDK:

```ruby
# /config/initializers/aws.rb

#have to use Aws instead of AWS: http://stackoverflow.com/questions/22826432/uninitialized-constant-aws-nameerror

#http://docs.aws.amazon.com/sdkforruby/api/
require 'json'
creds = JSON.load(File.read('../sensitive_data/secrets.json'))   #read file from *external* directory

Aws.config.update({
  credentials: Aws::Credentials.new(creds['AWS']['aws_access_key_id'], creds['AWS']['aws_secret_access_key']),
  region: 'us-east-1'
})

# list buckets in Amazon S3
s3 = Aws::S3::Client.new
resp = s3.list_buckets
S3_BUCKET = resp.buckets[0]
resp.buckets.map(&:name)

S3 = Aws::S3::Resource.new(region: 'us-east-1')
```

##Uploading a file with the Uploads Controller
We have to make a few changes to the app/controllers/uploads_controller.rb in order to upload files using the newer Ruby AWS SDK.

```ruby
class UploadsController < ApplicationController
  def new
  end

  def create
    #make an object in your bucket for the upload
    file_to_upload = params[:file]
    file_name = params[:file].original_filename
    bucket = S3.bucket(S3_BUCKET.name)
    
    obj = bucket.object(file_name)
    #byebug
    
    #upload the file:
    obj.put(
      acl: "public-read",
      body: file_to_upload
      )
      
    ##https://github.com/awslabs/aws-ruby-sample/blob/master/s3_sample.rb
      
    #create an object for the upload
    @upload = Upload.new(
      url: obj.public_url,
      name: obj.key
      )
    
    #save the upload
    if @upload.save
      redirect_to uploads_path, success: 'File successfully uploaded'
    else
      flash.now[:notice] = 'There was an error'
      render :new
    end    
  end

  def index
    @uploads = Upload.all
  end
end
```

This is it. Otherwise, it is safe to rely on the tutirial posted by uploaders. 
