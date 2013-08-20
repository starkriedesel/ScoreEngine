require 'net/http'
require 'net/https'

module Workers
  class HttpWorker < GenericWorker
    set_default_params rport: 80
    set_service_params({
      home_path: {description: 'HTTP path to be retrieved from server', default: '/', required: true},
      home_check: {description: 'MD5/Regex of page to be retrieved'}
    })

    def worker_name
      :Http
    end

    def prefix
      'http'
    end

    def self.make_request(url, log=nil, count=1)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if url.include?('https')
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = http.request(Net::HTTP::Get.new(uri.request_uri))
      if (response.code == '301' or response.code == '302') and count < 5
        new_url = response.header['location']
        log.debug_message += "Following #{response.code}: #{new_url}\n" unless log.nil?
        return make_request(new_url, log, count + 1)
      end
      response
    end

    def self.get_request_body(url)
      make_request(url).body
    end

    def do_check
      url = build_url

      @log.debug_message = "Request: #{url}\n"

      response = perform_action do
        HttpWorker.make_request url, @log
      end

      unless response.nil?
        @log.debug_message += "Http Responce Code #{response.code}\n"

        if response.code == '200'
          @log.debug_message += "Checking page against MD5/Regex: #{params[:home_check]}" unless params[:home_check].blank?
          if params[:home_check].blank? or perform_check response.body, params[:home_check]
            @log.message = "Http Responce Code #{response.code}"
            @log.status = ServiceLog::STATUS_RUNNING
          else
            log_server_error 'Incorrect Response (Defacement?)'
          end
        else
          @log.message = "Http Responce Code #{response.code}"
          @log.status = ServiceLog::STATUS_ERROR
        end

        #@log.debug_message += "\nResponse:\n#{response.body}"
      end
    end
  end
end