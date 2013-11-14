require 'socket'

module Workers
  class NetcatWorker < GenericWorker
    set_service_params({
        send: {description: 'Data to send after connection is made'},
        receive: {description: 'Regex of data to receive after data is sent'},
    })

    def worker_name
      'Netcat'
    end

    def do_check
      perform_action do
        log_server_connect

        addr = Socket.getaddrinfo params[:rhost], nil
        sock = Socket.new addr[0][0], Socket::SOCK_STREAM, 0

        optval = [5,0].pack 'l_2'
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval

        sock.connect Socket.pack_sockaddr_in(params[:rport], addr[0][3])

        unless params[:send].blank?
          @log.debug_message += "Sending: #{params[:send]}\n"
          sock.write params[:send]
        end

        unless params[:receive].blank?
          @log.debug_message += "Expecting response: #{params[:receive]}\n"
          response = sock.recv 1024
          @log.debug_message += "Received:\n#{response}\n"
          #unless perform_check response, params[:receive]
          #  log_server_error 'Incorrect Response'
          #end
        end

        @log.debug_message += "Closing connection\n"
        sock.close

        @log.status = ServiceLog::STATUS_RUNNING
        @log.message = 'Success'
      end
    end
  end
end