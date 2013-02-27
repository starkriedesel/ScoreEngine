require 'net/smtp'

module Workers
  class SmtpWorker < GenericWorker
    set_default_params rport: 25
    set_service_params({
      to_email: {description: 'Destination email address', required: true},
      from_email: {description: 'Source email address', required: true},
      helo_domain: {description: 'Source Domain (HELO)'},
      username: {description: 'Login Name'},
      password: {description: 'Login Password'},
      authtype: {description: 'Authentication Type (PLAIN, LOGIN, CRAM_MD5)', default: ''},
     })

    def worker_name
      :Smtp
    end

    def self.auathtype_order
      [:plain, :login, :cram_md5]
    end

    def do_login authtype
      if authtype.is_a? String
        input = authtype
        authtype = authtype.downcase.gsub(' ','_')
        authtype = self.class.auathtype_order.select {|a| a.to_s == authtype}.first
        if authtype.nil?
          @log.debug_message += "Unknown authentication method: #{input}\n"
          return try_login
        end
      end
      @log.debug_message += "Trying authentication using #{authtype.to_s.upcase.gsub '_', ' '}\n"
      return Net::SMTP.start params[:rhost], params[:rport], params[:helo_domain], params[:username], params[:password], authtype
    rescue => e
      @log.debug_message += "Failed with error: #{e.message}\n"
      nil
    end

    def try_login
      smtp = nil
      self.class.auathtype_order.each do |authtype|
        smtp = do_login authtype if smtp.nil?
      end
      smtp
    end

    def do_check
      smtp = nil
      success = false

      register_exception Net::SMTPFatalError
      register_exception Net::SMTPAuthenticationError
      register_exception Net::SMTPSyntaxError
      register_exception Net::SMTPUnknownError
      register_exception Net::SMTPUnsupportedCommand
      register_exception Net::SMTPServerBusy do |e|
        log_server_error "Server Busy"
      end

      perform_action do

        log_server_connect
        log_server_login

        @log.debug_message += "HELO #{params[:helo_domain]}\n" unless params[:helo_domain].blank?

        # Connect
        if params[:username].blank?
          @log.debug_message += "No LOGIN\n"
          smtp = Net::SMTP.start(params[:rhost], params[:rport], params[:helo_domain])
        else
          if params[:authtype].blank?
            smtp = try_login
          else
            smtp = do_login params[:authtype]
          end
        end

        if smtp.nil?
          log_server_error "Failed to Connect/Authenticate"
          return
        end

        o = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
        random_string = (0...50).map{ o[rand(o.length)] }.join

        msg_str = "From: #{params[:from_email]}\nTo: #{params[:to_email]}\nSubject: #{Time.now.to_i}\nDate: #{Time.now.iso8601}\n\n#{random_string}\n"

        @log.debug_message += "Sending mail from #{params[:from_email]} to #{params[:to_email]}\nContents: #{random_string}\n"
        smtp.send_message msg_str, params[:from_email], params[:to_email]

        success = true
      end

      # Disconnect
      smtp.finish unless smtp.nil?

      if @log.status.nil?
        if success
          @log.status = ServiceLog::STATUS_RUNNING
          @log.message = "Send Mail Success"
        else
          log_server_error "Unknown Error"
        end
      end
    end
  end
end