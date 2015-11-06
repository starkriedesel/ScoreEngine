require 'uri'
require 'tempfile'
require 'timeout'
require 'net/ssh'
require 'net/dns'
require 'rack/auth/digest/md5'
require 'daemon/log'

# TODO: Add total time to the ServiceLog message, should be on every worker so it can be handled generically

module Workers
  class GenericWorker
    attr_accessor :params, :log, :service

    include WorkerMixin

    set_service_params({
      rhost: {description: 'Host to connect to', name: 'Host', required: true},
      rport: {description: 'Port to connect to', name: 'Port', required: true},
    })

    WORKERS = {
        Http: 'HttpWorker',
        Https: 'HttpsWorker',
        Ftp: 'FtpWorker',
        Ftps: 'FtpsWorker',
        Sftp: 'SftpWorker',
        Ssh: 'SshWorker',
        Dns: 'DnsWorker',
        Mysql: 'MysqlWorker',
        Ldap: 'LdapWorker',
        Smtp: 'SmtpWorker',
        Imap: 'ImapWorker',
        Netcat: 'NetcatWorker',
    }.with_indifferent_access

    # @param [Service] service
    def initialize(service, options={})
      raise 'Invalid Service Object sent to ServiceWorker' unless service.is_a? Service

      @timeout = options[:timeout].to_i || 30
      @service = service
      @log = ServiceLog.new(service_id: @service.id, message:'', debug_message:'')
      @complete = false

      self.params = self.class.default_params.with_indifferent_access
      if service.params? and service.params.kind_of? Hash
        self.params.merge! service.params[self.worker_name.to_s] if service.params[self.worker_name.to_s].kind_of? Hash
      end

      unless options.empty?
        if options.key? :dns_server and not options[:dns_server].blank?
          @dns_server = options[:dns_server]
        else
          @dns_server = nil
        end

        if options.key? :domain and not options[:domain].blank?
          self.params[:domain] = options[:domain]
        else
          self.params[:domain] = ''
        end
      end

      self.params.each do |name, value|
        if self.class.service_params.key? name
          self.params[name] = param_replace value
        end
      end

      @exceptions = {}
    end

    def prefix
      nil
    end

    def register_exception(name, &block)
      @exceptions[name.to_s] = block
    end

    def build_url
      host = params[:rhost].chomp '/'
      path = params[:home_path] unless params[:home_path].nil?
      port = params[:rport].sub /[^0-9]/, ''
      (prefix.nil? ? '' : prefix + '://') + host + ':' + port + path
    end

    def do_check
      throw 'Invalid Worker, Override GenericWorker#check'
    end

    def check
      @complete = false
      @log = ServiceLog.new(service_id: @service.id, message:'', debug_message:'')
      self.class.required_params.each { |name| raise "Missing param: '#{name}'" unless params.key? name }
      params.each{|k,v| params[k.to_s] = v.to_s} # make sure each key/value is a string

      domain_ip = domain_lookup params[:rhost]
      if domain_ip.nil?
        log_server_error "Domain Lookup Failed: #{params[:rhost]}"
        log_daemon_info "Domain Lookup Failed: #{params[:rhost]}", @service
        return @log.status if @log.save
        return nil
      end
      params[:rhost] = domain_ip
      choose_username_password # Randomly choose username/password combo from comma separated list

      log_daemon_info 'Checking service', @service

      time_start = Time.now
      begin
        Timeout::timeout(@timeout) { self.do_check }
      rescue Timeout::Error
        log_server_error 'Timeout'
      end
      time_end = Time.now

      @log.debug_message += "Elapsed Time: #{(time_end - time_start)} sec\n"

      @complete = true
      @log
    end

    def complete?
      !!@complete
    end

    def log_server_down(message)
      @log.status = ServiceLog::STATUS_DOWN
      message ||= 'Server is down'
      @log.debug_message += "#{message}\n"
      @log.message += message
      true
    end

    def log_server_error(message)
      @log.status = ServiceLog::STATUS_ERROR
      message ||= 'There was an error'
      @log.debug_message += "#{message}\n"
      @log.message += message
      true
    end

    def log_server_connect
      @log.debug_message += "Opening Connection to: #{params[:rhost]}:#{params[:rport]}\n"
      true
    end

    def log_server_login(username=nil, password=nil)
      username = params[:username] if username.nil?
      password = params[:password] if password.nil?
      if password.blank?
        @log.debug_message += "Credentials: #{username} (NO PASSWORD)\n"
      else
        @log.debug_message += "Credentials: #{username}\n" # removed password for security purposes
      end
      true
    end

    # Lookup domain; uses given dns server, stored @dns_server, or default system server
    # Returns first match as string
    # Will pass through IP addresses
    # Never throws, returns nil on failure
    def domain_lookup(hostname, dns_server=nil, dns_port=53, record_type = Net::DNS::A)
      domain_lookup_with_errors hostname, dns_server, dns_port, record_type
    rescue => e
      nil
    end

    # Same as domain_lookup but throws
    def domain_lookup_with_errors(hostname, dns_server=nil, dns_port=53, record_type = Net::DNS::A)
      # pass through IP addresses
      return hostname unless hostname.match(/^\d+\.\d+\.\d+\.\d+$/).nil?

      packet = raw_domain_lookup hostname, dns_server, dns_port, record_type
      answer = packet.answer.first
      @log.debug_message += "DNS Response: #{answer}\n"
      if answer.type == 'CNAME' and record_type != Net::DNS::CNAME
        @log.debug_message += "Found CNAME: #{answer.cname}\n"
        return domain_lookup_with_errors answer.cname, dns_server, dns_port, record_type
      else
        response = answer.address.to_s
      end
      response
    rescue =>e
      @log.debug_message += "Domain lookup failed: #{e.message}\n"
      raise e
    end

    def self.raw_domain_lookup(hostname, dns_server=nil, dns_port=53, record_type = Net::DNS::A)
      tmp_worker = GenericWorker.new(Service.new)
      tmp_worker.raw_domain_lookup hostname, dns_server,dns_port, record_type
    end

    # Performs a lookup similar to domain_lookup but throws and returns the full packet
    def raw_domain_lookup(hostname, dns_server=nil, dns_port=53, record_type = Net::DNS::A)
      # use default server if un-specified
      dns_server ||= @dns_server

      @log.debug_message += "Domain lookup: #{hostname} @#{dns_server.nil? ? 'default' : dns_server} (type #{DnsWorker.record_name record_type})\n"

      if dns_server.nil?
        dns = Net::DNS::Resolver.new(port: dns_port)
      else
        dns_server.sub!(/(:\d+)$/, '') { dns_port = $1 if dns_port == 53 }
        dns = Net::DNS::Resolver.new(
            nameservers: dns_server,
            port: dns_port,
            domain: params[:domain],
        )
      end

      if dns.nil?
        packet = nil
      else
        packet = dns.query hostname, record_type
      end

      if packet.blank? or packet.answer.blank?
        raise Net::DNS::Resolver::NoResponseError.new
      else
        packet
      end
    end

    # Replaced parameters embeded in strings using the {...} syntax
    def param_replace(string)
      string = string.gsub(/\{(.+?)\}/) { params.has_key?($1.downcase) ? params[$1.downcase]: $1 }
      string.sub '\\n', "\n"
    end

    def perform_action
      begin
        return yield
      rescue Errno::ECONNREFUSED
        log_server_down 'Connection refused'
      rescue Errno::ETIMEDOUT
        log_server_down 'Connection timed out'
      rescue Errno::ECONNRESET
        log_server_down 'Connection was reset'
      rescue Errno::EHOSTUNREACH
        log_server_down 'Host Unreachable'
      rescue Net::SSH::AuthenticationFailed
        log_server_error 'Authentication failed'
      rescue Net::DNS::Resolver::NoResponseError
        log_server_error 'No response from DNS'
      rescue Timeout::Error
        throw Timeout:Error # This error is handled by GenericWorker#check
      rescue => e
        if @exceptions.key? e.class.to_s
          p = @exceptions[e.class.to_s]
          p.call e unless p.nil?
          log_server_error "#{e.class.name.to_s}: #{e.message}" if p.nil?
        else
          #log_server_error "Exception: #{e.class.name}"
          raise e
        end
      end
      nil
    end

    def choose_username_password
      params[:username].split! ',' if not params[:username].nil? and params[:username].include? ","
      params[:password].split! ',' if not params[:password].nil? and params[:password].include? ","

      if params[:username].kind_of? Array
        if params[:password].kind_of? Array
          n = rand([params[:username].length, params[:password].length].min)
          params[:username] = params[:username][n]
          params[:password] = params[:password][n]
        else
          params[:username] = params[:username][rand(params[:username].length)]
        end
      else
        params[:password] = params[:password].first if params[:password].kind_of? Array
      end

      params[:password].strip! unless params[:password].nil?
      params[:username].strip! unless params[:password].nil?
    end

    def perform_check(content, check_value)
      if (check_value =~ /^[a-f0-9]{32}$/i).nil?
        if check_value.length > 1 and check_value[0] == '/' and check_value[-1] == '/'
          @log.debug_message += "Using regex check\n"
          not (content =~ Regexp.new(check_value[1..-2])).nil?
        else
          @log.debug_message += "Using include check\n"
          content.include? check_value
        end
      else
        @log.debug_message += "Using md5 check\n"
        Digest::MD5.hexdigest(content) == check_value.downcase
      end
    end
  end
end
