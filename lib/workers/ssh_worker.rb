require 'net/ssh'

module Workers
  class SshWorker < GenericWorker
    set_default_params rport: 22
    set_service_params({
     username: {description: 'User to login as', default: 'root', required: true},
     password: {description: 'Password to login with'},
     command: {description: 'Command to run on server', default: 'ls /home/#{username}/', required: true, param_replace: true},
     command_check: {description: 'Regex for command response to match', default: '.+', required: true, param_replace: true},
    })

    def worker_name
      :Ssh
    end

    def do_check
      #register_execption Net::SSH::Authentication::AgentError do
      #  log_server_error "Login Failure"
      #end

      log_server_connect
      log_server_login
      @log.debug_message += "\n"

      response = perform_action do
        Net::SSH.start(params[:rhost], params[:username], password: params[:password]) do |ssh|
          ssh.exec!(params[:command]).to_s
        end
      end

      unless response.nil?
        @log.debug_message += "Response:\n#{response}\n\nRegex Expected: /#{params[:command_check]}/"

        if perform_check response, params[:command_check]
          @log.status = ServiceLog::STATUS_RUNNING
          @log.message = "Correct response recieved"
        else
          @log.status = ServiceLog::STATUS_ERROR
          @log.message = "Incorrect response"
        end
      end
    end
  end
end
