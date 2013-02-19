require 'digest'

class ToolsController < ApplicationController
  # GET /tools/hash
  def hash
    @header_text = "Hash Tool"
  end

  # POST /tools/hash
  def hash_post
    source = nil
    begin
      if params[:source] == 'text'
        source = params[:text]
      elsif params[:source] == 'file'
       source = params[:file].read
      elsif params[:source] == 'http'
        source = Workers::HttpWorker.get_request_body 'http://'+params[:http]
      elsif params[:source] == 'https'
        source = Workers::HttpWorker.get_request_body 'https://'+params[:https]
      end
      unless source.nil?
        if params[:source] == 'file'
          flash[:source] = params[:file].original_filename
        else
          flash[:source] = source
        end
        if params[:type] == 'md5'
          flash[:hash] = Digest::MD5.hexdigest source
        elsif params[:type] == 'sha1'
          flash[:hash] = Digest::SHA1.hexdigest source
        elsif params[:type] == 'sha2'
          flash[:hash] = Digest::SHA2.hexdigest source
        end
        flash[:type] = params[:type] unless flash[:hash].nil?
      end
    rescue => e
      flash[:error] = "Error: #{e.message}"
    end
    redirect_to hash_tool_path
  end
end
