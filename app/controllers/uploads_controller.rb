class UploadsController < ApplicationController
  def new
  end

  def create
    #make an object in your bucket for the upload
    file_to_upload = params[:file]

    if(file_to_upload!=nil)
      # try to upload it
      file_name = params[:file].original_filename
      bucket = S3.bucket(S3_BUCKET.name)
      
      obj = bucket.object(file_name)
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
    end
    
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
