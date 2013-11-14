require 'net/ldap'

module Workers
  class LdapWorker < GenericWorker
    set_default_params rport: 389
    set_service_params({
         domain: {description: 'Domain to login into', required: true},
         username: {description: 'User to login as', default: 'anonymous', required: true},
         password: {description: 'Password to login with', default: ''},
     })

    def worker_name
      'Ldap'
    end

    def do_check
      email = "#{params[:username]}@#{params[:domain]}"

      log_server_connect
      log_server_login email

      ldap = Net::LDAP.new host: params[:rhost], port: params[:rport], auth: {method: :simple, username: email, password: params[:password]}

      success = false
      perform_action do
        success = ldap.bind
        unless success
          log_server_error 'Username/Password Invalid for LDAP Auth'
          return
        end
        @log.debug_message += "LDAP Login Successful\n"
      end

      if success
        @log.message = 'LDAP Login Successful'
        @log.status = ServiceLog::STATUS_RUNNING
      end
    end
  end
end
