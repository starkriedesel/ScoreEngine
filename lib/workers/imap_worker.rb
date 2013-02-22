require 'net/smtp'

module Workers
  class SmtpWorker < GenericWorker
    set_default_params rport: 143
    set_service_params({
      username: {description: 'Login Name', required: true},
      password: {description: 'Login Password'},
    })

    def worker_name
      :Imap
    end

    def do_check
    end
  end
end