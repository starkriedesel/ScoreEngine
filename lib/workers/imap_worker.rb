require 'net/imap'

module Workers
  class ImapWorker < GenericWorker
    set_default_params rport: 143
    set_service_params({
      username: {description: 'Login Name', required: true},
      password: {description: 'Login Password'},
    })

    def worker_name
      :Imap
    end

    def do_check
      register_exception Net::IMAP::ResponseError do |e|
        log_server_error "IMAP Error: #{e}"
      end
      register_exception Net::IMAP::NoResponseError do |e|
        log_server_error "Authentication failed"
      end

      perform_action do
        log_server_connect
        imap = Net::IMAP.new params[:rhost], {port: params[:rport]}
        log_server_login
        imap.login params[:username], params[:password]
        @log.debug_message += "Checking INBOX\n"
        imap.examine 'INBOX'
        @log.debug_message += "Searching by RECENT\n"
        imap.search ['RECENT']
      end

      if @log.status.nil?
        @log.status = ServiceLog::STATUS_RUNNING
        @log.message = "Service Running"
      end
    end
  end
end