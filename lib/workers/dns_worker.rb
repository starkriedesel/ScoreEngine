module Workers
  class DnsWorker < GenericWorker
    set_default_params rport: 53
    set_service_params({
      hostname: {description: 'Host name to lookup', default: 'google.com', required: true},
      record_type: {description: 'Record type to lookup', default: 'A', required: true},
    })

    def worker_name
      "Dns"
    end

    def do_check
      dns = Net::DNS::Resolver.new(
          nameservers: params[:rhost],
          port: params[:rport].to_i
      )

      record_type = params[:record_type]
      if record_type == 'A'
        record_type = Net::DNS::A
      elsif record_type == 'AAAA'
        record_type = Net::DNS::AAAA
      else
        record_type = Net::DNS::A # defaults to A type
      end

      packet = perform_action do
        dns.query(params[:hostname], record_type)
      end

      if packet.answer.blank?
        @log.status = ServiceLog::STATUS_ERROR
        @log.message = "Empty response for '#{params[:hostname]}' (type #{params[:record_type]})"
      else
        @log.status = ServiceLog::STATUS_RUNNING
        @log.message = "Recieved response for '#{params[:hostname]}' (type #{params[:record_type]})"
      end

      @log.debug_message = packet.to_s
    end
  end
end