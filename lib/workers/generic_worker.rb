require 'uri'
require 'tempfile'
require 'net/ssh'
require 'net/dns'
require 'rack/auth/digest/md5'

module Workers
  class GenericWorker
    attr_accessor :params

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
    }.with_indifferent_access

    # @param [Service] service
    def initialize service, options={}
      raise "Invalid Service Object sent to ServiceWorker" unless service.is_a? Service

      @service = service
      @log = ServiceLog.new(service_id: @service.id, message:'', debug_message:'')

      self.params = self.class.default_params.with_indifferent_access
      if service.params? and service.params.kind_of? Hash
        self.params.merge! service.params[self.worker_name] if service.params[self.worker_name].kind_of? Hash
      end

      self.params.each do |name, value|
        if self.class.service_params.key? name and self.class.service_params[name][:param_replace]
          self.params[name] = param_replace value
        end
      end

      unless options.empty?
        if options.key? :dns_server and not options[:dns_server].blank?
          @dns_server = options[:dns_server]
        else
          @dns_server = nil
        end
      end

      @exceptions = {}
    end

    def prefix
      nil
    end

    def register_exception name, &block
      @exceptions[name.to_s] = block
    end

    def build_url
      host = params[:rhost].chomp '/'
      path = params[:home_path].chomp '/' unless params[:home_path].nil?
      port = params[:rport].sub /[^0-9]/, ''
      (prefix.nil? ? '' : prefix + '://') + host + ':' + port + path
    end

    def do_check
      throw "Invalid Worker, Override GenericWorker#check"
    end

    def check
      self.class.required_params.each { |name| raise "Missing param: '#{name}'" unless params.key? name }
      params.each{|k,v| params[k.to_s] = v.to_s} # make sure each key/value is a string
      domain_ip = domain_lookup params[:rhost]
      if domain_ip.nil?
        log_server_error "Domain Lookup Failed: #{params[:rhost]}"
        return @log.status if @log.save
        return nil
      end
      params[:rhost] = domain_ip
      choose_username_password # Randomly choose username/password combo from comma separated list
      self.do_check
      unless @log.message.blank?
        return @log.status if @log.save
      end
      nil
    end

    def log_server_down message
      @log.status = ServiceLog::STATUS_DOWN
      message ||= "Server is down"
      @log.debug_message += message
      @log.message += message
    end

    def log_server_error message
      @log.status = ServiceLog::STATUS_ERROR
      message ||= "There was an error"
      @log.debug_message += message
      @log.message += message
    end

    def log_server_connect
      @log.debug_message = "Opening Connection to: #{params[:rhost]}:#{params[:rport]}\n"
    end

    def log_server_login username=nil, password=nil
      username = params[:username] if username.nil?
      password = params[:password] if password.nil?
      if password.blank?
        @log.debug_message += "Credentials: #{username} (NO PASSWORD)\n"
      else
        @log.debug_message += "Credentials: #{username} : #{password}\n"
      end
    end

    def self.dns_lookup hostname, dns_server, dns_port=53, record_type = Net::DNS::A
      dns = nil
      if dns_server.nil?
        dns = Net::DNS::Resolver.new(
            port: dns_port,
        )
      else
        dns_server.sub!(/(:\d+)$/, '') { dns_port = $1 if dns_port == 53 }
        dns = Net::DNS::Resolver.new(
            nameservers: dns_server,
            port: dns_port,
            domain: 'ccdc-practice',
        )
      end

      if dns.nil?
        return nil
      end

      dns.query(hostname, record_type)

    rescue Net::DNS::Resolver::NoResponseError
      puts "************NoResponseError: #{dns_server}, #{dns_port}, #{hostname}\n"
      nil
    end

    def self.domain_lookup hostname, dns_server, dns_port=53, record_type = Net::DNS::A
      # ignore if hostname is already an IP
      return hostname unless hostname.match(/^\d+\.\d+\.\d+\.\d+$/).nil?
      packet = dns_lookup hostname, dns_server, dns_port, record_type
      if packet.nil? or packet.answer.blank?
        nil
      else
        packet.answer.first.address.to_s
      end
    end

    def dns_lookup hostname, dns_server=nil, dns_port=53, record_type = Net::DNS::A
      # use default server if un-specified
      dns_server ||= @dns_server
      self.class.dns_lookup hostname, dns_server, dns_port, record_type
    end

    def domain_lookup hostname, dns_server=nil, dns_port=53, record_type = Net::DNS::A
      # use default server if un-specified
      dns_server ||= @dns_server
      self.class.domain_lookup hostname, dns_server, dns_port, record_type
    end

    # Replaced parameters embeded in strings using the #{...} syntax
    def param_replace string
      string.gsub(/#\{(.+?)\}/) { params.has_key?($1) ? params[$1]: $1 }
    end

    def perform_action
      begin
        return yield
      rescue Errno::ECONNREFUSED
        log_server_down "Connection refused"
      rescue Errno::ETIMEDOUT
        log_server_down "Connection timed out"
      rescue Errno::ECONNRESET
        log_server_down "Connection was reset"
      rescue Net::SSH::AuthenticationFailed
        log_server_error "Authentication failed"
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

    def perform_check content, check_value
      if (check_value =~ /^[a-f0-9]{32}$/i).nil?
        not (content =~ Regexp.new(check_value)).nil?
      else
        Digest::MD5.hexdigest(content) == check_value.downcase
      end
    end
  end
end