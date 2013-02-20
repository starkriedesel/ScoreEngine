require 'digest'
require 'net/dns'

class ToolsController < ApplicationController
  before_filter :authenticate_user!

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

  # GET /tools/dns
  def dns
    @header_text = 'DNS Tool'
    @team_list = Team.all.collect{|t| ["Team #{t.name}", "team##{t.id}"]}
  end

  # POST /tools/dns
  def dns_post
    dns_server = nil
    packet = nil

    case params[:type]
      when 'AAAA'
        record_type = Net::DNS::AAAA
      when 'MX'
        record_type = Net::DNS::MX
      else
        record_type = Net::DNS::A
    end

    begin
      if params[:server] =~ /^team#(\d+)$/
        dns_server = Team.find($1.to_i).dns_server
      elsif params[:server] == 'ip'
        dns_server = params[:server_ip]
      else
        dns_server = nil
      end

      packet = Workers::GenericWorker.dns_lookup params[:domain], dns_server, 53, record_type

    rescue => e
      flash[:error] = "Error: #{e.message}"
    end

    unless packet.nil?
      flash[:first_anser] = packet.answer.first.to_s
      flash[:dns_packet] = packet.to_s
    end

    redirect_to dns_tool_path
  end
end
