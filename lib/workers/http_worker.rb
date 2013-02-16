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

    def make_request url, count=1
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if url.include?('https')
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = http.request(Net::HTTP::Get.new(uri.request_uri))
      if response.code == '301' and count < 5
        new_url = response.header['location']
        @log.debug_message += "Following 301: #{new_url}\n"
        return make_request(new_url, count + 1)
      end
      response
    end

    def do_check
      url = build_url

      @log.debug_message = "Request: #{url}\n"

      response = perform_action do
        make_request url
      end

      unless response.nil?
        if response.code == '200'
          @log.status = ServiceLog::STATUS_RUNNING
        else
          @log.status = ServiceLog::STATUS_ERROR
        end

        @log.message = "Http Responce Code #{response.code}"
        @log.debug_message += "\nResponse:\n#{response.body}"
      end
    end
  end
end